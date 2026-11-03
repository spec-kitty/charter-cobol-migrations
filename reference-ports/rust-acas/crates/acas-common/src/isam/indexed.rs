//! Indexed-organization files — reader for both shapes in F-B005.
//!
//! Two on-disk shapes exist for the same `ORGANIZATION INDEXED` FD:
//!
//! * **Paged** (shape A) — what GnuCOBOL writes when *it* creates the file:
//!   4 KiB block-0 header, then 4 KiB leaf pages whose items are
//!   `[len: u8][00 01][body]`, records and key-only separators interleaved.
//! * **Flat** (shape B) — the hand-authored framing our fixtures use:
//!   contiguous `record_size` records, 32 B space trailer, no header.
//!
//! The harness sees shape B (ACAS rewrote our fixtures in place) while a
//! clean ACAS run will leave shape A, so the reader accepts both and the
//! writer emits shape A (`sl055.cbl:269` reads `next record` in key order;
//! `rewrite` needs stable-size records, which both shapes give).
//!
//! Keys are always at body offset 0 (F-B005), so no key copy is stored.

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use super::{IsamError, Result};

/// Header/granularity constants pinned by F-B005.
const BLOCK_SIZE: usize = 4096;
const PAGE_TYPE_LEAF: u32 = 1;
const ITEM_FLAGS: [u8; 2] = [0x00, 0x01];

/// Which on-disk shape a file uses.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IndexedLayout {
    /// GnuCOBOL-created: block 0 header + leaf pages. See F-B005.
    Paged,
    /// Fixture-authored: flat records, no header. See F-B005 shape B.
    Flat,
}

/// Read-only view of an indexed file, records held in key order.
#[derive(Debug)]
pub struct IndexedFile {
    path: PathBuf,
    layout: IndexedLayout,
    record_size: usize,
    key_len: usize,
    records: BTreeMap<Vec<u8>, Vec<u8>>,
    trailer: Vec<u8>,
    page_count: u32,
}

