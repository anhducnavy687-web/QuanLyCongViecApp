import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('firestore.rules').readAsStringSync();
  // The fake parser has no function or rules_version support. Inline ONLY the
  // two exact helpers asserted below; keep all match paths and allow clauses.
  // This is a unit model, not an emulator/production rules validation.
  final signedIn = RegExp(
    r'function isSignedIn\(\)\s*\{\s*return request.auth != null;\s*\}',
  );
  final owner = RegExp(
    r'function isOwner\(uid\)\s*\{\s*return isSignedIn\(\) && request.auth.uid == uid;\s*\}',
  );
  test('rule helper definitions still match the unit model', () {
    expect(signedIn.allMatches(source).length, 1);
    expect(owner.allMatches(source).length, 1);
  });
  final rules = source
      .replaceFirst("rules_version = '2';", '')
      .replaceFirst(signedIn, '')
      .replaceFirst(owner, '')
      .replaceAll(
        'isOwner(uid)',
        'request.auth != null && request.auth.uid == uid',
      );
  final paths = [
    'users/a',
    'users/a/groups/g',
    'users/a/collaborators/c',
    'users/a/profiles/p',
    for (final name in [
      'stages',
      'milestones',
      'transactions',
      'attachments',
      'collaboratorAssignments',
      'tasks',
      'timelineEvents',
    ])
      'users/a/profiles/p/$name/x',
  ];
  for (final path in paths) {
    test('rules allow owner and reject another UID: $path', () async {
      final db = FakeFirebaseFirestore(securityRules: rules);
      db.authObject.add({'uid': 'a'});
      final doc = db.doc(path);
      await doc.set({'test': true});
      expect((await doc.get()).exists, true);
      await doc.update({'test': false});
      db.authObject.add({'uid': 'b'});
      final denied = throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'denied',
          contains('is not allowed'),
        ),
      );
      await expectLater(doc.get(), denied);
      await expectLater(doc.set({'test': true}), denied);
      await expectLater(doc.update({'test': true}), denied);
      await expectLater(doc.delete(), denied);
      db.authObject.add(null);
      await expectLater(doc.get(), denied);
      await expectLater(doc.set({'test': true}), denied);
      db.authObject.add({'uid': 'a'});
      await doc.delete();
    });
  }
  test('unknown collections and paths remain denied', () async {
    final db = FakeFirebaseFirestore(securityRules: rules);
    db.authObject.add({'uid': 'a'});
    for (final path in [
      'public/x',
      'users/a/unknown/x',
      'users/a/profiles/p/unknown/x',
    ]) {
      await expectLater(
        db.doc(path).set({'x': 1}),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'denied',
            contains('is not allowed'),
          ),
        ),
      );
      await expectLater(
        db.doc(path).get(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'denied',
            contains('is not allowed'),
          ),
        ),
      );
    }
  });
}
