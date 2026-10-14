// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'browser_link_opener_stub.dart';

class WebBrowserLinkOpener implements BrowserLinkOpener {
  @override
  Future<void> open(String url) async => html.window.open(url, '_blank');
}

BrowserLinkOpener createBrowserLinkOpener() => WebBrowserLinkOpener();
