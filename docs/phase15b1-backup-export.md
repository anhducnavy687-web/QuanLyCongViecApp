# Phase 1.5B1 — JSON backup and XLSX export

The Settings screen can export the repository's current, fully loaded data as
either a canonical JSON backup or a human-readable XLSX workbook. Restore and
import are intentionally outside this phase.

## Snapshot contract

`AppRepository.createExportSnapshot()` copies the complete in-memory graph into
an immutable `ExportSnapshot`. It refuses to export before initial sync, after a
sync error, while a repository write is active, or when the repository revision
changes while the snapshot is being checked. The snapshot describes application
state at `exportedAt`; it is not advertised as a Firestore-wide transactional
snapshot.

All public repository writes pass through the base repository's write counter.
The snapshot is validated before either encoder runs. A validation failure
produces no file delivery request.

## JSON schema v1

The UTF-8 document has `schemaVersion`, `exportedAt`, `appVersion`, `source`, and
`data`. `data` is a flat relational graph containing groups, profiles, stages,
milestones, tasks, timeline events, transactions, collaborators, collaborator
assignments, and attachment metadata. IDs and foreign keys are preserved.

The file contains no UID, authentication token, Firebase credential, password,
private key, or attachment binary. `localPathOrUrl` is metadata only and may not
work on another device.

Transactions are the source of truth for collaborator payments. Export is
rejected if an assignment's stored `paidAmount` differs from the amount rebuilt
from `COLLABORATOR_PAYMENT` transactions.

## XLSX workbook

The workbook contains exactly these sheets:

`Metadata`, `Groups`, `Profiles`, `Stages`, `Milestones`, `Tasks`,
`TimelineEvents`, `Transactions`, `Collaborators`,
`CollaboratorAssignments`, and `Attachments`.

Money cells are numeric, date/time cells use XLSX date values, IDs and foreign
keys remain visible, and raw enum values are retained alongside Vietnamese
labels. The attachment sheet always states that binary content is not included.

The implementation uses the MIT-licensed `excel` package at version 4.0.6.
Workbook generation is client-side and in-memory.

## File delivery and privacy

Web uses a Blob/Object URL download. Other supported platforms write a temporary
file and open the native share sheet. Firebase Storage is never used.

Backup and export files can contain names, phone numbers, notes, and financial
data. Anyone with the file can read it, so users should keep exported files in a
safe location.
