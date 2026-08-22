import 'dart:convert';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../models/partner_models.dart';
import '../../models/auth_models.dart';
import '../../models/commerce_models.dart';
import 'api_transport.dart';
import 'api_transport_factory.dart';

class PartnerPropertiesFetchResult {
  const PartnerPropertiesFetchResult({
    this.items = const <PropertyModel>[],
    this.activeTopCount = 0,
  });

  final List<PropertyModel> items;
  final int activeTopCount;
}

class NhaWowApiService {
  NhaWowApiService({ApiTransport? transport})
      : _transport = transport ?? createApiTransport();

  final ApiTransport _transport;
  String _authToken = '';

  void setAuthToken(String token) {
    _authToken = token.trim();
  }

  Map<String, String> get _authHeaders => _authToken.isEmpty
      ? const <String, String>{}
      : <String, String>{'Authorization': 'Bearer $_authToken'};

  Future<AuthSessionModel> login({
    required String loginName,
    required String password,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/login', {'lang': language}),
      <String, dynamic>{
        'loginName': loginName,
        'password': password,
      },
      authenticated: false,
    );
    return AuthSessionModel.fromJson(_asMap(root['data']));
  }

  Future<RegistrationResult> register({
    required String displayName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required bool isBroker,
    String avatarFileName = '',
    String avatarBase64Data = '',
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/register', {'lang': language}),
      <String, dynamic>{
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
        'isBroker': isBroker,
        'avatarFileName': avatarFileName,
        'avatarBase64Data': avatarBase64Data,
      },
      authenticated: false,
    );
    final data = _asMap(root['data']);
    final rawSeconds = data['otpExpireSeconds'];
    return RegistrationResult(
      email: (data['email'] ?? email).toString(),
      needVerify: data['needVerify'] == true,
      otpExpireSeconds: rawSeconds is num
          ? rawSeconds.toInt()
          : int.tryParse('$rawSeconds') ?? 0,
      message: (root['message'] ?? '').toString(),
    );
  }

  Future<AuthSessionModel> verifyEmailOtp({
    required String email,
    required String code,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/verify-email', {'lang': language}),
      <String, dynamic>{'email': email, 'code': code},
      authenticated: false,
    );
    return AuthSessionModel.fromJson(_asMap(root['data']));
  }

  Future<int> resendVerifyOtp({
    required String email,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/resend-otp', {'lang': language}),
      <String, dynamic>{'email': email},
      authenticated: false,
    );
    final data = _asMap(root['data']);
    final raw = data['otpExpireSeconds'];
    return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
  }

  Future<int> sendResetOtp({
    required String email,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/send-reset-otp', {'lang': language}),
      <String, dynamic>{'email': email},
      authenticated: false,
    );
    final data = _asMap(root['data']);
    final raw = data['otpExpireSeconds'];
    return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/reset-password', {'lang': language}),
      <String, dynamic>{
        'email': email,
        'code': code,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      authenticated: false,
    );
    return (root['message'] ?? '').toString();
  }

