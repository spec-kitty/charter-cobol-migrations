# disposition — `wssystem.cob` (system file record)

Source: `cobol-original/copybooks/wssystem.cob`, read through
`cobol-original/copybooks/fdsys.cob` (FD `system-file`, 1024-byte record,
relative). Vendored byte-exact; no patches.

Record 1 is the live record. Records 2-4 are written once by `ACAS.cbl`
mainlevel setup and are `default-record` (G/L only), `final-record` (G/L only,
blank) and `system-record-4` (v4 defaults). Only record 1 is dispositioned;
2-4 share the layout.

## Offsets are runtime offsets

Every offset here is the offset the **compiled binary** uses, which is
`copybook offset + 8` — the binary carries an 8-byte prefix ahead of the
version fields (F-B011). Do not re-derive these from the copybook without the
delta; `fixtures/sys_probe/regenerate.sh` produces the table from source and
applies the delta for you.

## Rust column

`acas-common/src/system.rs` accessors are named after the COBOL field (kebab →
snake). `as_bytes()`/`as_bytes_mut()` are the passthrough for bytes nobody has
typed yet. Filler is never typed; it round-trips verbatim because the whole
record is a raw `[u8; 1024]` underneath.

Groups (`System-Data-Block`, `Vat-Rates`, `Suser`, `File-Statuses`, `Level`,
`RDBMS-Flat-Statuses`, `Maps-Ser`, `System-Files`, `Vat-Rates2`) appear as rows
with their own span; the leaf fields under them follow. `Vat-Rate` and
`Scycle` are `REDEFINES` of `Vat-Rates` / `Cyclea` and share their offsets.

## Behaviour notes carried, not fixed

- `Suser` is 40 bytes wide in F-B002's words but the copybook declares `Usera`
  (32) followed by `User-Code` (32): the forty bytes are `usera` + the first
  8 of `user-code`. Both are typed; neither overlaps anything else.
- `Order-Entry-Block` and `IRS-Data-Block` are both 128 bytes at `+776`/`+904`
  and `IRS-Entry-Block` redefines `IRS-Data-Block` — the OE block's content is
  the IRS block's first 128 bytes by construction, which is why OE holds
  `Client`/`fn-*` in practice.
- `File-Status` is `pic 9 occurs 32` (display digits); a non-zero status is
  recorded per file index. `Pass-Word` is 4 bytes of already-encoded text —
  the encryptor (`maps01`) is out of scope for this WP.
- `RDBMS-DB-Name/User/Passwd` carry compile-time defaults `"ACASDB"`,
  `"ACAS-User"`, `"PaSsWoRd"` — the golden has them because the record was
  initialised, not because setup wrote them.

## Ledger

Sizes are reprised from the copybook verbatim; `+0..8` is the prefix pad from
F-B011 and has no COBOL name.
| 0 | 8 | *filler* | `as_bytes()` passthrough | filler — preserved verbatim |

### `System-Data-Block` @ +8 — System data block — company identity, cycle, dates, file switches, RDBMS settings (384 B)

