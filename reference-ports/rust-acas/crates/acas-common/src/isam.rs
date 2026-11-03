//! ACAS on-disk file formats.
//!
//! Two families, both empirically derived because ACAS talks to them directly
//! and a hybrid COBOL/Rust run must not see a format boundary:
//!
//! * [`relative`] — GnuCOBOL RELATIVE framing (F-B002): fixed stride, no
//!   markers, verbatim trailer. Used by `system.dat` and the ledger files.
//! * [`indexed`] — `ORGANIZATION INDEXED` files (F-B005): paged when GnuCOBOL
//!   creates them, flat when a builder authored them. Reader accepts both.
//!
//! `fixtures` builds byte-exact inputs for parity runs, so both halves of a
//! run start from identical bytes (charter L2R-002).

use std::path::PathBuf;

pub mod fixtures;
pub mod indexed;
pub mod relative;

pub use indexed::{IndexedFile, IndexedLayout};
pub use relative::RelativeFile;

/// Fresh relative files end with this many spaces (F-B002). Purpose unknown;
/// carried verbatim because dropping it would change every file we write.
pub const TRAILER_LEN: usize = 32;

pub type Result<T> = std::result::Result<T, IsamError>;

#[derive(thiserror::Error, Debug)]
pub enum IsamError {
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
    #[error("malformed: {0}")]
    Malformed(String),
    #[error("no record for key {key}")]
    NoRecord { key: String },
    #[error("duplicate key {key}")]
    DuplicateKey { key: String },
}

/// Which family a path belongs to, resolved from the name ACAS itself uses.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FileKind {
    /// `system.dat` — relative, 1024 B records.
    System,
    /// `invoice.dat` — indexed, 134 B records, 10 B key (`fdinv2.cob`).
    Invoice,
    /// `value.dat` — indexed, 66 B records, 3 B key (`fdval.cob`).
    Value,
    /// `analysis.dat` — indexed, 36 B records, 3 B key (`fdanal.cob`).
    Analysis,
    /// `openitm2.dat` — sequential, 114 B records (`fdoi2.cob`).
    OpenItem2,
}

impl FileKind {
    /// Record size from the FD that owns the file. These are byte facts, not
    /// preferences: `fdinv2.cob` header comment "size 134 bytes", `fdval.cob`
    /// "record size 66 bytes", `fdanal.cob` "36 bytes", `fdoi2.cob` "114
    /// bytes". The `value` figure was re-measured from a GnuCOBOL write
    /// (`fixtures/isam_probe/gen_value.cbl` → 0x42 length prefix).
    pub fn record_size(self) -> usize {
        match self {
            FileKind::System => 1024,
            FileKind::Invoice => 134,
            FileKind::Value => 66,
            FileKind::Analysis => 36,
            FileKind::OpenItem2 => 114,
        }
    }

    /// Primary-key length, 0 for non-indexed kinds (`selinv.cob`,
    /// `selval.cob`, `selanal.cob`).
    pub fn key_len(self) -> usize {
        match self {
            FileKind::Invoice => 10,
            FileKind::Value | FileKind::Analysis => 3,
            FileKind::System | FileKind::OpenItem2 => 0,
        }
    }

    pub fn is_indexed(self) -> bool {
        self.key_len() > 0
    }

    /// Resolve from a path by file name, as `zz010-Get-Env-Set-Files` does.
    pub fn from_path(path: impl Into<PathBuf>) -> Option<(Self, PathBuf)> {
        let path = path.into();
        let kind = match path.file_name()?.to_str()? {
            "system.dat" => FileKind::System,
            "invoice.dat" => FileKind::Invoice,
            "value.dat" => FileKind::Value,
            "analysis.dat" => FileKind::Analysis,
            "openitm2.dat" => FileKind::OpenItem2,
            _ => return None,
        };
        Some((kind, path))
    }
}

/// Any ACAS data file, opened through the framing its kind implies.
#[derive(Debug)]
pub enum DataFile {
    Relative(RelativeFile),
    Indexed(IndexedFile),
}

impl DataFile {
    /// Open by name, refusing kinds we have no pinned layout for.
    pub fn open(path: impl Into<PathBuf>) -> Result<Self> {
        let (kind, path) = FileKind::from_path(path)
            .ok_or_else(|| IsamError::Malformed("unknown ACAS data file name".into()))?;
        if kind.is_indexed() {
            Ok(DataFile::Indexed(IndexedFile::open(
                path,
                kind.record_size(),
                kind.key_len(),
            )?))
        } else if kind == FileKind::System {
            Ok(DataFile::Relative(RelativeFile::open(
                path,
                kind.record_size(),
            )?))
        } else {
            // Sequential fixed-record file: the relative framing applies.
            Ok(DataFile::Relative(RelativeFile::open(
                path,
                kind.record_size(),
            )?))
        }
    }
}
