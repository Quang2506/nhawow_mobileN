import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'property_detail_page.dart';
import 'property_sort_sheet.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    this.initialFilter = const SearchFilterModel(),
    this.embedded = false,
    super.key,
  });

  final SearchFilterModel initialFilter;
  final bool embedded;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchFilterModel _filter;
  late final TextEditingController _keywordController;
  List<PropertyModel> _results = const <PropertyModel>[];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _selectedSort = _normalizeInitialSort(_filter.sortBy);
    _filter = _filter.copyWith(sortBy: _apiSortFor(_selectedSort));
    _keywordController = TextEditingController(text: _filter.keyword);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final cities = _cityOptions(store);
    final selectedCity = cities.contains(_filter.city) ? _filter.city : 'Tất cả';
    if (selectedCity != _filter.city) {
      _filter = _filter.copyWith(city: selectedCity, ward: 'Tất cả');
    }

    final wards = _wardOptions(store, selectedCity);
    final selectedWard = wards.contains(_filter.ward) ? _filter.ward : 'Tất cả';
    if (selectedWard != _filter.ward) {
      _filter = _filter.copyWith(ward: selectedWard);
    }

    final types = _propertyTypeOptions(store);
    final selectedType = types.contains(_filter.propertyType)
        ? _filter.propertyType
        : 'Tất cả';
    if (selectedType != _filter.propertyType) {
      _filter = _filter.copyWith(propertyType: selectedType);
    }

    final visibleResults = _sortVisibleResults(
      _hasSearched
          ? _results
          : store.search(
              _filter.copyWith(keyword: _keywordController.text.trim()),
            ),
      _selectedSort,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Tìm kiếm bất động sản')),
        actions: [
          IconButton(
            tooltip: context.tr('Đặt lại bộ lọc'),
            onPressed: _isSearching ? null : _resetAndSearch,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: PageContainer(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            widget.embedded ? 140 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _keywordController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() => _hasSearched = false),
                onSubmitted: (_) => _runSearch(),
                decoration: InputDecoration(
                  hintText: context.tr('Tìm theo khu vực, dự án, tiêu đề...'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _keywordController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _keywordController.clear();
                            setState(() => _hasSearched = false);
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final fields = <Widget>[
                    DropdownButtonFormField<ListingKind?>(
                      key: ValueKey<String>(
                        'kind:${_filter.kind?.code ?? 'all'}',
                      ),
                      initialValue: _filter.kind,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Hình thức'),
                      ),
                      items: <DropdownMenuItem<ListingKind?>>[
                        DropdownMenuItem<ListingKind?>(
                          value: null,
                          child: Text(
                            context.tr('Tất cả'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...ListingKind.values
                            .map<DropdownMenuItem<ListingKind?>>(
                          (item) => DropdownMenuItem<ListingKind?>(
                            value: item,
                            child: Text(
                              context.tr(item.label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _hasSearched = false;
                        _filter = value == null
                            ? _filter.copyWith(clearKind: true)
                            : _filter.copyWith(kind: value);
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>('city:$selectedCity'),
                      initialValue: selectedCity,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Tỉnh/Thành phố'),
                      ),
                      items: cities
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                context.tr(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() {
                        _hasSearched = false;
                        _filter = _filter.copyWith(
                          city: value ?? 'Tất cả',
                          ward: 'Tất cả',
                        );
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(
                        'ward:$selectedCity:$selectedWard',
                      ),
                      initialValue: selectedWard,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Phường/Xã'),
                      ),
                      items: wards
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                context.tr(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() {
                        _hasSearched = false;
                        _filter = _filter.copyWith(
                          ward: value ?? 'Tất cả',
                        );
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>('type:$selectedType'),
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Loại bất động sản'),
                      ),
                      items: types
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                context.tr(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() {
                        _hasSearched = false;
                        _filter = _filter.copyWith(
                          propertyType: value ?? 'Tất cả',
                        );
                      }),
                    ),
                  ];

                  if (wide) {
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 4.2,
                      children: fields,
                    );
                  }

                  return Column(
                    children: [
                      for (final field in fields) ...[
                        field,
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              _PriceQuickFilter(
                onSelected: (min, max) => setState(() {
                  _hasSearched = false;
                  _filter = _filter.copyWith(
                    minPrice: min,
                    maxPrice: max,
                    clearMinPrice: min == null,
                    clearMaxPrice: max == null,
                  );
                }),
              ),
              const SizedBox(height: 14),
              const SizedBox(height: 4),
              FilledButton.icon(
                onPressed: _isSearching ? null : _runSearch,
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(
                  context.tr(
                    _isSearching ? 'Đang tìm kiếm...' : 'Tìm kiếm',
                  ),
                ),
              ),
              if (_searchError != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFC9C2)),
                  ),
                  child: Text(
                    _searchError!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SearchResultsHeader(
                title: context.tr(
                  '{count} kết quả',
                  {'count': visibleResults.length},
                ),
                subtitle: selectedCity == 'Tất cả'
                    ? context.tr('Tất cả khu vực')
                    : '${selectedWard == 'Tất cả' ? '' : '$selectedWard, '}$selectedCity',
                sortBy: _selectedSort,
                onSortTap: _isSearching ? () {} : _openSortSheet,
              ),
              const SizedBox(height: 12),
              if (!_isSearching && visibleResults.isEmpty)
                _EmptySearchResult(
                  message: context.tr(
                    'Không tìm thấy bất động sản phù hợp.',
                  ),
                )
              else
                PropertyGrid(
                  properties: visibleResults,
                  onPropertyTap: (property) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PropertyDetailPage(
                          propertyId: property.id,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeInitialSort(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'price_asc' || normalized == 'price_desc') {
      return normalized;
    }
    return 'relevant';
  }

  String _apiSortFor(String value) {
    switch (value) {
      case 'price_asc':
      case 'price_desc':
        return value;
      case 'newest':
      case 'relevant':
      default:
        // API hiện dùng "newest" cho thứ tự mặc định có Ghim Top / hội viên.
        // Với lựa chọn "Mới nhất", app sẽ sắp lại theo id sau khi tải kết quả.
        return 'newest';
    }
  }

  List<PropertyModel> _sortVisibleResults(
    List<PropertyModel> source,
    String sortBy,
  ) {
    final results = source.toList(growable: true);

    int compareDefault(PropertyModel a, PropertyModel b) {
      if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
      final priority = b.sortPriority.compareTo(a.sortPriority);
      if (priority != 0) return priority;
      return b.id.compareTo(a.id);
    }

    switch (sortBy) {
      case 'newest':
        results.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'price_asc':
        results.sort((a, b) {
          final aMissing = a.price <= 0;
          final bMissing = b.price <= 0;
          if (aMissing != bMissing) return aMissing ? 1 : -1;
          final compared = a.price.compareTo(b.price);
          return compared != 0 ? compared : compareDefault(a, b);
        });
        break;
      case 'price_desc':
        results.sort((a, b) {
          final aMissing = a.price <= 0;
          final bMissing = b.price <= 0;
          if (aMissing != bMissing) return aMissing ? 1 : -1;
          final compared = b.price.compareTo(a.price);
          return compared != 0 ? compared : compareDefault(a, b);
        });
        break;
      case 'relevant':
      default:
        break;
    }
    return results;
  }

  Future<void> _openSortSheet() async {
    final selected = await showPropertySortSheet(
      context,
      selectedValue: _selectedSort,
    );
    if (!mounted || selected == null || selected == _selectedSort) return;

    setState(() {
      _selectedSort = selected;
      _filter = _filter.copyWith(sortBy: _apiSortFor(selected));
    });
    await _runSearch();
  }

  Future<void> _runSearch() async {
    if (_isSearching) return;
    FocusScope.of(context).unfocus();

    final nextFilter = _filter.copyWith(
      keyword: _keywordController.text.trim(),
    );
    setState(() {
      _filter = nextFilter;
      _isSearching = true;
      _searchError = null;
    });

    final store = AppScope.of(context);
    try {
      final results = await store.searchPropertiesRemote(nextFilter);
      if (!mounted) return;
      setState(() {
        _results = results;
        _hasSearched = true;
      });
    } on ApiTransportException catch (error) {
      if (!mounted) return;
      setState(() {
        _results = store.search(nextFilter);
        _hasSearched = true;
        _searchError = context.tr(error.message);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _results = store.search(nextFilter);
        _hasSearched = true;
        _searchError = context.tr(error.toString());
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _resetAndSearch() async {
    _keywordController.clear();
    setState(() {
      _selectedSort = 'relevant';
      _filter = const SearchFilterModel();
      _hasSearched = false;
      _searchError = null;
    });
    await _runSearch();
  }

  List<String> _cityOptions(AppStore store) {
    final names = store.lookups.cities
        .map((item) => item.name.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (names.isEmpty) {
      names.addAll(
        store.properties
            .map((item) => item.city.trim())
            .where((item) => item.isNotEmpty),
      );
    }
    final sorted = names.toList()..sort();
    return <String>['Tất cả', ...sorted];
  }

  List<String> _wardOptions(AppStore store, String selectedCity) {
    int? selectedCityId;
    for (final city in store.lookups.cities) {
      if (city.name == selectedCity) {
        selectedCityId = city.id;
        break;
      }
    }

    final names = store.lookups.wards
        .where(
          (item) => selectedCity == 'Tất cả' ||
              selectedCityId == null ||
              item.cityId == null ||
              item.cityId == selectedCityId,
        )
        .map((item) => item.name.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    if (names.isEmpty) {
      names.addAll(
        store.properties
            .where(
              (item) =>
                  selectedCity == 'Tất cả' || item.city == selectedCity,
            )
            .map((item) => item.ward.trim())
            .where((item) => item.isNotEmpty),
      );
    }

    final sorted = names.toList()..sort();
    return <String>['Tất cả', ...sorted];
  }

  List<String> _propertyTypeOptions(AppStore store) {
    final names = store.lookups.propertyTypes
        .map((item) => item.name.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (names.isEmpty) {
      names.addAll(
        store.properties
            .map((item) => item.propertyType.trim())
            .where((item) => item.isNotEmpty),
      );
    }
    final sorted = names.toList()..sort();
    return <String>['Tất cả', ...sorted];
  }
}

class _SearchResultsHeader extends StatelessWidget {
  const _SearchResultsHeader({
    required this.title,
    required this.subtitle,
    required this.sortBy,
    required this.onSortTap,
  });

  final String title;
  final String subtitle;
  final String sortBy;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.blueGrey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: PropertySortButton(
            value: sortBy,
            onTap: onSortTap,
          ),
        ),
      ],
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: AppTheme.navy,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceQuickFilter extends StatelessWidget {
  const _PriceQuickFilter({required this.onSelected});

  final void Function(double? min, double? max) onSelected;

  @override
  Widget build(BuildContext context) {
    const values = [
      ('Tất cả giá', null, null),
      ('Dưới 2 tỷ', null, 2000000000.0),
      ('2–5 tỷ', 2000000000.0, 5000000000.0),
      ('5–10 tỷ', 5000000000.0, 10000000000.0),
      ('Trên 10 tỷ', 10000000000.0, null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Khoảng giá nhanh'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (item) => ActionChip(
                  label: Text(context.tr(item.$1)),
                  onPressed: () => onSelected(item.$2, item.$3),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