| Offset | Len | Field | Rust | Notes |
|---:|---:|---|---|---|
| 8 | 1 | `System-Record-Version-Prime` | `system_record_version_prime` | typed accessor |
| 9 | 1 | `System-Record-Version-Secondary` | `system_record_version_secondary` | typed accessor |
| 10 | 10 | `Vat-Rates` | `vat_rates` | typed accessor |
| 10 | 2 | `Vat-Rate-1` | `vat_rate_1` | typed accessor |
| 12 | 2 | `Vat-Rate-2` | `vat_rate_2` | typed accessor |
| 14 | 2 | `Vat-Rate-3` | `vat_rate_3` | typed accessor |
| 16 | 2 | `Vat-Rate-4` | `vat_rate_4` | typed accessor |
| 18 | 2 | `Vat-Rate-5` | `vat_rate_5` | typed accessor |
| 20 | 1 | `Cyclea` | `cyclea` | typed accessor |
| 21 | 1 | `Period` | `period` | typed accessor |
| 22 | 1 | `Page-Lines` | `page_lines` | typed accessor |
| 23 | 4 | `Next-Invoice` | `next_invoice` | typed accessor |
| 27 | 4 | `Run-Date` | `run_date` | typed accessor |
| 31 | 4 | `Start-Date` | `start_date` | typed accessor |
| 35 | 4 | `End-Date` | `end_date` | typed accessor |
| 39 | 32 | `Suser` | `suser` | typed accessor |
| 39 | 32 | `Usera` | `usera` | typed accessor |
| 71 | 32 | `User-Code` | `user_code` | typed accessor |
| 103 | 24 | `Address-1` | `address_1` | typed accessor |
| 127 | 24 | `Address-2` | `address_2` | typed accessor |
| 151 | 24 | `Address-3` | `address_3` | typed accessor |
| 175 | 24 | `Address-4` | `address_4` | typed accessor |
| 199 | 12 | `Post-Code` | `post_code` | typed accessor |
| 211 | 24 | `Country` | `country` | typed accessor |
| 235 | 48 | `Print-Spool-Name` | `print_spool_name` | typed accessor |
| 283 | 32 | `File-Statuses` | `file_statuses` | typed accessor |
| 315 | 1 | `Pass-Value` | `pass_value` | typed accessor |
| 316 | 6 | `Level` | `level` | typed accessor |
| 316 | 1 | `Level-1` | `level_1` | typed accessor |
| 317 | 1 | `Level-2` | `level_2` | typed accessor |
| 318 | 1 | `Level-3` | `level_3` | typed accessor |
| 319 | 1 | `Level-4` | `level_4` | typed accessor |
| 320 | 1 | `Level-5` | `level_5` | typed accessor |
| 321 | 1 | `Level-6` | `level_6` | typed accessor |
| 322 | 4 | `Pass-Word` | `pass_word` | typed accessor |
| 326 | 1 | `Host` | `host` | typed accessor |
| 327 | 1 | `Op-System` | `op_system` | typed accessor |
| 328 | 1 | `Current-Quarter` | `current_quarter` | typed accessor |
| 329 | 2 | `RDBMS-Flat-Statuses` | `rdbms_flat_statuses` | typed accessor |
| 329 | 1 | `File-System-Used` | `file_system_used` | typed accessor |
| 330 | 1 | `File-Duplicates-In-Use` | `file_duplicates_in_use` | typed accessor |
| 331 | 4 | `Maps-Ser` | `maps_ser` | typed accessor |
| 331 | 2 | `Maps-Ser-xx` | `maps_ser_xx` | typed accessor |
| 333 | 2 | `Maps-Ser-nn` | `maps_ser_nn` | typed accessor |
| 335 | 1 | `Date-Form` | `date_form` | typed accessor |
| 336 | 1 | `Data-Capture-Used` | `data_capture_used` | typed accessor |
| 337 | 12 | `RDBMS-DB-Name` | `rdbms_db_name` | typed accessor |
| 349 | 12 | `RDBMS-User` | `rdbms_user` | typed accessor |
| 361 | 12 | `RDBMS-Passwd` | `rdbms_passwd` | typed accessor |
| 373 | 11 | `VAT-Reg-Number` | `vat_reg_number` | typed accessor |
| 384 | 8 | *filler* | `as_bytes()` passthrough | filler — preserved verbatim |

### `General-Ledger-Block` @ +392 — G/L block — account numbers, toggles, batch/folio counters (80 B)

