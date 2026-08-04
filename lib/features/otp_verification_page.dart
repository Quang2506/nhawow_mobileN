import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    required this.email,
    this.initialSeconds = 120,
    super.key,
  });

  final String email;
  final int initialSeconds;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.initialSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Xác thực email'))),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 58,
                        color: AppTheme.primaryDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('Nhập mã OTP'),
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
                          'Mã xác thực đã được gửi tới {email}.',
                          {'email': widget.email},
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        maxLength: 8,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        onFieldSubmitted: (_) => _verify(),
                        style: const TextStyle(
                          letterSpacing: 8,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.navy,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: context.tr('Mã OTP'),
                          prefixIcon: const Icon(Icons.password_outlined),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? context.tr('Vui lòng nhập mã OTP.')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _verify,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(context.tr('Xác nhận')),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _secondsLeft > 0 || _isResending
                            ? null
                            : _resend,
                        child: Text(
                          _secondsLeft > 0
                              ? context.tr(
                                  'Gửi lại OTP sau {seconds} giây',
                                  {'seconds': _secondsLeft},
                                )
                              : context.tr('Gửi lại mã OTP'),
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

  Future<void> _verify() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await AppScope.of(context).verifyEmailOtp(
        email: widget.email,
        code: _codeController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Xác thực email thành công.'))),
      );
      Navigator.of(context).pop(true);
    } on ApiTransportException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final seconds = await AppScope.of(context).resendVerifyOtp(widget.email);
      if (!mounted) return;
      _startCountdown(seconds > 0 ? seconds : 120);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Đã gửi lại mã OTP.'))),
      );
    } on ApiTransportException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    _secondsLeft = seconds > 0 ? seconds : 0;
    if (_secondsLeft <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}
