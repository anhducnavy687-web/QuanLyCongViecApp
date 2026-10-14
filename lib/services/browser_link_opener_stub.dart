abstract class BrowserLinkOpener {
  Future<void> open(String url);
}

BrowserLinkOpener createBrowserLinkOpener() =>
    throw UnsupportedError('Mở liên kết chỉ được hỗ trợ trên Web.');