impl IndexedFile {
    /// Open and decode an indexed file.
    ///
    /// `key_len` and `record_size` come from the FD — neither is stored in the
    /// paged header (F-B005). An unrecognizable file is `Malformed` rather
    /// than being guessed at.
    pub fn open(path: impl AsRef<Path>, record_size: usize, key_len: usize) -> Result<Self> {
        if record_size == 0 || key_len == 0 || key_len > record_size {
            return Err(IsamError::Malformed(format!(
                "bad sizes: record {record_size} B, key {key_len} B"
            )));
        }
        let data = std::fs::read(path.as_ref())?;
        let layout = detect_layout(&data, record_size)?;
        let mut me = Self {
            path: path.as_ref().to_owned(),
            layout,
            record_size,
            key_len,
            records: BTreeMap::new(),
            trailer: Vec::new(),
            page_count: 0,
        };
        match layout {
            IndexedLayout::Paged => me.decode_paged(&data)?,
            IndexedLayout::Flat => me.decode_flat(&data)?,
        }
        Ok(me)
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn layout(&self) -> IndexedLayout {
        self.layout
    }

    pub fn record_size(&self) -> usize {
        self.record_size
    }

    pub fn key_len(&self) -> usize {
        self.key_len
    }

    pub fn len(&self) -> usize {
        self.records.len()
    }

    pub fn is_empty(&self) -> bool {
        self.records.is_empty()
    }

    /// Page count as recorded in the paged header (0 for flat files).
    pub fn page_count(&self) -> u32 {
        self.page_count
    }

    /// Trailer bytes carried verbatim (flat shape only; F-B002).
    pub fn trailer(&self) -> &[u8] {
        &self.trailer
    }

    /// Exact-key read — `READ … KEY` on the primary key.
    pub fn get(&self, key: &[u8]) -> Option<&[u8]> {
        self.records.get(key).map(Vec::as_slice)
    }

    /// `READ … NEXT RECORD`: ascending key order, key paired with body.
    pub fn iter(&self) -> impl Iterator<Item = (&[u8], &[u8])> {
        self.records
            .iter()
            .map(|(k, v)| (k.as_slice(), v.as_slice()))
    }

    /// Start position for `START … KEY NOT <` — the lowest key >= `key`.
    pub fn first_at_or_after(&self, key: &[u8]) -> impl Iterator<Item = (&[u8], &[u8])> {
        self.records
            .range::<[u8], _>((std::ops::Bound::Included(key), std::ops::Bound::Unbounded))
            .map(|(k, v)| (k.as_slice(), v.as_slice()))
    }

    fn insert(&mut self, body: &[u8]) {
        let key = body[..self.key_len].to_vec();
        self.records.insert(key, body.to_vec());
    }

    fn decode_flat(&mut self, data: &[u8]) -> Result<()> {
        let whole = data.len() / self.record_size;
        let used = whole * self.record_size;
        let trailer = data[used..].to_vec();
        self.trailer = trailer;
        for i in 0..whole {
            let body = &data[i * self.record_size..(i + 1) * self.record_size];
            // A blank record is a pad slot, not a row: ACAS never keys one.
            if body.iter().all(|b| *b == b' ' || *b == 0) {
                continue;
            }
            self.insert(body);
        }
        Ok(())
    }

    fn decode_paged(&mut self, data: &[u8]) -> Result<()> {
        let page_count = u32_bytes(&data[32..36]) as usize;
        let pages = data.len() / BLOCK_SIZE;
        if page_count > pages {
            return Err(IsamError::Malformed(format!(
                "header claims {page_count} pages, file holds {pages}"
            )));
        }
        self.page_count = page_count as u32;
        let want = self.record_size as u8;
        // F-B005: every record item is `[len][00 01][body]` with len ==
        // record_size; key-only separators carry len == key_len instead, so the
        // length byte is the discriminator. Walking pages 1..n and sorting by
        // key is idempotent with the page order, and the backend keeps leaves
        // only at the sizes we run (100-record probe: 6 leaves, no root).
        for page in 1..pages {
            let base = page * BLOCK_SIZE;
            let block = &data[base..base + BLOCK_SIZE];
            if u32_bytes(&block[4..8]) != PAGE_TYPE_LEAF {
                continue;
            }
            let mut at = 0usize;
            while at + 3 + self.record_size <= BLOCK_SIZE {
                if block[at] != want || block[at + 1..at + 3] != ITEM_FLAGS {
                    at += 1;
                    continue;
                }
                let body = &block[at + 3..at + 3 + self.record_size];
                if !plausible_key(&body[..self.key_len]) {
                    at += 1;
                    continue;
                }
                self.insert(body);
                at += 3 + self.record_size;
            }
        }
        Ok(())
    }
}

fn detect_layout(data: &[u8], record_size: usize) -> Result<IndexedLayout> {
    let paged = data.len() >= BLOCK_SIZE * 2
        && data.len().is_multiple_of(BLOCK_SIZE)
        && u32_bytes(&data[0..4]) == 0
        && u32_bytes(&data[20..24]) as usize == BLOCK_SIZE
        && u32_bytes(&data[4..8]) == 1;
    if paged {
        return Ok(IndexedLayout::Paged);
    }
    // Flat shape B: at least one record and a trailing remainder shorter than
    // one record (the space trailer). No header, so the first bytes are the
    // first record key, not a block id.
    if data.len() > record_size {
        return Ok(IndexedLayout::Flat);
    }
    Err(IsamError::Malformed(format!(
        "neither F-B005 shape: {} B, record size {record_size} B",
        data.len()
    )))
}

fn plausible_key(key: &[u8]) -> bool {
    // ACAS primary keys are display bytes of a `9(8)`/`x(3)` head, and the
    // item_nos byte that follows may be binary. Blank/zebra garbage is not.
    !key.is_empty()
        && key
            .iter()
            .all(|b| *b == b' ' || (0x21..=0x7e).contains(b) || *b < 0x20)
        && key.iter().any(|b| *b != b' ' && *b != 0)
}

fn u32_bytes(b: &[u8]) -> u32 {
    u32::from_le_bytes([b[0], b[1], b[2], b[3]])
}
