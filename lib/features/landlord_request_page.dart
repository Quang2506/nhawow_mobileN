import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_assets.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';
import 'partner_properties_page.dart';

class LandlordRequestPage extends StatefulWidget {
  const LandlordRequestPage({
    this.embedded = false,
    super.key,
  });

  /// Khi trang được dùng trực tiếp trong MainShell thì không hiển thị nút quay
  /// lại và chừa thêm khoảng trống cho thanh điều hướng dưới cùng.
  final bool embedded;

  @override
  State<LandlordRequestPage> createState() => _LandlordRequestPageState();
}

class _LandlordRequestPageState extends State<LandlordRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey();
  final _scrollController = ScrollController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();

  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = AppScope.of(context).authUser;
    if (user == null) return;

    if (_name.text.trim().isEmpty) _name.text = user.name;
    if (_phone.text.trim().isEmpty) _phone.text = user.phone;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: widget.embedded ? 118 : 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LandlordHero(
                    onPost: _openPostingManagement,
                    onRegister: _scrollToRegister,
                  ),
                  const SizedBox(height: 14),
                  const _OwnerProblemCard(),
                  const SizedBox(height: 22),
                  _CenteredHeading(
                    title: context.tr('Hãy để NhaWOW lo'),
                    subtitle: context.tr(
                      'Với nền tảng công nghệ và hệ sinh thái người dùng sẵn có, NhaWOW sẽ giúp bạn:',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _HelpCards(),
                  const SizedBox(height: 18),
                  _PostFreeSection(onPost: _openPostingManagement),
                  const SizedBox(height: 20),
                  Text(
                    context.tr(
                      'Dịch vụ VR 360 - Vũ khí chốt deal mạnh mẽ',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _VrServiceCards(),
                  const SizedBox(height: 18),
                  KeyedSubtree(
                    key: _registerKey,
                    child: _RegisterSection(
                      formKey: _formKey,
                      nameController: _name,
                      phoneController: _phone,
                      addressController: _address,
                      noteController: _note,
                      isSubmitting: _isSubmitting,
                      onSubmit: _submitRequest,
                      requiredValidator: _required,
                      phoneValidator: _validatePhone,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(context.tr('Đăng tin'))),
      body: body,
    );
  }

  Future<void> _openPostingManagement() async {
    final allowed = await AuthGate.ensurePostingPermission(context);
    if (!mounted || !allowed) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PartnerPropertiesPage(),
      ),
    );
  }

  void _scrollToRegister() {
    final registerContext = _registerKey.currentContext;
    if (registerContext == null) return;
    Scrollable.ensureVisible(
      registerContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  Future<void> _submitRequest() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final message = await AppScope.of(context).submitLandlordRequest(
        guestName: _name.text.trim(),
        guestPhone: _phone.text.trim(),
        propertyAddress: _address.text.trim(),
        customerNotes: _note.text.trim(),
      );
      if (!mounted) return;

      _address.clear();
      _note.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.trim().isEmpty
                ? context.tr('Đã gửi yêu cầu. NhaWOW sẽ liên hệ sớm.')
                : message,
          ),
        ),
      );
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.message))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _required(BuildContext context, String? value) {
    return (value ?? '').trim().isEmpty
        ? context.tr('Vui lòng nhập thông tin')
        : null;
  }

  String? _validatePhone(BuildContext context, String? value) {
    final requiredError = _required(context, value);
    if (requiredError != null) return requiredError;

    var digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('84') && digits.length >= 11) {
      digits = '0${digits.substring(2)}';
    }
    final validMobile = RegExp(r'^0(3|5|7|8|9)[0-9]{8}$').hasMatch(digits);
    final validLandline = RegExp(r'^02[0-9]{8,9}$').hasMatch(digits);
    return validMobile || validLandline
        ? null
        : context.tr('Số điện thoại Việt Nam không đúng định dạng.');
  }
}

class _LandlordHero extends StatelessWidget {
  const _LandlordHero({
    required this.onPost,
    required this.onRegister,
  });

  final VoidCallback onPost;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 205,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _AssetPicture(
              asset: AppAssets.landlordHeroMobile,
              fallbackIcon: Icons.home_work_outlined,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xE609234D), Color(0x47122D55)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      context.tr('Đăng tin nhanh - Chốt khách dễ dàng hơn'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      FilledButton.icon(
                        onPressed: onPost,
                        icon: const Icon(Icons.edit_note_rounded, size: 19),
                        label: Text(context.tr('Đăng tin miễn phí')),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          backgroundColor: const Color(0x2EFFFFFF),
                        ),
                        onPressed: onRegister,
                        icon: const Icon(Icons.view_in_ar_outlined, size: 18),
                        label: Text(context.tr('Đăng ký dịch vụ VR')),
                      ),
                    ],
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

