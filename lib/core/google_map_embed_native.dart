import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Google Maps nhúng cho Android/iOS.
///
/// Google Maps Embed API không cho phép mở URL embed trực tiếp như một trang
/// top-level. Vì vậy URL phải được đặt bên trong thẻ iframe. Cách này cũng sửa
/// lỗi iOS hiển thị dòng "The Google Maps Embed API must be used in an iframe".
class GoogleMapEmbed extends StatefulWidget {
  const GoogleMapEmbed({
    required this.url,
    required this.fallback,
    super.key,
  });

  final String url;
  final Widget fallback;

  @override
  State<GoogleMapEmbed> createState() => _GoogleMapEmbedState();
}

class _GoogleMapEmbedState extends State<GoogleMapEmbed> {
  static final Set<Factory<OneSequenceGestureRecognizer>>
      _mapGestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{
    Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
  };

  WebViewController? _controller;
  int _progress = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(covariant GoogleMapEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _createController();
  }

  void _createController() {
    final rawUrl = widget.url.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      _setStateIfMounted(() {
        _controller = null;
        _failed = true;
        _progress = 0;
      });
      return;
    }

    final safeUrl = const HtmlEscape(HtmlEscapeMode.attribute).convert(rawUrl);
    final html = '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
  <style>
    html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: #f3f5f7; }
    iframe { width: 100%; height: 100%; border: 0; display: block; }
  </style>
</head>
<body>
  <iframe
    src="$safeUrl"
    loading="eager"
    allowfullscreen
    referrerpolicy="no-referrer-when-downgrade">
  </iframe>
</body>
</html>
''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF3F5F7))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted || _progress == progress) return;
            setState(() => _progress = progress);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            setState(() => _failed = true);
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..loadHtmlString(html, baseUrl: 'https://www.google.com');

    _setStateIfMounted(() {
      _controller = controller;
      _failed = false;
      _progress = 0;
    });
  }

  void _setStateIfMounted(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    } else {
      callback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || controller == null) return widget.fallback;

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(
          controller: controller,
          gestureRecognizers: _mapGestureRecognizers,
        ),
        if (_progress < 100)
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: LinearProgressIndicator(
                minHeight: 2,
                value: _progress <= 0 ? null : _progress / 100,
              ),
            ),
          ),
      ],
    );
  }
}
