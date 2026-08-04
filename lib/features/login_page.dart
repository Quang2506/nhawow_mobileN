import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';
import 'forgot_password_page.dart';
import 'otp_verification_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Đăng nhập'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: PageContainer(
            maxWidth: 480,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandWordmark()),
                      const SizedBox(height: 24),
                      Text(
                        context.tr('Đăng nhập NhaWOW'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          'Sử dụng tài khoản giống trên website NhaWOW.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF667085)),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _loginController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                          AutofillHints.telephoneNumber,
                        ],
                        decoration: InputDecoration(
                          labelText: context.tr('Email hoặc số điện thoại'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? context.tr('Vui lòng nhập email hoặc số điện thoại.')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
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
                        validator: (value) => (value ?? '').isEmpty
                            ? context.tr('Vui lòng nhập mật khẩu.')
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _openForgotPassword,
                          child: Text(context.tr('Quên mật khẩu?')),
                        ),
                      ),
                      const SizedBox(height: 4),
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
                            : Text(context.tr('Đăng nhập')),
                      ),
                      const Divider(height: 32),
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : _openRegister,
                        child: Text(context.tr('Tạo tài khoản mới')),
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

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      await AppScope.of(context).login(
        loginName: _loginController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      if (error.needVerify) {
        final email = (error.data['email'] ?? _loginController.text).toString();
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => OtpVerificationPage(
              email: email,
              initialSeconds: 0,
            ),
          ),
        );
        if (!mounted) return;
        if (verified == true || AppScope.of(context).isLoggedIn) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showError(error.message);
      }
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openRegister() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const RegisterPage()),
    );
    if (!mounted) return;
    if (loggedIn == true || AppScope.of(context).isLoggedIn) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openForgotPassword() async {
    final email = _loginController.text.contains('@')
        ? _loginController.text.trim()
        : '';
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordPage(initialEmail: email),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}
