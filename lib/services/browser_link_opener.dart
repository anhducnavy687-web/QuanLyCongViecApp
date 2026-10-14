import 'browser_link_opener_stub.dart' show BrowserLinkOpener;
import 'browser_link_opener_stub.dart'
    if (dart.library.html) 'browser_link_opener_web.dart'
    as implementation;

export 'browser_link_opener_stub.dart' show BrowserLinkOpener;

BrowserLinkOpener browserLinkOpener() =>
    implementation.createBrowserLinkOpener();
