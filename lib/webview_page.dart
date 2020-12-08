import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewPage extends StatelessWidget {
  final String by;
  final String url;

  const WebviewPage({Key key, this.by, this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Article from $by'),
      ),
      body: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: url,
      ),
    );
  }
}