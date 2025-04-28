import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfViewerPage extends StatefulWidget {
  final String url;
  const PdfViewerPage({required this.url, super.key});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final viewerUrl = "https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📄 PDF Viewer')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