class _OwnerProblemCard extends StatelessWidget {
  const _OwnerProblemCard();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageWidth = constraints.maxWidth < 460
              ? constraints.maxWidth * 0.34
              : 190.0;
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 178),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: imageWidth,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                      child: const _AssetPicture(
                        asset: AppAssets.landlordProblem,
                        fallbackIcon: Icons.house_outlined,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr(
                              'Bạn có bất động sản cần cho thuê hoặc bán?',
                            ),
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontSize: 15.5,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('Bạn muốn đăng tin nhưng:'),
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          _ProblemLine(
                            text: context.tr('Không có khách xem?'),
                          ),
                          _ProblemLine(
                            text: context.tr('Mất nhiều thời gian dẫn khách?'),
                          ),
                          _ProblemLine(
                            text: context.tr(
                              'Khó tiếp cận đúng người có nhu cầu?',
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
        },
      ),
    );
  }
}

class _ProblemLine extends StatelessWidget {
  const _ProblemLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.cancel_rounded,
              color: Color(0xFFFF4773),
              size: 13,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 10.8,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredHeading extends StatelessWidget {
  const _CenteredHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HelpCards extends StatelessWidget {
  const _HelpCards();

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _CompactFeatureCard(
        icon: Icons.groups_rounded,
        title: context.tr('Tiếp cận đúng khách hàng'),
        description: context.tr(
          'Hệ thống tìm kiếm thông minh giúp tin đăng của bạn tiếp cận đúng người đang cần.',
        ),
      ),
      _CompactFeatureCard(
        icon: Icons.rocket_launch_rounded,
        title: context.tr('Tăng tỷ lệ chốt nhanh'),
        description: context.tr(
          'Hình ảnh đẹp và VR 360 giúp khách hàng ra quyết định nhanh hơn.',
        ),
      ),
      _CompactFeatureCard(
        icon: Icons.settings_rounded,
        title: context.tr('Quản lý dễ dàng'),
        description: context.tr(
          'Đăng, chỉnh sửa, theo dõi tin đăng cực kỳ đơn giản.',
        ),
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 205),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index < cards.length - 1) const SizedBox(width: 7),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactFeatureCard extends StatelessWidget {
  const _CompactFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 11),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEAF3FF),
            child: Icon(icon, color: const Color(0xFF0866FF), size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 9.4,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostFreeSection extends StatelessWidget {
  const _PostFreeSection({required this.onPost});

  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      child: Column(
        children: [
          Text(
            context.tr('Đăng tin miễn phí trên NhaWOW'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              'Chỉ với vài bước đơn giản, bạn có thể đăng bất động sản của mình lên hệ thống NhaWOW và tiếp cận hàng nghìn khách hàng mỗi ngày.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    flex: 4,
                    child: _AssetPicture(
                      asset: AppAssets.landlordPhone,
                      fallbackIcon: Icons.phone_android_rounded,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _InfoListCard(
                            title: context.tr('Nền tảng sẽ giúp bạn'),
                            items: [
                              context.tr('Miễn phí đăng tin bất động sản'),
                              context.tr('Tăng khả năng hiển thị'),
                              context.tr('Tối ưu hiệu quả quản lý khách'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _InfoListCard(
                            title: context.tr('Đăng tin chỉ trong 2 phút'),
                            items: [
                              context.tr('Chỉnh sửa dễ dàng'),
                              context.tr('Hiển thị thực tế và giá nhà'),
                              context.tr('Tối ưu tìm kiếm khách hàng'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(190, 46),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            onPressed: onPost,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(context.tr('Đăng tin miễn phí')),
          ),
        ],
      ),
    );
  }
}

class _InfoListCard extends StatelessWidget {
  const _InfoListCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D082457),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 10.5,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF0B73FF),
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 8.9,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VrServiceCards extends StatelessWidget {
  const _VrServiceCards();

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _VrCard(
        title: context.tr('Tin VR giúp bạn khác biệt'),
        items: [
          context.tr('Khách xem nhà rõ ràng hơn'),
          context.tr('Giảm số lần dẫn khách'),
          context.tr('Tăng độ tin cậy và chuyên nghiệp'),
        ],
        asset: AppAssets.vrService,
        fallbackIcon: Icons.threesixty_rounded,
      ),
      _VrCard(
        title: context.tr('Dịch vụ bao gồm'),
        items: [
          context.tr('VR 360 toàn bộ không gian'),
          context.tr('Ảnh chụp chuyên nghiệp'),
          context.tr('Video giới thiệu tùy chọn'),
        ],
        asset: AppAssets.vrCameraBox,
        fallbackIcon: Icons.photo_camera_outlined,
      ),
      _VrCard(
        title: context.tr('Kết quả bạn nhận được'),
        items: [
          context.tr('Tăng mạnh lượt xem'),
          context.tr('Tăng số lượng khách liên hệ'),
          context.tr('Tăng tỷ lệ chốt giao dịch'),
        ],
        asset: AppAssets.vrChart,
        fallbackIcon: Icons.trending_up_rounded,
        imageFit: BoxFit.contain,
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 265),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index < cards.length - 1) const SizedBox(width: 7),
            ],
          ],
        ),
      ),
    );
  }
}

