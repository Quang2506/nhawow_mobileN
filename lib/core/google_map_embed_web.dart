// ignore_for_file: deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart'
//     show PlatformViewHitTestBehavior;

/// Google Maps nhúng cho Flutter Web.
///
/// Iframe và phần tử bao ngoài được bật pointer-events/touch-action để các
/// nút Open in Maps, toàn màn hình, kéo và thu phóng nhận được thao tác chuột
/// hoặc cảm ứng thay vì bị lớp cuộn của Flutter giữ lại.
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
  static int _nextViewId = 0;

  String? _viewType;

  @override
  void initState() {
    super.initState();
    _registerIframe();
  }

  @override
  void didUpdateWidget(covariant GoogleMapEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _registerIframe();
  }

  void _registerIframe() {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      _viewType = null;
      return;
    }

    final viewType = 'nhawow-google-map-${_nextViewId++}';
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = uri.toString()
          ..title = 'NhaWOW map'
          ..tabIndex = 0
          ..setAttribute('loading', 'eager')
          ..setAttribute('referrerpolicy', 'no-referrer-when-downgrade')
          ..setAttribute(
            'allow',
            'fullscreen; geolocation; clipboard-read; clipboard-write',
          )
          ..style.border = '0'
          ..style.display = 'block'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'auto'
          ..style.touchAction = 'auto'
          ..style.userSelect = 'none';

        final host = html.DivElement()
          ..setAttribute('role', 'application')
          ..setAttribute('aria-label', 'NhaWOW Google Maps')
          ..style.position = 'relative'
          ..style.display = 'block'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.overflow = 'hidden'
          ..style.pointerEvents = 'auto'
          ..style.touchAction = 'auto';

        host.append(iframe);
        return host;
      },
    );
    _viewType = viewType;
  }

  @override
  void dispose() {
    // Tránh để iframe giữ focus khi Flutter ẩn/hủy platform view. Chrome sẽ
    // cảnh báo aria-hidden nếu một phần tử con đang focus bị ẩn.
    final activeElement = html.document.activeElement;
    if (activeElement is html.HtmlElement) activeElement.blur();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    if (viewType == null) return widget.fallback;

    return HtmlElementView(
      key: ValueKey<String>(viewType),
      viewType: viewType,
    );
  }
}
