import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/services/drive_http_transport.dart';
import 'package:quanlycongviecapp/services/google_drive_service.dart';

class _Request {
  const _Request(this.method, this.uri, this.headers, this.body);
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;
}

class _Transport implements DriveHttpTransport {
  final responses = <DriveHttpResponse>[];
  final requests = <_Request>[];

  @override
  Future<DriveHttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
    void Function(int sent, int total)? onProgress,
  }) async {
    requests.add(_Request(method, uri, headers, body));
    if (body is Uint8List) onProgress?.call(body.length, body.length);
    return responses.removeAt(0);
  }
}

DriveHttpResponse _json(Object value, {int status = 200}) =>
    DriveHttpResponse(status, jsonEncode(value), const {});

void main() {
  late _Transport transport;
  late GoogleDriveService service;

  setUp(() {
    transport = _Transport();
    service = GoogleDriveService(
      accessToken: () => 'memory-token',
      transport: transport,
    );
  });

  test(
    'creates the app, profiles, group and profile folder hierarchy',
    () async {
      for (var index = 0; index < 4; index++) {
        transport.responses
          ..add(_json({'files': []}))
          ..add(_json({'id': 'folder-$index'}));
      }
      final id = await service.ensureProfileFolder(
        groupId: 'group-1',
        groupName: 'Nhóm A',
        profileId: 'profile-1',
        profileName: 'Nguyễn Văn A',
      );
      expect(id, 'folder-3');
      final creates = transport.requests
          .where((r) => r.method == 'POST')
          .toList();
      expect(creates, hasLength(4));
      final bodies = creates
          .map((r) => jsonDecode(r.body! as String) as Map)
          .toList();
      expect(bodies[0]['name'], 'QuanLyCongViecApp');
      expect(bodies[1]['name'], '01_HỒ SƠ');
      expect(bodies[2]['parents'], ['folder-1']);
      expect((bodies[2]['appProperties'] as Map)['groupId'], 'group-1');
      expect((bodies[3]['appProperties'] as Map)['profileId'], 'profile-1');
    },
  );

  test('reuses an ID-linked folder and renames it cosmetically', () async {
    transport.responses
      ..add(
        _json({
          'files': [
            {'id': 'root', 'name': 'Tên cũ'},
          ],
        }),
      )
      ..add(_json({'id': 'root'}))
      ..add(
        _json({
          'files': [
            {'id': 'profiles', 'name': '01_HỒ SƠ'},
          ],
        }),
      )
      ..add(
        _json({
          'files': [
            {'id': 'group', 'name': 'Nhóm A'},
          ],
        }),
      )
      ..add(
        _json({
          'files': [
            {'id': 'profile', 'name': 'Nguyễn Văn A'},
          ],
        }),
      );
    expect(
      await service.ensureProfileFolder(
        groupId: 'g',
        groupName: 'Nhóm A',
        profileId: 'p',
        profileName: 'Nguyễn Văn A',
      ),
      'profile',
    );
    expect(transport.requests.where((r) => r.method == 'PATCH'), hasLength(1));
  });

  test('rejects duplicate folders with the same appProperties', () async {
    transport.responses.add(
      _json({
        'files': [
          {'id': 'a', 'name': 'QuanLyCongViecApp'},
          {'id': 'b', 'name': 'QuanLyCongViecApp'},
        ],
      }),
    );
    expect(
      () => service.ensureProfileFolder(
        groupId: 'g',
        groupName: 'G',
        profileId: 'p',
        profileName: 'P',
      ),
      throwsA(isA<GoogleDriveException>()),
    );
  });

  test('uses resumable upload and application properties', () async {
    transport.responses
      ..add(
        const DriveHttpResponse(200, '', {
          'location': 'https://upload.test/session',
        }),
      )
      ..add(
        _json({
          'id': 'file-1',
          'name': 'hoso.pdf',
          'mimeType': 'application/pdf',
          'size': '3',
          'webViewLink': 'https://drive.google.com/file/d/file-1/view',
        }),
      );
    var progress = 0;
    final result = await service.upload(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'hoso.pdf',
      mimeType: 'application/pdf',
      parentId: 'folder',
      profileId: 'profile',
      groupId: 'group',
      onProgress: (sent, total) => progress = sent,
    );
    expect(result.id, 'file-1');
    expect(progress, 3);
    expect(
      transport.requests.first.uri.queryParameters['uploadType'],
      'resumable',
    );
    final body = jsonDecode(transport.requests.first.body! as String) as Map;
    expect((body['appProperties'] as Map)['entityType'], 'profileAttachment');
    expect(transport.requests.last.method, 'PUT');
    expect(
      transport.requests.every((r) => !r.uri.path.contains('permissions')),
      isTrue,
    );
  });

  test('trashes a file without deleting it permanently', () async {
    transport.responses.add(_json({'id': 'file-1', 'trashed': true}));
    await service.trash('file-1');
    final request = transport.requests.single;
    expect(request.method, 'PATCH');
    expect(request.uri.path, endsWith('/files/file-1'));
    expect(jsonDecode(request.body! as String), {'trashed': true});
  });

  test('maps authorization failures to a reconnect message', () async {
    transport.responses.add(const DriveHttpResponse(401, '{}', {}));
    expect(
      () => service.trash('file-1'),
      throwsA(
        isA<GoogleDriveException>().having(
          (error) => error.message,
          'message',
          contains('hết hạn'),
        ),
      ),
    );
  });
}
