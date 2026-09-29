# Phase 1.5B2A — JSON import validation and preview

Settings offers **Kiểm tra bản sao lưu**. It selects a `.json` file using
`file_picker` (Web and mobile bytes), validates it, and displays a read-only
summary. A file is limited to 50 MiB before decoding or parsing. Cancel leaves
the app unchanged.

Only B1 `schemaVersion: 1` is supported. The parser requires the ten complete
flat entity arrays and every field emitted by B1. It checks JSON types, required
and nullable values, nonempty IDs/FKs, raw enum allowlists, finite numbers,
calendar-valid ISO timestamps, then uses the shared B1 graph validator. The
existing model `fromJson` methods are called only after these strict checks;
their fallback defaults cannot turn malformed input into a valid preview.

Transactions are the source of truth for collaborator payments. The preview
rebuilds paid amounts, checks them against assignment cache and commission, and
shows the rebuilt values and finance totals. An invalid entity rejects the
whole file. Source metadata such as `timeZone` and `recordCounts` may be absent
with a warning; the graph remains mandatory. Attachment entries contain
metadata only. Their local paths may not work on another device.

The validation result carries an immutable `ExportSnapshot` for a future phase
to consume. B2A never calls a repository write, Firestore, auth or session
operation, and never compares the file with current account data. The preview
has only a **Đóng** action. It cannot restore, replace, merge, delete or upload
anything.

`Attachment.localPathOrUrl` and `storagePath` may be null. The parser preserves
null instead of silently replacing it with an empty string; opening or sharing
such metadata shows a friendly message because no local file is available.
