import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_store.dart';
import '../core/app_image.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'property_detail_page.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({required this.conversationId, super.key});

  final int conversationId;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  static const int _maxImageBytes = 5 * 1024 * 1024;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final Set<int> _recallingMessageIds = <int>{};

  bool _requested = false;
  bool _isSending = false;
  bool _isUploadingImage = false;
  bool _isLoading = false;
  Timer? _syncTimer;

  bool get _isBusy => _isSending || _isUploadingImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMessages();
      _syncTimer ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) => _syncMessagesSilently(),
      );
    });
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final store = AppScope.of(context);
    try {
      await store.loadConversationMessages(widget.conversationId);
      await store.markConversationRead(widget.conversationId);
      _scrollToBottom(jump: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(store.chatError ?? 'Không thể tải hội thoại.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncMessagesSilently() async {
    if (!mounted || _isLoading || _isBusy || _recallingMessageIds.isNotEmpty) {
      return;
    }
    final store = AppScope.of(context);
    if (!store.isLoggedIn) return;
    try {
      await store.loadConversationMessages(widget.conversationId);
      _scrollToBottom();
    } catch (_) {
      // Lỗi mạng tạm thời sẽ được thử lại ở chu kỳ sau.
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    ConversationModel? conversation;
    for (final item in store.conversations) {
      if (item.id == widget.conversationId) {
        conversation = item;
        break;
      }
    }

    if (conversation == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : Text(context.tr('Không tìm thấy hội thoại')),
        ),
      );
    }

    final current = conversation;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              url: current.avatarUrl,
              fallbackText: current.title,
              radius: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(current.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (current.subtitle.trim().isNotEmpty)
                    Text(
                      context.tr(current.subtitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.blueGrey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: current.isPinned
                ? context.tr('Bỏ ghim')
                : context.tr('Ghim'),
            onPressed: () => _togglePin(store, current),
            icon: Icon(
              current.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
          ),
          IconButton(
            tooltip: context.tr('Đánh dấu'),
            onPressed: () => _toggleFlag(store, current),
            icon: Icon(
              current.isFlagged ? Icons.flag : Icons.flag_outlined,
              color: current.isFlagged ? Colors.amber : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (current.propertyId != null)
            Material(
              color: const Color(0xFFEAF7FF),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: AppNetworkImage(
                    url: current.propertyCover,
                    width: 54,
                    height: 46,
                    fit: BoxFit.cover,
                    fallback: const ColoredBox(
                      color: Color(0xFFDCEFF9),
                      child: SizedBox(
                        width: 54,
                        height: 46,
                        child: Icon(
                          Icons.home_work_outlined,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  context.tr(
                    current.propertyTitle.isNotEmpty
                        ? current.propertyTitle
                        : current.subtitle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: current.propertyAddress.isEmpty
                    ? null
                    : Text(
                        current.propertyAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PropertyDetailPage(
                        propertyId: current.propertyId!,
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                itemCount: current.messages.length,
                itemBuilder: (context, index) {
                  final message = current.messages[index];
                  return _MessageBubble(
                    message: message,
                    fallbackAvatarUrl: current.avatarUrl,
                    recalling: _recallingMessageIds.contains(message.id),
                    onRecall: message.isMine &&
                            !message.isSystem &&
                            !message.isRecalled
                        ? () => _confirmRecall(store, message)
                        : null,
                    onImageTap: message.isImage && !message.isRecalled
                        ? () => _showImagePreview(message)
                        : null,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5EAF0)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: context.tr('Gửi ảnh'),
                      onPressed: _isBusy ? null : () => _pickAndSendImage(store),
                      icon: _isUploadingImage
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        enabled: !_isBusy,
                        decoration: InputDecoration(
                          hintText: context.tr('Nhập tin nhắn...'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                        onSubmitted: (_) => _send(store),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isBusy ? null : () => _send(store),
                      icon: _isSending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(AppStore store) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isBusy) return;
    setState(() => _isSending = true);
    try {
      final sent = await store.sendMessage(widget.conversationId, text);
      if (sent) {
        _controller.clear();
        _scrollToBottom();
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage(AppStore store) async {
    if (_isBusy) return;
    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1920,
      );
    } catch (error) {
      _showError(error);
      return;
    }
    if (picked == null || !mounted) return;

    try {
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Không thể đọc ảnh đã chọn.');
      }
      if (bytes.length > _maxImageBytes) {
        throw Exception('Ảnh không được vượt quá 5MB.');
      }

      final fileName = _normalizedImageName(picked.name, picked.mimeType);
      final contentType = _imageContentType(fileName, picked.mimeType);
      setState(() => _isUploadingImage = true);
      final sent = await store.sendImageMessage(
        conversationId: widget.conversationId,
        fileName: fileName,
        bytes: bytes,
        contentType: contentType,
      );
      if (sent) _scrollToBottom();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _confirmRecall(
    AppStore store,
    ChatMessageModel message,
  ) async {
    if (_recallingMessageIds.contains(message.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Thu hồi tin nhắn')),
        content: Text(
          context.tr('Bạn có chắc muốn thu hồi tin nhắn này?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Hủy')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.undo_rounded),
            label: Text(context.tr('Thu hồi')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _recallingMessageIds.add(message.id));
    try {
      await store.recallMessage(widget.conversationId, message.id);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _recallingMessageIds.remove(message.id));
      }
    }
  }

  void _showImagePreview(ChatMessageModel message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: AppNetworkImage(
                url: message.imageUrl,
                fit: BoxFit.contain,
                fallback: const SizedBox(
                  height: 320,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(
    AppStore store,
    ConversationModel conversation,
  ) async {
    try {
      await store.toggleConversationPin(conversation.id);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _toggleFlag(
    AppStore store,
    ConversationModel conversation,
  ) async {
    try {
      await store.toggleConversationFlag(conversation.id);
    } catch (error) {
      _showError(error);
    }
  }

  String _normalizedImageName(String rawName, String? mimeType) {
    var name = rawName.trim();
    if (name.isEmpty) name = 'chat_image';
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (!RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false)
        .hasMatch(name)) {
      final mime = (mimeType ?? '').toLowerCase();
      final extension = mime.contains('png')
          ? '.png'
          : mime.contains('gif')
              ? '.gif'
              : mime.contains('webp')
                  ? '.webp'
                  : '.jpg';
      name += extension;
    }
    return name.length <= 120 ? name : name.substring(name.length - 120);
  }

  String _imageContentType(String fileName, String? mimeType) {
    final supplied = (mimeType ?? '').trim().toLowerCase();
    if (supplied.startsWith('image/')) return supplied;
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _showError(Object error) {
    if (!mounted) return;
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(text.isEmpty ? 'Không thể thực hiện thao tác.' : text),
        ),
      ),
    );
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(offset);
      } else {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.fallbackAvatarUrl,
    required this.recalling,
    this.onRecall,
    this.onImageTap,
  });

  final ChatMessageModel message;
  final String fallbackAvatarUrl;
  final bool recalling;
  final VoidCallback? onRecall;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final timeText = _formatMessageTime(context, message.sentAt);
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD88B)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Text(
                  context.tr(message.displayText),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFA35A00),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
          ],
        ),
      );
    }

    final canRecall = onRecall != null;
    final avatarUrl = message.senderAvatarUrl.trim().isNotEmpty
        ? message.senderAvatarUrl
        : fallbackAvatarUrl;

    final bubble = GestureDetector(
      onLongPress: canRecall ? onRecall : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.70,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMine ? const Color(0xFFC8F0FF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMine ? 16 : 4),
            bottomRight: Radius.circular(message.isMine ? 4 : 16),
          ),
          border: Border.all(
            color: message.isMine
                ? const Color(0xFFB5E5F7)
                : const Color(0xFFE1E7EE),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMine && message.senderName.trim().isNotEmpty) ...[
              Text(
                message.senderName,
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
            ],
            if (message.isRecalled)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.undo_rounded,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      context.tr('Tin nhắn đã được thu hồi'),
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              )
            else if (message.isImage) ...[
              InkWell(
                onTap: onImageTap,
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppNetworkImage(
                    url: message.imageUrl,
                    width: 230,
                    height: 165,
                    fit: BoxFit.cover,
                    fallback: const SizedBox(
                      width: 230,
                      height: 165,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              if (message.imageName.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  message.imageName.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ] else
              Text(
                context.tr(message.displayText),
                style: const TextStyle(color: AppTheme.navy),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMine) ...[
            AppAvatar(
              url: avatarUrl,
              fallbackText: message.senderName,
              radius: 16,
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                bubble,
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey,
                      ),
                    ),
                    if (canRecall) ...[
                      const SizedBox(width: 4),
                      SizedBox.square(
                        dimension: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: context.tr('Thu hồi'),
                          onPressed: recalling ? null : onRecall,
                          icon: recalling
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.undo_rounded, size: 17),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: true,
    );
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return time;
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    if (local.year == now.year) return '$day/$month $time';
    return '$day/$month/${local.year} $time';
  }
}
