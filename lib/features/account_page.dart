import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_store.dart';
import '../core/app_assets.dart';
import '../core/app_image.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../l10n/app_localizations.dart';
import 'agent_profile_page.dart';
import 'change_password_page.dart';
import 'landlord_request_page.dart';
import 'language_picker.dart';
import 'login_page.dart';
import 'membership_page.dart';
import 'notifications_page.dart';
import 'legal_info_page.dart';
import 'service_intro_page.dart';
import 'partner_properties_page.dart';
import 'profile_page.dart';
import 'wallet_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: Column(
          children: [
            if (store.isLoggedIn)
              _FixedAccountHeader(store: store)
            else
              const _FixedGuestHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: PageContainer(
                  maxWidth: 760,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
                  child: store.isLoggedIn
                      ? _LoggedInAccount(store: store)
                      : const _LoggedOutAccount(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedAccountHeader extends StatelessWidget {
  const _FixedAccountHeader({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final phone = store.currentUser.phone.trim();
    final secondaryText = phone.isNotEmpty
        ? phone
        : context.tr(store.currentUser.roleLabel);

    return SizedBox(
      width: double.infinity,
      height: topInset + 172,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF006A8E), Color(0xFF00956F)],
              ),
            ),
          ),
          Image.asset(
            AppAssets.accountBackground,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x26002134),
                  Color(0x4D00384A),
                  Color(0xB3003F46),
                ],
                stops: [0, 0.48, 1],
              ),
            ),
          ),
          Positioned(
            left: -34,
            top: topInset + 42,
            child: Transform.rotate(
              angle: -0.28,
              child: Container(
                width: 150,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, topInset + 17, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Tài khoản'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.92),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x50000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _ProfileAvatar(store: store, radius: 35),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.currentUser.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: Color(0x66000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 5,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: context.tr('Chỉnh sửa thông tin'),
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfilePage(),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedGuestHeader extends StatelessWidget {
  const _FixedGuestHeader();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      width: double.infinity,
      height: topInset + 164,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF006A8E), Color(0xFF00956F)],
              ),
            ),
          ),
          Image.asset(
            AppAssets.accountBackground,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x35002134), Color(0xB0003F46)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, topInset + 17, 18, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Tài khoản'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        AppAssets.brandLogo,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.tr('Đăng nhập để sử dụng đầy đủ NhaWOW'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoggedOutAccount extends StatelessWidget {
  const _LoggedOutAccount();

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Column(
      children: [
        EmptyState(
          icon: Icons.account_circle_outlined,
          title: context.tr('Đăng nhập để sử dụng đầy đủ NhaWOW'),
          message: context.tr(
            'Lưu tin, chat, nhận thông báo và quản lý bất động sản của bạn.',
          ),
          action: FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              );
            },
            child: Text(context.tr('Đăng nhập')),
          ),
        ),
        const SizedBox(height: 14),
        _AccountMenuItem(
          icon: Icons.language,
          title: context.tr('Ngôn ngữ'),
          subtitle: '${store.language.displayMark} ${store.language.nativeName}',
          onTap: () => showLanguagePicker(context),
        ),
      ],
    );
  }
}

class _LoggedInAccount extends StatelessWidget {
  const _LoggedInAccount({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (store.isBroker)
          _AccountMenuItem(
            icon: Icons.home_work_outlined,
            title: context.tr('Quản lý tin đăng'),
            subtitle: store.isLoadingPartnerProperties &&
                    store.partnerProperties.isEmpty
                ? context.tr('Đang tải...')
                : context.tr(
                    '{count} bất động sản của bạn',
                    {'count': store.partnerProperties.length},
                  ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PartnerPropertiesPage(),
                ),
              );
              if (!context.mounted) return;
              // Trang quản lý có thể đang lọc theo trạng thái/thành phố.
              // Khi quay lại, tải lại toàn bộ để con số tại Tài khoản luôn là
              // tổng số tin thực tế của người dùng.
              await store.preloadPartnerProperties();
            },
          ),
        if (store.isBroker)
          _AccountMenuItem(
            icon: Icons.person_search_outlined,
            title: context.tr('Xem hồ sơ môi giới'),
            subtitle: context.tr('Xem hồ sơ công khai và các tin đăng của bạn'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AgentProfilePage(agent: store.currentUser),
              ),
            ),
          ),
        _AccountMenuItem(
          icon: Icons.workspace_premium_outlined,
          title: context.tr('Hội viên'),
          subtitle: context.tr(
            'Gói hiện tại: {code}',
            {
              'code': context.tr(
                store.membershipUsage.currentPlanName.trim().isNotEmpty
                    ? store.membershipUsage.currentPlanName
                    : store.membershipCode,
              ),
            },
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MembershipPage()),
          ),
        ),
        _AccountMenuItem(
          icon: Icons.menu_book_outlined,
          title: context.tr('Gói mua & dịch vụ'),
          subtitle: context.tr('Xem bảng giá, quyền lợi hội viên và dịch vụ gia tăng'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ServiceIntroPage()),
          ),
        ),
        _AccountMenuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: context.tr('Ví NhaWOW'),
          subtitle: context.tr(
            'Số dư {amount} đ',
            {'amount': _formatMoney(store.walletBalance)},
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WalletPage()),
          ),
        ),
        _AccountMenuItem(
          icon: Icons.notifications_none,
          title: context.tr('Thông báo'),
          subtitle: context.tr(
            '{count} thông báo chưa đọc',
            {'count': store.unreadNotificationCount},
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsPage(),
            ),
          ),
        ),
        _AccountMenuItem(
          icon: Icons.real_estate_agent_outlined,
          title: context.tr('Gửi yêu cầu đăng nhà'),
          subtitle: context.tr('NhaWOW liên hệ hỗ trợ bạn đăng tin'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LandlordRequestPage(),
            ),
          ),
        ),
        _AccountMenuItem(
          icon: Icons.password_outlined,
          title: context.tr('Đổi mật khẩu'),
          subtitle: context.tr('Cập nhật mật khẩu đăng nhập tài khoản'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ChangePasswordPage(),
            ),
          ),
        ),
        _AccountMenuItem(
          icon: Icons.language,
          title: context.tr('Ngôn ngữ'),
          subtitle: '${store.language.displayMark} ${store.language.nativeName}',
          onTap: () => showLanguagePicker(context),
        ),
        _AccountMenuItem(
          icon: Icons.shield_outlined,
          title: context.tr('Điều khoản và quyền riêng tư'),
          subtitle: context.tr('Chính sách sử dụng nền tảng'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const LegalInfoPage()),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await store.logout();
              store.setSelectedTab(0);
            },
            icon: const Icon(Icons.logout),
            label: Text(context.tr('Đăng xuất')),
          ),
        ),
      ],
    );
  }

  String _formatMoney(double value) {
    final raw = value.round().toString();
    final chars = <String>[];
    for (var i = 0; i < raw.length; i++) {
      chars.add(raw[i]);
      final remaining = raw.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) chars.add('.');
    }
    return chars.join();
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF0F6FC),
            child: Icon(icon, color: AppTheme.primaryDark),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.store, this.radius = 34});

  final AppStore store;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = store.currentUser.avatarUrl.trim();
    if (avatarUrl.isNotEmpty) {
      return AppAvatar(
        url: avatarUrl,
        fallbackText: store.currentUser.name,
        radius: radius,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: const AssetImage(AppAssets.agentHero),
      backgroundColor: const Color(0xFFE7F7FF),
    );
  }
}
