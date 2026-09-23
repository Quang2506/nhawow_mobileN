import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _busy = false;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Xóa tài khoản'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 52, color: Color(0xFFB42318)),
                const SizedBox(height: 16),
                Text(
                  context.tr('Yêu cầu xóa tài khoản đã đến hạn'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    'Bạn đã được đăng xuất. Tài khoản và dữ liệu liên quan sẽ được xóa vĩnh viễn trên máy chủ khi yêu cầu đến hạn.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr('Quay lại')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final scheduledAt = store.accountDeletionAt;
    final isPending = scheduledAt != null && scheduledAt.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Xóa tài khoản'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.delete_forever_outlined,
                      size: 44,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        isPending
                            ? 'Yêu cầu xóa tài khoản đã được ghi nhận'
                            : 'Xóa tài khoản vĩnh viễn sau 1 giờ',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(
                        'Sau khi xác nhận, bạn có 1 giờ để hủy yêu cầu. Hết thời gian này, tài khoản cùng toàn bộ tin đăng, ảnh, dữ liệu VR và dữ liệu liên quan sẽ bị xóa vĩnh viễn và không thể khôi phục.',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              if (isPending) ...[
                const SizedBox(height: 18),
                _InfoCard(
                  title: context.tr('Thời gian còn lại'),
                  value: _remainingText(context, scheduledAt),
                  subtitle: context.tr(
                    'Dự kiến xóa vĩnh viễn lúc {time}',
                    {'time': _formatDateTime(scheduledAt)},
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _cancel(context, store),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.undo),
                  label: Text(context.tr('Hủy yêu cầu xóa tài khoản')),
                ),
              ] else ...[
                const SizedBox(height: 18),
                _Bullet(
                  icon: Icons.schedule,
                  text: context.tr('Bạn có 1 giờ để hủy trước khi tài khoản bị xóa vĩnh viễn.'),
                ),
                const SizedBox(height: 10),
                _Bullet(
                  icon: Icons.home_work_outlined,
                  text: context.tr('Toàn bộ tin đăng, ảnh nhà, dữ liệu VR và dữ liệu liên quan sẽ bị xóa.'),
                ),
                const SizedBox(height: 10),
                _Bullet(
                  icon: Icons.lock_outline,
                  text: context.tr('Sau khi xóa, tài khoản không thể khôi phục hoặc đăng nhập lại.'),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _confirm(context, store),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB42318),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_forever_outlined),
                  label: Text(context.tr('Xóa tài khoản sau 1 giờ')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, AppStore store) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('Xác nhận xóa tài khoản vĩnh viễn')),
        content: Text(
          dialogContext.tr(
            'Tài khoản và toàn bộ dữ liệu liên quan sẽ bị xóa vĩnh viễn sau 1 giờ kể từ khi bạn xác nhận. Bạn chỉ có thể hủy yêu cầu trong thời gian chờ 1 giờ này.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('Hủy')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            child: Text(dialogContext.tr('Xóa tài khoản')),
          ),
        ],
      ),
    );

    if (accepted != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final at = await store.scheduleAccountDeletion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Tài khoản sẽ bị xóa vĩnh viễn lúc {time}.',
              {'time': _formatDateTime(at)},
            ),
          ),
        ),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(BuildContext context, AppStore store) async {
    setState(() => _busy = true);
    try {
      await store.cancelAccountDeletion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Đã hủy yêu cầu xóa tài khoản.'))),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _remainingText(BuildContext context, DateTime at) {
    var seconds = at.difference(DateTime.now()).inSeconds;
    if (seconds < 0) seconds = 0;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)} ${two(local.day)}/${two(local.month)}/${local.year}';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFB42318),
                ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    );
  }
}
