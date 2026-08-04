import 'package:flutter/material.dart';

import 'media_url_resolver.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.borderRadius,
    super.key,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = MediaUrlResolver.resolve(url);
    Widget child;
    if (resolvedUrl.isEmpty) {
      child = fallback;
    } else {
      child = Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: FilterQuality.medium,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, image, progress) {
          if (progress == null) return image;
          final total = progress.expectedTotalBytes;
          return ColoredBox(
            color: const Color(0xFFE8EEF4),
            child: Center(
              child: CircularProgressIndicator(
                value: total == null ? null : progress.cumulativeBytesLoaded / total,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    final radius = borderRadius;
    if (radius == null) return child;
    return ClipRRect(borderRadius: radius, child: child);
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.url,
    required this.fallbackText,
    this.radius = 30,
    this.backgroundColor = const Color(0xFFE7F7FF),
    super.key,
  });

  final String url;
  final String fallbackText;
  final double radius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.trim().isEmpty ? '?' : fallbackText.trim().substring(0, 1);
    final fallback = ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFF11365B),
            fontSize: radius * 0.72,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: AppNetworkImage(
          url: url,
          fit: BoxFit.cover,
          fallback: fallback,
        ),
      ),
    );
  }
}
