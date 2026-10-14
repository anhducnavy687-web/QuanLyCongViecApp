import 'drive_http_transport_stub.dart' show DriveHttpTransport;
import 'drive_http_transport_stub.dart'
    if (dart.library.html) 'drive_http_transport_web.dart'
    as implementation;

export 'drive_http_transport_stub.dart'
    show DriveHttpResponse, DriveHttpTransport;

DriveHttpTransport defaultDriveHttpTransport() =>
    implementation.createDriveHttpTransport();