| Offset | Len | Field | Rust | Notes |
|---:|---:|---|---|---|
| 392 | 1 | `P-C` | `p_c` | typed accessor |
| 393 | 1 | `P-C-Grouped` | `p_c_grouped` | typed accessor |
| 394 | 1 | `P-C-Level` | `p_c_level` | typed accessor |
| 395 | 1 | `Comps` | `comps` | typed accessor |
| 396 | 1 | `Comps-Active` | `comps_active` | typed accessor |
| 397 | 1 | `M-V` | `m_v` | typed accessor |
| 398 | 1 | `Arch` | `arch` | typed accessor |
| 399 | 1 | `Trans-Print` | `trans_print` | typed accessor |
| 400 | 1 | `Trans-Printed` | `trans_printed` | typed accessor |
| 401 | 1 | `Header-Level` | `header_level` | typed accessor |
| 402 | 1 | `Sales-Range` | `sales_range` | typed accessor |
| 403 | 1 | `Purchase-Range` | `purchase_range` | typed accessor |
| 404 | 1 | `Vat` | `vat` | typed accessor |
| 405 | 1 | `Batch-Id` | `batch_id` | typed accessor |
| 406 | 1 | `Ledger-2nd-Index` | `ledger_2nd_index` | typed accessor |
| 407 | 1 | `Irs-Instead` | `irs_instead` | typed accessor |
| 408 | 2 | `Ledger-Sec` | `ledger_sec` | typed accessor |
| 410 | 2 | `Updates` | `updates` | typed accessor |
| 412 | 2 | `Postings` | `postings` | typed accessor |
| 414 | 2 | `Next-Batch` | `next_batch` | typed accessor |
| 416 | 4 | `Extra-Charge-Ac` | `extra_charge_ac` | typed accessor |
| 420 | 4 | `Vat-Ac` | `vat_ac` | typed accessor |
| 424 | 48 | `Print-Spool-Name2` | `print_spool_name2` | typed accessor |

### `Purchase-Ledger-Block` @ +472 — P/B ledger block (88 B)

| Offset | Len | Field | Rust | Notes |
|---:|---:|---|---|---|
| 472 | 4 | `Next-Folio` | `next_folio` | typed accessor |
| 476 | 4 | `BL-Pay-Ac` | `bl_pay_ac` | typed accessor |
| 480 | 4 | `P-Creditors` | `p_creditors` | typed accessor |
| 484 | 4 | `BL-Purch-Ac` | `bl_purch_ac` | typed accessor |
| 488 | 4 | `BL-End-Cycle-Date` | `bl_end_cycle_date` | typed accessor |
| 492 | 2 | `BL-Next-Batch` | `bl_next_batch` | typed accessor |
| 494 | 1 | `Age-To-Pay` | `age_to_pay` | typed accessor |
| 495 | 1 | `Purchase-Ledger` | `purchase_ledger` | typed accessor |
| 496 | 1 | `PL-Delim` | `pl_delim` | typed accessor |
| 497 | 1 | `Entry-Level` | `entry_level` | typed accessor |
| 498 | 1 | `P-Flag-A` | `p_flag_a` | typed accessor |
| 499 | 1 | `P-Flag-I` | `p_flag_i` | typed accessor |
| 500 | 1 | `P-Flag-P` | `p_flag_p` | typed accessor |
| 501 | 1 | `PL-Stock-Link` | `pl_stock_link` | typed accessor |
| 502 | 48 | `Print-Spool-Name3` | `print_spool_name3` | typed accessor |
| 550 | 10 | *filler* | `as_bytes()` passthrough | filler — preserved verbatim |

### `Sales-Ledger-Block` @ +560 — S/L block — invoicing switches, ageing, credit control, company headings (128 B)

