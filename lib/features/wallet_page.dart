import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';
import '../models/commerce_models.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _creatingTopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = AppScope.of(context);
      if (store.isLoggedIn) store.refreshWallet(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Ví NhaWOW'))),
        body: PageContainer(
          maxWidth: 760,
          child: EmptyState(
            icon: Icons.lock_outline,
            title: context.tr('Vui lòng đăng nhập'),
            message: context.tr(
              'Đăng nhập để xem số dư, lịch sử giao dịch và nạp ví.',
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
      appBar: AppBar(title: Text(context.tr('Ví NhaWOW'))),
      body: RefreshIndicator(
        onRefresh: () => store.refreshWallet(force: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BalanceCard(
                  balance: store.walletBalance,
                  loading: _creatingTopup,
                  onTopup: () => _showTopup(context, store),
                ),
                const SizedBox(height: 24),
                if (store.walletTopups.isNotEmpty) ...[
                  SectionHeader(title: context.tr('Đơn nạp gần đây')),
                  const SizedBox(height: 12),
                  ...store.walletTopups.take(5).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TopupHistoryTile(
                            topup: item,
                            onTap: item.isPending
                                ? () => _reopenPendingTopup(context, store, item)
                                : null,
                          ),
                        ),
                      ),
                  const SizedBox(height: 14),
                ],
                SectionHeader(title: context.tr('Lịch sử giao dịch')),
                const SizedBox(height: 12),
                if (store.isLoadingWallet && store.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 70),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (store.transactions.isEmpty)
                  EmptyState(
                    icon: store.walletError == null
                        ? Icons.receipt_long_outlined
                        : Icons.cloud_off_outlined,
                    title: context.tr(
                      store.walletError == null
                          ? 'Chưa có giao dịch'
                          : 'Không tải được ví NhaWOW',
                    ),
                    message: context.tr(
                      store.walletError ??
                          'Các giao dịch nạp và chi tiêu sẽ hiển thị tại đây.',
                    ),
                    action: store.walletError == null
                        ? null
                        : OutlinedButton.icon(
                            onPressed: () => store.refreshWallet(force: true),
                            icon: const Icon(Icons.refresh),
                            label: Text(context.tr('Thử lại')),
                          ),
                  )
                else
                  ...store.transactions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isCredit
                                ? const Color(0xFFEAF8EE)
                                : const Color(0xFFFFEEEE),
                            child: Icon(
                              item.isCredit
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              color: item.isCredit
                                  ? Colors.green
                                  : AppTheme.danger,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(_formatDateTime(item.createdAt)),
                          trailing: Text(
                            context.tr(
                              '{sign}{amount} đ',
                              {
                                'sign': item.isCredit ? '+' : '-',
                                'amount': _formatMoney(item.amount.abs()),
                              },
                            ),
                            style: TextStyle(
                              color: item.isCredit
                                  ? Colors.green
                                  : AppTheme.danger,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTopup(BuildContext context, AppStore store) async {
    if (store.walletAmountOptions.isEmpty) {
      await store.refreshWallet(force: true);
      if (!context.mounted) return;
    }

    final options = store.walletAmountOptions;
    if (options.isEmpty) {
      _showError(
        context,
        store.walletError ?? context.tr('Chưa tải được các mức nạp tiền.'),
      );
      return;
    }

    final amount = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('Chọn số tiền nạp'),
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options
                    .map(
                      (value) => ActionChip(
                        label: Text(
                          context.tr(
                            '{amount} đ',
                            {'amount': _formatMoney(value)},
                          ),
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(value),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr(
                  'Sau khi tạo đơn, ứng dụng dùng đúng cổng thanh toán đang cấu hình trên Web NhaWOW.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );

    if (amount == null || !mounted) return;
    setState(() => _creatingTopup = true);
    try {
      final checkout = await store.createWalletTopup(amount);
      if (!context.mounted) return;
      await _showCheckout(context, store, checkout);
    } on ApiTransportException catch (error) {
      if (context.mounted) _showError(context, error.message);
    } catch (error) {
      if (context.mounted) _showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _creatingTopup = false);
    }
  }

  Future<void> _reopenPendingTopup(
    BuildContext context,
    AppStore store,
    WalletTopupModel topup,
  ) async {
    final status = await store.checkWalletTopupStatus(topup.id);
    if (!context.mounted) return;
    if (status.paid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Giao dịch đã được thanh toán.'))),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            'Đơn nạp vẫn đang chờ thanh toán. Hãy tạo lại đơn nếu cần hiển thị QR.',
          ),
        ),
      ),
    );
  }

  Future<void> _showCheckout(
    BuildContext context,
    AppStore store,
    WalletTopupCheckoutModel checkout,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WalletCheckoutSheet(
        store: store,
        checkout: checkout,
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.loading,
    required this.onTopup,
  });

  final double balance;
  final bool loading;
  final VoidCallback onTopup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navy, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Số dư khả dụng'),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('{amount} đ', {'amount': _formatMoney(balance)}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: loading ? null : onTopup,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.navy,
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_2),
            label: Text(context.tr('Nạp tiền bằng QR')),
          ),
        ],
      ),
    );
  }
}

