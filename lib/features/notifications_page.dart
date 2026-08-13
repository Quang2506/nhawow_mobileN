import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'membership_page.dart';
import 'property_detail_page.dart';
import 'wallet_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = AppScope.of(context);
      if (store.isLoggedIn) {
        store.refreshNotifications(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Thông báo'))),
        body: PageContainer(
          maxWidth: 760,
          child: EmptyState(
            icon: Icons.lock_outline,
            title: context.tr('Vui lòng đăng nhập'),
            message: context.tr(
              'Nội dung này chỉ hiển thị cho tài khoản đã đăng nhập.',
            ),
            action: FilledButton(
              onPressed: () => AuthGate.ensureLoggedIn(context),
              child: Text(context.tr('Đăng nhập')),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Thông báo')),
        actions: [
          TextButton(
            onPressed: store.unreadNotificationCount == 0
                ? null
                : () async {
                    try {
                      await store.markAllNotificationsRead();
                    } catch (error) {
                      if (!context.mounted) return;
                      _showError(context, error.toString());
                    }
                  },
            child: Text(context.tr('Đọc tất cả')),
          ),
        ],
      ),
      body: PageContainer(
        maxWidth: 760,
        child: RefreshIndicator(
          onRefresh: () => store.refreshNotifications(force: true),
          child: _buildBody(context, store),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppStore store) {
    if (store.isLoadingNotifications && store.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (store.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: store.notificationError == null
                ? Icons.notifications_none
                : Icons.cloud_off_outlined,
            title: context.tr(
              store.notificationError == null
                  ? 'Chưa có thông báo'
                  : 'Không tải được thông báo',
            ),
            message: store.notificationError == null
                ? context.tr(
                    'Các cập nhật về tin đăng, hội viên và ví NhaWOW sẽ xuất hiện tại đây.',
                  )
                : context.tr(store.notificationError!),
            action: store.notificationError == null
                ? null
                : OutlinedButton.icon(
                    onPressed: () => store.refreshNotifications(force: true),
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('Thử lại')),
                  ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: store.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = store.notifications[index];
        return Card(
          color: item.isRead ? Colors.white : const Color(0xFFEAF7FF),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: item.isRead
                  ? const Color(0xFFF0F3F7)
                  : AppTheme.primary,
              child: Icon(
                _notificationIcon(item),
                color: item.isRead ? Colors.blueGrey : Colors.white,
              ),
            ),
            title: Text(
              context.tr(item.title),
              style: TextStyle(
                color: AppTheme.navy,
                fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w900,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(item.message)),
                  if (item.propertyTitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.propertyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(item.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            onTap: () => _openNotification(context, store, item),
          ),
        );
      },
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    AppStore store,
    NotificationModel item,
  ) async {
    if (!item.isRead) {
      try {
        await store.markNotificationRead(item.id);
      } catch (error) {
        if (!context.mounted) return;
        _showError(context, error.toString());
      }
    }
    if (!context.mounted) return;

    if (item.propertyId != null && item.propertyId! > 0) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PropertyDetailPage(propertyId: item.propertyId!),
        ),
      );
      return;
    }

    final target = item.url.trim().toLowerCase();
    if (target.contains('/membership')) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MembershipPage()),
      );
    } else if (target.contains('/wallet')) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const WalletPage()),
      );
    }
  }

  static IconData _notificationIcon(NotificationModel item) {
    final value = '${item.type} ${item.url}'.toLowerCase();
    if (value.contains('wallet') || value.contains('topup')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (value.contains('membership') || value.contains('member')) {
      return Icons.workspace_premium_outlined;
    }
    if (item.propertyId != null || value.contains('property')) {
      return Icons.home_work_outlined;
    }
    return Icons.notifications_outlined;
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}  ${two(local.day)}/${two(local.month)}/${local.year}';
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}
