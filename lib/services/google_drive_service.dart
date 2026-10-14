import 'dart:convert';
import 'dart:typed_data';

import 'drive_http_transport.dart';

class GoogleDriveException implements Exception {
  const GoogleDriveException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class DriveFileMetadata {
  const DriveFileMetadata({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.webViewLink,
  });
  final String id;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final String? webViewLink;

  factory DriveFileMetadata.fromJson(Map<String, dynamic> json) =>
      DriveFileMetadata(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        sizeBytes: int.tryParse(json['size']?.toString() ?? '') ?? 0,
        webViewLink: json['webViewLink'] as String?,
      );
}

class GoogleDriveService {
  GoogleDriveService({
    required String Function() accessToken,
    DriveHttpTransport? transport,
  }) : _transport = transport ?? defaultDriveHttpTransport(),
       // Named public arguments cannot initialize a private field formally.
       // ignore: prefer_initializing_formals
       _accessToken = accessToken;

  static const folderMime = 'application/vnd.google-apps.folder';
  final String Function() _accessToken;
  final DriveHttpTransport _transport;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_accessToken()}',
    'Content-Type': 'application/json; charset=UTF-8',
  };

  Future<String> ensureProfileFolder({
    required String groupId,
    required String groupName,
    required String profileId,
    required String profileName,
  }) async {
    final root = await _ensureFolder(
      name: 'QuanLyCongViecApp',
      properties: const {'app': 'QuanLyCongViecApp', 'folderType': 'root'},
    );
    final profilesRoot = await _ensureFolder(
      name: '01_HỒ SƠ',
      parentId: root,
      properties: const {
        'app': 'QuanLyCongViecApp',
        'folderType': 'profilesRoot',
      },
    );
    final group = await _ensureFolder(
      name: groupName,
      parentId: profilesRoot,
      properties: {
        'app': 'QuanLyCongViecApp',
        'folderType': 'group',
        'groupId': groupId,
      },
    );
    return _ensureFolder(
      name: profileName,
      parentId: group,
      properties: {
        'app': 'QuanLyCongViecApp',
        'folderType': 'profile',
        'profileId': profileId,
        'groupId': groupId,
      },
    );
  }

  Future<String> _ensureFolder({
    required String name,
    required Map<String, String> properties,
    String? parentId,
  }) async {
    final clauses = <String>[
      "mimeType = '$folderMime'",
      'trashed = false',
      if (parentId != null) "'$parentId' in parents",
      for (final entry in properties.entries)
        "appProperties has { key='${_escape(entry.key)}' and value='${_escape(entry.value)}' }",
    ];
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'q': clauses.join(' and '),
      'fields': 'files(id,name,trashed)',
      'spaces': 'drive',
      'pageSize': '10',
    });
    final response = await _transport.send(
      method: 'GET',
      uri: uri,
      headers: _headers,
    );
    final data = _json(response);
    final files = (data['files'] as List? ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (files.length > 1) {
      throw const GoogleDriveException(
        'Phát hiện nhiều thư mục ứng dụng trùng định danh trên Google Drive.',
      );
    }
    if (files.length == 1) {
      final file = files.single;
      if (file['name'] != name) {
        try {
          await _transport.send(
            method: 'PATCH',
            uri: Uri.parse(
              'https://www.googleapis.com/drive/v3/files/${file['id']}?fields=id',
            ),
            headers: _headers,
            body: jsonEncode({'name': name}),
          );
        } catch (_) {
          // Cosmetic rename must not block upload to the ID-linked folder.
        }
      }
      return file['id'] as String;
    }
    final created = await _transport.send(
      method: 'POST',
      uri: Uri.parse('https://www.googleapis.com/drive/v3/files?fields=id'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'mimeType': folderMime,
        if (parentId != null) 'parents': [parentId],
        'appProperties': properties,
      }),
    );
    return _json(created)['id'] as String;
  }

  Future<DriveFileMetadata> upload({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String parentId,
    required String profileId,
    required String groupId,
    void Function(int sent, int total)? onProgress,
  }) async {
    final initiate = await _transport.send(
      method: 'POST',
      uri: Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&fields=id,name,mimeType,size,webViewLink',
      ),
      headers: {
        ..._headers,
        'X-Upload-Content-Type': mimeType,
        'X-Upload-Content-Length': '${bytes.length}',
      },
      body: jsonEncode({
        'name': fileName,
        'parents': [parentId],
        'mimeType': mimeType,
        'appProperties': {
          'app': 'QuanLyCongViecApp',
          'entityType': 'profileAttachment',
          'profileId': profileId,
          'groupId': groupId,
        },
      }),
    );
    _ensureSuccess(initiate);
    final location = initiate.headers['location'];
    if (location == null) {
      throw const GoogleDriveException(
        'Google Drive không trả về phiên tải lên.',
      );
    }
    final uploaded = await _transport.send(
      method: 'PUT',
      uri: Uri.parse(location),
      headers: {
        'Authorization': 'Bearer ${_accessToken()}',
        'Content-Type': mimeType,
        'Content-Length': '${bytes.length}',
      },
      body: bytes,
      onProgress: onProgress,
    );
    return DriveFileMetadata.fromJson(_json(uploaded));
  }

  Future<void> trash(String fileId) async {
    final response = await _transport.send(
      method: 'PATCH',
      uri: Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?fields=id,trashed',
      ),
      headers: _headers,
      body: jsonEncode({'trashed': true}),
    );
    _ensureSuccess(response);
  }

  String _escape(String value) => value.replaceAll("'", "\\'");

  Map<String, dynamic> _json(DriveHttpResponse response) {
    _ensureSuccess(response);
    return response.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  void _ensureSuccess(DriveHttpResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.statusCode == 401
          ? 'Quyền Google Drive đã hết hạn. Vui lòng kết nối lại.'
          : response.statusCode == 403
          ? 'Google Drive từ chối thao tác hoặc đã vượt hạn mức.'
          : 'Google Drive gặp lỗi (${response.statusCode}).';
      throw GoogleDriveException(message, statusCode: response.statusCode);
    }
  }
}
