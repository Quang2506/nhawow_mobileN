import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../l10n/app_language.dart';
import '../data/remote/api_transport.dart';
import '../data/remote/nhawow_api_service.dart';
import '../models/models.dart';
import '../models/auth_models.dart';
import '../models/partner_models.dart';

class AppStore extends ChangeNotifier {
  AppStore()
      : _properties = <PropertyModel>[],
        _conversations = <ConversationModel>[],
        _notifications = [...mockNotifications],
        _transactions = [...mockTransactions];

  final List<PropertyModel> _properties;
  final List<PropertyModel> _partnerProperties = <PropertyModel>[];
  final List<ConversationModel> _conversations;
  final List<NotificationModel> _notifications;
  final List<WalletTransactionModel> _transactions;
  static const int _homePageSize = 8;
  static const String _languagePreferenceKey = 'nhawow.language';
  static const String _authTokenPreferenceKey = 'nhawow.auth_token';

  final NhaWowApiService _api = NhaWowApiService();
  final Map<int, String> _loadingDetailLanguages = <int, String>{};
  final Set<ListingKind> _loadingMoreKinds = <ListingKind>{};
  final Map<ListingKind, int> _loadedPages = <ListingKind, int>{
    for (final kind in ListingKind.values) kind: 0,
  };
  final Map<ListingKind, bool> _hasMoreByKind = <ListingKind, bool>{
    for (final kind in ListingKind.values) kind: true,
  };

  String _authToken = '';
  AuthUserModel? _authUser;
  bool _isAuthenticating = false;
  String? _authError;
  bool _isInitializing = false;
  bool _isBootstrapComplete = false;
  bool _hasLanguagePreference = false;
  AppLanguage _language = AppLanguage.vietnamese;
  int _selectedTab = 0;
  int _refreshGeneration = 0;
  double _walletBalance = 102000;
  String _membershipCode = 'FREE';
  bool _isLoadingProperties = false;
  bool _isInitialized = false;
  bool _usingMockData = false;
  String? _propertyError;
  ApiLookups _lookups = const ApiLookups();
  PartnerFormLookups _partnerFormLookups = const PartnerFormLookups();
  bool _isLoadingPartnerProperties = false;
  bool _isLoadingPartnerLookups = false;
  bool _isSubmittingPartnerProperty = false;
  String? _partnerPropertyError;
  bool _isLoadingConversations = false;
  String? _chatError;

  bool get isLoggedIn => _authToken.isNotEmpty && _authUser != null;
  bool get isAuthenticating => _isAuthenticating;
  String? get authError => _authError;
  AuthUserModel? get authUser => _authUser;
  bool get isBootstrapComplete => _isBootstrapComplete;
  bool get hasLanguagePreference => _hasLanguagePreference;
  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  String get apiLanguageCode => _language.apiCode;
  bool get isBroker => _authUser?.isBroker ?? false;
  int get selectedTab => _selectedTab;
  double get walletBalance => _walletBalance;
  String get membershipCode => _membershipCode.isEmpty ? 'FREE' : _membershipCode;
  bool get isLoadingProperties => _isLoadingProperties;
  bool get isInitialized => _isInitialized;
  bool get usingMockData => _usingMockData;
  String? get propertyError => _propertyError;
  ApiLookups get lookups => _lookups;
  PartnerFormLookups get partnerFormLookups => _partnerFormLookups;
  bool get isLoadingPartnerProperties => _isLoadingPartnerProperties;
  bool get isLoadingPartnerLookups => _isLoadingPartnerLookups;
  bool get isSubmittingPartnerProperty => _isSubmittingPartnerProperty;
  String? get partnerPropertyError => _partnerPropertyError;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get chatError => _chatError;
  AgentModel get currentUser => _authUser?.toAgentModel() ?? agentLan;

  List<PropertyModel> get properties => List.unmodifiable(_properties);
  List<PropertyModel> get favoriteProperties =>
      _properties.where((item) => item.isFavorite).toList(growable: false);
  List<PropertyModel> get partnerProperties =>
      List<PropertyModel>.unmodifiable(_partnerProperties);
  List<ConversationModel> get conversations => List.unmodifiable(_conversations);
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  List<WalletTransactionModel> get transactions => List.unmodifiable(_transactions);

  int get unreadNotificationCount => _notifications.where((item) => !item.isRead).length;
  int get unreadMessageCount => _conversations.fold<int>(
        0,
        (sum, item) => sum + item.unreadCount,
      );

  bool isPropertyDetailLoading(int propertyId) =>
      _loadingDetailLanguages.containsKey(propertyId);

  bool isLoadingMoreProperties(ListingKind kind) =>
      _loadingMoreKinds.contains(kind);

