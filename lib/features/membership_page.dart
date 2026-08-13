import 'package:flutter/material.dart';

import '../app/app_store.dart';
// import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';
import '../models/commerce_models.dart';
import '../models/models.dart';
import 'partner_properties_page.dart';
import 'wallet_page.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

enum _OrderType { plan, posting, addon }

class _SelectedOrder {
  const _SelectedOrder({
    required this.type,
    required this.code,
    required this.name,
    required this.price,
    this.description = '',
  });

  final _OrderType type;
  final String code;
  final String name;
  final double price;
  final String description;
}

class _MembershipPageState extends State<MembershipPage> {
  final GlobalKey _memberPlansKey = GlobalKey();
  final GlobalKey _postingPackagesKey = GlobalKey();
  final GlobalKey _addonServicesKey = GlobalKey();
  final ScrollController _planScrollController = ScrollController();

  _SelectedOrder? _selectedOrder;
  int _activeTab = 0;
  bool _orderExpanded = false;
  bool _processing = false;
  String _paymentMethod = 'wallet';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = AppScope.of(context);
      if (store.isLoggedIn) {
        store.refreshMembership(force: true);
      }
    });
  }

  @override
  void dispose() {
    _planScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Gói hội viên'))),
        body: PageContainer(
          maxWidth: 760,
          child: EmptyState(
            icon: Icons.lock_outline,
            title: context.tr('Vui lòng đăng nhập'),
            message: context.tr(
              'Đăng nhập để xem gói hiện tại, hạn mức và mua gói hội viên.',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.tr('Nâng cấp & thanh toán')),
        actions: [
          IconButton(
            tooltip: context.tr('Ví NhaWOW'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const WalletPage()),
              );
              if (context.mounted) {
                await AppScope.of(context).refreshMembership(force: true);
              }
            },
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () => store.refreshMembership(force: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 118),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CompactUsagePanel(store: store),
                        const SizedBox(height: 10),
                        _MembershipTabs(
                          activeIndex: _activeTab,
                          onTap: _selectTab,
                        ),
                        const SizedBox(height: 10),
                        if (store.isLoadingMembership &&
                            store.membershipPlans.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 100),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (store.membershipPlans.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: EmptyState(
                              icon: Icons.workspace_premium_outlined,
                              title: context.tr('Không tải được gói hội viên'),
                              message: context.tr(
                                store.membershipError ??
                                    'Vui lòng kiểm tra kết nối và thử lại.',
                              ),
                              action: OutlinedButton.icon(
                                onPressed: () =>
                                    store.refreshMembership(force: true),
                                icon: const Icon(Icons.refresh),
                                label: Text(context.tr('Thử lại')),
                              ),
                            ),
                          )
                        else ...[
                          _buildMembershipSection(store),
                          const SizedBox(height: 14),
                          _buildPostingSection(store),
                          const SizedBox(height: 14),
                          _buildAddonSection(store),
                          const SizedBox(height: 12),
                          const _RulesSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _OrderSheet(
              order: _selectedOrder,
              store: store,
              expanded: _orderExpanded,
              paymentMethod: _paymentMethod,
              processing: _processing,
              onToggle: () => setState(() {
                _orderExpanded = !_orderExpanded;
              }),
              onPaymentMethodChanged: (value) {
                setState(() => _paymentMethod = value);
              },
              onCheckout: _selectedOrder == null || _processing
                  ? null
                  : () => _checkout(store),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipSection(AppStore store) {
    // Web hiển thị đủ 4 gói: Miễn phí, Cơ bản, Cao cấp, Tối thượng.
    // Không lọc price == 0 để mobile luôn đồng bộ đúng danh sách từ backend.
    final plans = store.membershipPlans.toList(growable: false);

    return Container(
      key: _memberPlansKey,
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Giữ kích thước card như mobile web: trên màn hình nhỏ sẽ thấy
          // khoảng 3 card và có thể kéo ngang để xem card thứ 4.
          final width = ((constraints.maxWidth - 30) / 3).clamp(124.0, 145.0);
          return Column(
            children: [
              SizedBox(
                height: 322,
                child: ListView.separated(
                  controller: _planScrollController,
                  padding: const EdgeInsets.fromLTRB(2, 7, 2, 8),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final active = store.membershipCode.toLowerCase() ==
                        plan.code.toLowerCase();
                    final selected = _selectedOrder?.type == _OrderType.plan &&
                        _selectedOrder?.code.toLowerCase() ==
                            plan.code.toLowerCase();
                    final canPurchase = plan.price > 0 && !active;

                    return SizedBox(
                      width: width,
                      child: _MobilePlanCard(
                        plan: plan,
                        active: active,
                        selected: selected,
                        onSelect: canPurchase
                            ? () => _selectOrder(
                                  _SelectedOrder(
                                    type: _OrderType.plan,
                                    code: plan.code,
                                    name:
                                        '${context.tr('Gói')} ${context.tr(plan.name)} (1 ${context.tr('tháng')})',
                                    price: plan.price,
                                  ),
                                )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 3),
              _PlanScrollIndicator(controller: _planScrollController),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostingSection(AppStore store) {
    final singles = store.postingPackages
        .where((item) => !item.isCombo)
        .toList(growable: false);
    final combos = store.postingPackages
        .where((item) => item.isCombo)
        .toList(growable: false);

    return Container(
      key: _postingPackagesKey,
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 12),
      decoration: _sectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            icon: Icons.sell_outlined,
            title: context.tr('Đăng Tin Lẻ & Combo'),
            subtitle: context.tr(
              'Dành cho người dùng thỉnh thoảng mới đăng bài.',
            ),
          ),
          const SizedBox(height: 10),
          ...singles.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _PostingSingleRow(
                item: item,
                selected: _isOrderSelected(_OrderType.posting, item.code),
                onSelect: () => _selectOrder(
                  _SelectedOrder(
                    type: _OrderType.posting,
                    code: item.code,
                    name: context.tr(item.name),
                    price: item.price,
                  ),
                ),
              ),
            ),
          ),
          if (combos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAF0),
                border: Border.all(color: const Color(0xFFFFC96B)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '🔥 ${context.tr('Combo Phổ Biến (Tiết kiệm hơn)')}',
                    style: const TextStyle(
                      color: Color(0xFFE56800),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...combos.asMap().entries.map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key == combos.length - 1 ? 0 : 7,
                          ),
                          child: _PostingComboRow(
                            item: entry.value,
                            number: entry.key + 1,
                            selected: _isOrderSelected(
                              _OrderType.posting,
                              entry.value.code,
                            ),
                            onSelect: () => _selectOrder(
                              _SelectedOrder(
                                type: _OrderType.posting,
                                code: entry.value.code,
                                name: context.tr(entry.value.name),
                                price: entry.value.price,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddonSection(AppStore store) {
    return Container(
      key: _addonServicesKey,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            icon: Icons.rocket_launch_outlined,
            title: context.tr('Dịch vụ gia tăng'),
            subtitle: context.tr(
              'Mua rời khi cần tăng hiệu quả hiển thị.',
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: store.addonFeatures
                    .map(
                      (feature) => SizedBox(
                        width: itemWidth,
                        child: _AddonCard(
                          feature: feature,
                          selected: _isOrderSelected(
                            _OrderType.addon,
                            feature.code,
                          ),
                          onSelect: () => _selectOrder(
                            _SelectedOrder(
                              type: _OrderType.addon,
                              code: feature.code,
                              name: context.tr(feature.name),
                              price: feature.price,
                              description: context.tr(feature.description),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isOrderSelected(_OrderType type, String code) {
    return _selectedOrder?.type == type &&
        _selectedOrder?.code.toLowerCase() == code.toLowerCase();
  }

  void _selectOrder(_SelectedOrder order) {
    setState(() {
      _selectedOrder = order;
      _paymentMethod = 'wallet';
      _orderExpanded = true;
    });
  }

  Future<void> _selectTab(int index) async {
    setState(() => _activeTab = index);
    final key = switch (index) {
      0 => _memberPlansKey,
      1 => _postingPackagesKey,
      _ => _addonServicesKey,
    };
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 330),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  Future<void> _checkout(AppStore store) async {
    final order = _selectedOrder;
    if (order == null || _processing) return;

    if (_paymentMethod != 'wallet') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const WalletPage()),
      );
      if (mounted) await store.refreshMembership(force: true);
      return;
    }

    setState(() => _processing = true);
    try {
      switch (order.type) {
        case _OrderType.plan:
          await _buyPlan(store, order);
          break;
        case _OrderType.posting:
          await _openPostingFlow(order);
          break;
        case _OrderType.addon:
          await _buyAddon(store, order);
          break;
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _buyPlan(AppStore store, _SelectedOrder order) async {
    try {
      final message = await store.buyMembership(order.code);
      if (!mounted) return;
      _showSuccess(
        message.trim().isEmpty
            ? context.tr('Mua gói hội viên thành công.')
            : message,
      );
      setState(() {
        _selectedOrder = null;
        _orderExpanded = false;
      });
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      if (error.code == 'INSUFFICIENT_WALLET_BALANCE') {
        await _showInsufficientBalance(error.message);
      } else {
        _showError(error.message);
      }
    } catch (error) {
      if (mounted) _showError(error.toString());
    }
  }

  Future<void> _openPostingFlow(_SelectedOrder order) async {
    final allowed = await AuthGate.ensurePostingPermission(context);
    if (!allowed || !mounted) return;

    setState(() => _orderExpanded = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerPropertiesPage(
          initialPostingPackageCode: order.code,
          initialPostingPackageName: order.name,
          autoStartCreate: true,
        ),
      ),
    );

    if (!mounted) return;
    final store = AppScope.of(context);
    await Future.wait<void>([
      store.refreshMembership(force: true),
      store.refreshWallet(force: true),
      store.refreshNotifications(force: true),
    ]);
  }

  Future<void> _buyAddon(AppStore store, _SelectedOrder order) async {
    final allowed = await AuthGate.ensurePostingPermission(context);
    if (!allowed || !mounted) return;

    setState(() => _orderExpanded = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerPropertiesPage(
          selectedAddonFeatureCode: order.code,
          selectedAddonFeatureName: order.name,
          selectedAddonFeatureDescription: order.description,
          selectedAddonFeaturePrice: order.price,
        ),
      ),
    );

    if (!mounted) return;
    await Future.wait<void>([
      store.refreshMembership(force: true),
      store.refreshWallet(force: true),
      store.refreshNotifications(force: true),
    ]);
  }

  Future<void> _showInsufficientBalance(String message) async {
    final openWallet = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Số dư ví không đủ')),
        content: Text(context.tr(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Đóng')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('Nạp ví')),
          ),
        ],
      ),
    );
    if (openWallet == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const WalletPage()),
      );
      if (mounted) {
        await AppScope.of(context).refreshMembership(force: true);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(message)),
        backgroundColor: const Color(0xFF10983F),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}

class _CompactUsagePanel extends StatelessWidget {
  const _CompactUsagePanel({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final usage = store.membershipUsage;
    final planName = usage.currentPlanName.trim().isEmpty
        ? store.membershipCode
        : usage.currentPlanName;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _sectionDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: width,
                child: _UsageMiniCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF10983F),
                  iconBackground: const Color(0xFFEAF8EF),
                  label: context.tr('Ví hiện có'),
                  value: context.tr(
                    '{amount} đ',
                    {'amount': _formatMoney(store.walletBalance)},
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: _UsageMiniCard(
                  icon: Icons.star,
                  iconColor: const Color(0xFF2F80ED),
                  iconBackground: const Color(0xFFEAF1FF),
                  label: context.tr('Gói hiện tại'),
                  value: context.tr(planName),
                ),
              ),
              SizedBox(
                width: width,
                child: _UsageMiniCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: const Color(0xFFEA7C00),
                  iconBackground: const Color(0xFFFFF3DD),
                  label: context.tr('Còn hôm nay'),
                  value: '${usage.dailyRemaining} / ${usage.dailyLimit}',
                ),
              ),
              SizedBox(
                width: width,
                child: _UsageMiniCard(
                  icon: Icons.calendar_month_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  iconBackground: const Color(0xFFF3E9FF),
                  label: context.tr('Còn tháng'),
                  value: '${usage.monthlyRemaining} / ${usage.monthlyLimit}',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UsageMiniCard extends StatelessWidget {
  const _UsageMiniCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipTabs extends StatelessWidget {
  const _MembershipTabs({required this.activeIndex, required this.onTap});

  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.star, context.tr('Gói Hội Viên')),
      (Icons.sell_outlined, context.tr('Đăng Tin Lẻ & Combo')),
      (Icons.rocket_launch, context.tr('Dịch Vụ Gia Tăng')),
    ];

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: List.generate(items.length, (index) {
          final active = index == activeIndex;
          final item = items[index];
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Container(
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFF4FFF7) : Colors.white,
                  border: Border(
                    right: index < items.length - 1
                        ? const BorderSide(color: Color(0xFFE5E7EB))
                        : BorderSide.none,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$1,
                      size: 14,
                      color: active
                          ? const Color(0xFF10983F)
                          : const Color(0xFF334155),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? const Color(0xFF087B30)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PlanScrollIndicator extends StatelessWidget {
  const _PlanScrollIndicator({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final trackWidth = constraints.maxWidth;
              var progress = 0.0;
              var thumbFraction = 0.42;

              if (controller.hasClients) {
                final position = controller.position;
                final maxScroll = position.maxScrollExtent;
                final viewport = position.viewportDimension;
                final contentWidth = viewport + maxScroll;

                if (maxScroll > 0) {
                  progress = (position.pixels / maxScroll).clamp(0.0, 1.0);
                }
                if (contentWidth > 0) {
                  thumbFraction =
                      (viewport / contentWidth).clamp(0.26, 1.0).toDouble();
                }
              }

              final thumbWidth = trackWidth * thumbFraction;
              final left = (trackWidth - thumbWidth) * progress;

              return Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E7EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: thumbWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4F),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MobilePlanCard extends StatelessWidget {
  const _MobilePlanCard({
    required this.plan,
    required this.active,
    required this.selected,
    required this.onSelect,
  });

  final MembershipPlanModel plan;
  final bool active;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final code = plan.code.toLowerCase();
    final icon = code == 'free'
        ? Icons.badge_outlined
        : code == 'basic'
            ? Icons.military_tech
            : code == 'advanced'
                ? Icons.emoji_events
                : Icons.workspace_premium;
    final iconColor = code == 'top'
        ? const Color(0xFFE32636)
        : code == 'advanced'
            ? const Color(0xFFD9A20B)
            : const Color(0xFF94A3B8);
    final currentColor = code == 'free'
        ? const Color(0xFF8B96A3)
        : const Color(0xFF10983F);
    final support = plan.hasDedicatedSupport
        ? context.tr('1-kèm-1, Duyệt siêu tốc')
        : plan.hasPrioritySupport
            ? context.tr('Ưu tiên hỗ trợ')
            : context.tr('Cơ bản');
    final gift = plan.freeTopLimit <= 0
        ? context.tr('Không có')
        : '🎁 ${plan.freeTopLimit} ${context.tr('tin Ghim 7 ngày')}';
    final display = plan.label.trim().isEmpty
        ? context.tr('Sắp xếp thường')
        : '${context.tr('Ưu tiên + Nhãn')} [${context.tr(plan.label)}]';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: active
              ? (code == 'free'
                  ? const Color(0xFFF3F5F7)
                  : const Color(0xFFF3FFF6))
              : selected
                  ? const Color(0xFFF6F9FF)
                  : Colors.white,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.fromLTRB(7, 15, 7, 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: active
                      ? currentColor
                      : selected
                          ? const Color(0xFF2F80ED)
                          : const Color(0xFFF59E0B),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 20, color: iconColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${context.tr('Gói')} ${context.tr(plan.name)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: code == 'top'
                                ? const Color(0xFFE32636)
                                : code == 'advanced'
                                    ? const Color(0xFF9A6200)
                                    : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.price <= 0
                            ? context.tr('{amount} đ', {'amount': '0'})
                            : _formatMoneyK(plan.price),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '/ ${context.tr('tháng')}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (plan.price > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8EF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${context.tr('Chỉ từ')} ${_unitPrice(context, plan.price, plan.monthlyPostLimit)}',
                          style: const TextStyle(
                            color: Color(0xFF087B30),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                  const Divider(height: 18),
                  _PlanLine('${plan.dailyPostLimit} ${context.tr('tin/ngày')}'),
                  _PlanLine('${plan.monthlyPostLimit} ${context.tr('tin/tháng')}'),
                  _PlanLine(display),
                  _PlanLine(gift),
                  _PlanLine(support),
                  const Spacer(),
                  SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: onSelect,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        backgroundColor:
                            active ? currentColor : const Color(0xFFFF7200),
                        disabledBackgroundColor: active
                            ? currentColor
                            : const Color(0xFFB8C0C9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        active
                            ? context.tr('Đang sử dụng')
                            : plan.price <= 0
                                ? context.tr('Gói miễn phí')
                                : context.tr('Nâng cấp ngay'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (plan.isRecommended)
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10983F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.tr('Khuyên dùng'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        if (active)
          Positioned(
            top: 5,
            right: 5,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: currentColor,
              child: const Icon(Icons.check, color: Colors.white, size: 13),
            ),
          ),
        if (selected && !active)
          const Positioned(
            top: 5,
            right: 5,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Color(0xFF2F80ED),
              child: Icon(Icons.check, color: Colors.white, size: 13),
            ),
          ),
      ],
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 8.7,
          height: 1.22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1E293B), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostingSingleRow extends StatelessWidget {
  const _PostingSingleRow({
    required this.item,
    required this.selected,
    required this.onSelect,
  });

  final PostingPackageModel item;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF6F9FF) : Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF2F80ED) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Text(item.icon.isEmpty ? '🏷️' : item.icon,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr(item.name)}: ${_formatMoneyK(item.price)} / ${context.tr('tin')}',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(item.description),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            height: 34,
            child: OutlinedButton.icon(
              onPressed: onSelect,
              icon: Icon(selected ? Icons.check : Icons.shopping_cart, size: 13),
              label: Text(selected ? context.tr('Đã chọn') : context.tr('Mua')),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF2F80ED)
                      : const Color(0xFFFF7200),
                ),
                foregroundColor: selected
                    ? const Color(0xFF2F80ED)
                    : const Color(0xFFFF7200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostingComboRow extends StatelessWidget {
  const _PostingComboRow({
    required this.item,
    required this.number,
    required this.selected,
    required this.onSelect,
  });

  final PostingPackageModel item;
  final int number;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF6F9FF) : Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF2F80ED) : const Color(0xFFFFC96B),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFB126),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '${context.tr(item.name)} = ${_formatMoneyK(item.price)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 96,
            height: 31,
            child: OutlinedButton.icon(
              onPressed: onSelect,
              icon: Icon(selected ? Icons.check : Icons.shopping_cart, size: 12),
              label: Text(selected ? context.tr('Đã chọn') : context.tr('Mua')),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF2F80ED)
                      : const Color(0xFFFF7200),
                ),
                foregroundColor: selected
                    ? const Color(0xFF2F80ED)
                    : const Color(0xFFFF7200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                textStyle: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddonCard extends StatelessWidget {
  const _AddonCard({
    required this.feature,
    required this.selected,
    required this.onSelect,
  });

  final AddonFeatureModel feature;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = _addonAccent(feature.code);
    return Container(
      constraints: const BoxConstraints(minHeight: 152),
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 10),
      decoration: BoxDecoration(
        color: accent.$2,
        border: Border.all(
          color: selected ? const Color(0xFF2F80ED) : accent.$1.withValues(alpha: 0.35),
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            feature.icon.isEmpty ? '✨' : feature.icon,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 5),
          Text(
            context.tr(feature.name),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _formatMoneyK(feature.price),
                  style: TextStyle(
                    color: accent.$1,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: '/${context.tr('lượt')}',
                  style: TextStyle(
                    color: accent.$1,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: FilledButton.icon(
              onPressed: onSelect,
              icon: Icon(selected ? Icons.check : Icons.shopping_cart, size: 13),
              label: Text(
                selected ? context.tr('Đã chọn') : context.tr('Chọn mua'),
              ),
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                backgroundColor:
                    selected ? const Color(0xFF2F80ED) : accent.$1,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️ ${context.tr('Lưu ý quan trọng:')}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 5),
          _RuleLine(
            context.tr(
              'Hạn mức theo ngày/tháng sẽ tự động làm mới, không cộng dồn hay chuyển sang tháng sau.',
            ),
          ),
          _RuleLine(
            context.tr(
              'Quà tặng kèm Ghim tin chỉ có giá trị trong tháng, không được chuyển nhượng hoặc quy đổi thành tiền mặt.',
            ),
          ),
          const Divider(height: 16),
          Text(
            '🚫 ${context.tr('Quy định nền tảng (Cấm vi phạm):')}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7F1D1D),
            ),
          ),
          const SizedBox(height: 5),
          _RuleLine(
            context.tr(
              'NhaWOW yêu cầu tài khoản chính chủ; nghiêm cấm tin giả, tin trùng lặp hoặc hình ảnh sao chép.',
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 4, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSheet extends StatelessWidget {
  const _OrderSheet({
    required this.order,
    required this.store,
    required this.expanded,
    required this.paymentMethod,
    required this.processing,
    required this.onToggle,
    required this.onPaymentMethodChanged,
    required this.onCheckout,
  });

  final _SelectedOrder? order;
  final AppStore store;
  final bool expanded;
  final String paymentMethod;
  final bool processing;
  final VoidCallback onToggle;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    final name = order?.name ?? context.tr('Chưa chọn gói');
    final total = context.tr(
      '{amount} đ',
      {'amount': order == null ? '0' : _formatMoney(order!.price)},
    );

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: expanded ? 430 : 96,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.fromLTRB(12, expanded ? 7 : 7, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDBE5DE)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F172A),
              blurRadius: 32,
              offset: Offset(0, -9),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 64,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DAE1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: onToggle,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_cart,
                              size: 18,
                              color: Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              context.tr('Đơn hàng của bạn'),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF10983F),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.tr('Tổng thanh toán'),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        total,
                        style: const TextStyle(
                          color: Color(0xFF10983F),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: const Color(0xFF0F172A),
                  ),
                ],
              ),
            ),
            if (expanded) ...[
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3FFF6),
                          border: Border.all(color: const Color(0xFFCCEBD6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('Gói đã chọn:'),
                                    style: const TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Color(0xFF087B30),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              total,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        context.tr('Phương thức thanh toán:'),
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _PaymentMethodRow(
                        selected: paymentMethod == 'wallet',
                        icon: Icons.account_balance_wallet,
                        title: context.tr('Ví NhaWOW'),
                        subtitle:
                            '${context.tr('Trừ trực tiếp từ số dư ví')} · ${context.tr('{amount} đ', {'amount': _formatMoney(store.walletBalance)})}',
                        onTap: () => onPaymentMethodChanged('wallet'),
                      ),
                      const SizedBox(height: 7),
                      _PaymentMethodRow(
                        selected: paymentMethod == 'payos',
                        icon: Icons.qr_code_2,
                        title: context.tr('Chuyển khoản VietQR'),
                        subtitle: context.tr('Dùng để nạp ví trước'),
                        onTap: () => onPaymentMethodChanged('payos'),
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        height: 49,
                        child: FilledButton.icon(
                          onPressed: onCheckout,
                          icon: processing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(_checkoutIcon(order, paymentMethod)),
                          label: Text(
                            processing
                                ? context.tr('ĐANG XỬ LÝ...')
                                : _checkoutLabel(context, order, paymentMethod),
                            textAlign: TextAlign.center,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10983F),
                            disabledBackgroundColor: const Color(0xFFB9C5BD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: Color(0xFF10983F),
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              context.tr(
                                'Thanh toán an toàn. Nếu chọn VietQR, hệ thống sẽ mở Ví NhaWOW để nạp tiền trước.',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _checkoutLabel(
    BuildContext context,
    _SelectedOrder? order,
    String paymentMethod,
  ) {
    if (paymentMethod != 'wallet') {
      return context.tr('ĐI NẠP VÍ TRƯỚC');
    }
    switch (order?.type) {
      case _OrderType.posting:
        return context.tr('CHỌN GÓI VÀ TẠO BÀI ĐĂNG');
      case _OrderType.addon:
        return context.tr('CHỌN BÀI ĐĂNG ĐỂ MUA');
      case _OrderType.plan:
      case null:
        return context.tr('THANH TOÁN BẰNG VÍ NHAWOW');
    }
  }

  static IconData _checkoutIcon(
    _SelectedOrder? order,
    String paymentMethod,
  ) {
    if (paymentMethod != 'wallet') return Icons.account_balance_wallet;
    switch (order?.type) {
      case _OrderType.posting:
        return Icons.edit_note;
      case _OrderType.addon:
        return Icons.home_work_outlined;
      case _OrderType.plan:
      case null:
        return Icons.lock_outline;
    }
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFF10983F)
                  : const Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? const Color(0xFF10983F)
                    : const Color(0xFF94A3B8),
                size: 22,
              ),
              Icon(icon, color: const Color(0xFF334155), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



BoxDecoration _sectionDecoration() {
  return BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFE5E7EB)),
    borderRadius: BorderRadius.circular(13),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0D0F172A),
        blurRadius: 14,
        offset: Offset(0, 4),
      ),
    ],
  );
}

(Color, Color) _addonAccent(String rawCode) {
  switch (rawCode.trim().toLowerCase()) {
    case 'top7':
      return (const Color(0xFFEF2B2D), const Color(0xFFFFF7F7));
    case 'refresh':
      return (const Color(0xFF2F80ED), const Color(0xFFF6FAFF));
    case 'urgent_review':
      return (const Color(0xFFFF8A00), const Color(0xFFFFFAF0));
    case 'certified7':
      return (const Color(0xFF0EA54B), const Color(0xFFF5FFF8));
    default:
      return (const Color(0xFF64748B), const Color(0xFFF8FAFC));
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

String _formatMoneyK(double value) {
  if (value <= 0) return '0k';
  final number = value / 1000;
  if (number == number.roundToDouble()) return '${number.round()}k';
  return '${number.toStringAsFixed(1).replaceAll('.', ',')}k';
}

String _unitPrice(BuildContext context, double price, int quota) {
  if (price <= 0 || quota <= 0) return '-';
  final number = (price / quota) / 1000;
  final text = number == number.roundToDouble()
      ? number.round().toString()
      : number.toStringAsFixed(1).replaceAll('.', ',');
  return '${text}k/${context.tr('tin')}';
}
