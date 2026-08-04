import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Google Maps nhúng cho Android/iOS.
///
/// [gestureRecognizers] dùng EagerGestureRecognizer để WebView nhận thao tác
/// chạm, kéo, thu phóng và các nút điều khiển ngay cả khi nằm trong
/// SingleChildScrollView của trang Detail.
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
    if (oldWidget.url != widget.url) {
      _createController();
    }
  }

  void _createController() {
    final uri = Uri.tryParse(widget.url.trim());
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
      ..loadRequest(uri);

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
