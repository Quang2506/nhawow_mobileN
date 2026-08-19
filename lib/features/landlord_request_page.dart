import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/floating_contact.dart';
import '../l10n/app_localizations.dart';
import 'partner_properties_page.dart';
import 'vr_service_registration_page.dart';

class LandlordRequestPage extends StatefulWidget {
  const LandlordRequestPage({
    this.embedded = false,
    super.key,
  });

  final bool embedded;

  @override
  State<LandlordRequestPage> createState() => _LandlordRequestPageState();
}

class _LandlordRequestPageState extends State<LandlordRequestPage> {
  final _scrollController = ScrollController();
  final _vrKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(context.tr('Đăng tin'))),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: widget.embedded ? 118 : 28),
              child: Column(
                children: [
                  _HeroSection(
                    onPost: _openPostingManagement,
                    onExploreVr: _scrollToVr,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Column(
                      children: [
                        const _BenefitsRow(),
                        const SizedBox(height: 14),
                        _PostFreeCard(onPost: _openPostingManagement),
                        const SizedBox(height: 14),
                        KeyedSubtree(
                          key: _vrKey,
                          child: _VrCard(onRegister: _openVrRegistration),
                        ),
                        const SizedBox(height: 14),
                        const _BottomAssuranceCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: FloatingContact(
                bottomOffset: widget.embedded ? 112 : 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPostingManagement() async {
    final allowed = await AuthGate.ensurePostingPermission(context);
    if (!mounted || !allowed) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PartnerPropertiesPage()),
    );
  }

  void _scrollToVr() {
    final target = _vrKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _openVrRegistration() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const VrServiceRegistrationPage(),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onPost, required this.onExploreVr});
  final VoidCallback onPost;
  final VoidCallback onExploreVr;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.landlordHeroMobile,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFEAF3FF),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 26),
              child: const Icon(
                Icons.home_work_rounded,
                color: Color(0xFF9FC5F8),
                size: 112,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.0, 0.44, 0.72, 1.0],
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xF4FFFFFF),
                  Color(0xB5FFFFFF),
                  Color(0x12FFFFFF),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 34, 18, 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Đăng tin nhanh –\nChốt khách dễ dàng hơn'),
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 25,
                        height: 1.15,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr('Đăng tin miễn phí hoặc nâng cấp trải nghiệm với VR 360.'),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13.2,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0866FF),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        onPressed: onPost,
                        icon: const Icon(Icons.edit_square, size: 17),
                        label: Text(
                          context.tr('Đăng tin miễn phí'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0866FF),
                          backgroundColor: const Color(0xEFFFFFFF),
                          minimumSize: const Size.fromHeight(44),
                          side: const BorderSide(color: Color(0xFF4D91FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        onPressed: onExploreVr,
                        icon: const Icon(Icons.threesixty_rounded, size: 18),
                        label: Text(
                          context.tr('Khám phá VR 360'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsRow extends StatelessWidget {
  const _BenefitsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BenefitCard(
            icon: Icons.groups_rounded,
            title: context.tr('Tiếp cận đúng\nkhách hàng'),
            subtitle: context.tr('Đúng người, đúng nhu cầu.'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BenefitCard(
            icon: Icons.bolt_rounded,
            title: context.tr('Đăng tin nhanh\ntrong vài phút'),
            subtitle: context.tr('Đơn giản, dễ thực hiện.'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BenefitCard(
            icon: Icons.inventory_2_rounded,
            title: context.tr('Quản lý tin\ndễ dàng'),
            subtitle: context.tr('Chỉnh sửa, theo dõi tiện lợi.'),
          ),
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 134,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF1F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1479F8), size: 21),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 12.0,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8893A3),
                  fontSize: 9.3,
                  height: 1.18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostFreeCard extends StatelessWidget {
  const _PostFreeCard({required this.onPost});
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: SizedBox(
        height: 238,
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: 7,
              bottom: 6,
              width: 180,
              child: Transform.rotate(
                angle: 0.08,
                child: Image.asset(
                  AppAssets.landlordPhone,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.phone_iphone_rounded,
                    color: Color(0xFFB7C9E4),
                    size: 132,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 144, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Đăng tin miễn phí'),
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.tr('Tạo tin trong vài phút, chỉnh sửa dễ dàng và tiếp cận khách hàng mỗi ngày.'),
                      style: const TextStyle(
                        color: Color(0xFF758195),
                        fontSize: 11.8,
                        height: 1.42,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CheckLine(text: context.tr('Miễn phí đăng tin')),
                    _CheckLine(text: context.tr('Dễ chỉnh sửa')),
                    _CheckLine(text: context.tr('Tối ưu hiển thị')),
                    const Spacer(),
                    SizedBox(
                      width: 190,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0866FF),
                          minimumSize: const Size.fromHeight(43),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onPost,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('Đăng tin ngay'),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VrCard extends StatelessWidget {
  const _VrCard({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('VR 360 – Tăng trải nghiệm xem nhà'),
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 17.5,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.tr('Cho khách xem nhà trước khi đến, tăng quan tâm và giảm lượt xem không phù hợp.'),
                      style: const TextStyle(
                        color: Color(0xFF6F7B8F),
                        fontSize: 11.4,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 164,
                  height: 124,
                  child: Image.asset(
                    AppAssets.vrService,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFEAF3FF),
                      child: const Icon(
                        Icons.vrpano_rounded,
                        color: Color(0xFF1479F8),
                        size: 52,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VrBenefit(icon: Icons.visibility_rounded, text: context.tr('Xem rõ\nkhông gian')),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _VrBenefit(icon: Icons.trending_up_rounded, text: context.tr('Tăng lượt\nquan tâm')),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _VrBenefit(icon: Icons.star_rounded, text: context.tr('Chuyên\nnghiệp hơn')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0866FF),
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onRegister,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr('Đăng ký VR 360'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 18),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VrBenefit extends StatelessWidget {
  const _VrBenefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF2F8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1479F8), size: 22),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 10.4,
              height: 1.16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2A8BFF), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 11.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAssuranceCard extends StatelessWidget {
  const _BottomAssuranceCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, color: Color(0xFF1479F8), size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              context.tr('Cần hỗ trợ? NhaWOW luôn sẵn sàng đồng hành trong quá trình đăng tin và triển khai VR 360.'),
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 11.8,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 22,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}
