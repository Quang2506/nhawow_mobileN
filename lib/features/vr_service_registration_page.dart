import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_assets.dart';
import '../core/app_theme.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';

class VrServiceRegistrationPage extends StatefulWidget {
  const VrServiceRegistrationPage({super.key});

  @override
  State<VrServiceRegistrationPage> createState() =>
      _VrServiceRegistrationPageState();
}

class _VrServiceRegistrationPageState extends State<VrServiceRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
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
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          context.tr('Đăng ký dịch vụ'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Trợ giúp'),
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
            const _SelectedServiceCard(),
            const SizedBox(height: 18),
            _SectionTitle(
              icon: Icons.person_rounded,
              title: context.tr('Thông tin liên hệ'),
            ),
            const SizedBox(height: 10),
            _FormCard(
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    hint: 'Họ và tên',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (value) => _required(context, value),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    hint: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (value) => _validatePhone(context, value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              icon: Icons.home_rounded,
              title: context.tr('Thông tin bất động sản'),
            ),
            const SizedBox(height: 10),
            _FormCard(
              children: [
                TextFormField(
                  controller: _address,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    hint: 'Địa chỉ bất động sản',
                    icon: Icons.location_on_outlined,
                  ),
                  validator: (value) => _required(context, value),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE4EBF5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.photo_camera_outlined,
                        color: Color(0xFF1479F8),
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr(
                            'NhaWOW sẽ trao đổi lịch chụp VR phù hợp sau khi nhận yêu cầu.',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF67758B),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              icon: Icons.edit_note_rounded,
              title: context.tr('Nhu cầu & ghi chú'),
            ),
            const SizedBox(height: 10),
            _FormCard(
              children: [
                TextFormField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _inputDecoration(
                    context,
                    hint: 'Mô tả nhu cầu hoặc ghi chú thêm',
                    icon: Icons.chat_bubble_outline_rounded,
                    alignIconTop: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBD9FF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: Color(0xFF1479F8),
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(
                        'NhaWOW sẽ liên hệ xác nhận trong thời gian sớm nhất.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9EEF5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Color(0xFF1479F8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: Text(
                    context.tr('Hủy'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0866FF),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.tr('Gửi yêu cầu'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    bool alignIconTop = false,
  }) {
    return InputDecoration(
      hintText: context.tr(hint),
      hintStyle: const TextStyle(color: Color(0xFF9AA5B4), fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: alignIconTop ? 46 : 0),
        child: Icon(icon, color: const Color(0xFF5F6B7A), size: 22),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFDDE5EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF1479F8), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
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
    final mobile = RegExp(r'^0(3|5|7|8|9)[0-9]{8}$').hasMatch(digits);
    final landline = RegExp(r'^02[0-9]{8,9}$').hasMatch(digits);
    return mobile || landline
        ? null
        : context.tr('Số điện thoại Việt Nam không đúng định dạng.');
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final message = await AppScope.of(context).submitLandlordRequest(
        guestName: _name.text.trim(),
        guestPhone: _phone.text.trim(),
        propertyAddress: _address.text.trim(),
        customerNotes: _note.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.trim().isEmpty
                ? context.tr('Đã gửi yêu cầu. NhaWOW sẽ liên hệ sớm.')
                : message,
          ),
        ),
      );
      Navigator.of(context).pop();
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.message))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Dịch vụ VR 360'),
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'Sau khi gửi yêu cầu, NhaWOW sẽ liên hệ để xác nhận bất động sản, thời gian chụp và các thông tin cần thiết trước khi triển khai VR 360.',
              ),
              style: const TextStyle(color: Color(0xFF667085), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedServiceCard extends StatelessWidget {
  const _SelectedServiceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFE2FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Dịch vụ đã chọn'),
            style: const TextStyle(
              color: Color(0xFF1479F8),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 128,
                  height: 92,
                  child: _ServiceImage(
                    asset: AppAssets.vrService,
                    overlay360: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('VR 360 cho bất động sản'),
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        'Tăng trải nghiệm xem nhà và giúp khách hiểu rõ không gian hơn.',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniTag(icon: Icons.visibility_outlined, text: context.tr('Tăng lượt xem')),
                        _MiniTag(icon: Icons.vrpano_outlined, text: context.tr('Xem nhà từ xa')),
                        _MiniTag(icon: Icons.star_rounded, text: context.tr('Chuyên nghiệp hơn')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF1479F8), size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF376294),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1479F8), size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({required this.asset, this.overlay360 = false});
  final String asset;
  final bool overlay360;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFEAF3FF),
            child: const Icon(
              Icons.vrpano_rounded,
              color: Color(0xFF1479F8),
              size: 44,
            ),
          ),
        ),
        if (overlay360)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x99000000),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '360°',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 19),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
