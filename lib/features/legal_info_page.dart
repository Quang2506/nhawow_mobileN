import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../core/app_theme.dart';

class LegalInfoPage extends StatefulWidget {
  const LegalInfoPage({super.key});

  @override
  State<LegalInfoPage> createState() => _LegalInfoPageState();
}

enum _LegalTab { terms, privacy }

class _LegalInfoPageState extends State<LegalInfoPage> {
  late final String _termsUrl;
  late final String _privacyUrl;
  WebViewController? _termsController;
  WebViewController? _privacyController;

  _LegalTab _currentTab = _LegalTab.terms;
  int _loadingProgress = 0;
  bool _isLoading = false;

  bool get _supportsEmbeddedWebView {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _termsUrl = '${AppConfig.webBaseUrl}/dieu-khoan-su-dung';
    _privacyUrl = '${AppConfig.webBaseUrl}/chinh-sach-bao-mat';

    if (_supportsEmbeddedWebView) {
      _termsController = _createController(_termsUrl);
      _privacyController = _createController(_privacyUrl);
    }
  }

  WebViewController _createController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = progress;
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = 0;
              _isLoading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = 100;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _reloadCurrent() async {
    if (!_supportsEmbeddedWebView) return;
    final controller = _currentTab == _LegalTab.terms ? _termsController : _privacyController;
    await controller?.reload();
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở trang. Vui lòng kiểm tra lại đường dẫn website.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều khoản và quyền riêng tư'),
        actions: [
          if (_supportsEmbeddedWebView)
            IconButton(
              tooltip: 'Tải lại',
              onPressed: _reloadCurrent,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C63E7), Color(0xFF00B1FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điều khoản & Chính sách',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _supportsEmbeddedWebView
                      ? 'Hiển thị trực tiếp nội dung từ Mobile Web ngay trong ứng dụng.'
                      : 'Thiết bị / môi trường hiện tại không hỗ trợ WebView nhúng. Bạn vẫn có thể mở đúng nội dung từ Mobile Web bằng nút bên dưới.',
                  style: const TextStyle(color: Colors.white, height: 1.45),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LegalTabButton(
                        title: 'Điều khoản sử dụng',
                        active: _currentTab == _LegalTab.terms,
                        onTap: () {
                          setState(() {
                            _currentTab = _LegalTab.terms;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LegalTabButton(
                        title: 'Chính sách bảo mật',
                        active: _currentTab == _LegalTab.privacy,
                        onTap: () {
                          setState(() {
                            _currentTab = _LegalTab.privacy;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_supportsEmbeddedWebView) ...[
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: _loadingProgress <= 0 || _loadingProgress >= 100
                      ? null
                      : _loadingProgress / 100,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6ECF4)),
                ),
                clipBehavior: Clip.antiAlias,
                child: IndexedStack(
                  index: _currentTab == _LegalTab.terms ? 0 : 1,
                  children: [
                    if (_termsController != null) WebViewWidget(controller: _termsController!),
                    if (_privacyController != null) WebViewWidget(controller: _privacyController!),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _ExternalOpenCard(
                      title: 'Điều khoản sử dụng',
                      description: 'Quy định về việc sử dụng nền tảng NhaWOW, trách nhiệm người dùng, nội dung bị cấm và các lưu ý giao dịch an toàn.',
                      url: _termsUrl,
                      icon: Icons.description_outlined,
                      onOpen: () => _openExternal(_termsUrl),
                    ),
                    const SizedBox(height: 12),
                    _ExternalOpenCard(
                      title: 'Chính sách bảo mật',
                      description: 'Nội dung về thu thập, sử dụng, chia sẻ, lưu trữ và bảo vệ dữ liệu cá nhân của người dùng trên nền tảng NhaWOW.',
                      url: _privacyUrl,
                      icon: Icons.privacy_tip_outlined,
                      onOpen: () => _openExternal(_privacyUrl),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FBFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCEBFA)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryDark),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nếu bạn đang chạy app trên Windows hoặc một môi trường Flutter chưa hỗ trợ WebView nhúng, hệ thống sẽ mở nội dung bằng trình duyệt ngoài để tránh lỗi màn hình đỏ.',
                              style: TextStyle(height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegalTabButton extends StatelessWidget {
  const _LegalTabButton({
    required this.title,
    required this.active,
    required this.onTap,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppTheme.navy : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExternalOpenCard extends StatelessWidget {
  const _ExternalOpenCard({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.onOpen,
  });

  final String title;
  final String description;
  final String url;
  final IconData icon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 10),
          Text(
            url,
            style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Mở nội dung'),
            ),
          ),
        ],
      ),
    );
  }
}
