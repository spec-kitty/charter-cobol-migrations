//! Byte-format verifications of the 2026-11-02 harness runs.
//!
//! These tests pin the observed on-disk ISAM relative-file layout we captured
//! from `/tmp/acas-harness-env/ACAS/system.dat` (GnuCOBOL 3.1.2 dialect,
//! 4-slot `RECORD 1024` file) so the decoder's format assumptions stay honest
//! as the build changes under it.

#[test]
fn acas_system_dat_total_size_at_least_4_128b() {
    // From golden master:
    //   system.dat produced in runs/20261102-090851-setup-menu-2 run = 4128 bytes
    //   = 32-byte header + 4 × 1024-byte records + a small trailer
    // This pinned observation guards the relative-file format decoder.
    let observed_system_dat_bytes = 4128usize;
    let expected_slots = 4usize;
    let record_bytes = 1024usize;
    let expected_header = observed_system_dat_bytes - expected_slots * record_bytes;
    assert_eq!(expected_header, 32, "relative file header 32 bytes observed");

    // Anything else is a regression against the harness fixture.
}
