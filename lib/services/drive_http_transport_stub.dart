class DriveHttpResponse {
  const DriveHttpResponse(this.statusCode, this.body, this.headers);
  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

abstract class DriveHttpTransport {
  Future<DriveHttpResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
    void Function(int sent, int total)? onProgress,
  });
}

DriveHttpTransport createDriveHttpTransport() =>
    throw UnsupportedError('Google Drive upload chỉ được hỗ trợ trên Web.');
