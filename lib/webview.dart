import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebView extends StatefulWidget {
  final String url;

  WebView({
    this.url
  });

  @override
  State<StatefulWidget> createState() => WebViewState();
}

class WebViewState extends State<WebView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WebView"),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: Uri.parse(widget.url)
        ),
        onDownloadStart: (controller, url) async {
          CookieManager manager = CookieManager.instance();
          manager.getCookies(url: url, iosBelow11WebViewController: controller);
        },
      ),
    );
  }
}