class _TopupHistoryTile extends StatelessWidget {
  const _TopupHistoryTile({required this.topup, this.onTap});

  final WalletTopupModel topup;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final paid = topup.isPaid;
    final pending = topup.isPending;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: paid
              ? const Color(0xFFEAF8EE)
              : pending
                  ? const Color(0xFFFFF4DE)
                  : const Color(0xFFF0F3F7),
          child: Icon(
            paid
                ? Icons.check_rounded
                : pending
                    ? Icons.schedule_rounded
                    : Icons.close_rounded,
            color: paid
                ? Colors.green
                : pending
                    ? Colors.orange.shade800
                    : Colors.blueGrey,
          ),
        ),
        title: Text(
          '${context.tr('{amount} đ', {'amount': _formatMoney(topup.amount)})} · ${topup.paymentProvider}',
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text('${topup.paymentCode} · ${_formatDateTime(topup.createdAt)}'),
        trailing: Text(
          _topupStatusText(context, topup.status),
          style: TextStyle(
            color: paid
                ? Colors.green
                : pending
                    ? Colors.orange.shade800
                    : Colors.blueGrey,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _WalletCheckoutSheet extends StatefulWidget {
  const _WalletCheckoutSheet({
    required this.store,
    required this.checkout,
  });

  final AppStore store;
  final WalletTopupCheckoutModel checkout;

  @override
  State<_WalletCheckoutSheet> createState() => _WalletCheckoutSheetState();
}

class _WalletCheckoutSheetState extends State<_WalletCheckoutSheet> {
  Timer? _timer;
  bool _checking = false;
  bool _paid = false;
  bool _cancelled = false;
  String _status = 'pending';
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.checkout.status;
    _paid = _status.toLowerCase() == 'paid';
    if (!_paid) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus());
      Future<void>.delayed(const Duration(milliseconds: 700), _checkStatus);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_checking || _paid || _cancelled || !mounted) return;
    _checking = true;
    try {
      final result = await widget.store.checkWalletTopupStatus(
        widget.checkout.topupId,
      );
      if (!mounted) return;
      setState(() {
        _status = result.status;
        _paid = result.paid;
        _cancelled = result.status.toLowerCase() == 'cancelled';
        _error = null;
      });
      if (_paid || _cancelled) _timer?.cancel();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _checking = false;
    }
  }

  Future<void> _cancel() async {
    if (_paid || _cancelled) return;
    try {
      final message = await widget.store.cancelWalletTopup(
        widget.checkout.topupId,
      );
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _cancelled = true;
        _status = 'cancelled';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(message))),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _openCheckout() async {
    final value = widget.checkout.checkoutUrl.trim();
    if (value.isEmpty) return;
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _error = context.tr('Không mở được trang thanh toán.'));
    }
  }

  Future<void> _openSePayForm() async {
    if (!widget.checkout.hasSePayForm) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SePayCheckoutPage(checkout: widget.checkout),
      ),
    );
    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final checkout = widget.checkout;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('Thanh toán nạp ví'),
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusBadge(status: _status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  '{amount} đ',
                  {'amount': _formatMoney(checkout.amount)},
                ),
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr('Mã thanh toán')}: ${checkout.paymentCode}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text('${context.tr('Cổng')}: ${checkout.paymentProvider}'),
              if (checkout.message.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    checkout.message,
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
              if (_paid) ...[
                const SizedBox(height: 18),
                _ResultBanner(
                  icon: Icons.check_circle,
                  title: context.tr('Nạp tiền thành công'),
                  message: context.tr(
                    'Số dư ví và lịch sử giao dịch đã được cập nhật từ Web NhaWOW.',
                  ),
                  success: true,
                ),
              ] else if (_cancelled) ...[
                const SizedBox(height: 18),
                _ResultBanner(
                  icon: Icons.cancel_outlined,
                  title: context.tr('Đơn nạp đã hủy'),
                  message: context.tr('Bạn có thể tạo một đơn nạp mới.'),
                  success: false,
                ),
              ] else ...[
                if (checkout.hasQr) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE7ECF2)),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: checkout.qrCode,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const AspectRatio(
                          aspectRatio: 1,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => const AspectRatio(
                          aspectRatio: 1,
                          child: Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                      ),
                    ),
                  ),
                ],
                if (checkout.bankName.trim().isNotEmpty ||
                    checkout.bankAccountNumber.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _PaymentInfoRow(
                    label: context.tr('Ngân hàng'),
                    value: checkout.bankName,
                  ),
                  _PaymentInfoRow(
                    label: context.tr('Số tài khoản'),
                    value: checkout.bankAccountNumber,
                  ),
                  if (checkout.bankAccountName.trim().isNotEmpty)
                    _PaymentInfoRow(
                      label: context.tr('Chủ tài khoản'),
                      value: checkout.bankAccountName,
                    ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    context.tr(
                      'Chuyển đúng số tiền và giữ nguyên nội dung/mã thanh toán để hệ thống tự cộng ví.',
                    ),
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
                if (!checkout.hasQr &&
                    !checkout.hasCheckout &&
                    !checkout.hasSePayForm) ...[
                  const SizedBox(height: 14),
                  _ResultBanner(
                    icon: Icons.info_outline,
                    title: context.tr('Chưa có kênh thanh toán khả dụng'),
                    message: checkout.message.trim().isNotEmpty
                        ? checkout.message
                        : context.tr(
                            'Backend đã tạo đơn nhưng cổng thanh toán chưa được cấu hình đầy đủ trên Web.config.',
                          ),
                    success: false,
                  ),
                ],
                if (checkout.hasCheckout) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _openCheckout,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(context.tr('Mở trang thanh toán')),
                  ),
                ],
                if (checkout.hasSePayForm) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _openSePayForm,
                    icon: const Icon(Icons.account_balance_outlined),
                    label: Text(context.tr('Thanh toán qua SePay')),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _checking ? null : _checkStatus,
                  icon: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(context.tr('Kiểm tra thanh toán')),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _cancel,
                  child: Text(context.tr('Hủy đơn nạp')),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ],
              if (_paid || _cancelled) ...[
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr('Đóng')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SePayCheckoutPage extends StatefulWidget {
  const _SePayCheckoutPage({required this.checkout});

  final WalletTopupCheckoutModel checkout;

  @override
  State<_SePayCheckoutPage> createState() => _SePayCheckoutPageState();
}

class _SePayCheckoutPageState extends State<_SePayCheckoutPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildAutoSubmitHtml(widget.checkout));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Thanh toán SePay'))),
      body: WebViewWidget(controller: _controller),
    );
  }

  static String _buildAutoSubmitHtml(WalletTopupCheckoutModel checkout) {
    const escape = HtmlEscape();
    final action = escape.convert(checkout.sePayCheckoutUrl);
    final fields = checkout.sePayFormFields
        .map(
          (field) => '<input type="hidden" name="${escape.convert(field.name)}" value="${escape.convert(field.value)}">',
        )
        .join();
    return '''<!doctype html>
<html><head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body><form id="sepay" method="post" action="$action">$fields</form>
<script>document.getElementById('sepay').submit();</script></body></html>''';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final value = status.toLowerCase();
    final paid = value == 'paid';
    final pending = value == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: paid
            ? const Color(0xFFEAF8EE)
            : pending
                ? const Color(0xFFFFF4DE)
                : const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _topupStatusText(context, status),
        style: TextStyle(
          color: paid
              ? Colors.green.shade800
              : pending
                  ? Colors.orange.shade900
                  : Colors.blueGrey,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  const _PaymentInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.success,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFEAF8EE) : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: success ? Colors.green : Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _topupStatusText(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return context.tr('Đã thanh toán');
    case 'pending':
      return context.tr('Đang chờ');
    case 'cancelled':
    case 'canceled':
      return context.tr('Đã hủy');
    case 'expired':
      return context.tr('Hết hạn');
    default:
      return status;
  }
}

String _formatMoney(double value) {
  final raw = value.round().toString();
  final chars = <String>[];
  for (var i = 0; i < raw.length; i++) {
    chars.add(raw[i]);
    final remaining = raw.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) chars.add('.');
  }
  return chars.join();
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}  ${two(local.day)}/${two(local.month)}/${local.year}';
}
