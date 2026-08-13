import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../models/partner_models.dart';
import 'property_form_page.dart';
import 'wallet_page.dart';

class PartnerPropertiesPage extends StatefulWidget {
  const PartnerPropertiesPage({
    this.initialPostingPackageCode = '',
    this.initialPostingPackageName = '',
    this.autoStartCreate = false,
    this.selectedAddonFeatureCode = '',
    this.selectedAddonFeatureName = '',
    this.selectedAddonFeatureDescription = '',
    this.selectedAddonFeaturePrice = 0.0,
    super.key,
  });

  final String initialPostingPackageCode;
  final String initialPostingPackageName;
  final bool autoStartCreate;
  final String selectedAddonFeatureCode;
  final String selectedAddonFeatureName;
  final String selectedAddonFeatureDescription;
  final double selectedAddonFeaturePrice;

  @override
  State<PartnerPropertiesPage> createState() => _PartnerPropertiesPageState();
}

class _PartnerPropertiesPageState extends State<PartnerPropertiesPage> {
  bool _initialized = false;
  bool _autoCreateStarted = false;
  int _cityId = 0;
  int _wardId = 0;
  String _status = 'all';

  bool get _isAddonSelectionMode =>
      widget.selectedAddonFeatureCode.trim().isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;
    final store = AppScope.of(context);
    if (!store.isLoggedIn || !store.isBroker) return;
    try {
      await Future.wait([
        store.loadPartnerFormLookups(),
        store.refreshPartnerProperties(
          featureCode: widget.selectedAddonFeatureCode,
        ),
      ]);
      if (mounted && widget.autoStartCreate && !_autoCreateStarted) {
        _autoCreateStarted = true;
        await _openCreateFlow(
          context,
          postingPackageCode: widget.initialPostingPackageCode,
          postingPackageName: widget.initialPostingPackageName,
        );
      }
    } catch (_) {
      // Lỗi được hiển thị bằng partnerPropertyError trong giao diện.
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn || !store.isBroker) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Tin đăng của tôi'))),
        body: PageContainer(
          maxWidth: 820,
          child: EmptyState(
            icon: Icons.lock_outline,
            title: context.tr('Cần quyền đăng tin'),
            message: context.tr(
              'Đăng nhập và mở quyền đối tác để quản lý tin đăng.',
            ),
            action: FilledButton(
              onPressed: () => AuthGate.ensurePostingPermission(context),
              child: Text(context.tr('Tiếp tục')),
            ),
          ),
        ),
      );
    }

    final items = store.partnerProperties;
    final lookups = store.partnerFormLookups;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(
            _isAddonSelectionMode ? 'Quản lý bài đăng' : 'Tin đăng của tôi',
          ),
        ),
        actions: _isAddonSelectionMode
            ? null
            : [
                IconButton(
                  tooltip: context.tr('Tạo tin mới'),
                  onPressed: store.isLoadingPartnerLookups
                      ? null
                      : () => _openCreateFlow(context),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
      ),
      floatingActionButton: _isAddonSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: store.isLoadingPartnerLookups
                  ? null
                  : () => _openCreateFlow(context),
              icon: const Icon(Icons.add),
              label: Text(context.tr('Đăng tin')),
            ),
      body: RefreshIndicator(
        onRefresh: _applyFilters,
        child: PageContainer(
          maxWidth: 820,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_isAddonSelectionMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AddonSelectionBanner(
                      featureName: widget.selectedAddonFeatureName,
                      featureDescription:
                          widget.selectedAddonFeatureDescription,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _FilterPanel(
                  lookups: lookups,
                  selectedCityId: _cityId,
                  selectedWardId: _wardId,
                  selectedStatus: _status,
                  isBusy: store.isLoadingPartnerProperties ||
                      store.isLoadingPartnerLookups,
                  onCityChanged: _changeCity,
                  onWardChanged: (value) {
                    setState(() => _wardId = value);
                  },
                  onStatusChanged: (value) {
                    setState(() => _status = value);
                  },
                  onApply: _applyFilters,
                  onReset: _resetFilters,
                ),
              ),
              if (!_isAddonSelectionMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _TopPinSummary(
                      count: store.activeTopPropertyCount,
                    ),
                  ),
                ),
              if (store.partnerPropertyError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Material(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          context.tr(store.partnerPropertyError!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (store.isLoadingPartnerProperties && items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.home_work_outlined,
                    title: context.tr('Không có tin phù hợp'),
                    message: context.tr(
                      'Thay đổi bộ lọc hoặc tạo tin đăng bất động sản mới.',
                    ),
                    action: _isAddonSelectionMode
                        ? null
                        : FilledButton(
                            onPressed: () => _openCreateFlow(context),
                            child: Text(context.tr('Tạo tin')),
                          ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 12, bottom: 100),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _PartnerPropertyCard(
                      property: items[index],
                      isAddonSelectionMode: _isAddonSelectionMode,
                      selectedAddonFeatureCode:
                          widget.selectedAddonFeatureCode,
                      onSelectAddon: () => _buyAddonForProperty(items[index]),
                      onEdit: () => _openEditFlow(items[index]),
                      onClose: () => _closeProperty(items[index]),
                      onReopen: () => _reopenProperty(items[index]),
                      onBoost: () => _buyTopForProperty(items[index]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeCity(int value) async {
    setState(() {
      _cityId = value;
      _wardId = 0;
    });
    final store = AppScope.of(context);
    try {
      await store.loadPartnerFormLookups(
        cityId: value > 0 ? value : null,
      );
    } catch (_) {}
  }

  Future<void> _applyFilters() async {
    final store = AppScope.of(context);
    try {
      await store.refreshPartnerProperties(
        cityId: _cityId > 0 ? _cityId : null,
        wardId: _wardId > 0 ? _wardId : null,
        status: _status,
        featureCode: widget.selectedAddonFeatureCode,
      );
    } catch (_) {}
  }

  Future<void> _resetFilters() async {
    setState(() {
      _cityId = 0;
      _wardId = 0;
      _status = 'all';
    });
    final store = AppScope.of(context);
    try {
      await store.loadPartnerFormLookups();
      await store.refreshPartnerProperties(
        featureCode: widget.selectedAddonFeatureCode,
      );
    } catch (_) {}
  }

  Future<void> _openCreateFlow(
    BuildContext context, {
    String postingPackageCode = '',
    String postingPackageName = '',
  }) async {
    final store = AppScope.of(context);
    try {
      if (store.partnerFormLookups.isEmpty) {
        await store.loadPartnerFormLookups();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.toString()))),
      );
      return;
    }
    if (!mounted) return;

    ListingKind? kind;
    PartnerLookupItem? propertyType;
    while (mounted && propertyType == null) {
      kind ??= await showModalBottomSheet<ListingKind>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _ListingKindSheet(),
      );
      if (!mounted || kind == null) return;

      final propertyTypes = store.partnerFormLookups.propertyTypes.where((item) {
        final isPremises = _isPremisesType(item);
        final isLand = _isLandType(item);
        switch (kind!) {
          case ListingKind.houseSale:
          case ListingKind.houseRent:
            return !isLand;
          case ListingKind.landSale:
            return isLand && !isPremises;
          case ListingKind.premises:
            return isPremises;
        }
      }).toList(growable: false);

      final result = await showModalBottomSheet<Object>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PropertyTypeSheet(
          kind: kind!,
          items: propertyTypes,
        ),
      );
      if (!mounted) return;
      if (result is _BackToListingKind) {
        kind = null;
        continue;
      }
      if (result is! PartnerLookupItem) return;
      propertyType = result;
    }

    if (!mounted || kind == null || propertyType == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PropertyFormPage(
          kind: kind!,
          propertyType: propertyType!,
          postingPackageCode: postingPackageCode,
          postingPackageName: postingPackageName,
        ),
      ),
    );
    if (!mounted || created != true) return;
    await _applyFilters();
  }

  Future<void> _openEditFlow(PropertyModel property) async {
    final store = AppScope.of(context);
    try {
      final data = await store.loadPartnerPropertyForEdit(property.id);
      await store.loadPartnerFormLookups(cityId: data.cityId);
      if (!mounted) return;

      PartnerLookupItem? selectedType;
      for (final item in store.partnerFormLookups.propertyTypes) {
        if (item.code.trim().toLowerCase() ==
            data.propertyType.trim().toLowerCase()) {
          selectedType = item;
          break;
        }
      }
      selectedType ??= PartnerLookupItem(
        id: 0,
        code: data.propertyType,
        name: property.propertyType.isNotEmpty
            ? property.propertyType
            : data.propertyType,
        category: data.propertyType.toLowerCase().startsWith('land_')
            ? 'land'
            : 'house',
        listingMode: listingKindFromCode(data.listingType).isRent
            ? 'rent'
            : 'sale',
      );

      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => PropertyFormPage(
            kind: listingKindFromCode(data.listingType),
            propertyType: selectedType!,
            initialData: data,
          ),
        ),
      );
      if (!mounted || updated != true) return;
      await _applyFilters();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.toString()))),
      );
    }
  }

  Future<void> _buyAddonForProperty(PropertyModel property) async {
    if (!_isAddonSelectionMode || !mounted) return;
    final featureName = widget.selectedAddonFeatureName.trim().isEmpty
        ? context.tr('Dịch vụ gia tăng')
        : widget.selectedAddonFeatureName.trim();
    await _confirmAndBuyFeature(
      property: property,
      featureCode: widget.selectedAddonFeatureCode,
      featureName: featureName,
      featurePrice: widget.selectedAddonFeaturePrice,
    );
  }

  Future<void> _buyTopForProperty(PropertyModel property) async {
    if (!mounted) return;
    final store = AppScope.of(context);
    if (store.addonFeatures.isEmpty) {
      await store.refreshMembership();
      if (!mounted) return;
    }

    var featureName = context.tr('Ghim Top');
    var featurePrice = 0.0;
    for (final feature in store.addonFeatures) {
      if (feature.code.trim().toLowerCase() == 'top7') {
        if (feature.name.trim().isNotEmpty) featureName = feature.name.trim();
        featurePrice = feature.price;
        break;
      }
    }

    await _confirmAndBuyFeature(
      property: property,
      featureCode: 'top7',
      featureName: property.boostedUntil != null &&
              property.boostedUntil!.isAfter(DateTime.now().toUtc())
          ? context.tr('Gia hạn Ghim Top')
          : featureName,
      featurePrice: featurePrice,
      showFreeTopHint: true,
    );
  }

  Future<void> _confirmAndBuyFeature({
    required PropertyModel property,
    required String featureCode,
    required String featureName,
    required double featurePrice,
    bool showFreeTopHint = false,
  }) async {
    if (!mounted) return;
    final store = AppScope.of(context);
    final content = <String>[context.tr(featureName), property.title];
    if (showFreeTopHint && store.membershipUsage.freeTopRemaining > 0) {
      content.add(
        context.tr(
          'Hệ thống sẽ ưu tiên dùng lượt Ghim Top miễn phí còn lại.',
        ),
      );
    } else if (featurePrice > 0) {
      content.add(
        '${context.tr('Giá dịch vụ')}: ${context.tr('{amount} đ', {'amount': _formatMoney(featurePrice)})}',
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Xác nhận mua dịch vụ')),
        content: Text(content.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Hủy')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('Xác nhận')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      final message = await store.buyAddonFeature(
        propertyId: property.id,
        featureCode: featureCode,
        useFreeTopBenefit: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(message)),
          backgroundColor: const Color(0xFF10983F),
        ),
      );
      await _applyFilters();
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      if (error.code == 'INSUFFICIENT_WALLET_BALANCE') {
        final openWallet = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.tr('Số dư ví không đủ')),
            content: Text(context.tr(error.message)),
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
          if (mounted) await _applyFilters();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(error.message))),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.toString()))),
      );
    }
  }

  Future<void> _closeProperty(PropertyModel property) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Đóng tin')),
        content: Text(
          context.tr(
            'Bạn có chắc muốn đóng bài đăng này không?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Hủy')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('Đóng tin')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final store = AppScope.of(context);
    try {
      final message = await store.closePartnerProperty(property.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(message)),
          backgroundColor: const Color(0xFF10983F),
        ),
      );
      await _applyFilters();
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.message))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.toString()))),
      );
    }
  }

  Future<void> _reopenProperty(PropertyModel property) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Mở lại tin')),
        content: Text(
          context.tr(
            'Bạn có chắc muốn mở lại bài đăng này không? Bài đăng sẽ chuyển về trạng thái chờ duyệt.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Hủy')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('Mở lại tin')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final store = AppScope.of(context);
    try {
      final message = await store.reopenPartnerProperty(property.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(message)),
          backgroundColor: const Color(0xFF10983F),
        ),
      );
      await _applyFilters();
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.message))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(error.toString()))),
      );
    }
  }

  bool _isPremisesType(PartnerLookupItem item) {
    final code = item.code.trim().toLowerCase();
    if (item.listingMode == 'rent' && item.category == 'land') return true;
    switch (code) {
      case 'land_office':
      case 'land_warehouse':
      case 'land_factory':
      case 'land_ground':
      case 'land_business':
      case 'land_transfer':
        return true;
      default:
        return false;
    }
  }

  bool _isLandType(PartnerLookupItem item) {
    final code = item.code.trim().toLowerCase();
    return item.category == 'land' ||
        _isPremisesType(item) ||
        code == 'land' ||
        code.startsWith('land_');
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.lookups,
    required this.selectedCityId,
    required this.selectedWardId,
    required this.selectedStatus,
    required this.isBusy,
    required this.onCityChanged,
    required this.onWardChanged,
    required this.onStatusChanged,
    required this.onApply,
    required this.onReset,
  });

  final PartnerFormLookups lookups;
  final int selectedCityId;
  final int selectedWardId;
  final String selectedStatus;
  final bool isBusy;
  final ValueChanged<int> onCityChanged;
  final ValueChanged<int> onWardChanged;
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function() onApply;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final statusItems = lookups.statuses.isEmpty
        ? const <PartnerLookupItem>[
            PartnerLookupItem(id: 0, code: 'all', name: 'Tất cả trạng thái'),
            PartnerLookupItem(id: 0, code: 'pendingapproval', name: 'Chờ duyệt'),
            PartnerLookupItem(id: 0, code: 'published', name: 'Đang hiển thị'),
            PartnerLookupItem(id: 0, code: 'draft', name: 'Bản nháp'),
            PartnerLookupItem(id: 0, code: 'rejected', name: 'Từ chối'),
          ]
        : lookups.statuses;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt_outlined, color: AppTheme.navy),
                const SizedBox(width: 8),
                Text(
                  context.tr('Lọc tin đăng'),
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 680;
                final fields = <Widget>[
                  DropdownButtonFormField<int>(
                    key: ValueKey('partner-city-$selectedCityId'),
                    initialValue: selectedCityId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr('Tỉnh/Thành phố'),
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text(context.tr('Tất cả thành phố')),
                      ),
                      ...lookups.cities.map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: isBusy
                        ? null
                        : (value) => onCityChanged(value ?? 0),
                  ),
                  DropdownButtonFormField<int>(
                    key: ValueKey('partner-ward-$selectedCityId-$selectedWardId'),
                    initialValue: selectedWardId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr('Phường/Xã'),
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                    items: [
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text(context.tr('Tất cả phường/xã')),
                      ),
                      ...lookups.wards.map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: isBusy || selectedCityId <= 0
                        ? null
                        : (value) => onWardChanged(value ?? 0),
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey('partner-status-$selectedStatus'),
                    initialValue: selectedStatus,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr('Trạng thái'),
                      prefixIcon: const Icon(Icons.fact_check_outlined),
                    ),
                    items: statusItems
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.code,
                            child: Text(
                              context.tr(item.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: isBusy
                        ? null
                        : (value) => onStatusChanged(value ?? 'all'),
                  ),
                ];

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < fields.length; i++) ...[
                        Expanded(child: fields[i]),
                        if (i < fields.length - 1) const SizedBox(width: 10),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      fields[i],
                      if (i < fields.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: isBusy ? null : onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(context.tr('Đặt lại')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: isBusy ? null : onApply,
                  icon: isBusy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(context.tr('Áp dụng')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddonSelectionBanner extends StatelessWidget {
  const _AddonSelectionBanner({
    required this.featureName,
    required this.featureDescription,
  });

  final String featureName;
  final String featureDescription;

  @override
  Widget build(BuildContext context) {
    final name = featureName.trim().isEmpty
        ? context.tr('Dịch vụ gia tăng')
        : context.tr(featureName.trim());
    final description = context.tr(featureDescription.trim());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        border: Border.all(color: const Color(0xFF86EFAC)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Vui lòng chọn một bài đăng để sử dụng dịch vụ'),
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description.isEmpty ? name : '$name — $description',
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _TopPinSummary extends StatelessWidget {
  const _TopPinSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.push_pin_rounded,
            size: 19,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('Tin đang Ghim Top'),
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.tr('{count} tin', {'count': '$count'}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerPropertyCard extends StatelessWidget {
  const _PartnerPropertyCard({
    required this.property,
    required this.isAddonSelectionMode,
    required this.selectedAddonFeatureCode,
    required this.onSelectAddon,
    required this.onEdit,
    required this.onClose,
    required this.onReopen,
    required this.onBoost,
  });

  final PropertyModel property;
  final bool isAddonSelectionMode;
  final String selectedAddonFeatureCode;
  final Future<void> Function() onSelectAddon;
  final Future<void> Function() onEdit;
  final Future<void> Function() onClose;
  final Future<void> Function() onReopen;
  final Future<void> Function() onBoost;

  bool get _isClosed =>
      property.status == PropertyStatus.closed ||
      property.status == PropertyStatus.sold ||
      property.status == PropertyStatus.rented;

  bool get _hasActiveTop =>
      !_isClosed &&
      property.boostedUntil != null &&
      property.boostedUntil!.isAfter(DateTime.now().toUtc());

  bool get _isSelectedUrgentPurchased =>
      selectedAddonFeatureCode.trim().toLowerCase() == 'urgent_review' &&
      property.hasUrgentReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 105,
              height: 92,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: PropertyVisual(property: property),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (property.hasUrgentReview) ...[
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 15,
                            color: Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              context.tr(
                                'Duyệt siêu tốc - đang hiển thị công khai',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFEA580C),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_hasActiveTop && property.boostedUntil != null) ...[
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${context.tr('Ghim Top')} · ${_featureRemainingText(context, property.boostedUntil!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBE123C),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isAddonSelectionMode && !_isClosed) ...[
                    const SizedBox(height: 8),
                    if (_isSelectedUrgentPurchased)
                      _PurchasedFeaturePanel(
                        icon: Icons.bolt_rounded,
                        detail: context.tr(
                          'Tin đã được hiển thị công khai và đang chờ Admin hoàn thiện kiểm duyệt.',
                        ),
                      )
                    else if (property.hasActiveSelectedPaidFeature &&
                        property.selectedPaidFeatureExpiresAt != null)
                      _PurchasedFeaturePanel(
                        icon: Icons.access_time_filled_rounded,
                        detail: _featureRemainingText(
                          context,
                          property.selectedPaidFeatureExpiresAt!,
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: onSelectAddon,
                        icon: const Icon(Icons.check_circle, size: 15),
                        label: Text(context.tr('Chọn tin này')),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    '${context.tr(property.priceLabel)} · ${property.area} m²',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: property.status
                              .color(Theme.of(context).colorScheme)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.tr(property.status.label),
                          style: TextStyle(
                            color: property.status
                                .color(Theme.of(context).colorScheme),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isAddonSelectionMode)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await onEdit();
                  } else if (value == 'close') {
                    await onClose();
                  } else if (value == 'reopen') {
                    await onReopen();
                  } else if (value == 'boost') {
                    await onBoost();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(context.tr('Chỉnh sửa')),
                  ),
                  if (_isClosed)
                    PopupMenuItem(
                      value: 'reopen',
                      child: Text(context.tr('Mở lại tin')),
                    )
                  else ...[
                    PopupMenuItem(
                      value: 'close',
                      child: Text(context.tr('Đóng tin')),
                    ),
                    PopupMenuItem(
                      value: 'boost',
                      child: Text(
                        context.tr(_hasActiveTop ? 'Gia hạn Ghim Top' : 'Ghim Top'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PurchasedFeaturePanel extends StatelessWidget {
  const _PurchasedFeaturePanel({
    required this.icon,
    required this.detail,
  });

  final IconData icon;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        border: Border.all(color: const Color(0xFF86EFAC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('Đã mua'),
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

String _featureRemainingText(BuildContext context, DateTime expiresAt) {
  final remaining = expiresAt.toUtc().difference(DateTime.now().toUtc());
  if (remaining.inSeconds <= 0) return context.tr('Đã hết thời gian');

  final days = remaining.inDays;
  final hours = remaining.inHours.remainder(24);
  final minutes = remaining.inMinutes.remainder(60);
  if (days > 0) {
    return context.tr(
      'Còn {days} ngày {hours} giờ',
      {'days': '$days', 'hours': '$hours'},
    );
  }
  if (remaining.inHours > 0) {
    return context.tr(
      'Còn {hours} giờ {minutes} phút',
      {'hours': '${remaining.inHours}', 'minutes': '$minutes'},
    );
  }
  return context.tr(
    'Còn {minutes} phút',
    {'minutes': '${remaining.inMinutes.clamp(1, 59)}'},
  );
}

String _formatMoney(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

class _ListingKindSheet extends StatelessWidget {
  const _ListingKindSheet();

  @override
  Widget build(BuildContext context) {
    final options = <_ListingOption>[
      const _ListingOption(
        kind: ListingKind.houseSale,
        icon: Icons.home_rounded,
        title: 'Đăng bán nhà',
        subtitle: 'Nhà, căn hộ hoặc bất động sản để bán',
        color: Colors.orange,
      ),
      const _ListingOption(
        kind: ListingKind.houseRent,
        icon: Icons.key_rounded,
        title: 'Đăng thuê nhà',
        subtitle: 'Nhà, căn hộ, phòng cho thuê',
        color: Colors.indigo,
      ),
      const _ListingOption(
        kind: ListingKind.landSale,
        icon: Icons.terrain_rounded,
        title: 'Đăng đất bán',
        subtitle: 'Đất thổ cư, đất dự án hoặc loại đất khác',
        color: Colors.green,
      ),
      const _ListingOption(
        kind: ListingKind.premises,
        icon: Icons.storefront_rounded,
        title: 'Đăng mặt bằng',
        subtitle: 'Văn phòng, kho bãi, nhà xưởng hoặc mặt bằng đất',
        color: Colors.cyan,
      ),
    ];

    return _SelectionSheet(
      icon: Icons.home_work_rounded,
      title: context.tr('Bạn muốn đăng loại tin nào?'),
      subtitle: context.tr(
        'Chọn hình thức trước, sau đó chọn loại bất động sản cụ thể.',
      ),
      child: Column(
        children: options
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _SelectionTile(
                  icon: item.icon,
                  color: item.color,
                  title: context.tr(item.title),
                  subtitle: context.tr(item.subtitle),
                  onTap: () => Navigator.of(context).pop(item.kind),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PropertyTypeSheet extends StatelessWidget {
  const _PropertyTypeSheet({required this.kind, required this.items});

  final ListingKind kind;
  final List<PartnerLookupItem> items;

  @override
  Widget build(BuildContext context) {
    return _SelectionSheet(
      icon: Icons.apartment_rounded,
      title: context.tr('Chọn loại bất động sản'),
      subtitle: context.tr(
        'Hình thức đã chọn: {type}. Chọn loại cụ thể để tiếp tục vào màn đăng bài.',
        {'type': context.tr(kind.label)},
      ),
      showBack: true,
      onBack: () => Navigator.of(context).pop(const _BackToListingKind()),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                context.tr('Chưa có loại bất động sản phù hợp.'),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _SelectionTile(
                        icon: _iconForPropertyType(item.code),
                        color: AppTheme.primary,
                        title: context.tr(item.name),
                        onTap: () => Navigator.of(context).pop(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  IconData _iconForPropertyType(String code) {
    switch (code) {
      case 'land_office':
        return Icons.domain_rounded;
      case 'land_warehouse':
        return Icons.warehouse_rounded;
      case 'land_factory':
        return Icons.factory_rounded;
      case 'land_business':
        return Icons.store_rounded;
      case 'land_transfer':
        return Icons.swap_horiz_rounded;
      case 'land_ground':
        return Icons.landscape_rounded;
      case 'apartment':
        return Icons.apartment_rounded;
      case 'villa':
        return Icons.villa_rounded;
      default:
        return Icons.home_work_rounded;
    }
  }
}

class _SelectionSheet extends StatelessWidget {
  const _SelectionSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
    this.onBack,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBack)
                    IconButton(
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: context.tr('Quay lại'),
                    ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle),
              const SizedBox(height: 18),
              child,
              const SizedBox(height: 4),
              Center(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr('Hủy')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle = '',
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
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
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackToListingKind {
  const _BackToListingKind();
}

class _ListingOption {
  const _ListingOption({
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final ListingKind kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
