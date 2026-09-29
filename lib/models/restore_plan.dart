import 'export_snapshot.dart';

class RestoreDocument {
  RestoreDocument({required this.path, required Map<String, dynamic> data})
    : data = Map.unmodifiable(data);

  final String path;
  final Map<String, dynamic> data;
}

class RestorePlan {
  RestorePlan({
    required this.uid,
    required this.incomingSnapshot,
    required Set<String> currentDocumentPaths,
    required List<RestoreDocument> documentsToSet,
    required Set<String> documentsToDelete,
  }) : currentDocumentPaths = Set.unmodifiable(currentDocumentPaths),
       incomingDocumentPaths = Set.unmodifiable(
         documentsToSet.map((document) => document.path),
       ),
       documentsToSet = List.unmodifiable(documentsToSet),
       documentsToDelete = Set.unmodifiable(documentsToDelete),
       expectedFinalCounts = Map.unmodifiable(incomingSnapshot.recordCounts);

  final String uid;
  final ExportSnapshot incomingSnapshot;
  final Set<String> currentDocumentPaths;
  final Set<String> incomingDocumentPaths;
  final List<RestoreDocument> documentsToSet;
  final Set<String> documentsToDelete;
  final Map<String, int> expectedFinalCounts;

  int get totalSetOperations => documentsToSet.length;
  int get totalDeleteOperations => documentsToDelete.length;
  int get totalWrites => totalSetOperations + totalDeleteOperations;
}
