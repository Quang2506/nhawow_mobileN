import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _otpSent = false;
  bool _isSubmitting = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Quên mật khẩu'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: PageContainer(
            maxWidth: 500,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: _otpSent ? _buildResetForm() : _buildEmailForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 58,
            color: AppTheme.primaryDark,
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('Đặt lại mật khẩu'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Nhập email đã đăng ký để nhận mã OTP.'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _sendOtp(),
            decoration: InputDecoration(
              labelText: context.tr('Email'),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting ? null : _sendOtp,
            child: _loadingOrText('Gửi mã OTP'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.password_rounded,
            size: 58,
            color: AppTheme.primaryDark,
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('Tạo mật khẩu mới'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Mã OTP đã được gửi tới {email}.',
              {'email': _emailController.text.trim()},
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: InputDecoration(
              labelText: context.tr('Mã OTP'),
              prefixIcon: const Icon(Icons.password_outlined),
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? context.tr('Vui lòng nhập mã OTP.')
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: context.tr('Mật khẩu mới'),
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
                return context.tr('Vui lòng nhập mật khẩu mới.');
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
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: InputDecoration(
              labelText: context.tr('Xác nhận mật khẩu mới'),
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(
                  () => _hideConfirmPassword = !_hideConfirmPassword,
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
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting ? null : _resetPassword,
            child: _loadingOrText('Đặt lại mật khẩu'),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _sendOtp,
            child: Text(context.tr('Gửi lại mã OTP')),
          ),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => setState(() => _otpSent = false),
            child: Text(context.tr('Dùng email khác')),
          ),
        ],
      ),
    );
  }

  Widget _loadingOrText(String text) {
    return _isSubmitting
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        : Text(context.tr(text));
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return context.tr('Vui lòng nhập email.');
    final valid = RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
    return valid ? null : context.tr('Email không đúng định dạng.');
  }

  Future<void> _sendOtp() async {
    if (_isSubmitting || !(_emailFormKey.currentState?.validate() ?? _otpSent)) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await AppScope.of(context).sendResetOtp(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _otpSent = true);
      _showMessage(context.tr('OTP đặt lại mật khẩu đang được gửi tới email.'));
    } on ApiTransportException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_isSubmitting || !(_resetFormKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final message = await AppScope.of(context).resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!mounted) return;
      _showMessage(
        message.trim().isEmpty
            ? context.tr('Đặt lại mật khẩu thành công.')
            : context.tr(message),
      );
      Navigator.of(context).pop();
    } on ApiTransportException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}
