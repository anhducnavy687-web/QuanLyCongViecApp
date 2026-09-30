# Phase 1.6 — Dynamic profile fields

Each work group owns a profile form schema. Built-in metadata stays in the
application catalog; the group stores only `fieldId`, `enabled`, `required`,
and `order`. Custom definitions are stored on the group and custom values are
stored in `Profile.customFieldValues`, keyed by an immutable app-generated ID.

New groups use the new default: the personnel and aspiration fields are
enabled, while family and legacy phone/work-content fields are disabled.
Legacy group documents without a schema use a separate compatibility
configuration in memory, where phone, work target, description, and note stay
visible. They are written in the new format only when the group is saved.
Legacy profiles parse missing fields as `null`. Hiding a field never clears its
stored value, and re-enabling it reveals that value again.

Custom fields support text, multiline text, number, date, year, boolean, and
single-select values. Select values store an option ID rather than its label.
Definitions and options are deactivated instead of hard-deleted so old values
remain readable. Custom fields may belong to Subject Information or Work
Content; they cannot be placed in Aspirations.

The group sheet shows only live counts and opens a dedicated full-screen field
configuration page. Only active fields appear in reorder lists. Inactive
built-ins and custom definitions can be enabled from Add Field. Persisted
custom fields may change label, required state, active state, order, and safe
option metadata; their IDs, types, and sections stay immutable.

The profile form validates only enabled required fields. `fullName` is always
enabled and required. Aspirations remain in a fixed block at the end of the
form. Search intentionally includes stored hidden values so a temporarily
hidden field does not make an existing profile undiscoverable.

JSON backup schema version 2 includes group form configuration, custom field
definitions, built-in dynamic values, and custom values. Import continues to
accept schema version 1 and reports a migration warning. XLSX export contains
13 sheets; `FieldDefinitions` and `CustomFieldValues` are the two additions.

Firestore documents remain under the current per-UID paths. No collection,
rule, Firebase configuration, or Storage behavior changes in this phase.