  bool hasMoreProperties(ListingKind kind) =>
      _hasMoreByKind[kind] ?? true;

  Future<void> initialize() async {
    if (_isBootstrapComplete || _isInitializing) return;
    _isInitializing = true;

    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
      final savedLanguage =
          AppLanguage.tryParse(preferences.getString(_languagePreferenceKey));
      if (savedLanguage != null) {
        _language = savedLanguage;
        _hasLanguagePreference = true;
      }

      final savedToken =
          (preferences.getString(_authTokenPreferenceKey) ?? '').trim();
      if (savedToken.isNotEmpty) {
        _authToken = savedToken;
        _api.setAuthToken(savedToken);
        try {
          _authUser = await _api.fetchCurrentUser(language: apiLanguageCode);
          _membershipCode = _authUser?.membershipCode ?? 'FREE';
        } catch (_) {
          await _clearAuthState(preferences: preferences, notify: false);
        }
      }
    } catch (_) {
      // Nếu bộ nhớ cục bộ tạm thời không khả dụng, ứng dụng vẫn khởi động.
      _hasLanguagePreference = false;
    } finally {
      _isInitializing = false;
      _isBootstrapComplete = true;
      notifyListeners();
    }

    if (_hasLanguagePreference) {
      await refreshProperties();
      if (isLoggedIn) await refreshConversations();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    final shouldReload = !_hasLanguagePreference || _language != language;
    _language = language;
    _hasLanguagePreference = true;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_languagePreferenceKey, language.apiCode);
    } catch (_) {
      // Lựa chọn vẫn có hiệu lực trong phiên hiện tại; lần mở sau ứng dụng sẽ
      // hỏi lại nếu thiết bị không thể ghi SharedPreferences.
    }

    if (shouldReload) {
      if (isLoggedIn) {
        try {
          _authUser = await _api.fetchCurrentUser(language: apiLanguageCode);
          _membershipCode = _authUser?.membershipCode ?? 'FREE';
          notifyListeners();
        } on ApiTransportException catch (error) {
          if (error.needLogin) await _clearAuthState();
        } catch (_) {
          // Giữ hồ sơ hiện tại nếu chỉ việc tải lại nhãn ngôn ngữ thất bại.
        }
      }
      await refreshProperties(force: true);
      if (isLoggedIn) await refreshConversations();
    }
  }

  Future<void> refreshProperties({bool force = false}) async {
    if (_isLoadingProperties && !force) return;
    final generation = ++_refreshGeneration;
    final requestedLanguage = apiLanguageCode;
    _isLoadingProperties = true;
    _propertyError = null;
    _loadingMoreKinds.clear();
    notifyListeners();

    try {
      final kinds = ListingKind.values;
      final responses = await Future.wait<List<PropertyModel>>(
        kinds.map(
          (kind) => _api.fetchProperties(
            language: requestedLanguage,
            kind: kind,
            page: 1,
            pageSize: _homePageSize,
          ),
        ),
      );

      if (generation != _refreshGeneration ||
          requestedLanguage != apiLanguageCode) {
        return;
      }

      final byId = <int, PropertyModel>{};

      for (var index = 0; index < kinds.length; index++) {
        final kind = kinds[index];
        final pageItems = responses[index];
        _loadedPages[kind] = 1;
        _hasMoreByKind[kind] = pageItems.length >= _homePageSize;

        for (final item in pageItems) {
          byId[item.id] = isLoggedIn
              ? item
              : item.copyWith(isFavorite: false);
        }
      }

      final lookups = await _api.fetchLookups(language: requestedLanguage);
      if (generation != _refreshGeneration ||
          requestedLanguage != apiLanguageCode) {
        return;
      }

      _properties
        ..clear()
        ..addAll(byId.values);
      _lookups = lookups;
      _usingMockData = false;
      _isInitialized = true;
    } catch (error) {
      if (generation != _refreshGeneration ||
          requestedLanguage != apiLanguageCode) {
        return;
      }
      _propertyError = error.toString();
      _isInitialized = true;

      // Giữ giao diện sử dụng được khi máy công ty chưa trỏ đúng API.
      // Dữ liệu mẫu đã nằm sẵn trong ứng dụng nên không cần tải thêm trang.
      if (_properties.isEmpty) {
        _properties.addAll(mockProperties);
        _usingMockData = true;
      }
      for (final kind in ListingKind.values) {
        _loadedPages[kind] = 1;
        _hasMoreByKind[kind] = false;
      }
    } finally {
      if (generation == _refreshGeneration) {
        _isLoadingProperties = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreProperties(ListingKind kind) async {
    if (_isLoadingProperties ||
        _usingMockData ||
        _loadingMoreKinds.contains(kind) ||
        !hasMoreProperties(kind)) {
      return;
    }

    final generation = _refreshGeneration;
    final requestedLanguage = apiLanguageCode;
    _loadingMoreKinds.add(kind);
    notifyListeners();

    final nextPage = (_loadedPages[kind] ?? 0) + 1;
    try {
      final pageItems = await _api.fetchProperties(
        language: requestedLanguage,
        kind: kind,
        page: nextPage,
        pageSize: _homePageSize,
      );

      if (generation != _refreshGeneration ||
          requestedLanguage != apiLanguageCode) {
        return;
      }

      final existingIds = _properties.map((item) => item.id).toSet();
      for (final item in pageItems) {
        if (!existingIds.add(item.id)) continue;
        _properties.add(item);
      }

      _loadedPages[kind] = nextPage;
      _hasMoreByKind[kind] = pageItems.length >= _homePageSize;
      _propertyError = null;
    } catch (error) {
      if (generation != _refreshGeneration ||
          requestedLanguage != apiLanguageCode) {
        return;
      }

      // Không xóa danh sách đang hiển thị khi tải trang tiếp theo thất bại.
      // Dừng tự động tải để tránh gửi yêu cầu lặp liên tục; nút "Thử lại"
      // trên thông báo lỗi sẽ tải lại danh sách từ trang đầu.
      _propertyError = error.toString();
      _hasMoreByKind[kind] = false;
    } finally {
      _loadingMoreKinds.remove(kind);
      notifyListeners();
    }
  }

  Future<PropertyModel?> loadPropertyDetail(int propertyId) async {
    if (propertyId <= 0) return propertyById(propertyId);

    final requestedLanguage = apiLanguageCode;
    if (_loadingDetailLanguages[propertyId] == requestedLanguage) {
      return propertyById(propertyId);
    }

    _loadingDetailLanguages[propertyId] = requestedLanguage;
    notifyListeners();
    try {
      final detail = await _api.fetchPropertyDetail(
        propertyId,
        language: requestedLanguage,
      );

      if (_loadingDetailLanguages[propertyId] != requestedLanguage ||
          requestedLanguage != apiLanguageCode) {
        return propertyById(propertyId);
      }

      final index = _properties.indexWhere((item) => item.id == propertyId);
      final merged = isLoggedIn
          ? detail
          : detail.copyWith(isFavorite: false);
      if (index >= 0) {
        _properties[index] = merged;
      } else {
        _properties.add(merged);
      }
      _propertyError = null;
      return merged;
    } catch (error) {
      if (_loadingDetailLanguages[propertyId] == requestedLanguage &&
          requestedLanguage == apiLanguageCode) {
        _propertyError = error.toString();
      }
      return propertyById(propertyId);
    } finally {
      if (_loadingDetailLanguages[propertyId] == requestedLanguage) {
        _loadingDetailLanguages.remove(propertyId);
        notifyListeners();
      }
    }
  }

  void setSelectedTab(int index) {
    if (_selectedTab == index) return;
    _selectedTab = index;
    notifyListeners();
  }

  Future<bool> toggleFavorite(int propertyId) async {
    if (!isLoggedIn || propertyId <= 0) return false;
    try {
      final result = await _api.toggleFavorite(
        propertyId: propertyId,
        language: apiLanguageCode,
      );
      final favoriteIds = result.favoriteIds.toSet();
      for (var i = 0; i < _properties.length; i++) {
        _properties[i] = _properties[i].copyWith(
          isFavorite: favoriteIds.contains(_properties[i].id),
        );
      }
      notifyListeners();
      return result.isFavorite;
    } on ApiTransportException catch (error) {
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  PropertyModel? propertyById(int id) {
    for (final property in _properties) {
      if (property.id == id) return property;
    }
    return null;
  }

  List<PropertyModel> search(SearchFilterModel filter) {
    final keyword = filter.keyword.trim().toLowerCase();
    final results = _properties.where((property) {
      final keywordMatched = keyword.isEmpty ||
          property.title.toLowerCase().contains(keyword) ||
          property.displayAddress.toLowerCase().contains(keyword) ||
          property.city.toLowerCase().contains(keyword) ||
          property.ward.toLowerCase().contains(keyword);
      final cityMatched = filter.city == 'Tất cả' || property.city == filter.city;
      final wardMatched = filter.ward == 'Tất cả' || property.ward == filter.ward;
      final kindMatched = filter.kind == null || property.kind == filter.kind;
      final typeMatched =
          filter.propertyType == 'Tất cả' || property.propertyType == filter.propertyType;
      final minMatched = filter.minPrice == null || property.price >= filter.minPrice!;
      final maxMatched = filter.maxPrice == null || property.price <= filter.maxPrice!;
      return keywordMatched &&
          cityMatched &&
          wardMatched &&
          kindMatched &&
          typeMatched &&
          minMatched &&
          maxMatched;
    }).toList(growable: true);

    _sortSearchResults(results, filter.sortBy);
    return List<PropertyModel>.unmodifiable(results);
  }

  void _sortSearchResults(List<PropertyModel> results, String sortBy) {
    int compareFeaturedThenNewest(PropertyModel a, PropertyModel b) {
      if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
      return b.id.compareTo(a.id);
    }

    switch (sortBy.trim().toLowerCase()) {
      case 'oldest':
        results.sort((a, b) => a.id.compareTo(b.id));
        return;
      case 'price_asc':
        results.sort((a, b) {
          final aMissing = a.price <= 0;
          final bMissing = b.price <= 0;
          if (aMissing != bMissing) return aMissing ? 1 : -1;
          final compared = a.price.compareTo(b.price);
          return compared != 0 ? compared : compareFeaturedThenNewest(a, b);
        });
        return;
      case 'price_desc':
        results.sort((a, b) {
          final aMissing = a.price <= 0;
          final bMissing = b.price <= 0;
          if (aMissing != bMissing) return aMissing ? 1 : -1;
          final compared = b.price.compareTo(a.price);
          return compared != 0 ? compared : compareFeaturedThenNewest(a, b);
        });
        return;
      case 'newest':
      default:
        results.sort(compareFeaturedThenNewest);
    }
  }


  /// Tìm kiếm trực tiếp trên Mobile API để kết quả không bị giới hạn trong
  /// các tin đã tải ở trang chủ. Khi API chưa khả dụng, trang tìm kiếm vẫn có
  /// thể dùng [search] làm dữ liệu dự phòng.
  Future<List<PropertyModel>> searchPropertiesRemote(
    SearchFilterModel filter,
  ) async {
    if (_usingMockData) return search(filter);

    LookupItem? findByName(List<LookupItem> items, String name) {
      final normalized = name.trim().toLowerCase();
      for (final item in items) {
        if (item.name.trim().toLowerCase() == normalized) return item;
      }
      return null;
    }

    final selectedCity = filter.city == 'Tất cả'
        ? null
        : findByName(_lookups.cities, filter.city);

    LookupItem? selectedWard;
    if (filter.ward != 'Tất cả') {
      final normalizedWard = filter.ward.trim().toLowerCase();
      for (final item in _lookups.wards) {
        final matchesCity = selectedCity == null ||
            item.cityId == null ||
            item.cityId == selectedCity.id;
        if (matchesCity &&
            item.name.trim().toLowerCase() == normalizedWard) {
          selectedWard = item;
          break;
        }
      }
    }

    final selectedType = filter.propertyType == 'Tất cả'
        ? null
        : findByName(_lookups.propertyTypes, filter.propertyType);

    final items = await _api.fetchProperties(
      language: apiLanguageCode,
      kind: filter.kind,
      keyword: filter.keyword.trim(),
      cityId: selectedCity?.id,
      wardId: selectedWard?.id,
      propertyType: selectedType?.code ?? '',
      sortBy: filter.sortBy,
      page: 1,
      pageSize: 50,
    );

    return items.where((property) {
      final minMatched =
          filter.minPrice == null || property.price >= filter.minPrice!;
      final maxMatched =
          filter.maxPrice == null || property.price <= filter.maxPrice!;
      return minMatched && maxMatched;
    }).toList(growable: false);
  }

  Future<void> refreshPartnerProperties({
    int? cityId,
    int? wardId,
    String status = 'all',
  }) async {
    if (!isLoggedIn || !isBroker || _isLoadingPartnerProperties) return;
    _isLoadingPartnerProperties = true;
    _partnerPropertyError = null;
    notifyListeners();
    try {
      final items = await _api.fetchPartnerProperties(
        language: apiLanguageCode,
        cityId: cityId,
        wardId: wardId,
        status: status,
      );
      _partnerProperties
        ..clear()
        ..addAll(items);
    } on ApiTransportException catch (error) {
      _partnerPropertyError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    } catch (error) {
      _partnerPropertyError = error.toString();
      rethrow;
    } finally {
      _isLoadingPartnerProperties = false;
      notifyListeners();
    }
  }

  Future<PartnerFormLookups> loadPartnerFormLookups({
    int? cityId,
  }) async {
    if (!isLoggedIn || !isBroker) return _partnerFormLookups;
    _isLoadingPartnerLookups = true;
    _partnerPropertyError = null;
    notifyListeners();
    try {
      _partnerFormLookups = await _api.fetchPartnerFormLookups(
        language: apiLanguageCode,
        cityId: cityId,
      );
      return _partnerFormLookups;
    } on ApiTransportException catch (error) {
      _partnerPropertyError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    } catch (error) {
      _partnerPropertyError = error.toString();
      rethrow;
    } finally {
      _isLoadingPartnerLookups = false;
      notifyListeners();
    }
  }

  Future<PartnerPropertyEditData> loadPartnerPropertyForEdit(
    int propertyId,
  ) async {
    if (!isLoggedIn || !isBroker) {
      throw const ApiTransportException(
        'Tài khoản chưa có quyền đăng tin.',
        code: 'POST_PERMISSION_REQUIRED',
      );
    }
    _partnerPropertyError = null;
    notifyListeners();
    try {
      return await _api.fetchPartnerPropertyForEdit(
        propertyId: propertyId,
        language: apiLanguageCode,
      );
    } on ApiTransportException catch (error) {
      _partnerPropertyError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    } catch (error) {
      _partnerPropertyError = error.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<PartnerPropertyCreateResult> updatePartnerProperty(
    int propertyId,
    PartnerPropertyCreateRequest request,
  ) async {
    if (!isLoggedIn || !isBroker) {
      throw const ApiTransportException(
        'Tài khoản chưa có quyền đăng tin.',
        code: 'POST_PERMISSION_REQUIRED',
      );
    }
    _isSubmittingPartnerProperty = true;
    _partnerPropertyError = null;
    notifyListeners();
    try {
      final result = await _api.updatePartnerProperty(
        propertyId: propertyId,
        request: request,
        language: apiLanguageCode,
      );
      await refreshPartnerProperties();
      return result;
    } on ApiTransportException catch (error) {
      _partnerPropertyError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    } catch (error) {
      _partnerPropertyError = error.toString();
      rethrow;
    } finally {
      _isSubmittingPartnerProperty = false;
      notifyListeners();
    }
  }

  Future<PartnerPropertyCreateResult> createPartnerProperty(
    PartnerPropertyCreateRequest request,
  ) async {
    if (!isLoggedIn || !isBroker) {
      throw const ApiTransportException(
        'Tài khoản chưa có quyền đăng tin.',
        code: 'POST_PERMISSION_REQUIRED',
      );
    }
    _isSubmittingPartnerProperty = true;
    _partnerPropertyError = null;
    notifyListeners();
    try {
      final result = await _api.createPartnerProperty(
        request: request,
        language: apiLanguageCode,
      );
      await refreshPartnerProperties();
      return result;
    } on ApiTransportException catch (error) {
      _partnerPropertyError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    } catch (error) {
      _partnerPropertyError = error.toString();
      rethrow;
    } finally {
      _isSubmittingPartnerProperty = false;
      notifyListeners();
    }
  }

  void markNotificationRead(int notificationId) {
    final index = _notifications.indexWhere((item) => item.id == notificationId);
    if (index < 0 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  Future<void> refreshConversations({bool force = false}) async {
    if (!isLoggedIn) {
      _conversations.clear();
      _chatError = null;
      notifyListeners();
      return;
    }
    if (_isLoadingConversations && !force) return;

    _isLoadingConversations = true;
    _chatError = null;
    notifyListeners();
    try {
      final items = await _api.fetchChatConversations(
        language: apiLanguageCode,
      );
      _conversations
        ..clear()
        ..addAll(items);
    } on ApiTransportException catch (error) {
      _chatError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    } catch (error) {
      _chatError = error.toString();
      rethrow;
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<ConversationModel?> loadConversationMessages(
    int conversationId,
  ) async {
    if (!isLoggedIn || conversationId <= 0) return null;
    try {
      final messages = await _api.fetchChatMessages(
        conversationId: conversationId,
        language: apiLanguageCode,
      );
      final index = _conversations.indexWhere((item) => item.id == conversationId);
      if (index < 0) {
        await refreshConversations(force: true);
      }
      final refreshedIndex =
          _conversations.indexWhere((item) => item.id == conversationId);
      if (refreshedIndex < 0) return null;
      final lastMessage = messages.isEmpty
          ? _conversations[refreshedIndex].lastMessage
          : messages.last.displayText;
      final lastMessageAt = messages.isEmpty
          ? _conversations[refreshedIndex].lastMessageAt
          : messages.last.sentAt;
      _conversations[refreshedIndex] = _conversations[refreshedIndex].copyWith(
        messages: messages,
        unreadCount: 0,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
      );
      notifyListeners();
      return _conversations[refreshedIndex];
    } on ApiTransportException catch (error) {
      _chatError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  Future<ConversationModel> startPropertyConversation(int propertyId) async {
    if (!isLoggedIn) {
      throw const ApiTransportException(
        'Vui lòng đăng nhập để nhắn tin.',
        code: 'AUTH_REQUIRED',
        data: <String, dynamic>{'needLogin': true},
      );
    }
    final conversationId = await _api.startChatConversation(
      propertyId: propertyId,
      language: apiLanguageCode,
    );
    if (conversationId <= 0) {
      throw const ApiTransportException('Không thể tạo hội thoại.');
    }
    await refreshConversations(force: true);
    var index = _conversations.indexWhere((item) => item.id == conversationId);
    if (index < 0) {
      final property = propertyById(propertyId);
      _conversations.insert(
        0,
        ConversationModel(
          id: conversationId,
          title: property?.owner.name ?? 'Tin nhắn',
          subtitle: property?.title ?? '',
          propertyId: propertyId,
          propertyTitle: property?.title ?? '',
          propertyCover: property?.thumbnailUrl ?? '',
          propertyAddress: property?.displayAddress ?? '',
          avatarUrl: property?.owner.avatarUrl ?? '',
          messages: const <ChatMessageModel>[],
        ),
      );
      index = 0;
    }
    final loaded = await loadConversationMessages(conversationId);
    if (loaded != null) return loaded;
    final finalIndex = indexWhereConversation(conversationId);
    if (finalIndex >= 0) return _conversations[finalIndex];
    throw const ApiTransportException('Không thể tải hội thoại vừa tạo.');
  }

  int indexWhereConversation(int conversationId) =>
      _conversations.indexWhere((item) => item.id == conversationId);

  Future<void> markConversationRead(int conversationId) async {
    final index = indexWhereConversation(conversationId);
    if (index >= 0 && _conversations[index].unreadCount != 0) {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
      notifyListeners();
    }
    if (!isLoggedIn || conversationId <= 0) return;
    try {
      await _api.markChatRead(
        conversationId: conversationId,
        language: apiLanguageCode,
      );
    } on ApiTransportException catch (error) {
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  Future<bool> sendMessage(int conversationId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !isLoggedIn) return false;
    try {
      final newMessages = await _api.sendChatMessage(
        conversationId: conversationId,
        message: trimmed,
        language: apiLanguageCode,
      );
      final index = indexWhereConversation(conversationId);
      if (index < 0) {
        await refreshConversations(force: true);
        return true;
      }
      final conversation = _conversations[index];
      final merged = <ChatMessageModel>[
        ...conversation.messages,
        ...newMessages.where(
          (message) => !conversation.messages.any((item) => item.id == message.id),
        ),
      ];
      final last = merged.isEmpty ? null : merged.last;
      _conversations[index] = conversation.copyWith(
        messages: merged,
        unreadCount: 0,
        lastMessage: last?.displayText ?? conversation.lastMessage,
        lastMessageAt: last?.sentAt ?? conversation.lastMessageAt,
      );
      notifyListeners();
      return true;
    } on ApiTransportException catch (error) {
      _chatError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  Future<bool> sendImageMessage({
    required int conversationId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    if (bytes.isEmpty || !isLoggedIn) return false;
    try {
      final newMessages = await _api.sendChatImage(
        conversationId: conversationId,
        fileName: fileName,
        bytes: bytes,
        contentType: contentType,
        language: apiLanguageCode,
      );
      final index = indexWhereConversation(conversationId);
      if (index < 0) {
        await refreshConversations(force: true);
        return true;
      }
      final conversation = _conversations[index];
      final merged = <ChatMessageModel>[
        ...conversation.messages,
        ...newMessages.where(
          (message) => !conversation.messages.any((item) => item.id == message.id),
        ),
      ];
      final last = merged.isEmpty ? null : merged.last;
      _conversations[index] = conversation.copyWith(
        messages: merged,
        unreadCount: 0,
        lastMessage: last?.displayText ?? conversation.lastMessage,
        lastMessageAt: last?.sentAt ?? conversation.lastMessageAt,
      );
      notifyListeners();
      return true;
    } on ApiTransportException catch (error) {
      _chatError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  Future<void> recallMessage(int conversationId, int messageId) async {
    if (!isLoggedIn || conversationId <= 0 || messageId <= 0) return;
    try {
      await _api.recallChatMessage(
        messageId: messageId,
        language: apiLanguageCode,
      );
      final index = indexWhereConversation(conversationId);
      if (index < 0) return;
      final conversation = _conversations[index];
      final messages = conversation.messages
          .map(
            (message) => message.id == messageId
                ? message.copyWith(isRecalled: true)
                : message,
          )
          .toList(growable: false);
      final isLast = messages.isNotEmpty && messages.last.id == messageId;
      _conversations[index] = conversation.copyWith(
        messages: messages,
        lastMessage: isLast
            ? 'Tin nhắn đã được thu hồi'
            : conversation.lastMessage,
      );
      notifyListeners();
    } on ApiTransportException catch (error) {
      _chatError = error.toString();
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  Future<void> toggleConversationPin(int conversationId) async {
    final index = indexWhereConversation(conversationId);
    if (index < 0) return;
    await setConversationsPinned(
      <int>[conversationId],
      !_conversations[index].isPinned,
    );
  }

  Future<void> toggleConversationFlag(int conversationId) async {
    final index = indexWhereConversation(conversationId);
    if (index < 0) return;
    await setConversationsFlagged(
      <int>[conversationId],
      !_conversations[index].isFlagged,
    );
  }

  Future<void> setConversationsPinned(
    Iterable<int> conversationIds,
    bool value,
  ) async {
    final ids = conversationIds.where((id) => id > 0).toSet().toList();
    if (!isLoggedIn || ids.isEmpty) return;
    _chatError = null;
    try {
      for (final conversationId in ids) {
        await _api.setChatPinned(
          conversationId: conversationId,
          value: value,
          language: apiLanguageCode,
        );
      }
      for (final conversationId in ids) {
        final index = indexWhereConversation(conversationId);
        if (index >= 0) {
          _conversations[index] =
              _conversations[index].copyWith(isPinned: value);
        }
      }
      notifyListeners();
    } on ApiTransportException catch (error) {
      _chatError = error.toString();
      if (error.needLogin) await _clearAuthState();
      try {
        await refreshConversations(force: true);
      } catch (_) {}
      rethrow;
    } catch (error) {
      _chatError = error.toString();
      try {
        await refreshConversations(force: true);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> setConversationsFlagged(
    Iterable<int> conversationIds,
    bool value,
  ) async {
    final ids = conversationIds.where((id) => id > 0).toSet().toList();
    if (!isLoggedIn || ids.isEmpty) return;
    _chatError = null;
    try {
      for (final conversationId in ids) {
        await _api.setChatFlagged(
          conversationId: conversationId,
          value: value,
          language: apiLanguageCode,
        );
      }
      for (final conversationId in ids) {
        final index = indexWhereConversation(conversationId);
        if (index >= 0) {
          _conversations[index] =
              _conversations[index].copyWith(isFlagged: value);
        }
      }
      notifyListeners();
    } on ApiTransportException catch (error) {
      _chatError = error.toString();
      if (error.needLogin) await _clearAuthState();
      try {
        await refreshConversations(force: true);
      } catch (_) {}
      rethrow;
    } catch (error) {
      _chatError = error.toString();
      try {
        await refreshConversations(force: true);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> deleteConversations(Iterable<int> conversationIds) async {
    final ids = conversationIds.where((id) => id > 0).toSet().toList();
    if (!isLoggedIn || ids.isEmpty) return;
    _chatError = null;
    try {
      for (final conversationId in ids) {
        await _api.deleteChatConversation(
          conversationId: conversationId,
          language: apiLanguageCode,
        );
      }
      _conversations.removeWhere((item) => ids.contains(item.id));
      notifyListeners();
    } on ApiTransportException catch (error) {
      _chatError = error.toString();
      if (error.needLogin) await _clearAuthState();
      try {
        await refreshConversations(force: true);
      } catch (_) {}
      rethrow;
    } catch (error) {
      _chatError = error.toString();
      try {
        await refreshConversations(force: true);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> login({
    required String loginName,
    required String password,
  }) async {
    _isAuthenticating = true;
    _authError = null;
    notifyListeners();
    try {
      final session = await _api.login(
        loginName: loginName,
        password: password,
        language: apiLanguageCode,
      );
      await _applyAuthSession(session);
      await refreshProperties(force: true);
      await refreshConversations(force: true);
    } catch (error) {
      _authError = error.toString();
      rethrow;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<RegistrationResult> registerAccount({
    required String displayName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required bool isBroker,
    String avatarFileName = '',
    String avatarBase64Data = '',
  }) {
    return _api.register(
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
      isBroker: isBroker,
      avatarFileName: avatarFileName,
      avatarBase64Data: avatarBase64Data,
      language: apiLanguageCode,
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    final session = await _api.verifyEmailOtp(
      email: email,
      code: code,
      language: apiLanguageCode,
    );
    await _applyAuthSession(session);
    await refreshProperties(force: true);
    await refreshConversations(force: true);
  }

  Future<int> resendVerifyOtp(String email) {
    return _api.resendVerifyOtp(email: email, language: apiLanguageCode);
  }

  Future<int> sendResetOtp(String email) {
    return _api.sendResetOtp(email: email, language: apiLanguageCode);
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _api.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
      language: apiLanguageCode,
    );
  }

  Future<void> updateProfile({
    required String displayName,
    required String email,
    required String phoneNumber,
    required bool isBroker,
    String avatarFileName = '',
    String avatarBase64Data = '',
  }) async {
    try {
      final session = await _api.updateProfile(
        displayName: displayName,
        email: email,
        phoneNumber: phoneNumber,
        isBroker: isBroker,
        avatarFileName: avatarFileName,
        avatarBase64Data: avatarBase64Data,
        language: apiLanguageCode,
      );
      await _applyAuthSession(session);
    } on ApiTransportException catch (error) {
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      return await _api.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        language: apiLanguageCode,
      );
    } on ApiTransportException catch (error) {
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  Future<String> submitLandlordRequest({
    required String guestName,
    required String guestPhone,
    required String propertyAddress,
    required String customerNotes,
  }) {
    return _api.submitLandlordRequest(
      guestName: guestName,
      guestPhone: guestPhone,
      propertyAddress: propertyAddress,
      customerNotes: customerNotes,
      language: apiLanguageCode,
    );
  }

  Future<bool> ensurePostingPermission() async {
    if (!isLoggedIn) return false;
    if (isBroker) return true;
    try {
      final session = await _api.enablePostingPermission(
        language: apiLanguageCode,
      );
      await _applyAuthSession(session);
      return isBroker;
    } on ApiTransportException catch (error) {
      if (error.needLogin) await _clearAuthState();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout(language: apiLanguageCode);
    } catch (_) {
      // Token vẫn phải được xóa trên thiết bị kể cả khi mạng đang lỗi.
    }
    await _clearAuthState();
    for (var i = 0; i < _properties.length; i++) {
      if (_properties[i].isFavorite) {
        _properties[i] = _properties[i].copyWith(isFavorite: false);
      }
    }
    notifyListeners();
  }

  Future<void> _applyAuthSession(AuthSessionModel session) async {
    if (session.token.isEmpty || session.user.id <= 0) {
      throw StateError('Dữ liệu đăng nhập không hợp lệ.');
    }
    _authToken = session.token;
    _authUser = session.user;
    _membershipCode = session.user.membershipCode.isEmpty
        ? 'FREE'
        : session.user.membershipCode;
    _api.setAuthToken(_authToken);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_authTokenPreferenceKey, _authToken);
    } catch (_) {
      // Phiên vẫn hoạt động trong RAM khi thiết bị tạm thời không ghi được bộ nhớ.
    }
    notifyListeners();
  }

  Future<void> _clearAuthState({
    SharedPreferences? preferences,
    bool notify = true,
  }) async {
    _authToken = '';
    _authUser = null;
    _authError = null;
    _membershipCode = 'FREE';
    _partnerProperties.clear();
    _conversations.clear();
    _chatError = null;
    _isLoadingConversations = false;
    _partnerFormLookups = const PartnerFormLookups();
    _partnerPropertyError = null;
    _api.setAuthToken('');
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      await prefs.remove(_authTokenPreferenceKey);
    } catch (_) {
      // Trạng thái trong RAM vẫn được xóa ngay cả khi SharedPreferences lỗi.
    }
    if (notify) notifyListeners();
  }

  void buyMembership(String code) {
    _membershipCode = code;
    notifyListeners();
  }

  void topupWallet(double amount) {
    if (amount <= 0) return;
    _walletBalance += amount;
    _transactions.insert(
      0,
      WalletTransactionModel(
        id: DateTime.now().microsecondsSinceEpoch,
        title: 'Nạp tiền qua QR',
        amount: amount,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addPartnerProperty({
    required String title,
    required String address,
    required String city,
    required ListingKind kind,
    required String propertyType,
    required double price,
    required double area,
  }) {
    final nextId = _properties.fold<int>(0, (max, item) => item.id > max ? item.id : max) + 1;
    final priceLabel = kind.isRent
        ? '${_formatMoney(price)} đ/tháng'
        : '${_formatMoney(price)} đ';
    _properties.insert(
      0,
      PropertyModel(
        id: nextId,
        title: title,
        address: address,
        city: city,
        ward: 'Chưa cập nhật',
        kind: kind,
        propertyType: propertyType,
        price: price,
        priceLabel: priceLabel,
        area: area,
        infoTags: const ['Tin mới'],
        amenities: const [],
        description: 'Nội dung mô tả đang được cập nhật.',
        owner: currentUser,
        status: PropertyStatus.pending,
      ),
    );
    notifyListeners();
  }

  void changePropertyStatus(int propertyId, PropertyStatus status) {
    final index = _properties.indexWhere((item) => item.id == propertyId);
    if (index < 0) return;
    _properties[index] = _properties[index].copyWith(status: status);
    notifyListeners();
  }

  String _formatMoney(double value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({
    required AppStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