class _VrCard extends StatelessWidget {
  const _VrCard({
    required this.title,
    required this.items,
    required this.asset,
    required this.fallbackIcon,
    this.imageFit = BoxFit.cover,
  });

  final String title;
  final List<String> items;
  final String asset;
  final IconData fallbackIcon;
  final BoxFit imageFit;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFF0B73FF),
                      size: 11,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 8.8,
                        height: 1.22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 83,
              width: double.infinity,
              child: _AssetPicture(
                asset: asset,
                fallbackIcon: fallbackIcon,
                fit: imageFit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterSection extends StatelessWidget {
  const _RegisterSection({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.noteController,
    required this.isSubmitting,
    required this.onSubmit,
    required this.requiredValidator,
    required this.phoneValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController noteController;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? Function(BuildContext context, String? value) requiredValidator;
  final String? Function(BuildContext context, String? value) phoneValidator;

  @override
  Widget build(BuildContext context) {
    final benefits = <_BenefitData>[
      _BenefitData(
        icon: Icons.home_work_rounded,
        title: context.tr('Đăng tin miễn phí'),
        description: context.tr(
          'Đăng tin dễ dàng, hoàn toàn miễn phí và nhanh chóng.',
        ),
      ),
      _BenefitData(
        icon: Icons.groups_rounded,
        title: context.tr('Tiếp cận khách hàng thực'),
        description: context.tr(
          'Kết nối với những khách hàng đang tìm kiếm mỗi ngày.',
        ),
      ),
      _BenefitData(
        icon: Icons.trending_up_rounded,
        title: context.tr('Tăng hiệu quả giao dịch'),
        description: context.tr(
          'Công cụ hỗ trợ thông minh giúp bạn chốt giao dịch nhanh hơn.',
        ),
      ),
      _BenefitData(
        icon: Icons.verified_user_rounded,
        title: context.tr('An toàn & tin cậy'),
        description: context.tr(
          'Thông tin được bảo mật, giao dịch an toàn và minh bạch.',
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = _WhiteCard(
          padding: const EdgeInsets.fromLTRB(9, 12, 9, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Bắt đầu đăng tin ngay hôm nay!'),
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              for (final benefit in benefits)
                _BenefitItem(data: benefit),
            ],
          ),
        );

        final form = _WhiteCard(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('Đăng ký dịch vụ của NhaWOW'),
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: context.tr('Họ tên'),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => requiredValidator(context, value),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: context.tr('Số điện thoại'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (value) => phoneValidator(context, value),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: addressController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: context.tr('Địa chỉ bất động sản'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) => requiredValidator(context, value),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: noteController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: context.tr('Nhu cầu và ghi chú'),
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 72),
                      child: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    context.tr(isSubmitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
                  ),
                ),
              ],
            ),
          ),
        );

        if (constraints.maxWidth >= 410) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: side),
              const SizedBox(width: 8),
              Expanded(flex: 6, child: form),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            side,
            const SizedBox(height: 10),
            form,
          ],
        );
      },
    );
  }
}

class _BenefitData {
  const _BenefitData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.data});

  final _BenefitData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E7F1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEAF3FF),
            child: Icon(data.icon, color: const Color(0xFF0866FF), size: 17),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 10.2,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.description,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 8.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B082457),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AssetPicture extends StatelessWidget {
  const _AssetPicture({
    required this.asset,
    required this.fallbackIcon,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final IconData fallbackIcon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFEAF3FF)),
          child: Center(
            child: Icon(
              fallbackIcon,
              color: const Color(0xFF0866FF),
              size: 42,
            ),
          ),
        );
      },
    );
  }
}
