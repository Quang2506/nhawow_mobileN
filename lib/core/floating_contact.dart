import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Mobile counterpart of the web partial `_FloatingContact.cshtml`.
///
/// Place this widget in a full-screen Stack (preferably with Positioned.fill).
/// It only captures the entire screen while the contact panel is open; when
/// closed, only the floating action button participates in hit testing.
class FloatingContact extends StatefulWidget {
  const FloatingContact({
    this.bottomOffset = 112,
    this.rightOffset = 14,
    super.key,
  });

  /// Distance from the bottom edge of the page body. In the main shell this
  /// should keep the button above the custom bottom navigation bar.
  final double bottomOffset;
  final double rightOffset;

  @override
  State<FloatingContact> createState() => _FloatingContactState();
}

class _FloatingContactState extends State<FloatingContact> {
  bool _open = false;

  void _setOpen(bool value) {
    if (_open == value) return;
    setState(() => _open = value);
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showLaunchError(context);
      }
    } catch (_) {
      if (context.mounted) _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.tr('Không thể mở kênh liên hệ. Vui lòng thử lại.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final panelWidth = (media.size.width - 28).clamp(0.0, 360.0).toDouble();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _setOpen(false),
              child: const SizedBox.expand(),
            ),
          ),
        Positioned(
          right: widget.rightOffset,
          bottom: widget.bottomOffset + 64,
          child: IgnorePointer(
            ignoring: !_open,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _open ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                offset: _open ? Offset.zero : const Offset(0, 0.05),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  scale: _open ? 1 : 0.98,
                  child: _ContactPanel(
                    width: panelWidth,
                    onClose: () => _setOpen(false),
                    onPhone: () => _launch(
                      context,
                      Uri(scheme: 'tel', path: '0813118696'),
                    ),
                    onZalo: () => _launch(
                      context,
                      Uri.parse('https://zalo.me/0813118696'),
                    ),
                    onEmail: () => _launch(
                      context,
                      Uri(
                        scheme: 'mailto',
                        path: 'nhawowoffice@gmail.com',
                      ),
                    ),
                    onFacebook: () => _launch(
                      context,
                      Uri.parse('https://web.facebook.com/NhaWowOfficial'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: widget.rightOffset,
          bottom: widget.bottomOffset,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _open
                ? _RoundFab(
                    key: const ValueKey('floating-contact-close'),
                    icon: Icons.close_rounded,
                    semanticLabel: context.tr('Đóng'),
                    onTap: () => _setOpen(false),
                  )
                : _ContactFab(
                    key: const ValueKey('floating-contact-open'),
                    semanticLabel: context.tr('Liên hệ'),
                    onTap: () => _setOpen(true),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ContactFab extends StatelessWidget {
  const _ContactFab({
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: const Color(0xFFE11D2E),
        elevation: 8,
        shadowColor: const Color(0x44000000),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.headset_mic_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 17,
                  child: _OnlineDot(size: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundFab extends StatelessWidget {
  const _RoundFab({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: const Color(0xFFE11D2E),
        elevation: 8,
        shadowColor: const Color(0x44000000),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

class _ContactPanel extends StatelessWidget {
  const _ContactPanel({
    required this.width,
    required this.onClose,
    required this.onPhone,
    required this.onZalo,
    required this.onEmail,
    required this.onFacebook,
  });

  final double width;
  final VoidCallback onClose;
  final VoidCallback onPhone;
  final VoidCallback onZalo;
  final VoidCallback onEmail;
  final VoidCallback onFacebook;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x140F172A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 34,
              offset: Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: const Color(0xFFE11D2E),
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 38,
                    height: 38,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x2EFFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.headset_mic_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: _OnlineDot(size: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('NhàWow có thể hỗ trợ gì cho anh chị ạ?'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: context.tr('Đóng'),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x2E000000),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(32, 32),
                      maximumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _ContactItem(
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF22C55E),
                    title: context.tr('Gọi điện thoại trực tiếp'),
                    subtitle: '0813 118 696',
                    onTap: onPhone,
                  ),
                  const SizedBox(height: 9),
                  _ContactItem(
                    label: 'Zalo',
                    iconColor: const Color(0xFF0EA5E9),
                    title: context.tr('Nhắn tin qua Zalo'),
                    subtitle: 'zalo.me/0813118696',
                    onTap: onZalo,
                  ),
                  const SizedBox(height: 9),
                  _ContactItem(
                    icon: Icons.mail_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: context.tr('Liên hệ qua Email'),
                    subtitle: 'nhawowoffice@gmail.com',
                    onTap: onEmail,
                  ),
                  const SizedBox(height: 9),
                  _ContactItem(
                    label: 'f',
                    iconColor: const Color(0xFF2563EB),
                    title: context.tr('Xem thêm tại Facebook'),
                    subtitle: 'facebook.com/NhaWowOfficial',
                    onTap: onFacebook,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    this.icon,
    this.label,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null || label != null);

  final IconData? icon;
  final String? label;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF0F3),
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 19)
                    : Text(
                        label!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: label == 'f' ? 22 : 11,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xB30F172A),
                        fontSize: 11.7,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
