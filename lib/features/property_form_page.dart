import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../models/partner_models.dart';

class PropertyFormPage extends StatefulWidget {
  const PropertyFormPage({
    required this.kind,
    required this.propertyType,
    this.initialData,
    super.key,
  });

  final ListingKind kind;
  final PartnerLookupItem propertyType;
  final PartnerPropertyEditData? initialData;

  @override
  State<PropertyFormPage> createState() => _PropertyFormPageState();
}

class _PropertyFormPageState extends State<PropertyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _addressDetail = TextEditingController();
  final _oldAddress = TextEditingController();
  final _price = TextEditingController();
  final _area = TextEditingController();
  final _viewingNote = TextEditingController();
  final _moveInStatus = TextEditingController();

  // Các trường dùng chung đúng cấu trúc lưu của web partner/createProperty.
  final _field1 = TextEditingController(); // SaleFrontage
  final _field2 = TextEditingController(); // SaleRoadWidth
  final _field3 = TextEditingController(); // SaleLegalInfo
  final _field4 = TextEditingController(); // LeaseTerm
  final _field5 = TextEditingController(); // FloorInfo
  final _water = TextEditingController();
  final _electricity = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final List<_PickedPartnerImage> _images = <_PickedPartnerImage>[];
  final List<PartnerExistingImage> _existingImages = <PartnerExistingImage>[];
  final Set<int> _removedExistingImageIds = <int>{};
  final Set<String> _selectedAmenities = <String>{};
  final Map<String, int> _selectedInforTags = <String, int>{};

  int _cityId = 0;
  int _wardId = 0;
  String _orientationCode = '';
  bool _useOldAddress = false;
  bool _submitting = false;
  int _coverImageIndex = 0;
  int? _selectedExistingCoverImageId;

  bool get _isEditing => widget.initialData != null;
  List<PartnerExistingImage> get _activeExistingImages => _existingImages
      .where((item) => !_removedExistingImageIds.contains(item.imageId))
      .toList(growable: false);
  int get _activeImageCount => _activeExistingImages.length + _images.length;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;

    _cityId = data.cityId;
    _wardId = data.wardId;
    _useOldAddress = data.useOldAddressDisplay;
    _orientationCode = data.orientationCode;
    _title.text = data.title;
    _description.text = data.description;
    _addressDetail.text = data.newAddressDetail;
    _oldAddress.text = data.oldAddressLine;
    _price.text = _formatMoneyInput(data.price);
    _area.text = _formatPlainNumber(data.areaSqm);
    _viewingNote.text = data.viewingNote;
    _moveInStatus.text = data.moveInStatus;
    _field1.text = data.saleFrontage;
    _field2.text = data.saleRoadWidth;
    _field3.text = data.saleLegalInfo;
    _field4.text = data.leaseTerm;
    _field5.text = data.floorInfo;
    _water.text = data.waterInfo;
    _electricity.text = data.electricityInfo;
    _selectedAmenities.addAll(data.amenities);
    for (final item in data.inforTags) {
      if (item.code.isNotEmpty) {
        _selectedInforTags[item.code] = item.quantity > 0 ? item.quantity : 1;
      }
    }
    _existingImages.addAll(data.images);
    for (final image in data.images) {
      if (image.isCover) {
        _selectedExistingCoverImageId = image.imageId;
        _coverImageIndex = -1;
        break;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _addressDetail.dispose();
    _oldAddress.dispose();
    _price.dispose();
    _area.dispose();
    _viewingNote.dispose();
    _moveInStatus.dispose();
    _field1.dispose();
    _field2.dispose();
    _field3.dispose();
    _field4.dispose();
    _field5.dispose();
    _water.dispose();
    _electricity.dispose();
    super.dispose();
  }

  bool get _isHouse =>
      widget.kind == ListingKind.houseSale ||
      widget.kind == ListingKind.houseRent;
  bool get _isHouseSale => widget.kind == ListingKind.houseSale;
  bool get _isHouseRent => widget.kind == ListingKind.houseRent;
  bool get _isLandSale => widget.kind == ListingKind.landSale;
  bool get _isPremises => widget.kind == ListingKind.premises;
  String get _propertyTypeCode => widget.propertyType.code;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final lookups = store.partnerFormLookups;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_isEditing
            ? 'Chỉnh sửa tin bất động sản'
            : 'Tạo tin bất động sản')),
      ),
      body: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 760,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SelectedTypeSummary(
                  kind: widget.kind,
                  propertyType: widget.propertyType,
                ),
                const SizedBox(height: 18),
                const _StepHeader(number: 1, title: 'Thông tin bài đăng'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: context.tr('Tiêu đề tin đăng'),
                    hintText: context.tr(
                      'Ví dụ: Bán nhà 3 tầng gần trung tâm, ngõ ô tô',
                    ),
                  ),
                  validator: (value) {
                    final length = (value ?? '').trim().length;
                    if (length == 0) {
                      return context.tr('Vui lòng nhập tiêu đề');
                    }
                    if (length > 200) {
                      return context.tr('Tiêu đề tối đa 200 ký tự');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: context.tr('Mô tả bất động sản'),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 22),
                const _StepHeader(number: 2, title: 'Địa chỉ'),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('create-city-$_cityId'),
                  initialValue: _cityId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Tỉnh/Thành phố'),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: 0,
                      child: Text(context.tr('Chọn tỉnh/thành phố')),
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
                  validator: (value) => (value ?? 0) <= 0
                      ? context.tr('Vui lòng chọn tỉnh/thành phố')
                      : null,
                  onChanged: _submitting || store.isLoadingPartnerLookups
                      ? null
                      : (value) => _changeCity(value ?? 0),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('create-ward-$_cityId-$_wardId'),
                  initialValue: _wardId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Phường/Xã'),
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: 0,
                      child: Text(context.tr('Chọn phường/xã')),
                    ),
                    ...lookups.wards.map(
                      (item) => DropdownMenuItem<int>(
                        value: item.id,
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  validator: (value) => (value ?? 0) <= 0
                      ? context.tr('Vui lòng chọn phường/xã')
                      : null,
                  onChanged: _submitting || _cityId <= 0
                      ? null
                      : (value) => setState(() => _wardId = value ?? 0),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressDetail,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: context.tr('Số nhà, đường, thôn/xóm'),
                    hintText: context.tr('Nhập phần địa chỉ chi tiết'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _useOldAddress,
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _useOldAddress = value),
                  title: Text(
                    context.tr('Hiển thị theo địa chỉ cũ'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    context.tr(
                      'Bản đồ vẫn dùng địa chỉ hành chính mới đã chọn ở trên.',
                    ),
                  ),
                ),
                if (_useOldAddress) ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _oldAddress,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: context.tr('Địa chỉ cũ'),
                      hintText: context.tr(
                        'Ví dụ: Xóm Lộc, xã Mỹ Thuận, huyện Mỹ Lộc, Nam Định',
                      ),
                    ),
                    validator: (value) => _useOldAddress &&
                            (value ?? '').trim().isEmpty
                        ? context.tr('Vui lòng nhập địa chỉ cũ')
                        : null,
                  ),
                ],
                const SizedBox(height: 22),
                const _StepHeader(number: 3, title: 'Giá và diện tích'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              _ThousandsSeparatorInputFormatter(
                                separator: _moneySeparator(context),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: context.tr('Giá (VNĐ)'),
                              hintText: context.tr(
                                'Để trống hoặc nhập 0 nếu thỏa thuận',
                              ),
                              suffixText: _isHouseRent || _isPremises
                                  ? context.tr('/tháng')
                                  : null,
                            ),
                            validator: (value) =>
                                _nonNegativeMoneyValidator(context, value),
                          ),
                          const SizedBox(height: 7),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _price,
                            builder: (context, value, _) {
                              final amount = _parseMoney(value.text) ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.32),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      context.tr('Hiển thị'),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _pricePreviewText(context, amount),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: AppTheme.navy,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _area,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('Diện tích'),
                          suffixText: 'm²',
                        ),
                        validator: (value) =>
                            _requiredPositiveValidator(context, value),
                      ),
                    ];
                    if (constraints.maxWidth >= 560) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: fields[0]),
                          const SizedBox(width: 12),
                          Expanded(child: fields[1]),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        fields[0],
                        const SizedBox(height: 12),
                        fields[1],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                const _StepHeader(number: 4, title: 'Thông tin theo loại tin'),
                const SizedBox(height: 12),
                _buildDynamicFields(context, lookups),
                if (_isHouse) ...[
                  const SizedBox(height: 20),
                  _buildHouseInformation(context, lookups),
                ],
                if (_isHouse || _isPremises) ...[
                  const SizedBox(height: 20),
                  _buildAmenities(context, lookups),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _viewingNote,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: context.tr('Ghi chú khi xem nhà'),
                    hintText: context.tr(
                      'Ví dụ: Liên hệ trước 30 phút, xem nhà sau 18 giờ',
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const _StepHeader(number: 5, title: 'Hình ảnh bất động sản'),
                const SizedBox(height: 12),
                _buildImagePicker(context),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.publish_outlined),
                  label: Text(
                    _submitting
                        ? context.tr(_isEditing
                            ? 'Đang lưu thay đổi...'
                            : 'Đang gửi bài...')
                        : context.tr(_isEditing
                            ? 'Lưu thay đổi'
                            : 'Gửi duyệt tin đăng'),
                  ),
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFields(
    BuildContext context,
    PartnerFormLookups lookups,
  ) {
    if (_isHouseSale) {
      return _DynamicFieldGrid(
        fields: [
          _DynamicField(
            controller: _field1,
            label: context.tr('Mặt tiền'),
            suffix: 'm',
            numeric: true,
          ),
          _DynamicField(
            controller: _field2,
            label: context.tr('Đường vào'),
            suffix: 'm',
            numeric: true,
          ),
          _DynamicField(
            controller: _field3,
            label: context.tr('Pháp lý'),
            hint: context.tr('Sổ đỏ, sổ hồng, hợp đồng...'),
          ),
          _DynamicField(
            controller: _field5,
            label: context.tr('Số tầng'),
            suffix: context.tr('tầng'),
            numeric: true,
          ),
        ],
        validator: _optionalPositiveValidator,
      );
    }

    if (_isHouseRent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DynamicFieldGrid(
            fields: [
              _DynamicField(
                controller: _field5,
                label: context.tr('Số tầng'),
                suffix: context.tr('tầng'),
                numeric: true,
              ),
              _DynamicField(
                controller: _water,
                label: context.tr('Giá nước'),
                suffix: context.tr('đ/khối'),
                numeric: true,
              ),
              _DynamicField(
                controller: _electricity,
                label: context.tr('Giá điện'),
                suffix: context.tr('đ/số'),
                numeric: true,
              ),
              _DynamicField(
                controller: _field4,
                label: context.tr('Thời hạn thuê'),
                suffix: context.tr('tháng'),
                numeric: true,
                integer: true,
              ),
            ],
            validator: _optionalPositiveValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _moveInStatus,
            decoration: InputDecoration(
              labelText: context.tr('Tình trạng vào ở'),
              hintText: context.tr('Có thể vào ở ngay, từ ngày...'),
            ),
          ),
        ],
      );
    }

    if (_isLandSale) {
      return _DynamicFieldGrid(
        fields: [
          _DynamicField(
            controller: _field1,
            label: context.tr('Mặt tiền'),
            suffix: 'm',
            numeric: true,
          ),
          _DynamicField(
            controller: _field2,
            label: context.tr('Đường vào'),
            suffix: 'm',
            numeric: true,
          ),
          _DynamicField(
            controller: _field3,
            label: context.tr('Pháp lý'),
            hint: context.tr('Sổ đỏ, hợp đồng, đang chờ cấp...'),
          ),
        ],
        validator: _optionalPositiveValidator,
      );
    }

    switch (_propertyTypeCode) {
      case 'land_office':
        return _DynamicFieldGrid(
          fields: [
            _DynamicField(
              controller: _field5,
              label: context.tr('Số tầng'),
              suffix: context.tr('tầng'),
              numeric: true,
              integer: true,
            ),
            _DynamicField(
              controller: _field4,
              label: context.tr('Thời hạn thuê'),
              suffix: context.tr('tháng'),
              numeric: true,
              integer: true,
            ),
          ],
          validator: _optionalPositiveValidator,
        );
      case 'land_warehouse':
        return _DynamicFieldGrid(
          fields: [
            _DynamicField(
              controller: _field1,
              label: context.tr('Chiều cao kho'),
              suffix: 'm',
              numeric: true,
            ),
            _DynamicField(
              controller: _field2,
              label: context.tr('Tải trọng sàn'),
              suffix: context.tr('tấn/m²'),
              numeric: true,
            ),
            _DynamicField(
              controller: _field3,
              label: context.tr('Đường vào'),
              suffix: 'm',
              numeric: true,
            ),
          ],
          validator: _optionalPositiveValidator,
        );
      case 'land_factory':
        return _DynamicFieldGrid(
          fields: [
            _DynamicField(
              controller: _field1,
              label: context.tr('Công suất điện'),
              suffix: 'KVA',
              numeric: true,
            ),
            _DynamicField(
              controller: _field2,
              label: context.tr('Tải trọng sàn'),
              suffix: context.tr('tấn/m²'),
              numeric: true,
            ),
          ],
          validator: _optionalPositiveValidator,
        );
      case 'land_business':
        return _DynamicFieldGrid(
          fields: [
            _DynamicField(
              controller: _field1,
              label: context.tr('Mặt tiền'),
              suffix: 'm',
              numeric: true,
            ),
            _DynamicField(
              controller: _field2,
              label: context.tr('Vỉa hè'),
              suffix: 'm',
              numeric: true,
            ),
            _DynamicField(
              controller: _field4,
              label: context.tr('Thời hạn thuê'),
              suffix: context.tr('tháng'),
              numeric: true,
              integer: true,
            ),
          ],
          validator: _optionalPositiveValidator,
        );
      case 'land_ground':
        return _DynamicFieldGrid(
          fields: [
            _DynamicField(
              controller: _field1,
              label: context.tr('Loại đất'),
              hint: context.tr('Đất ở, đất thương mại, đất sản xuất...'),
            ),
            _DynamicField(
              controller: _field2,
              label: context.tr('Mặt tiền'),
              suffix: 'm',
              numeric: true,
            ),
            _DynamicField(
              controller: _field3,
              label: context.tr('Đường vào'),
              suffix: 'm',
              numeric: true,
            ),
            _DynamicField(
              controller: _field4,
              label: context.tr('Pháp lý'),
            ),
            _DynamicField(
              controller: _field5,
              label: context.tr('Thời hạn thuê'),
              suffix: context.tr('tháng'),
              numeric: true,
              integer: true,
            ),
          ],
          validator: _optionalPositiveValidator,
        );
      case 'land_transfer':
        return _DynamicFieldGrid(
          fields: [
            _DynamicField(
              controller: _field1,
              label: context.tr('Giá sang nhượng'),
              hint: context.tr('Ví dụ: 300000000'),
              suffix: 'VNĐ',
              numeric: true,
            ),
            _DynamicField(
              controller: _field2,
              label: context.tr('Tài sản đi kèm'),
            ),
            _DynamicField(
              controller: _field3,
              label: context.tr('Hợp đồng còn lại'),
            ),
            _DynamicField(
              controller: _field4,
              label: context.tr('Lý do sang nhượng'),
            ),
          ],
          validator: _optionalPositiveValidator,
        );
      default:
        return Text(
          context.tr('Không có trường bổ sung cho loại bất động sản này.'),
        );
    }
  }

  Widget _buildHouseInformation(
    BuildContext context,
    PartnerFormLookups lookups,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('Thông tin phòng và hướng'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey('orientation-$_orientationCode'),
          initialValue: _orientationCode,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('Hướng'),
            prefixIcon: const Icon(Icons.explore_outlined),
          ),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(context.tr('Chưa chọn hướng')),
            ),
            ...lookups.orientations.map(
              (item) => DropdownMenuItem<String>(
                value: item.code,
                child: Text(item.name),
              ),
            ),
          ],
          onChanged: _submitting
              ? null
              : (value) => setState(() => _orientationCode = value ?? ''),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('Số lượng phòng'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (lookups.inforTags.isEmpty)
                  Text(context.tr('Chưa cập nhật danh mục phòng.'))
                else
                  ...lookups.inforTags.map((item) {
                    final selected = _selectedInforTags.containsKey(item.code);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selected,
                            onChanged: _submitting
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedInforTags[item.code] = 1;
                                      } else {
                                        _selectedInforTags.remove(item.code);
                                      }
                                    });
                                  },
                          ),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          SizedBox(
                            width: 82,
                            child: TextFormField(
                              key: ValueKey(
                                'qty-${item.code}-${_selectedInforTags[item.code]}',
                              ),
                              initialValue: selected
                                  ? '${_selectedInforTags[item.code] ?? 1}'
                                  : '',
                              enabled: selected && !_submitting,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: context.tr('Số lượng'),
                                isDense: true,
                              ),
                              validator: (value) {
                                if (!selected) return null;
                                final parsed = int.tryParse((value ?? '').trim());
                                return parsed == null || parsed <= 0
                                    ? context.tr('Không hợp lệ')
                                    : null;
                              },
                              onChanged: (value) {
                                final parsed = int.tryParse(value.trim());
                                if (parsed != null && parsed > 0) {
                                  _selectedInforTags[item.code] = parsed;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities(
    BuildContext context,
    PartnerFormLookups lookups,
  ) {
    final items = _isPremises
        ? lookups.premisesAmenities
            .where(
              (item) => item.propertyTypes.isEmpty ||
                  item.propertyTypes.contains(_propertyTypeCode),
            )
            .toList(growable: false)
        : lookups.amenities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(_isPremises ? 'Tiện ích mặt bằng' : 'Tiện ích / Nội thất'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(context.tr('Chưa cập nhật danh mục tiện ích.'))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final selected = _selectedAmenities.contains(item.code);
              return FilterChip(
                selected: selected,
                label: Text(item.name),
                avatar: Icon(
                  selected ? Icons.check_circle : Icons.add_circle_outline,
                  size: 18,
                ),
                onSelected: _submitting
                    ? null
                    : (value) {
                        setState(() {
                          if (value) {
                            _selectedAmenities.add(item.code);
                          } else {
                            _selectedAmenities.remove(item.code);
                          }
                        });
                      },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final existing = _activeExistingImages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: 0.32,
              ),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _submitting || _activeImageCount >= 12 ? null : _pickImages,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
              child: Column(
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 42,
                    color: AppTheme.primaryDark,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('Thêm ảnh bất động sản'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'Tối đa 12 ảnh. Chạm vào ảnh để chọn ảnh bìa.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_activeImageCount/12',
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (existing.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.tr('Ảnh hiện tại'),
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: existing.length,
            itemBuilder: (context, index) {
              final image = existing[index];
              final cover = _selectedExistingCoverImageId == image.imageId;
              return GestureDetector(
                onTap: _submitting
                    ? null
                    : () {
                        setState(() {
                          _selectedExistingCoverImageId = image.imageId;
                          _coverImageIndex = -1;
                        });
                      },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        image.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    if (cover) _coverBadge(context),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submitting
                            ? null
                            : () => _removeExistingImage(image.imageId),
                        icon: const Icon(Icons.close, size: 17),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.tr(_isEditing ? 'Ảnh mới' : 'Ảnh đã chọn'),
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              final cover = _selectedExistingCoverImageId == null &&
                  index == _coverImageIndex;
              return GestureDetector(
                onTap: _submitting
                    ? null
                    : () {
                        setState(() {
                          _selectedExistingCoverImageId = null;
                          _coverImageIndex = index;
                        });
                      },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(image.bytes, fit: BoxFit.cover),
                    ),
                    if (cover) _coverBadge(context),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submitting ? null : () => _removeImage(index),
                        icon: const Icon(Icons.close, size: 17),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _coverBadge(BuildContext context) {
    return Positioned(
      left: 5,
      bottom: 5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.navy.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          context.tr('Ảnh bìa'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Future<void> _changeCity(int cityId) async {
    setState(() {
      _cityId = cityId;
      _wardId = 0;
    });
    if (cityId <= 0) return;
    try {
      await AppScope.of(context).loadPartnerFormLookups(cityId: cityId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      final remaining = 12 - _activeImageCount;
      if (remaining <= 0) return;
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (picked.isEmpty) return;

      final accepted = picked.take(remaining);
      final loaded = <_PickedPartnerImage>[];
      for (final file in accepted) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) continue;
        loaded.add(_PickedPartnerImage(name: file.name, bytes: bytes));
      }
      if (!mounted || loaded.isEmpty) return;
      setState(() {
        final hadNoImages = _activeImageCount == 0;
        _images.addAll(loaded);
        if (hadNoImages ||
            (_selectedExistingCoverImageId == null && _coverImageIndex < 0)) {
          _selectedExistingCoverImageId = null;
          _coverImageIndex = 0;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('Không thể chọn ảnh')}: $error')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      final removedWasCover = _selectedExistingCoverImageId == null &&
          _coverImageIndex == index;
      _images.removeAt(index);
      if (_coverImageIndex > index) _coverImageIndex--;

      if (!removedWasCover) return;
      final existing = _activeExistingImages;
      if (existing.isNotEmpty) {
        _selectedExistingCoverImageId = existing.first.imageId;
        _coverImageIndex = -1;
      } else if (_images.isNotEmpty) {
        _selectedExistingCoverImageId = null;
        _coverImageIndex = 0;
      } else {
        _selectedExistingCoverImageId = null;
        _coverImageIndex = 0;
      }
    });
  }

  void _removeExistingImage(int imageId) {
    setState(() {
      _removedExistingImageIds.add(imageId);
      if (_selectedExistingCoverImageId != imageId) return;

      final existing = _activeExistingImages;
      if (existing.isNotEmpty) {
        _selectedExistingCoverImageId = existing.first.imageId;
        _coverImageIndex = -1;
      } else if (_images.isNotEmpty) {
        _selectedExistingCoverImageId = null;
        _coverImageIndex = 0;
      } else {
        _selectedExistingCoverImageId = null;
        _coverImageIndex = 0;
      }
    });
  }

  String? _requiredPositiveValidator(BuildContext context, String? value) {
    final number = _parseNumber(value);
    return number == null || number <= 0
        ? context.tr('Giá trị phải lớn hơn 0')
        : null;
  }

  String? _nonNegativeMoneyValidator(BuildContext context, String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final number = _parseMoney(value);
    return number == null || number < 0
        ? context.tr('Giá trị không hợp lệ')
        : null;
  }

  String _moneySeparator(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode.toLowerCase();
    return language == 'vi' ? '.' : ',';
  }

  String _pricePreviewText(BuildContext context, double amount) {
    if (amount <= 0) return context.tr('Giá thỏa thuận');

    final language = Localizations.localeOf(context).languageCode.toLowerCase();
    String text;
    if (language == 'zh') {
      if (amount < 10000) {
        text = _formatCompactNumber(amount, language);
      } else if (amount < 100000000) {
        text = '${_formatCompactNumber(amount / 10000, language)}万';
      } else {
        text = '${_formatCompactNumber(amount / 100000000, language)}亿';
      }
    } else if (amount < 1000) {
      text = _formatCompactNumber(amount, language);
    } else if (amount < 1000000) {
      text = '${_formatCompactNumber(amount / 1000, language)} '
          '${language == 'en' ? 'thousand' : 'nghìn'}';
    } else if (amount < 1000000000) {
      text = '${_formatCompactNumber(amount / 1000000, language)} '
          '${language == 'en' ? 'M' : 'triệu'}';
    } else {
      text = '${_formatCompactNumber(amount / 1000000000, language)} '
          '${language == 'en' ? 'B' : 'tỷ'}';
    }

    if (_isHouseRent || _isPremises) text += context.tr('/tháng');
    return text;
  }

  String _formatCompactNumber(double value, String language) {
    final truncated = (value * 1000).floor() / 1000;
    var text = truncated.toStringAsFixed(3);
    text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    if (language == 'vi') text = text.replaceAll('.', ',');
    return text;
  }

  static String _formatMoneyInput(double value) {
    if (value <= 0) return '';
    final digits = value.round().toString();
    return _groupDigits(digits, '.');
  }

  static String _formatPlainNumber(double value) {
    if (value <= 0) return '';
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _groupDigits(String digits, String separator) {
    final normalized = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < normalized.length; i++) {
      final remaining = normalized.length - i;
      buffer.write(normalized[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(separator);
    }
    return buffer.toString();
  }

  double? _parseMoney(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  String? _optionalPositiveValidator(
    BuildContext context,
    String? value,
    bool integer,
  ) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (integer) {
      final parsed = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
      return parsed == null || parsed <= 0
          ? context.tr('Giá trị phải là số nguyên dương')
          : null;
    }
    final parsed = _parseNumber(text);
    return parsed == null || parsed <= 0
        ? context.tr('Giá trị phải lớn hơn 0')
        : null;
  }

  double? _parseNumber(String? raw) {
    var value = (raw ?? '').trim().replaceAll(' ', '');
    if (value.isEmpty) return null;
    if (value.contains(',') && value.contains('.')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else {
      value = value.replaceAll(',', '.');
    }
    return double.tryParse(value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final imagePayloads = <PartnerImagePayload>[];
    for (var i = 0; i < _images.length; i++) {
      imagePayloads.add(
        PartnerImagePayload(
          fileName: _images[i].name,
          base64Data: base64Encode(_images[i].bytes),
          sortOrder: i + 1,
          isCover: _selectedExistingCoverImageId == null &&
              i == _coverImageIndex,
        ),
      );
    }

    final request = PartnerPropertyCreateRequest(
      listingType: widget.kind.code,
      propertyType: widget.propertyType.code,
      cityId: _cityId,
      wardId: _wardId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      newAddressDetail: _addressDetail.text.trim(),
      useOldAddressDisplay: _useOldAddress,
      oldAddressLine: _oldAddress.text.trim(),
      price: _parseMoney(_price.text) ?? 0,
      areaSqm: _parseNumber(_area.text) ?? 0,
      orientationCode: _isHouse ? _orientationCode : '',
      moveInStatus: _isHouseRent ? _moveInStatus.text.trim() : '',
      viewingNote: _viewingNote.text.trim(),
      saleFrontage: _field1.text.trim(),
      saleRoadWidth: _field2.text.trim(),
      saleLegalInfo: _field3.text.trim(),
      floorInfo: _field5.text.trim(),
      waterInfo: _water.text.trim(),
      electricityInfo: _electricity.text.trim(),
      leaseTerm: _field4.text.trim(),
      amenities: _selectedAmenities.toList(growable: false),
      inforTags: _selectedInforTags.entries
          .map(
            (entry) => PartnerInforTagValue(
              code: entry.key,
              quantity: entry.value,
            ),
          )
          .toList(growable: false),
      images: imagePayloads,
      existingCoverImageId: _selectedExistingCoverImageId,
      removeImageIds: _removedExistingImageIds.toList(growable: false),
    );

    try {
      final store = AppScope.of(context);
      final result = _isEditing
          ? await store.updatePartnerProperty(
              widget.initialData!.propertyId,
              request,
            )
          : await store.createPartnerProperty(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() => _submitting = false);
    }
  }
}


class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const _ThousandsSeparatorInputFormatter({required this.separator});

  final String separator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(separator);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PickedPartnerImage {
  const _PickedPartnerImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class _SelectedTypeSummary extends StatelessWidget {
  const _SelectedTypeSummary({required this.kind, required this.propertyType});

  final ListingKind kind;
  final PartnerLookupItem propertyType;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.home_work_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(kind.label),
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    propertyType.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _DynamicField {
  const _DynamicField({
    required this.controller,
    required this.label,
    this.hint,
    this.suffix,
    this.numeric = false,
    this.integer = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final bool numeric;
  final bool integer;
}

class _DynamicFieldGrid extends StatelessWidget {
  const _DynamicFieldGrid({required this.fields, required this.validator});

  final List<_DynamicField> fields;
  final String? Function(BuildContext context, String? value, bool integer)
      validator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                _buildField(context, fields[i]),
                if (i < fields.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < fields.length; i += 2) {
          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < fields.length ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildField(context, fields[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < fields.length
                        ? _buildField(context, fields[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  Widget _buildField(BuildContext context, _DynamicField field) {
    return TextFormField(
      controller: field.controller,
      keyboardType: field.numeric
          ? TextInputType.numberWithOptions(decimal: !field.integer)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        suffixText: field.suffix,
      ),
      validator: field.numeric
          ? (value) => validator(context, value, field.integer)
          : null,
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppTheme.primary,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            context.tr(title),
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
