import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isBroker = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isSubmitting = false;
  Uint8List? _avatarBytes;
  String _avatarFileName = '';
  String? _emailServerError;
  String? _phoneServerError;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Tạo tài khoản'))),
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
                      const Center(child: BrandWordmark()),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('Đăng ký tài khoản NhaWOW'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAvatarEditor(context),
                      if (_submitError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF04438),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 19,
                                color: Color(0xFFD92D20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr(_submitError!),
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
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
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: context.tr('Email'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        onChanged: (_) {
                          if (_emailServerError != null || _submitError != null) {
                            setState(() {
                              _emailServerError = null;
                              _submitError = null;
                            });
                          }
                        },
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: InputDecoration(
                          labelText: context.tr('Số điện thoại (không bắt buộc)'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        onChanged: (_) {
                          if (_phoneServerError != null || _submitError != null) {
                            setState(() {
                              _phoneServerError = null;
                              _submitError = null;
                            });
                          }
                        },
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: context.tr('Mật khẩu'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _hidePassword = !_hidePassword,
                            ),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return context.tr('Vui lòng nhập mật khẩu.');
                          }
                          if ((value ?? '').length < 6) {
                            return context.tr('Mật khẩu phải có ít nhất 6 ký tự.');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _hideConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: context.tr('Xác nhận mật khẩu'),
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _hideConfirmPassword =
                                  !_hideConfirmPassword,
                            ),
                            icon: Icon(
                              _hideConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value != _passwordController.text
                            ? context.tr('Mật khẩu xác nhận không khớp.')
                            : null,
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isBroker,
                        onChanged: _isSubmitting
                            ? null
                            : (value) => setState(() => _isBroker = value),
                        title: Text(
                          context.tr('Tôi là môi giới/đối tác đăng tin'),
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          context.tr(
                            'Bật lựa chọn này để quản lý và đăng bất động sản.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(context.tr('Đăng ký')),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr(
                          'Sau khi đăng ký, mã OTP sẽ được gửi tới email và có hiệu lực trong 2 phút.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12.5,
                        ),
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
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: const Color(0xFFD6E0EC)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _avatarBytes == null
                    ? const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 42,
                        color: AppTheme.primaryDark,
                      )
                    : Image.memory(
                        _avatarBytes!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
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
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
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
                          Icons.close_rounded,
                          size: 17,
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
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: Text(context.tr('Thêm ảnh đại diện')),
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
        _submitError = null;
      });
    } catch (error) {
      if (!mounted) return;
      _showError('${context.tr('Không thể chọn ảnh')}: $error');
    }
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return context.tr('Vui lòng nhập email.');
    final valid = RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
    if (!valid) return context.tr('Email không đúng định dạng.');
    return _emailServerError == null
        ? null
        : context.tr(_emailServerError!);
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').replaceAll(RegExp(r'[\s.\-]'), '');
    if (phone.isEmpty) return _phoneServerError == null
        ? null
        : context.tr(_phoneServerError!);
    final normalized = phone.startsWith('+84')
        ? '0${phone.substring(3)}'
        : (phone.startsWith('84') ? '0${phone.substring(2)}' : phone);
    if (!RegExp(r'^0(3|5|7|8|9)\d{8}$').hasMatch(normalized)) {
      return context.tr('Số điện thoại Việt Nam không đúng định dạng.');
    }
    return _phoneServerError == null
        ? null
        : context.tr(_phoneServerError!);
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _emailServerError = null;
      _phoneServerError = null;
      _submitError = null;
    });

    try {
      final result = await AppScope.of(context).registerAccount(
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        isBroker: _isBroker,
        avatarFileName: _avatarFileName,
        avatarBase64Data:
            _avatarBytes == null ? '' : base64Encode(_avatarBytes!),
      );
      if (!mounted) return;

      if (result.needVerify) {
        await _openOtp(result.email, result.otpExpireSeconds);
      }
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      if (error.needVerify) {
        _showError(error.message);
        final email = (error.data['email'] ?? _emailController.text).toString();
        await _openOtp(email, 0);
      } else {
        if (error.code == 'EMAIL_EXISTS') {
          setState(() {
            _emailServerError = error.message;
            _submitError = error.message;
          });
          _formKey.currentState?.validate();
        } else if (error.code == 'PHONE_EXISTS') {
          setState(() {
            _phoneServerError = error.message;
            _submitError = error.message;
          });
          _formKey.currentState?.validate();
        } else {
          setState(() => _submitError = error.message);
        }
        _showError(error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submitError = error.toString());
        _showError(error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  Future<void> _openOtp(String email, int initialSeconds) async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OtpVerificationPage(
          email: email,
          initialSeconds: initialSeconds,
        ),
      ),
    );
    if (!mounted) return;
    if (verified == true || AppScope.of(context).isLoggedIn) {
      Navigator.of(context).pop(true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}
