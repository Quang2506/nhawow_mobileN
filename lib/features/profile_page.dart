import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_store.dart';
import '../core/app_image.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late bool _isBroker;
  Uint8List? _avatarBytes;
  String _avatarFileName = '';
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = AppScope.of(context).authUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _isBroker = user?.isBroker ?? false;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Thông tin tài khoản'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: PageContainer(
            maxWidth: 560,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAvatarEditor(context),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.tr('Họ và tên'),
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? context.tr('Vui lòng nhập họ và tên.')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.tr('Email'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        decoration: InputDecoration(
                          labelText: context.tr('Số điện thoại'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isBroker,
                        onChanged: _isSubmitting
                            ? null
                            : (value) => setState(() => _isBroker = value),
                        title: Text(
                          context.tr('Tài khoản môi giới/đối tác'),
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          context.tr('Cho phép quản lý và đăng bất động sản.'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _save,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(context.tr('Lưu thay đổi')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarEditor(BuildContext context) {
    final user = AppScope.of(context).authUser;
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (_avatarBytes != null)
                Container(
                  width: 96,
                  height: 96,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD6E0EC)),
                  ),
                  child: Image.memory(
                    _avatarBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                )
              else
                AppAvatar(
                  url: user?.avatarUrl ?? '',
                  fallbackText: user?.name ?? '',
                  radius: 48,
                ),
              Positioned(
                right: -3,
                bottom: -3,
                child: Material(
                  color: AppTheme.primary,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isSubmitting ? null : _pickAvatar,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (_avatarBytes != null)
                Positioned(
                  left: -3,
                  bottom: -3,
                  child: Material(
                    color: const Color(0xFFE9EEF5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() {
                                _avatarBytes = null;
                                _avatarFileName = '';
                              }),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.undo_rounded,
                          size: 18,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _isSubmitting ? null : _pickAvatar,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(context.tr('Thay đổi ảnh đại diện')),
          ),
          Text(
            context.tr('JPG, PNG hoặc WEBP. Tối đa 2MB.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
        _showError('Ảnh đại diện không được vượt quá 2MB.');
        return;
      }
      setState(() {
        _avatarBytes = bytes;
        _avatarFileName = file.name;
      });
    } catch (error) {
      if (!mounted) return;
      _showError('${context.tr('Không thể chọn ảnh')}: $error');
    }
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    final valid = RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
    return valid ? null : context.tr('Email không đúng định dạng.');
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').replaceAll(RegExp(r'[\s.\-]'), '');
    if (phone.isEmpty) return null;
    final normalized = phone.startsWith('+84')
        ? '0${phone.substring(3)}'
        : (phone.startsWith('84') ? '0${phone.substring(2)}' : phone);
    return RegExp(r'^0(3|5|7|8|9)\d{8}$').hasMatch(normalized)
        ? null
        : context.tr('Số điện thoại Việt Nam không đúng định dạng.');
  }

  Future<void> _save() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await AppScope.of(context).updateProfile(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        isBroker: _isBroker,
        avatarFileName: _avatarFileName,
        avatarBase64Data:
            _avatarBytes == null ? '' : base64Encode(_avatarBytes!),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Cập nhật hồ sơ thành công.'))),
      );
      Navigator.of(context).pop();
    } on ApiTransportException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}