  Future<AuthUserModel> fetchCurrentUser({required String language}) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/auth/me', {'lang': language}),
    );
    return AuthUserModel.fromJson(_asMap(root['data']));
  }

  Future<AuthSessionModel> updateProfile({
    required String displayName,
    required String email,
    required String phoneNumber,
    required bool isBroker,
    String avatarFileName = '',
    String avatarBase64Data = '',
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/profile', {'lang': language}),
      <String, dynamic>{
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'isBroker': isBroker,
        'avatarFileName': avatarFileName,
        'avatarBase64Data': avatarBase64Data,
      },
    );
    return AuthSessionModel.fromJson(_asMap(root['data']));
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/change-password', {'lang': language}),
      <String, dynamic>{
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    return (root['message'] ?? '').toString();
  }

  Future<AuthSessionModel> enablePostingPermission({
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/auth/post-permission', {'lang': language}),
      const <String, dynamic>{},
    );
    return AuthSessionModel.fromJson(_asMap(root['data']));
  }

  Future<void> logout({required String language}) async {
    if (_authToken.isNotEmpty) {
      await _postEnvelope(
        AppConfig.buildApiUri('/auth/logout', {'lang': language}),
        const <String, dynamic>{},
      );
    }
  }

  Future<String> submitLandlordRequest({
    required String guestName,
    required String guestPhone,
    required String propertyAddress,
    required String customerNotes,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/landlord/request', {'lang': language}),
      <String, dynamic>{
        'guestName': guestName,
        'guestPhone': guestPhone,
        'propertyAddress': propertyAddress,
        'customerNotes': customerNotes,
      },
      authenticated: false,
    );
    final data = _asMap(root['data']);
    return (data['message'] ?? root['message'] ?? '').toString();
  }

  Future<FavoriteToggleModel> toggleFavorite({
    required int propertyId,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/favorites/toggle', {'lang': language}),
      <String, dynamic>{'propertyId': propertyId},
    );
    final data = _asMap(root['data']);
    final ids = data['favoriteIds'] is List
        ? (data['favoriteIds'] as List)
            .map((item) => item is num ? item.toInt() : int.tryParse('$item') ?? 0)
            .where((item) => item > 0)
            .toList(growable: false)
        : const <int>[];
    return FavoriteToggleModel(
      isFavorite: data['isFavorite'] == true,
      favoriteIds: ids,
    );
  }

  Future<PartnerPropertiesFetchResult> fetchPartnerProperties({
    required String language,
    int? cityId,
    int? wardId,
    String status = 'all',
    String featureCode = '',
  }) async {
    final uri = AppConfig.buildApiUri('/partner/properties', {
      'cityId': cityId?.toString(),
      'wardId': wardId?.toString(),
      'status': status,
      'feature': featureCode.trim().isEmpty ? null : featureCode.trim(),
      'lang': language,
    });
    final root = await _getEnvelope(uri);
    final data = _asMap(root['data']);
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => PropertyModel.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0)
            .toList(growable: false)
        : const <PropertyModel>[];
    final rawActiveTopCount = data['activeTopCount'];
    final activeTopCount = rawActiveTopCount is num
        ? rawActiveTopCount.toInt()
        : int.tryParse(rawActiveTopCount?.toString() ?? '') ?? 0;
    return PartnerPropertiesFetchResult(
      items: items,
      activeTopCount: activeTopCount,
    );
  }

  Future<String> closePartnerProperty({
    required int propertyId,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/partner/properties/$propertyId/close', {
        'lang': language,
      }),
      const <String, dynamic>{},
    );
    final data = _asMap(root['data']);
    final message = (data['message'] ?? root['message'] ?? '').toString().trim();
    return message.isEmpty ? 'Đã đóng tin.' : message;
  }

  Future<String> reopenPartnerProperty({
    required int propertyId,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/partner/properties/$propertyId/reopen', {
        'lang': language,
      }),
      const <String, dynamic>{},
    );
    final data = _asMap(root['data']);
    final message = (data['message'] ?? root['message'] ?? '').toString().trim();
    return message.isEmpty ? 'Đã mở lại tin.' : message;
  }

  Future<PartnerPropertyEditData> fetchPartnerPropertyForEdit({
    required int propertyId,
    required String language,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/partner/properties/$propertyId/edit', {
        'lang': language,
      }),
    );
    return PartnerPropertyEditData.fromJson(_asMap(root['data']));
  }

  Future<PartnerFormLookups> fetchPartnerFormLookups({
    required String language,
    int? cityId,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/partner/form-lookups', {
        'cityId': cityId?.toString(),
        'lang': language,
      }),
    );
    final remote = PartnerFormLookups.fromJson(_asMap(root['data']));

    // Hỗ trợ cả backend cũ từng trả Id/Code/Name dạng PascalCase và
    // database chưa đủ danh mục. Khi danh mục Partner thiếu, lấy thêm
    // dữ liệu từ endpoint public /lookups rồi bổ sung các loại chuẩn của web.
    var publicLookups = const ApiLookups();
    if (remote.cities.isEmpty ||
        remote.propertyTypes.isEmpty ||
        (cityId != null && cityId > 0 && remote.wards.isEmpty)) {
      try {
        publicLookups = await fetchLookups(
          language: language,
          cityId: cityId,
        );
      } catch (_) {
        // Danh mục fallback cứng bên dưới vẫn giúp luồng chọn loại tin hoạt động.
      }
    }

    return _completePartnerFormLookups(
      remote,
      publicLookups,
      language,
    );
  }

  PartnerFormLookups _completePartnerFormLookups(
    PartnerFormLookups remote,
    ApiLookups publicLookups,
    String language,
  ) {
    final cities = <PartnerLookupItem>[...remote.cities];
    final wards = <PartnerLookupItem>[...remote.wards];
    final propertyTypes = <PartnerLookupItem>[];

    bool containsLookup(
      List<PartnerLookupItem> items,
      PartnerLookupItem candidate,
    ) {
      if (candidate.id > 0 && items.any((item) => item.id == candidate.id)) {
        return true;
      }
      final code = candidate.code.trim().toLowerCase();
      return code.isNotEmpty &&
          items.any((item) => item.code.trim().toLowerCase() == code);
    }

    void addUnique(
      List<PartnerLookupItem> items,
      PartnerLookupItem candidate,
    ) {
      if ((candidate.name.isEmpty && candidate.code.isEmpty) ||
          containsLookup(items, candidate)) {
        return;
      }
      items.add(candidate);
    }

    for (final item in publicLookups.cities) {
      addUnique(
        cities,
        PartnerLookupItem(
          id: item.id,
          code: item.code,
          name: item.name,
          cityId: item.cityId,
        ),
      );
    }
    for (final item in publicLookups.wards) {
      addUnique(
        wards,
        PartnerLookupItem(
          id: item.id,
          code: item.code,
          name: item.name,
          cityId: item.cityId,
        ),
      );
    }

    PartnerLookupItem normalizePropertyType(PartnerLookupItem item) {
      final code = item.code.trim().toLowerCase();
      final premises = _isPremisesPropertyTypeCode(code);
      final land = premises || code.startsWith('land_') || code == 'land';
      return PartnerLookupItem(
        id: item.id,
        code: code,
        name: item.name,
        cityId: item.cityId,
        category: item.category.isNotEmpty
            ? item.category
            : (land ? 'land' : 'house'),
        listingMode: item.listingMode.isNotEmpty
            ? item.listingMode
            : (premises ? 'rent' : (land ? 'sale' : 'both')),
        iconUrl: item.iconUrl,
        propertyTypes: item.propertyTypes,
      );
    }

    for (final item in remote.propertyTypes) {
      addUnique(propertyTypes, normalizePropertyType(item));
    }
    for (final item in publicLookups.propertyTypes) {
      addUnique(
        propertyTypes,
        normalizePropertyType(
          PartnerLookupItem(
            id: item.id,
            code: item.code,
            name: item.name,
            cityId: item.cityId,
          ),
        ),
      );
    }

    for (final item in _partnerPropertyTypeFallbacks(language)) {
      addUnique(propertyTypes, item);
    }

    final statuses = remote.statuses.isNotEmpty
        ? remote.statuses
        : _partnerStatusFallbacks(language);

    return PartnerFormLookups(
      cities: cities,
      wards: wards,
      propertyTypes: propertyTypes,
      amenities: remote.amenities,
      premisesAmenities: remote.premisesAmenities,
      inforTags: remote.inforTags,
      orientations: remote.orientations,
      statuses: statuses,
    );
  }

  bool _isPremisesPropertyTypeCode(String code) {
    switch (code.trim().toLowerCase()) {
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

  List<PartnerLookupItem> _partnerPropertyTypeFallbacks(String language) {
    String text(String vi, String en, String zh) {
      final normalized = language.trim().toLowerCase();
      if (normalized.startsWith('en')) return en;
      if (normalized.startsWith('zh')) return zh;
      return vi;
    }

    PartnerLookupItem item(
      String code,
      String vi,
      String en,
      String zh,
      String category,
      String listingMode,
    ) {
      return PartnerLookupItem(
        id: 0,
        code: code,
        name: text(vi, en, zh),
        category: category,
        listingMode: listingMode,
      );
    }

    return <PartnerLookupItem>[
      item('apartment', 'Căn hộ', 'Apartment', '公寓', 'house', 'both'),
      item('house', 'Nhà riêng', 'House', '独栋房屋', 'house', 'both'),
      item('villa', 'Biệt thự', 'Villa', '别墅', 'house', 'both'),
      item('office', 'Văn phòng', 'Office', '办公室', 'house', 'both'),
      item('studio', 'Studio', 'Studio', '单间', 'house', 'both'),
      item(
        'land_residential',
        'Đất thổ cư',
        'Residential land',
        '住宅用地',
        'land',
        'sale',
      ),
      item(
        'land_project',
        'Đất dự án',
        'Project land',
        '项目用地',
        'land',
        'sale',
      ),
      item('land_office', 'Văn phòng', 'Office', '办公室', 'land', 'rent'),
      item('land_warehouse', 'Kho bãi', 'Warehouse', '仓库', 'land', 'rent'),
      item('land_factory', 'Nhà xưởng', 'Factory', '厂房', 'land', 'rent'),
      item(
        'land_ground',
        'Mặt bằng đất',
        'Land premises',
        '土地场地',
        'land',
        'rent',
      ),
      item(
        'land_business',
        'Mặt bằng kinh doanh',
        'Business premises',
        '经营场地',
        'land',
        'rent',
      ),
      item(
        'land_transfer',
        'Sang nhượng',
        'Business transfer',
        '转让',
        'land',
        'rent',
      ),
    ];
  }

  List<PartnerLookupItem> _partnerStatusFallbacks(String language) {
    String text(String vi, String en, String zh) {
      final normalized = language.trim().toLowerCase();
      if (normalized.startsWith('en')) return en;
      if (normalized.startsWith('zh')) return zh;
      return vi;
    }

    return <PartnerLookupItem>[
      PartnerLookupItem(
        id: 0,
        code: 'all',
        name: text('Tất cả trạng thái', 'All statuses', '全部状态'),
      ),
      PartnerLookupItem(
        id: 0,
        code: 'pendingapproval',
        name: text('Chờ duyệt', 'Pending approval', '待审核'),
      ),
      PartnerLookupItem(
        id: 0,
        code: 'published',
        name: text('Đang hiển thị', 'Published', '展示中'),
      ),
      PartnerLookupItem(
        id: 0,
        code: 'draft',
        name: text('Bản nháp', 'Draft', '草稿'),
      ),
      PartnerLookupItem(
        id: 0,
        code: 'rejected',
        name: text('Từ chối', 'Rejected', '已拒绝'),
      ),
      PartnerLookupItem(
        id: 0,
        code: 'rented',
        name: text('Đã cho thuê', 'Rented', '已出租'),
      ),
      PartnerLookupItem(
        id: 0,
        code: 'sold',
        name: text('Đã bán', 'Sold', '已售出'),
      ),
      PartnerLookupItem(
        id: 0,
        code: 'closed',
        name: text('Đã đóng', 'Closed', '已关闭'),
      ),
    ];
  }

  Future<PartnerPropertyCreateResult> updatePartnerProperty({
    required int propertyId,
    required PartnerPropertyCreateRequest request,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/partner/properties/$propertyId/update', {
        'lang': language,
      }),
      request.toJson(),
    );
    return PartnerPropertyCreateResult.fromJson(_asMap(root['data']));
  }

  Future<PartnerPropertyCreateResult> createPartnerProperty({
    required PartnerPropertyCreateRequest request,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/partner/properties/create', {'lang': language}),
      request.toJson(),
    );
    return PartnerPropertyCreateResult.fromJson(_asMap(root['data']));
  }

  Future<List<PropertyModel>> fetchProperties({
    required String language,
    ListingKind? kind,
    String keyword = '',
    int? cityId,
    int? wardId,
    String propertyType = '',
    String priceRange = '',
    String sortBy = 'newest',
    int page = 1,
    int pageSize = 50,
  }) async {
    final uri = AppConfig.buildApiUri('/properties', {
      'listingType': kind?.code,
      'assetCategory': kind == null ? null : (kind.isLand ? 'land' : 'house'),
      'keyword': keyword,
      'cityId': cityId?.toString(),
      'wardId': wardId?.toString(),
      'propertyType': propertyType,
      'priceRange': priceRange,
      'sortBy': sortBy,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'lang': language,
    });

    final root = await _getEnvelope(uri);
    final data = _asMap(root['data']);
    final items = data['items'];
    if (items is! List) return const <PropertyModel>[];

    return items
        .whereType<Map>()
        .map((item) => PropertyModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<AgentProfileModel> fetchAgentProfile(
    int agentId, {
    required String language,
    int page = 1,
    int pageSize = 50,
  }) async {
    final uri = AppConfig.buildApiUri('/agents/$agentId', {
      'lang': language,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
    final root = await _getEnvelope(uri);
    return AgentProfileModel.fromJson(_asMap(root['data']));
  }

  Future<PropertyModel> fetchPropertyDetail(
    int id, {
    required String language,
  }) async {
    final uri = AppConfig.buildApiUri('/properties/$id', {
      'lang': language,
    });
    final root = await _getEnvelope(uri);
    final data = _asMap(root['data']);
    return PropertyModel.fromJson(data);
  }

  /// Lấy tour VR native (scene + hotspot) trực tiếp từ Mobile API.
  /// Android/iOS không cần mở trang /Property/Vr/{id} của website.
  Future<VrTourModel> fetchPropertyVr(
    int id, {
    required String language,
  }) async {
    final uri = AppConfig.buildApiUri('/properties/$id/vr', {
      'lang': language,
    });
    final root = await _getEnvelope(uri);
    return VrTourModel.fromJson(_asMap(root['data']));
  }

  Future<GeocodeResult?> geocodeAddress(
    String address, {
    required String language,
  }) async {
    final normalizedAddress = address.trim();
    if (normalizedAddress.isEmpty) return null;

    final uri = AppConfig.buildApiUri('/geocode', {
      'address': normalizedAddress,
      'lang': language,
    });
    final root = await _getEnvelope(uri);
    final data = _asMap(root['data']);
    if (data['found'] != true) return null;

    final latitude = _toNullableDouble(data['latitude']);
    final longitude = _toNullableDouble(data['longitude']);
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return GeocodeResult(
      latitude: latitude,
      longitude: longitude,
      displayName: (data['displayName'] ?? normalizedAddress).toString(),
      renderMode: (data['renderMode'] ?? 'point').toString(),
      boundsNorth: _toNullableDouble(data['boundsNorth']),
      boundsSouth: _toNullableDouble(data['boundsSouth']),
      boundsEast: _toNullableDouble(data['boundsEast']),
      boundsWest: _toNullableDouble(data['boundsWest']),
      polygon: _parseMapPoints(data['polygon']),
    );
  }

  List<MapPointModel> _parseMapPoints(Object? value) {
    if (value is! List) return const <MapPointModel>[];

    final result = <MapPointModel>[];
    for (final item in value) {
      double? latitude;
      double? longitude;

      if (item is List && item.length >= 2) {
        latitude = _toNullableDouble(item[0]);
        longitude = _toNullableDouble(item[1]);
      } else if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        latitude = _toNullableDouble(map['latitude'] ?? map['lat']);
        longitude = _toNullableDouble(
          map['longitude'] ?? map['lng'] ?? map['lon'],
        );
      }

      if (latitude == null ||
          longitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }

      result.add(
        MapPointModel(latitude: latitude, longitude: longitude),
      );
    }

    return result;
  }

  double? _toNullableDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> registerPushToken({
    required String token,
    required String platform,
    required String language,
  }) async {
    await _postEnvelope(
      AppConfig.buildApiUri('/push/register', {'lang': language}),
      <String, dynamic>{
        'token': token.trim(),
        'platform': platform.trim().toLowerCase(),
      },
    );
  }

  Future<void> unregisterPushToken({
    required String token,
    required String platform,
    required String language,
  }) async {
    await _postEnvelope(
      AppConfig.buildApiUri('/push/unregister', {'lang': language}),
      <String, dynamic>{
        'token': token.trim(),
        'platform': platform.trim().toLowerCase(),
      },
    );
  }

  Future<List<NotificationModel>> fetchNotifications({
    required String language,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/notifications', {'lang': language}),
    );
    final data = _asMap(root['data']);
    final rawItems = data['items'];
    if (rawItems is! List) return const <NotificationModel>[];
    return rawItems
        .whereType<Map>()
        .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<int> fetchUnreadNotificationCount({
    required String language,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/notifications/summary', {'lang': language}),
    );
    final data = _asMap(root['data']);
    final raw = data['unread'];
    return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
  }

  Future<int> markNotificationRead({
    required int notificationId,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/notifications/read', {'lang': language}),
      <String, dynamic>{'id': notificationId},
    );
    final data = _asMap(root['data']);
    final raw = data['unread'];
    return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
  }

  Future<void> markAllNotificationsRead({required String language}) async {
    await _postEnvelope(
      AppConfig.buildApiUri('/notifications/read-all', {'lang': language}),
      const <String, dynamic>{},
    );
  }

  Future<MembershipOverviewModel> fetchMembershipOverview({
    required String language,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/membership', {'lang': language}),
    );
    return MembershipOverviewModel.fromJson(_asMap(root['data']));
  }

  Future<MembershipPurchaseResult> buyMembership({
    required String planCode,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/membership/buy', {'lang': language}),
      <String, dynamic>{'planCode': planCode},
    );
    final data = _asMap(root['data']);
    final usageRaw = data['usage'];
    final activeRaw = data['activeMembership'];
    return MembershipPurchaseResult(
      message: (root['message'] ?? '').toString(),
      usage: usageRaw is Map
          ? MembershipUsageModel.fromJson(Map<String, dynamic>.from(usageRaw))
          : const MembershipUsageModel(),
      activeMembership: activeRaw is Map
          ? ActiveMembershipModel.fromJson(Map<String, dynamic>.from(activeRaw))
          : null,
    );
  }

  Future<AddonFeaturePurchaseResult> buyAddonFeature({
    required int propertyId,
    required String featureCode,
    required bool useFreeTopBenefit,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/membership/buy-feature', {'lang': language}),
      <String, dynamic>{
        'propertyId': propertyId,
        'featureCode': featureCode,
        'useFreeTopBenefit': useFreeTopBenefit,
      },
    );
    final data = _asMap(root['data']);
    final usageRaw = data['usage'];
    final rawPropertyId = data['propertyId'];
    return AddonFeaturePurchaseResult(
      message: (root['message'] ?? '').toString(),
      usage: usageRaw is Map
          ? MembershipUsageModel.fromJson(Map<String, dynamic>.from(usageRaw))
          : const MembershipUsageModel(),
      propertyId: rawPropertyId is num
          ? rawPropertyId.toInt()
          : int.tryParse(rawPropertyId?.toString() ?? '') ?? 0,
      featureCode: (data['featureCode'] ?? '').toString(),
      expiresAtUtc: parseApiDate(data['expiresAtUtc']),
    );
  }

  Future<WalletOverviewModel> fetchWalletOverview({
    required String language,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/wallet', {'lang': language}),
    );
    return WalletOverviewModel.fromJson(_asMap(root['data']));
  }

  Future<WalletTopupCheckoutModel> createWalletTopup({
    required double amount,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/wallet/topup', {'lang': language}),
      <String, dynamic>{'amount': amount.round()},
    );
    return WalletTopupCheckoutModel.fromJson(
      _asMap(root['data']),
      message: (root['message'] ?? '').toString(),
    );
  }

  Future<WalletTopupStatusModel> fetchWalletTopupStatus({
    required int topupId,
    required String language,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/wallet/topup-status', {
        'id': topupId.toString(),
        'lang': language,
      }),
    );
    return WalletTopupStatusModel.fromJson(_asMap(root['data']));
  }

  Future<String> cancelWalletTopup({
    required int topupId,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/wallet/cancel-topup', {'lang': language}),
      <String, dynamic>{'id': topupId},
    );
    return (root['message'] ?? '').toString();
  }

  Future<List<ConversationModel>> fetchChatConversations({
    required String language,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/chat/conversations', {'lang': language}),
    );
    final data = _asMap(root['data']);
    final rawItems = data['items'];
    if (rawItems is! List) return const <ConversationModel>[];
    return rawItems
        .whereType<Map>()
        .map((item) => ConversationModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<ChatMessageModel>> fetchChatMessages({
    required int conversationId,
    required String language,
  }) async {
    final root = await _getEnvelope(
      AppConfig.buildApiUri('/chat/messages', {
        'id': conversationId.toString(),
        'lang': language,
      }),
    );
    final data = _asMap(root['data']);
    final rawItems = data['items'];
    if (rawItems is! List) return const <ChatMessageModel>[];
    return rawItems
        .whereType<Map>()
        .map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<int> startChatConversation({
    int? propertyId,
    int? agentId,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/chat/start', {'lang': language}),
      <String, dynamic>{
        'propertyId': propertyId,
        'agentId': agentId,
      },
    );
    final data = _asMap(root['data']);
    final raw = data['conversationId'];
    return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
  }

  Future<List<ChatMessageModel>> sendChatMessage({
    required int conversationId,
    required String message,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/chat/send', {'lang': language}),
      <String, dynamic>{
        'conversationId': conversationId,
        'message': message,
      },
    );
    final data = _asMap(root['data']);
    final rawItems = data['items'];
    if (rawItems is! List) return const <ChatMessageModel>[];
    return rawItems
        .whereType<Map>()
        .map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<ChatMessageModel>> sendChatImage({
    required int conversationId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
    required String language,
  }) async {
    final root = await _postMultipartEnvelope(
      AppConfig.buildApiUri('/chat/send-image', {'lang': language}),
      fields: <String, String>{
        'conversationId': conversationId.toString(),
      },
      files: <ApiMultipartFile>[
        ApiMultipartFile(
          fieldName: 'image',
          fileName: fileName,
          bytes: bytes,
          contentType: contentType,
        ),
      ],
    );
    final data = _asMap(root['data']);
    final rawItems = data['items'];
    if (rawItems is! List) return const <ChatMessageModel>[];
    return rawItems
        .whereType<Map>()
        .map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<int> recallChatMessage({
    required int messageId,
    required String language,
  }) async {
    final root = await _postEnvelope(
      AppConfig.buildApiUri('/chat/recall', {'lang': language}),
      <String, dynamic>{'messageId': messageId},
    );
    final data = _asMap(root['data']);
    final raw = data['messageId'];
    return raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
  }

  Future<void> markChatRead({
    required int conversationId,
    required String language,
  }) async {
    await _postEnvelope(
      AppConfig.buildApiUri('/chat/read', {'lang': language}),
      <String, dynamic>{'conversationId': conversationId},
    );
  }

  Future<void> setChatPinned({
    required int conversationId,
    required bool value,
    required String language,
  }) async {
    await _postEnvelope(
      AppConfig.buildApiUri('/chat/pin', {'lang': language}),
      <String, dynamic>{
        'conversationId': conversationId,
        'value': value,
      },
    );
  }

  Future<void> setChatFlagged({
    required int conversationId,
    required bool value,
    required String language,
  }) async {
    await _postEnvelope(
      AppConfig.buildApiUri('/chat/flag', {'lang': language}),
      <String, dynamic>{
        'conversationId': conversationId,
        'value': value,
      },
    );
  }

  Future<void> deleteChatConversation({
    required int conversationId,
    required String language,
  }) async {
    await _postEnvelope(
      AppConfig.buildApiUri('/chat/delete', {'lang': language}),
      <String, dynamic>{'conversationId': conversationId},
    );
  }

  Future<ApiLookups> fetchLookups({
    required String language,
    int? cityId,
  }) async {
    final uri = AppConfig.buildApiUri('/lookups', {
      'cityId': cityId?.toString(),
      'lang': language,
    });
    final root = await _getEnvelope(uri);
    return ApiLookups.fromJson(_asMap(root['data']));
  }

  Future<Map<String, dynamic>> _getEnvelope(Uri uri) async {
    final body = await _transport.get(uri, headers: _authHeaders);
    return _decodeEnvelope(body);
  }

  Future<Map<String, dynamic>> _postEnvelope(
    Uri uri,
    Map<String, dynamic> payload, {
    bool authenticated = true,
  }) async {
    final body = await _transport.post(
      uri,
      headers: authenticated ? _authHeaders : const <String, String>{},
      body: jsonEncode(payload),
    );
    return _decodeEnvelope(body);
  }

  Future<Map<String, dynamic>> _postMultipartEnvelope(
    Uri uri, {
    Map<String, String> fields = const <String, String>{},
    List<ApiMultipartFile> files = const <ApiMultipartFile>[],
    bool authenticated = true,
  }) async {
    final body = await _transport.postMultipart(
      uri,
      headers: authenticated ? _authHeaders : const <String, String>{},
      fields: fields,
      files: files,
    );
    return _decodeEnvelope(body);
  }

  Map<String, dynamic> _decodeEnvelope(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const ApiTransportException('Máy chủ trả về dữ liệu JSON không hợp lệ.');
    }

    final root = _asMap(decoded);
    if (root['success'] != true) {
      final errors = root['errors'];
      String? code;
      if (errors is List && errors.isNotEmpty && errors.first is Map) {
        code = Map<String, dynamic>.from(errors.first as Map)['code']?.toString();
      }
      throw ApiTransportException(
        (root['message'] ?? 'Máy chủ không thể xử lý yêu cầu.').toString(),
        code: code,
        data: _asMap(root['data']),
      );
    }
    return root;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}

class GeocodeResult {
  const GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.renderMode = 'point',
    this.boundsNorth,
    this.boundsSouth,
    this.boundsEast,
    this.boundsWest,
    this.polygon = const <MapPointModel>[],
  });

  final double latitude;
  final double longitude;
  final String displayName;
  final String renderMode;
  final double? boundsNorth;
  final double? boundsSouth;
  final double? boundsEast;
  final double? boundsWest;
  final List<MapPointModel> polygon;
}

class LookupItem {
  const LookupItem({
    required this.id,
    required this.code,
    required this.name,
    this.cityId,
  });

  final int id;
  final String code;
  final String name;
  final int? cityId;

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawCityId = json['cityId'];
    return LookupItem(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      cityId: rawCityId is num
          ? rawCityId.toInt()
          : int.tryParse('${rawCityId ?? ''}'),
    );
  }
}

class ApiLookups {
  const ApiLookups({
    this.cities = const <LookupItem>[],
    this.wards = const <LookupItem>[],
    this.propertyTypes = const <LookupItem>[],
    this.priceFilters = const <LookupItem>[],
  });

  final List<LookupItem> cities;
  final List<LookupItem> wards;
  final List<LookupItem> propertyTypes;
  final List<LookupItem> priceFilters;

  factory ApiLookups.fromJson(Map<String, dynamic> json) {
    List<LookupItem> parse(Object? value) {
      if (value is! List) return const <LookupItem>[];
      return value
          .whereType<Map>()
          .map((item) => LookupItem.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id > 0 && item.name.isNotEmpty)
          .toList(growable: false);
    }

    return ApiLookups(
      cities: parse(json['cities']),
      wards: parse(json['wards']),
      propertyTypes: parse(json['propertyTypes']),
      priceFilters: parse(json['priceFilters']),
    );
  }
}
