import 'export_snapshot.dart';

/// A validated file and its read-only summary. No operation in B2A applies it.
class RestorePreview {
  RestorePreview({
    required this.fileName,
    required this.fileSize,
    required this.snapshot,
    required List<String> warnings,
    required this.totalReceived,
    required this.totalExpense,
    required this.totalCollaboratorPayment,
    required Map<String, num> rebuiltPaidAmounts,
    this.sourceSchemaVersion = 2,
  }) : warnings = List.unmodifiable(warnings),
       rebuiltPaidAmounts = Map.unmodifiable(rebuiltPaidAmounts);

  final String fileName;
  final int fileSize;
  final ExportSnapshot snapshot;
  final List<String> warnings;
  final num totalReceived;
  final num totalExpense;
  final num totalCollaboratorPayment;
  final Map<String, num> rebuiltPaidAmounts;
  final int sourceSchemaVersion;

  int get schemaVersion => sourceSchemaVersion;
  DateTime get exportedAt => snapshot.exportedAt;
  String get appVersion => snapshot.appVersion;
  String get sourceMode => snapshot.sourceMode;
  Map<String, int> get recordCounts => Map.unmodifiable(snapshot.recordCounts);
  int get archivedAssignmentCount =>
      snapshot.collaboratorAssignments.where((a) => a.isArchived).length;
  int get inactiveCollaboratorCount =>
      snapshot.collaborators.where((c) => !c.active).length;
  bool get isValid => true;
}
