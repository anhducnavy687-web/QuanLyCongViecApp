import 'export_file_delivery.dart';
import 'file_download_service_stub.dart'
    if (dart.library.html) 'file_download_service_web.dart'
    if (dart.library.io) 'file_download_service_io.dart'
    as platform;

export 'export_file_delivery.dart';

ExportFileDelivery createFileDownloadService() =>
    platform.createFileDownloadService();
