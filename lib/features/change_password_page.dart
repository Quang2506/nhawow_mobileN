import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Đổi mật khẩu'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: PageContainer(
            maxWidth: 500,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        size: 56,
                        color: AppTheme.primaryDark,
                      ),
                      const SizedBox(height: 18),
                      _passwordField(
                        controller: _oldPasswordController,
                        label: 'Mật khẩu hiện tại',
                        hidden: _hideOld,
                        onToggle: () => setState(() => _hideOld = !_hideOld),
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        controller: _newPasswordController,
                        label: 'Mật khẩu mới',
                        hidden: _hideNew,
                        onToggle: () => setState(() => _hideNew = !_hideNew),
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        controller: _confirmPasswordController,
                        label: 'Xác nhận mật khẩu mới',
                        hidden: _hideConfirm,
                        onToggle: () => setState(
                          () => _hideConfirm = !_hideConfirm,
                        ),
                        action: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        isConfirmation: true,
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock_reset_outlined),
                        label: Text(context.tr('Đổi mật khẩu')),
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

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
    required TextInputAction action,
    ValueChanged<String>? onSubmitted,
    bool isConfirmation = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hidden,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: context.tr(label),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) {
        if ((value ?? '').isEmpty) {
          return context.tr('Vui lòng nhập đầy đủ mật khẩu.');
        }
        if (!isConfirmation && controller == _newPasswordController &&
            (value ?? '').length < 6) {
          return context.tr('Mật khẩu phải có ít nhất 6 ký tự.');
        }
        if (isConfirmation && value != _newPasswordController.text) {
          return context.tr('Mật khẩu xác nhận không khớp.');
        }
        return null;
      },
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final message = await AppScope.of(context).changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              message.trim().isEmpty
                  ? 'Đổi mật khẩu thành công.'
                  : message,
            ),
          ),
        ),
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
