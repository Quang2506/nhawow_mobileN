import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_store.dart';
import '../core/app_image.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'chat_thread_page.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  bool _requested = false;
  bool _isApplyingSelectionAction = false;
  final Set<int> _selectedConversationIds = <int>{};

  bool get _isSelecting => _selectedConversationIds.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppScope.of(context);
    if (!store.isLoggedIn || _requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(store));
  }

  Future<void> _refresh(AppStore store) async {
    try {
      await store.refreshConversations(force: true);
      if (!mounted) return;
      final availableIds = store.conversations.map((item) => item.id).toSet();
      setState(() {
        _selectedConversationIds.removeWhere(
          (conversationId) => !availableIds.contains(conversationId),
        );
      });
    } catch (_) {
      // Lỗi đã được lưu trong AppStore và hiển thị ngay trên màn hình.
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Tin nhắn'))),
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

    final conversations = [...store.conversations]
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.sortTime.compareTo(a.sortTime);
      });

    final selectedConversations = conversations
        .where((item) => _selectedConversationIds.contains(item.id))
        .toList(growable: false);
    final allSelectedPinned = selectedConversations.isNotEmpty &&
        selectedConversations.every((item) => item.isPinned);
    final allSelectedFlagged = selectedConversations.isNotEmpty &&
        selectedConversations.every((item) => item.isFlagged);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Tin nhắn')),
        actions: [
          IconButton(
            tooltip: context.tr('Làm mới'),
            onPressed: store.isLoadingConversations ||
                    _isApplyingSelectionAction
                ? null
                : () {
                    _exitSelectionMode();
                    _refresh(store);
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: PageContainer(
        maxWidth: 760,
        child: Column(
          children: [
            if (store.isLoadingConversations)
              const LinearProgressIndicator(minHeight: 2),
            if (store.chatError != null) ...[
              const SizedBox(height: 10),
              Material(
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger),
                      const SizedBox(width: 8),
                      Expanded(child: Text(context.tr(store.chatError!))),
                    ],
                  ),
                ),
              ),
            ],
            Expanded(
              child: conversations.isEmpty && !store.isLoadingConversations
                  ? EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: context.tr('Chưa có hội thoại'),
                      message: context.tr(
                        'Tin nhắn với khách hàng và chủ nhà sẽ xuất hiện tại đây.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        _exitSelectionMode();
                        await _refresh(store);
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 10, bottom: 18),
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = conversations[index];
                          return _ConversationTile(
                            item: item,
                            isSelectionMode: _isSelecting,
                            isSelected:
                                _selectedConversationIds.contains(item.id),
                            onTap: () => _handleConversationTap(store, item),
                            onLongPress: () => _enterSelectionMode(item.id),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isSelecting
          ? _ConversationSelectionBar(
              selectedCount: _selectedConversationIds.length,
              isBusy: _isApplyingSelectionAction,
              allPinned: allSelectedPinned,
              allFlagged: allSelectedFlagged,
              onClose: _isApplyingSelectionAction ? null : _exitSelectionMode,
              onPin: _isApplyingSelectionAction
                  ? null
                  : () => _setSelectedPinned(
                        store,
                        pinned: !allSelectedPinned,
                      ),
              onFlag: _isApplyingSelectionAction
                  ? null
                  : () => _setSelectedFlagged(
                        store,
                        flagged: !allSelectedFlagged,
                      ),
              onDelete: _isApplyingSelectionAction
                  ? null
                  : () => _deleteSelected(store),
            )
          : null,
    );
  }

  Future<void> _handleConversationTap(
    AppStore store,
    ConversationModel item,
  ) async {
    if (_isSelecting) {
      _toggleSelectedConversation(item.id);
      return;
    }

    try {
      await store.loadConversationMessages(item.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(store.chatError ?? 'Không thể tải hội thoại.'),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadPage(conversationId: item.id),
      ),
    );
    if (!mounted) return;
    await _refresh(store);
  }

  void _enterSelectionMode(int conversationId) {
    if (_isApplyingSelectionAction) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedConversationIds.add(conversationId);
    });
  }

  void _toggleSelectedConversation(int conversationId) {
    if (_isApplyingSelectionAction) return;
    setState(() {
      if (!_selectedConversationIds.remove(conversationId)) {
        _selectedConversationIds.add(conversationId);
      }
    });
  }

  void _exitSelectionMode() {
    if (!mounted || _selectedConversationIds.isEmpty) return;
    setState(_selectedConversationIds.clear);
  }

  Future<void> _setSelectedPinned(
    AppStore store, {
    required bool pinned,
  }) async {
    final ids = _selectedConversationIds.toList(growable: false);
    if (ids.isEmpty) return;
    await _runSelectionAction(
      () => store.setConversationsPinned(ids, pinned),
      successMessage: pinned
          ? 'Đã ghim các cuộc trò chuyện đã chọn.'
          : 'Đã bỏ ghim các cuộc trò chuyện đã chọn.',
    );
  }

  Future<void> _setSelectedFlagged(
    AppStore store, {
    required bool flagged,
  }) async {
    final ids = _selectedConversationIds.toList(growable: false);
    if (ids.isEmpty) return;
    await _runSelectionAction(
      () => store.setConversationsFlagged(ids, flagged),
      successMessage: flagged
          ? 'Đã đánh dấu các cuộc trò chuyện đã chọn.'
          : 'Đã bỏ đánh dấu các cuộc trò chuyện đã chọn.',
    );
  }

  Future<void> _deleteSelected(AppStore store) async {
    final ids = _selectedConversationIds.toList(growable: false);
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Xóa cuộc trò chuyện?')),
        content: Text(
          context.tr(
            'Bạn có chắc muốn xóa các cuộc trò chuyện đã chọn khỏi hộp tin nhắn?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Hủy')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('Xóa')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runSelectionAction(
      () => store.deleteConversations(ids),
      successMessage: 'Đã xóa các cuộc trò chuyện khỏi hộp tin nhắn.',
    );
  }

  Future<void> _runSelectionAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_isApplyingSelectionAction) return;
    setState(() => _isApplyingSelectionAction = true);
    try {
      await action();
      if (!mounted) return;
      setState(_selectedConversationIds.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(successMessage))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              error.toString().trim().isEmpty
                  ? 'Không thể thực hiện thao tác. Vui lòng thử lại.'
                  : error.toString(),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplyingSelectionAction = false);
    }
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final ConversationModel item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final selectedBackground = const Color(0xFFEAF7FF);
    final selectedBorder = const Color(0xFF77CFFF);

    return Card(
      elevation: 0,
      color: isSelected ? selectedBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? selectedBorder : const Color(0xFFE8EDF3),
          width: isSelected ? 1.2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minVerticalPadding: 11,
        horizontalTitleGap: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: isSelectionMode
                  ? Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _SelectionCircle(isSelected: isSelected),
                    )
                  : const SizedBox.shrink(),
            ),
            AppAvatar(
              url: item.avatarUrl,
              fallbackText: item.title,
              radius: 27,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                context.tr(item.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.navy,
                  fontWeight:
                      item.unreadCount > 0 ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
            if (item.isPinned)
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: Icon(
                  Icons.push_pin,
                  size: 15,
                  color: AppTheme.primaryDark,
                ),
              ),
            if (item.isFlagged)
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: Icon(Icons.flag, size: 15, color: Colors.amber),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              context.tr(item.subtitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(item.previewText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.unreadCount > 0 ? AppTheme.navy : Colors.blueGrey,
                fontWeight:
                    item.unreadCount > 0 ? FontWeight.w700 : FontWeight.w400,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatConversationTime(item.sortTime),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8194AD),
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 8),
              if (item.unreadCount > 0)
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppTheme.danger,
                  child: Text(
                    item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (!isSelectionMode)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF9AA9BA),
                ),
            ],
          ),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  static String _formatConversationTime(DateTime value) {
    if (value.millisecondsSinceEpoch <= 0) return '';
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    final dd = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$dd/$month/${local.year}';
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppTheme.primary : Colors.white,
        border: Border.all(
          color: isSelected ? AppTheme.primary : const Color(0xFFC8D6E5),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }
}

