//! acas-common — Rust port skeleton for ACAS.
//! Behaviors ported per charter-pack directives; see docs/disposition.yaml.

//! System-file record types, ISAM abstraction, environment resolution.
//!
//! Phase 1 brings up only the system file (wssystem.cob layout →
//! `SystemFile`) and the environment gate (ACAS_LEDGERS/ACAS_IRS/ACAS_BIN)
//! because those two are load-bearing for everything else.

use std::path::PathBuf;

/// ACAS runtime environment (mirrors ACAS.cbl zz010-Get-Env-Set-Files).
///
/// In COBOL these arrive as `ACCEPT ... FROM ENVIRONMENT`, fail → SY009 abort.
/// We keep *that behavior exactly* — the affordance that ACAS refuses to run
/// without explicit directories is a feature (it prevents data writes into
/// unknown paths) and is therefore carried, not retired.
#[derive(Debug, Clone)]
pub struct AcasEnv {
    pub ledgers: PathBuf,
    pub irs: PathBuf,
    pub bin: PathBuf,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum EnvError {
    /// L2R behavior parity: SY009 — one or more required env vars unset.
    Missing(Vec<&'static str>),
}

impl std::fmt::Display for EnvError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            EnvError::Missing(v) =>
                write!(f, "SY009 Environment variables not yet set up: {:?}", v),
        }
    }
}

impl std::error::Error for EnvError {}

impl AcasEnv {
    /// Mirror of zz010. Missing var names echoed exactly as COBOL does.
    pub fn from_env() -> Result<Self, EnvError> {
        let mut missing = vec![];
        let ledgers = std::env::var("ACAS_LEDGERS").ok().or_else(|| {
            missing.push("ACAS_LEDGERS");
            None
        });
        let irs = std::env::var("ACAS_IRS").ok().or_else(|| {
            missing.push("ACAS_IRS");
            None
        });
        let bin = std::env::var("ACAS_BIN").ok().or_else(|| {
            missing.push("ACAS_BIN");
            None
        });
        if !missing.is_empty() {
            return Err(EnvError::Missing(missing));
        }
        Ok(Self {
            ledgers: PathBuf::from(ledgers.unwrap()),
            irs: PathBuf::from(irs.unwrap()),
            bin: PathBuf::from(bin.unwrap()),
        })
    }

    /// Whether the caller asked for the Unix path dialect (first char `/`).
    /// L2R behavior parity with `if ACAS_LEDGERS (1:1) = "/"`.
    pub fn os_delimiter(&self) -> char {
        match self.ledgers.as_os_str().to_string_lossy().chars().next() {
            Some('/') => '/',
            Some('\\') => '\\',
            _ => std::path::MAIN_SEPARATOR,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn env_missing_all_gives_sy009() {
        // SAFETY: single-test threads only; key names unique to this test.
        for k in ["ACAS_LEDGERS", "ACAS_IRS", "ACAS_BIN"] {
            std::env::remove_var(k);
        }
        match AcasEnv::from_env() {
            Err(EnvError::Missing(v)) => {
                assert!(v.contains(&"ACAS_LEDGERS"));
                assert!(v.contains(&"ACAS_IRS"));
                assert!(v.contains(&"ACAS_BIN"));
            }
            _ => panic!("expected SY009"),
        }
    }

    #[test]
    fn env_unix_delim() {
        std::env::set_var("ACAS_LEDGERS", "/tmp/acas-test/ACAS");
        std::env::set_var("ACAS_IRS", "/tmp/acas-test/IRS");
        std::env::set_var("ACAS_BIN", "/tmp/acas-test/bin");
        let e = AcasEnv::from_env().unwrap();
        assert_eq!(e.os_delimiter(), '/');
    }
}
pub mod isam;

#[cfg(test)]
#[path = "tests/fixtures.rs"]
mod fixtures;
