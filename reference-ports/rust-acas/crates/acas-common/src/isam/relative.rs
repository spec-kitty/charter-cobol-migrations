//! Relative-organization files — F-B002 framing.
//!
//! Layout, verified against `fixtures/generated/setup/system.dat` (4128 B):
//!
//! ```text
//! [ rrn 1 .. rrn N ]  N contiguous records of `record_size` bytes
//! [ trailer ]         whatever followed the last record, copied verbatim
//! ```
//!
//! No per-record used/free marker: the record number *is* the position
//! (`pread(fd, (rrn-1) * record_size)`). The fresh-file trailer is 32 spaces,
//! purpose unknown; F-B002 says carry it verbatim, so we do — byte-exactly,
//! including a zero-length trailer if a file has none.

use std::path::{Path, PathBuf};

use super::{IsamError, Result};

/// A relative file held in memory: record frames plus the untouched trailer.
#[derive(Debug)]
pub struct RelativeFile {
    path: PathBuf,
    record_size: usize,
    records: Vec<Vec<u8>>,
    trailer: Vec<u8>,
}

impl RelativeFile {
    /// Read a relative file, splitting the tail past the last whole record
    /// into `trailer`.
    ///
    /// A trailer at least one record long means the file is not the framing we
    /// know (F-B002); that is `Malformed`, not a silent guess.
    pub fn open(path: impl AsRef<Path>, record_size: usize) -> Result<Self> {
        if record_size == 0 {
            return Err(IsamError::Malformed("record size 0".into()));
        }
        let data = std::fs::read(path.as_ref())?;
        let whole = data.len() / record_size;
        let used = whole * record_size;
        // The trailer is whatever is left. The format has no length field, so
        // it is only recoverable while it stays shorter than one record; with
        // record sizes <= 32 a saved trailer folds back into records.
        let trailer = data[used..].to_vec();
        let records = (0..whole)
            .map(|i| data[i * record_size..(i + 1) * record_size].to_vec())
            .collect();
        Ok(Self {
            path: path.as_ref().to_owned(),
            record_size,
            records,
            trailer,
        })
    }

    /// Build an empty relative file under `path` with a 32-space trailer.
    pub fn create(path: impl AsRef<Path>, record_size: usize) -> Self {
        Self {
            path: path.as_ref().to_owned(),
            record_size,
            records: Vec::new(),
            trailer: vec![b' '; super::TRAILER_LEN],
        }
    }

    /// Record count (highest valid RRN).
    pub fn len(&self) -> usize {
        self.records.len()
    }

    pub fn is_empty(&self) -> bool {
        self.records.is_empty()
    }

    pub fn record_size(&self) -> usize {
        self.record_size
    }

    pub fn trailer(&self) -> &[u8] {
        &self.trailer
    }

    /// 1-based RRN read, exactly the COBOL `READ … KEY rrn` affordance.
    pub fn read_record(&self, rrn: usize) -> Result<&[u8]> {
        self.records
            .get(rrn.saturating_sub(1))
            .map(Vec::as_slice)
            .ok_or_else(|| IsamError::NoRecord { key: format!("rrn {rrn}") })
    }

    /// 1-based RRN write. Gaps between the last record and `rrn` are filled
    /// with space records, which is how GnuCOBOL extends a relative file.
    pub fn write_record(&mut self, rrn: usize, body: &[u8]) -> Result<()> {
        if rrn == 0 {
            return Err(IsamError::Malformed("rrn 0".into()));
        }
        if body.len() != self.record_size {
            return Err(IsamError::Malformed(format!(
                "record {} B != file record size {} B",
                body.len(),
                self.record_size
            )));
        }
        while self.records.len() < rrn {
            self.records.push(vec![b' '; self.record_size]);
        }
        self.records[rrn - 1].copy_from_slice(body);
        Ok(())
    }

    /// Append past the last record; returns the new RRN.
    pub fn append(&mut self, body: &[u8]) -> Result<usize> {
        let rrn = self.records.len() + 1;
        self.write_record(rrn, body)?;
        Ok(rrn)
    }

    /// Serialize back to disk, trailer included.
    pub fn save(&self) -> Result<()> {
        let mut out =
            Vec::with_capacity(self.records.len() * self.record_size + self.trailer.len());
        for r in &self.records {
            out.extend_from_slice(r);
        }
        out.extend_from_slice(&self.trailer);
        std::fs::write(&self.path, out)?;
        Ok(())
    }
}
