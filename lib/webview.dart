
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'localizations/localizations.dart';

class WebView extends StatefulWidget {
  final String url;

  WebView({
    this.url
  });

  @override
  State<StatefulWidget> createState() => WebViewState();
}

class WebViewState extends State<WebView> {
  InAppWebViewController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt("webview")),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () async {
              launch((await controller?.getUrl())?.toString() ?? widget.url);
            }
          )
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: Uri.parse(widget.url)
        ),
        onWebViewCreated: (controller) {
          this.controller = controller;
        },
        onDownloadStart: (controller, url) async {
          CookieManager manager = CookieManager.instance();
          manager.getCookies(url: url, iosBelow11WebViewController: controller);
        },
      ),
    );
  }
}