| Offset | Len | Field | Rust | Notes |
|---:|---:|---|---|---|
| 560 | 1 | `Sales-Ledger` | `sales_ledger` | typed accessor |
| 561 | 1 | `SL-Delim` | `sl_delim` | typed accessor |
| 562 | 1 | `Oi-3-Flag` | `oi_3_flag` | typed accessor |
| 563 | 1 | `Cust-Flag` | `cust_flag` | typed accessor |
| 564 | 1 | `Oi-5-Flag` | `oi_5_flag` | typed accessor |
| 565 | 1 | `S-Flag-Oi-3` | `s_flag_oi_3` | typed accessor |
| 566 | 1 | `Full-Invoicing` | `full_invoicing` | typed accessor |
| 567 | 1 | `S-Flag-A` | `s_flag_a` | typed accessor |
| 568 | 1 | `S-Flag-I` | `s_flag_i` | typed accessor |
| 569 | 1 | `S-Flag-P` | `s_flag_p` | typed accessor |
| 570 | 1 | `SL-Dunning` | `sl_dunning` | typed accessor |
| 571 | 1 | `SL-Charges` | `sl_charges` | typed accessor |
| 572 | 1 | `Sl-Own-Nos` | `sl_own_nos` | typed accessor |
| 573 | 1 | `SL-Stats-Run` | `sl_stats_run` | typed accessor |
| 574 | 1 | `Sl-Day-Book` | `sl_day_book` | typed accessor |
| 575 | 1 | `invoicer` | `invoicer` | typed accessor |
| 576 | 14 | `Extra-Desc` | `extra_desc` | typed accessor |
| 590 | 1 | `Extra-Type` | `extra_type` | typed accessor |
| 591 | 1 | `Extra-Print` | `extra_print` | typed accessor |
| 592 | 1 | `SL-Stock-Link` | `sl_stock_link` | typed accessor |
| 593 | 1 | `SL-Stock-Audit` | `sl_stock_audit` | typed accessor |
| 594 | 2 | `SL-Late-Per` | `sl_late_per` | typed accessor |
| 596 | 2 | `SL-Disc` | `sl_disc` | typed accessor |
| 598 | 2 | `Extra-Rate` | `extra_rate` | typed accessor |
| 600 | 1 | `SL-Days-1` | `sl_days_1` | typed accessor |
| 601 | 1 | `SL-Days-2` | `sl_days_2` | typed accessor |
| 602 | 1 | `SL-Days-3` | `sl_days_3` | typed accessor |
| 603 | 1 | `SL-Credit` | `sl_credit` | typed accessor |
| 604 | 2 | *filler* | `as_bytes()` passthrough | slack byte — preserved verbatim |
| 606 | 2 | `SL-Min` | `sl_min` | typed accessor |
| 608 | 2 | `SL-Max` | `sl_max` | typed accessor |
| 610 | 2 | `PF-Retention` | `pf_retention` | typed accessor |
| 612 | 2 | `First-Sl-Batch` | `first_sl_batch` | typed accessor |
| 614 | 4 | `First-Sl-Inv` | `first_sl_inv` | typed accessor |
| 618 | 4 | `SL-Limit` | `sl_limit` | typed accessor |
| 622 | 4 | `SL-Pay-Ac` | `sl_pay_ac` | typed accessor |
| 626 | 4 | `S-Debtors` | `s_debtors` | typed accessor |
| 630 | 4 | `SL-Sales-Ac` | `sl_sales_ac` | typed accessor |
| 634 | 4 | `S-End-Cycle-Date` | `s_end_cycle_date` | typed accessor |
| 638 | 1 | `SL-Comp-Head-Pick` | `sl_comp_head_pick` | typed accessor |
| 639 | 1 | `SL-Comp-Head-Inv` | `sl_comp_head_inv` | typed accessor |
| 640 | 1 | `SL-Comp-Head-Stat` | `sl_comp_head_stat` | typed accessor |
| 641 | 1 | `SL-Comp-Head-Lets` | `sl_comp_head_lets` | typed accessor |
| 642 | 1 | `SL-VAT-Printed` | `sl_vat_printed` | typed accessor |
| 643 | 45 | *filler* | `as_bytes()` passthrough | filler — preserved verbatim |

### `Stock-Control-Block` @ +688 — Stock control block (88 B)

