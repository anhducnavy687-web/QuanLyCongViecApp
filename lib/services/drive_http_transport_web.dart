// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'drive_http_transport_stub.dart';

class WebDriveHttpTransport implements DriveHttpTransport {
  @override
  Future<DriveHttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
    void Function(int sent, int total)? onProgress,
  }) async {
    final request = html.HttpRequest();
    request.open(method, uri.toString());
    headers.forEach(request.setRequestHeader);
    if (onProgress != null) {
      request.upload.onProgress.listen((event) {
        onProgress(event.loaded ?? 0, event.total ?? 0);
      });
    }
    final completer = Completer<DriveHttpResponse>();
    request.onLoad.listen((_) {
      final responseHeaders = <String, String>{};
      for (final line in request.getAllResponseHeaders().split('\n')) {
        final index = line.indexOf(':');
        if (index > 0) {
          responseHeaders[line.substring(0, index).trim().toLowerCase()] = line
              .substring(index + 1)
              .trim();
        }
      }
      completer.complete(
        DriveHttpResponse(
          request.status ?? 0,
          request.responseText ?? '',
          responseHeaders,
        ),
      );
    });
    request.onError.listen(
      (_) => completer.completeError(
        StateError('Không thể kết nối Google Drive.'),
      ),
    );
    request.send(body is Uint8List ? body : body);
    return completer.future;
  }
}

DriveHttpTransport createDriveHttpTransport() => WebDriveHttpTransport();