class _ConversationSelectionBar extends StatelessWidget {
  const _ConversationSelectionBar({
    required this.selectedCount,
    required this.isBusy,
    required this.allPinned,
    required this.allFlagged,
    required this.onClose,
    required this.onPin,
    required this.onFlag,
    required this.onDelete,
  });

  final int selectedCount;
  final bool isBusy;
  final bool allPinned;
  final bool allFlagged;
  final VoidCallback? onClose;
  final VoidCallback? onPin;
  final VoidCallback? onFlag;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Material(
        elevation: 10,
        color: Colors.white,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE0E7EF)),
          ),
          child: Row(
            children: [
              _SelectionActionButton(
                tooltip: context.tr('Hủy'),
                icon: Icons.close_rounded,
                onPressed: onClose,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedCount',
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('đã chọn'),
                      style: const TextStyle(
                        color: Color(0xFF70839A),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.3),
                  ),
                )
              else ...[
                _SelectionActionButton(
                  tooltip: context.tr(allPinned ? 'Bỏ ghim' : 'Ghim'),
                  icon: allPinned
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  onPressed: onPin,
                  isActive: allPinned,
                ),
                const SizedBox(width: 6),
                _SelectionActionButton(
                  tooltip:
                      context.tr(allFlagged ? 'Bỏ đánh dấu' : 'Đánh dấu'),
                  icon: allFlagged ? Icons.flag : Icons.flag_outlined,
                  onPressed: onFlag,
                  isActive: allFlagged,
                ),
                const SizedBox(width: 6),
                _SelectionActionButton(
                  tooltip: context.tr('Xóa'),
                  icon: Icons.delete_outline_rounded,
                  onPressed: onDelete,
                  isDanger: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.isDanger = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final background = isDanger
        ? const Color(0xFFFFECEF)
        : isActive
            ? const Color(0xFFDDF3FF)
            : const Color(0xFFF0F8FF);
    final foreground = isDanger ? AppTheme.danger : AppTheme.primaryDark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, color: foreground, size: 21),
          ),
        ),
      ),
    );
  }
}