| Offset | Len | Field | Rust | Notes |
|---:|---:|---|---|---|
| 688 | 6 | `Stk-Abrev-Ref` | `stk_abrev_ref` | typed accessor |
| 694 | 1 | `Stk-Debug` | `stk_debug` | typed accessor |
| 695 | 1 | `Stk-Manu-Used` | `stk_manu_used` | typed accessor |
| 696 | 1 | `Stk-OE-Used` | `stk_oe_used` | typed accessor |
| 697 | 1 | `Stk-Audit-Used` | `stk_audit_used` | typed accessor |
| 698 | 1 | `Stk-Mov-Audit` | `stk_mov_audit` | typed accessor |
| 699 | 1 | `Stk-Period-Cur` | `stk_period_cur` | typed accessor |
| 700 | 1 | `Stk-Period-dat` | `stk_period_dat` | typed accessor |
| 701 | 1 | *filler* | `as_bytes()` passthrough | slack byte — preserved verbatim |
| 702 | 1 | `Stock-Control` | `stock_control` | typed accessor |
| 703 | 1 | `Stk-Averaging` | `stk_averaging` | typed accessor |
| 704 | 1 | `Stk-Activity-Rep-Run` | `stk_activity_rep_run` | typed accessor |
| 705 | 1 | *filler* | `as_bytes()` passthrough | slack byte — preserved verbatim |
| 706 | 1 | `Stk-Page-Lines` | `stk_page_lines` | typed accessor |
| 707 | 1 | `Stk-Audit-No` | `stk_audit_no` | typed accessor |
| 708 | 68 | *filler* | `as_bytes()` passthrough | filler — preserved verbatim |

### `Order-Entry-Block` @ +776 — Order entry block (128 B)

| Offset | Len | Field | Rust | Notes |
|---:|---:|---|---|---|
| 776 | 128 | `filler-Dummy` | `filler_dummy` | typed accessor |

### `IRS-Data-Block` @ +904 — IRS block — client, file names, VAT rates 2, sequencing (128 B)

| Offset | Len | Field | Rust | Notes |
|---:|---:|---|---|---|
| 904 | 128 | `filler-dummy4` | `filler_dummy4` | typed accessor |

### `IRS-Data-Block` @ +904 — IRS block — client, file names, VAT rates 2, sequencing (128 B)

| Offset | Len | Field | Rust | Notes |
|---:|---:|---|---|---|
| 904 | 24 | `Client` | `client` | typed accessor |
| 928 | 48 | `System-Files` | `system_files` | typed accessor |
| 928 | 9 | `fn-1` | `fn_1` | typed accessor |
| 937 | 10 | `fn-2` | `fn_2` | typed accessor |
| 947 | 8 | `fn-3` | `fn_3` | typed accessor |
| 955 | 8 | `fn-4` | `fn_4` | typed accessor |
| 963 | 12 | `fn-5` | `fn_5` | typed accessor |
| 975 | 1 | `System-Ops` | `system_ops` | typed accessor |
| 976 | 5 | `Next-Post` | `next_post` | typed accessor |
| 981 | 12 | `Vat-Rates2` | `vat_rates2` | typed accessor |
| 981 | 4 | `vat1` | `vat1` | typed accessor |
| 985 | 4 | `vat2` | `vat2` | typed accessor |
| 989 | 4 | `vat3` | `vat3` | typed accessor |
| 993 | 1 | `IRS-Pass-Value` | `irs_pass_value` | typed accessor |
| 994 | 1 | `save-sequ` | `save_sequ` | typed accessor |
| 995 | 18 | `system-work-group` | `system_work_group` | typed accessor |
| 1013 | 1 | `PL-App-Created` | `pl_app_created` | typed accessor |
| 1014 | 5 | `PL-Approp-AC` | `pl_approp_ac` | typed accessor |
| 1019 | 1 | `1st-Time-Flag` | `1st_time_flag` | typed accessor |
