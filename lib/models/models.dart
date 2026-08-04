import 'package:flutter/material.dart';

import '../core/media_url_resolver.dart';

enum ListingKind { houseSale, houseRent, landSale, premises }

enum PropertyStatus { published, pending, draft, rejected, closed, sold, rented }

ListingKind listingKindFromCode(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'rent':
      return ListingKind.houseRent;
    case 'land_sale':
      return ListingKind.landSale;
    case 'premises':
      return ListingKind.premises;
    case 'sale':
    default:
      return ListingKind.houseSale;
  }
}

PropertyStatus propertyStatusFromCode(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'pending':
    case 'pendingapproval':
      return PropertyStatus.pending;
    case 'draft':
      return PropertyStatus.draft;
    case 'rejected':
      return PropertyStatus.rejected;
    case 'closed':
      return PropertyStatus.closed;
    case 'sold':
      return PropertyStatus.sold;
    case 'rented':
      return PropertyStatus.rented;
    case 'published':
    default:
      return PropertyStatus.published;
  }
}

extension ListingKindX on ListingKind {
  String get code {
    switch (this) {
      case ListingKind.houseSale:
        return 'sale';
      case ListingKind.houseRent:
        return 'rent';
      case ListingKind.landSale:
        return 'land_sale';
      case ListingKind.premises:
        return 'premises';
    }
  }

  String get label {
    switch (this) {
      case ListingKind.houseSale:
        return 'Bán nhà';
      case ListingKind.houseRent:
        return 'Thuê nhà';
      case ListingKind.landSale:
        return 'Đất bán';
      case ListingKind.premises:
        return 'Mặt bằng';
    }
  }

  bool get isLand => this == ListingKind.landSale || this == ListingKind.premises;
  bool get isRent => this == ListingKind.houseRent || this == ListingKind.premises;
}

extension PropertyStatusX on PropertyStatus {
  String get label {
    switch (this) {
      case PropertyStatus.published:
        return 'Đang hiển thị';
      case PropertyStatus.pending:
        return 'Chờ duyệt';
      case PropertyStatus.draft:
        return 'Bản nháp';
      case PropertyStatus.rejected:
        return 'Từ chối';
      case PropertyStatus.closed:
        return 'Đã đóng';
      case PropertyStatus.sold:
        return 'Đã bán';
      case PropertyStatus.rented:
        return 'Đã cho thuê';
    }
  }

  Color color(ColorScheme scheme) {
    switch (this) {
      case PropertyStatus.published:
        return Colors.green;
      case PropertyStatus.pending:
        return Colors.orange;
      case PropertyStatus.draft:
        return Colors.blueGrey;
      case PropertyStatus.rejected:
        return Colors.red;
      case PropertyStatus.closed:
        return Colors.grey;
      case PropertyStatus.sold:
        return scheme.primary;
      case PropertyStatus.rented:
        return Colors.indigo;
    }
  }
}

class MapPointModel {
  const MapPointModel({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class BasicInfoItemModel {
  const BasicInfoItemModel({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final String value;

  factory BasicInfoItemModel.fromJson(Map<String, dynamic> json) {
    return BasicInfoItemModel(
      key: (json['key'] ?? json['Key'] ?? '').toString().trim(),
      label: (json['label'] ?? json['Label'] ?? '').toString().trim(),
      value: (json['value'] ?? json['Value'] ?? '').toString().trim(),
    );
  }
}

class PropertyModel {
  const PropertyModel({
    required this.id,
    required this.title,
    required this.address,
    this.mapAddress = '',
    this.mapQuery = '',
    this.mapEmbedUrl = '',
    this.mapOpenUrl = '',
    this.mapActionUrl = '',
    this.mapActionText = '',
    this.mapDisplayNote = '',
    this.mapRenderMode = 'iframe',
    this.mapBoundsNorth,
    this.mapBoundsSouth,
    this.mapBoundsEast,
    this.mapBoundsWest,
    this.mapPolygon = const <MapPointModel>[],
    required this.city,
    required this.ward,
    required this.kind,
    required this.propertyType,
    required this.price,
    required this.priceLabel,
    required this.area,
    required this.infoTags,
    required this.amenities,
    this.basicInfoItems = const <BasicInfoItemModel>[],
    required this.description,
    required this.owner,
    this.updatedAgoText = '',
    this.isVrAvailable = false,
    this.vrUrl = '',
    this.vrScenes = const <VrSceneModel>[],
    this.isFeatured = false,
    this.isCertified = false,
    this.isFavorite = false,
    this.viewCount = 0,
    this.status = PropertyStatus.published,
    this.frontage,
    this.roadWidth,
    this.legalInfo,
    this.floorInfo,
    this.leaseTerm,
    this.orientation,
    this.moveInStatus,
    this.waterInfo,
    this.electricityInfo,
    this.viewingNote,
    this.latitude,
    this.longitude,
    this.thumbnailUrl = '',
    this.imageUrls = const <String>[],
    this.imageCount = 0,
    this.propertyTypeCode = '',
    this.isApproximateLocation = false,
  });

  final int id;
  final String title;
  final String address;
  /// Địa chỉ hành chính được chọn theo đúng logic của website.
  final String mapAddress;
  /// Chuỗi truy vấn hoàn chỉnh: địa chỉ + tỉnh/thành (khi cần) + Việt Nam.
  final String mapQuery;
  final String mapEmbedUrl;
  final String mapOpenUrl;
  final String mapActionUrl;
  final String mapActionText;
  final String mapDisplayNote;
  final String mapRenderMode;
  final double? mapBoundsNorth;
  final double? mapBoundsSouth;
  final double? mapBoundsEast;
  final double? mapBoundsWest;
  final List<MapPointModel> mapPolygon;
  final String city;
  final String ward;
  final ListingKind kind;
  final String propertyType;
  final double price;
  final String priceLabel;
  final double area;
  final List<String> infoTags;
  final List<String> amenities;
  final List<BasicInfoItemModel> basicInfoItems;
  final String description;
  final AgentModel owner;
  final String updatedAgoText;
  final bool isVrAvailable;
  final String vrUrl;
  final List<VrSceneModel> vrScenes;
  final bool isFeatured;
  final bool isCertified;
  final bool isFavorite;
  final int viewCount;
  final PropertyStatus status;
  final String? frontage;
  final String? roadWidth;
  final String? legalInfo;
  final String? floorInfo;
  final String? leaseTerm;
  final String? orientation;
  final String? moveInStatus;
  final String? waterInfo;
  final String? electricityInfo;
  final String? viewingNote;
  final double? latitude;
  final double? longitude;
  final String thumbnailUrl;
  final List<String> imageUrls;
  final int imageCount;
  final String propertyTypeCode;
  final bool isApproximateLocation;

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final ownerJson = json['owner'];
    final ownerMap = ownerJson is Map<String, dynamic>
        ? ownerJson
        : ownerJson is Map
            ? Map<String, dynamic>.from(ownerJson)
            : const <String, dynamic>{};

    List<String> stringList(Object? value) {
      if (value is List) {
        return value
            .where((item) => item != null)
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
      return const <String>[];
    }

    List<MapPointModel> mapPointList(Object? value) {
      if (value is! List) return const <MapPointModel>[];

      final points = <MapPointModel>[];
      for (final item in value) {
        double? latitude;
        double? longitude;

        if (item is List && item.length >= 2) {
          latitude = item[0] is num
              ? (item[0] as num).toDouble()
              : double.tryParse('${item[0]}');
          longitude = item[1] is num
              ? (item[1] as num).toDouble()
              : double.tryParse('${item[1]}');
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final rawLatitude = map['latitude'] ?? map['lat'];
          final rawLongitude = map['longitude'] ?? map['lng'] ?? map['lon'];
          latitude = rawLatitude is num
              ? rawLatitude.toDouble()
              : double.tryParse('$rawLatitude');
          longitude = rawLongitude is num
              ? rawLongitude.toDouble()
              : double.tryParse('$rawLongitude');
        }

        if (latitude == null ||
            longitude == null ||
            latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          continue;
        }

        points.add(
          MapPointModel(latitude: latitude, longitude: longitude),
        );
      }

      return points;
    }

    List<BasicInfoItemModel> basicInfoList(Object? value) {
      if (value is! List) return const <BasicInfoItemModel>[];

      return value
          .whereType<Map>()
          .map((item) => BasicInfoItemModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => item.label.isNotEmpty && item.value.isNotEmpty)
          .toList(growable: false);
    }

    List<String> imageList(Object? value) {
      if (value is! List) return const <String>[];
      final result = <String>[];

      for (final item in value) {
        String url = '';
        if (item is String) {
          url = item.trim();
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          url = (map['url'] ??
                  map['imageUrl'] ??
                  map['image_url'] ??
                  map['path'] ??
                  map['src'] ??
                  map['fullUrl'] ??
                  '')
              .toString()
              .trim();
        }
        if (url.isNotEmpty && !result.contains(url)) result.add(url);
      }
      return result;
    }

    double toDouble(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    double? toNullableDouble(Object? value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    final rawImages = <String>[
      ...imageList(json['imageUrls']),
      ...imageList(json['images']),
      ...imageList(json['propertyImages']),
    ];
    final images = MediaUrlResolver.resolveAll(rawImages);
    final thumbnail = MediaUrlResolver.resolve(
      (json['thumbnailUrl'] ??
              json['coverImageUrl'] ??
              json['cover_image_url'] ??
              '')
          .toString(),
    );
    final reportedImageCount = toInt(
      json['imageCount'] ?? json['imagesCount'] ?? json['image_count'],
    );

    final rawVrScenes = json['vrScenes'];
    final vrScenes = rawVrScenes is List
        ? rawVrScenes
            .whereType<Map>()
            .map((item) => VrSceneModel.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0 && item.sceneKey.isNotEmpty)
            .toList(growable: false)
        : const <VrSceneModel>[];

    return PropertyModel(
      id: toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      address: (json['address'] ??
              json['addressLine'] ??
              json['address_line'] ??
              '')
          .toString(),
      mapAddress: (json['mapAddress'] ??
              json['newAddressLine'] ??
              json['new_address_line'] ??
              '')
          .toString(),
      mapQuery: (json['mapQuery'] ?? '').toString(),
      mapEmbedUrl: (json['mapEmbedUrl'] ?? '').toString(),
      mapOpenUrl: (json['mapOpenUrl'] ?? '').toString(),
      mapActionUrl: (json['mapActionUrl'] ?? '').toString(),
      mapActionText: (json['mapActionText'] ?? '').toString(),
      mapDisplayNote: (json['mapDisplayNote'] ?? '').toString(),
      mapRenderMode: (json['mapRenderMode'] ?? 'iframe').toString(),
      mapBoundsNorth: toNullableDouble(json['mapBoundsNorth']),
      mapBoundsSouth: toNullableDouble(json['mapBoundsSouth']),
      mapBoundsEast: toNullableDouble(json['mapBoundsEast']),
      mapBoundsWest: toNullableDouble(json['mapBoundsWest']),
      mapPolygon: mapPointList(json['mapPolygon']),
      city: (json['city'] ?? '').toString(),
      ward: (json['ward'] ?? '').toString(),
      kind: listingKindFromCode(json['listingType']?.toString()),
      propertyType: (json['propertyType'] ?? json['propertyTypeCode'] ?? '').toString(),
      propertyTypeCode: (json['propertyTypeCode'] ?? '').toString(),
      price: toDouble(json['price']),
      priceLabel: (json['priceLabel'] ?? 'Giá thỏa thuận').toString(),
      area: toDouble(json['area']),
      infoTags: stringList(json['infoTags']),
      amenities: stringList(json['amenities']),
      basicInfoItems: basicInfoList(json['basicInfoItems']),
      description: (json['description'] ?? '').toString(),
      owner: AgentModel.fromJson(ownerMap),
      updatedAgoText: (json['updatedAgoText'] ?? '').toString().trim(),
      isVrAvailable: toBool(json['isVrAvailable']),
      vrUrl: MediaUrlResolver.resolve((json['vrUrl'] ?? '').toString()),
      vrScenes: vrScenes,
      isFeatured: toBool(json['isFeatured']),
      isCertified: toBool(json['isCertified']),
      isFavorite: toBool(json['isFavorite']),
      viewCount: toInt(json['viewCount'] ?? json['view_count'] ?? json['views']),
      status: propertyStatusFromCode(json['status']?.toString()),
      frontage: _nullableText(json['frontage']),
      roadWidth: _nullableText(json['roadWidth']),
      legalInfo: _nullableText(json['legalInfo']),
      floorInfo: _nullableText(json['floorInfo']),
      leaseTerm: _nullableText(json['leaseTerm']),
      orientation: _nullableText(json['orientation']),
      moveInStatus: _nullableText(json['moveInStatus']),
      waterInfo: _nullableText(json['waterInfo']),
      electricityInfo: _nullableText(json['electricityInfo']),
      viewingNote: _nullableText(json['viewingNote']),
      latitude: json['latitude'] == null ? null : toDouble(json['latitude']),
      longitude: json['longitude'] == null ? null : toDouble(json['longitude']),
      thumbnailUrl: thumbnail.isNotEmpty ? thumbnail : (images.isEmpty ? '' : images.first),
      imageUrls: images,
      imageCount: reportedImageCount > images.length
          ? reportedImageCount
          : images.length,
      isApproximateLocation: toBool(json['isApproximateLocation']),
    );
  }

  PropertyModel copyWith({
    bool? isFavorite,
    PropertyStatus? status,
  }) {
    return PropertyModel(
      id: id,
      title: title,
      address: address,
      mapAddress: mapAddress,
      mapQuery: mapQuery,
      mapEmbedUrl: mapEmbedUrl,
      mapOpenUrl: mapOpenUrl,
      mapActionUrl: mapActionUrl,
      mapActionText: mapActionText,
      mapDisplayNote: mapDisplayNote,
      mapRenderMode: mapRenderMode,
      mapBoundsNorth: mapBoundsNorth,
      mapBoundsSouth: mapBoundsSouth,
      mapBoundsEast: mapBoundsEast,
      mapBoundsWest: mapBoundsWest,
      mapPolygon: mapPolygon,
      city: city,
      ward: ward,
      kind: kind,
      propertyType: propertyType,
      price: price,
      priceLabel: priceLabel,
      area: area,
      infoTags: infoTags,
      amenities: amenities,
      basicInfoItems: basicInfoItems,
      description: description,
      owner: owner,
      updatedAgoText: updatedAgoText,
      isVrAvailable: isVrAvailable,
      vrUrl: vrUrl,
      vrScenes: vrScenes,
      isFeatured: isFeatured,
      isCertified: isCertified,
      isFavorite: isFavorite ?? this.isFavorite,
      viewCount: viewCount,
      status: status ?? this.status,
      frontage: frontage,
      roadWidth: roadWidth,
      legalInfo: legalInfo,
      floorInfo: floorInfo,
      leaseTerm: leaseTerm,
      orientation: orientation,
      moveInStatus: moveInStatus,
      waterInfo: waterInfo,
      electricityInfo: electricityInfo,
      viewingNote: viewingNote,
      latitude: latitude,
      longitude: longitude,
      thumbnailUrl: thumbnailUrl,
      imageUrls: imageUrls,
      imageCount: imageCount,
      propertyTypeCode: propertyTypeCode,
      isApproximateLocation: isApproximateLocation,
    );
  }

  /// Địa chỉ công khai do API web trả về từ `properties.address_line`.
  ///
  /// Web đã áp dụng sẵn quy tắc:
  /// - Không dùng địa chỉ cũ: hiển thị địa chỉ mới.
  /// - Có dùng địa chỉ cũ: "địa chỉ cũ (địa chỉ hành chính mới + chữ mới)".
  ///
  /// Chỉ ghép phường và tỉnh làm phương án dự phòng cho dữ liệu/API cũ
  /// chưa có trường `address`.
  String get displayAddress {
    final publicAddress = address.trim();
    if (publicAddress.isNotEmpty) return publicAddress;

    final parts = <String>[];
    final wardName = ward.trim();
    final cityName = city.trim();
    if (wardName.isNotEmpty) parts.add(wardName);
    if (cityName.isNotEmpty &&
        !parts.any((item) => item.toLowerCase() == cityName.toLowerCase())) {
      parts.add(cityName);
    }
    return parts.join(', ');
  }

  /// Chuỗi địa chỉ dùng để xác định vị trí bản đồ. API trả `mapQuery`
  /// từ cùng bộ giải quyết bản đồ của website, vì vậy mobile và web cùng dùng:
  /// tọa độ -> địa chỉ mới -> địa chỉ cũ + tỉnh/thành -> Việt Nam.
  String get mapDisplayAddress {
    final resolvedQuery = mapQuery.trim();
    if (resolvedQuery.isNotEmpty) return resolvedQuery;

    final officialAddress = mapAddress.trim();
    if (officialAddress.isNotEmpty) {
      return officialAddress.toLowerCase().contains('việt nam')
          ? officialAddress
          : '$officialAddress, Việt Nam';
    }

    final publicAddress = displayAddress.trim();
    final cityName = city.trim();
    final parts = <String>[];
    if (publicAddress.isNotEmpty) parts.add(publicAddress);
    if (cityName.isNotEmpty &&
        !parts.any((item) => item.toLowerCase().contains(cityName.toLowerCase()))) {
      parts.add(cityName);
    }
    parts.add('Việt Nam');
    return parts.join(', ');
  }

  bool get hasVrContent =>
      isVrAvailable && (vrUrl.trim().isNotEmpty || vrScenes.isNotEmpty);

  String get compactViewCount {
    if (viewCount < 1000) return '$viewCount';
    final value = viewCount / 1000;
    final text = value.toStringAsFixed(value >= 10 ? 0 : 1).replaceAll('.0', '');
    return '${text}k';
  }
}

class VrHotspotModel {
  const VrHotspotModel({
    required this.id,
    this.pitch = 0,
    this.yaw = 0,
    this.text = '',
    this.targetSceneKey = '',
    this.targetSceneExists = false,
    this.targetPitch,
    this.targetYaw,
    this.targetHfov,
  });

  final int id;
  final double pitch;
  final double yaw;
  final String text;
  final String targetSceneKey;
  final bool targetSceneExists;
  final double? targetPitch;
  final double? targetYaw;
  final double? targetHfov;

  bool get isNavigation =>
      targetSceneExists && targetSceneKey.trim().isNotEmpty;

  factory VrHotspotModel.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double toDouble(Object? value, double fallback) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    double? toNullableDouble(Object? value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    return VrHotspotModel(
      id: toInt(json['id']),
      pitch: toDouble(json['pitch'], 0),
      yaw: toDouble(json['yaw'], 0),
      text: (json['text'] ?? '').toString().trim(),
      targetSceneKey: (json['targetSceneKey'] ?? '').toString().trim(),
      targetSceneExists: toBool(json['targetSceneExists']),
      targetPitch: toNullableDouble(json['targetPitch']),
      targetYaw: toNullableDouble(json['targetYaw']),
      targetHfov: toNullableDouble(json['targetHfov']),
    );
  }
}

class VrSceneModel {
  const VrSceneModel({
    required this.id,
    required this.sceneKey,
    required this.title,
    this.panoType = 'equirectangular',
    this.panoramaUrl = '',
    this.previewUrl = '',
    this.nativeSupported = true,
    this.isDefault = false,
    this.hfov = 110,
    this.pitch = 0,
    this.yaw = 0,
    this.hotspots = const <VrHotspotModel>[],
  });

  final int id;
  final String sceneKey;
  final String title;
  final String panoType;
  final String panoramaUrl;
  final String previewUrl;
  final bool nativeSupported;
  final bool isDefault;
  final double hfov;
  final double pitch;
  final double yaw;
  final List<VrHotspotModel> hotspots;

  bool get canOpenNatively =>
      nativeSupported && panoramaUrl.trim().isNotEmpty;

  factory VrSceneModel.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double toDouble(Object? value, double fallback) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool toBool(Object? value, {bool fallback = false}) {
      if (value == null) return fallback;
      if (value is bool) return value;
      final normalized = value.toString().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
      return fallback;
    }

    final rawHotspots = json['hotspots'];
    final hotspots = rawHotspots is List
        ? rawHotspots
            .whereType<Map>()
            .map(
              (item) => VrHotspotModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.id > 0)
            .toList(growable: false)
        : const <VrHotspotModel>[];

    final rawPanoramaUrl = (json['mobilePanoramaUrl'] ??
            json['panoramaUrl'] ??
            '')
        .toString();
    final panoramaUrl = MediaUrlResolver.resolve(rawPanoramaUrl);

    return VrSceneModel(
      id: toInt(json['id']),
      sceneKey: (json['sceneKey'] ?? '').toString().trim(),
      title: (json['title'] ?? json['sceneKey'] ?? '').toString().trim(),
      panoType: (json['panoType'] ?? 'equirectangular').toString(),
      panoramaUrl: panoramaUrl,
      previewUrl: MediaUrlResolver.resolve(
        (json['previewUrl'] ?? '').toString(),
      ),
      nativeSupported: toBool(
        json['nativeSupported'],
        fallback: panoramaUrl.isNotEmpty,
      ),
      isDefault: toBool(json['isDefault']),
      hfov: toDouble(json['hfov'], 110),
      pitch: toDouble(json['pitch'], 0),
      yaw: toDouble(json['yaw'], 0),
      hotspots: hotspots,
    );
  }
}

class VrTourModel {
  const VrTourModel({
    required this.propertyId,
    required this.isVrAvailable,
    required this.defaultSceneKey,
    required this.scenes,
  });

  final int propertyId;
  final bool isVrAvailable;
  final String defaultSceneKey;
  final List<VrSceneModel> scenes;

  List<VrSceneModel> get nativeScenes => scenes
      .where((scene) => scene.canOpenNatively)
      .toList(growable: false);

  factory VrTourModel.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    final rawScenes = json['scenes'] ?? json['vrScenes'];
    final scenes = rawScenes is List
        ? rawScenes
            .whereType<Map>()
            .map(
              (item) => VrSceneModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.id > 0 && item.sceneKey.isNotEmpty)
            .toList(growable: false)
        : const <VrSceneModel>[];

    return VrTourModel(
      propertyId: toInt(json['propertyId']),
      isVrAvailable: toBool(json['isVrAvailable']),
      defaultSceneKey: (json['defaultSceneKey'] ?? '').toString().trim(),
      scenes: scenes,
    );
  }
}

class AgentModel {
  const AgentModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.roleLabel,
    this.level = 1,
    this.levelName = '',
    this.levelColor = '#BDBDBD',
    this.verifiedListingCount = 0,
    this.membershipCode = 'FREE',
    this.isBroker = false,
    this.isGoldAgent = false,
    this.avatarUrl = '',
  });

  final int id;
  final String name;
  final String phone;
  final String roleLabel;
  final int level;
  final String levelName;
  final String levelColor;
  final int verifiedListingCount;
  final String membershipCode;
  final bool isBroker;
  final bool isGoldAgent;
  final String avatarUrl;

  String get displayLevelName {
    if (!isBroker) return roleLabel;
    if (levelName.trim().isNotEmpty) return levelName.trim();
    return 'Môi giới Lv$level';
  }

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    return AgentModel(
      id: toInt(json['id']),
      name: (json['name'] ?? 'Chủ nhà').toString(),
      phone: (json['phone'] ?? '').toString(),
      roleLabel: (json['roleLabel'] ?? 'Chủ nhà').toString(),
      level: toInt(json['level']),
      levelName: (json['levelName'] ?? '').toString(),
      levelColor: (json['levelColor'] ?? '#BDBDBD').toString(),
      verifiedListingCount: toInt(json['verifiedListingCount']),
      membershipCode: (json['membershipCode'] ?? 'FREE').toString(),
      isBroker: toBool(json['isBroker']),
      isGoldAgent: toBool(json['isGoldAgent']),
      avatarUrl: MediaUrlResolver.resolve((json['avatarUrl'] ?? '').toString()),
    );
  }
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.messages,
    this.conversationType = 'property_owner',
    this.propertyId,
    this.propertyTitle = '',
    this.propertyCover = '',
    this.propertyAddress = '',
    this.avatarUrl = '',
    this.membershipCode = 'FREE',
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isFlagged = false,
  });

  final int id;
  final String conversationType;
  final String title;
  final String subtitle;
  final int? propertyId;
  final String propertyTitle;
  final String propertyCover;
  final String propertyAddress;
  final String avatarUrl;
  final String membershipCode;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isPinned;
  final bool isFlagged;
  final List<ChatMessageModel> messages;

  String get previewText {
    if (messages.isNotEmpty) return messages.last.displayText;
    return lastMessage == ChatMessageModel.ownerOfflineToken
        ? 'Môi giới hiện đang ngoại tuyến và sẽ phản hồi sớm.'
        : lastMessage;
  }

  DateTime get sortTime {
    if (messages.isNotEmpty) return messages.last.sentAt;
    return lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    DateTime? toDate(Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      return DateTime.tryParse(text)?.toLocal();
    }

    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
            .whereType<Map>()
            .map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <ChatMessageModel>[];

    final rawPropertyId = json['propertyId'];
    final propertyId = rawPropertyId == null ? null : toInt(rawPropertyId);

    return ConversationModel(
      id: toInt(json['id'] ?? json['conversationId']),
      conversationType: (json['conversationType'] ?? 'property_owner').toString(),
      title: (json['title'] ?? 'Tin nhắn').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      propertyId: propertyId != null && propertyId > 0 ? propertyId : null,
      propertyTitle: (json['propertyTitle'] ?? '').toString(),
      propertyCover: MediaUrlResolver.resolve((json['propertyCover'] ?? '').toString()),
      propertyAddress: (json['propertyAddress'] ?? '').toString(),
      avatarUrl: MediaUrlResolver.resolve((json['avatarUrl'] ?? '').toString()),
      membershipCode: (json['membershipCode'] ?? 'FREE').toString(),
      lastMessage: (json['lastMessage'] ?? '').toString(),
      lastMessageAt: toDate(json['lastMessageAt']),
      unreadCount: toInt(json['unreadCount']),
      isPinned: toBool(json['isPinned']),
      isFlagged: toBool(json['isFlagged']),
      messages: messages,
    );
  }

  ConversationModel copyWith({
    String? title,
    String? subtitle,
    List<ChatMessageModel>? messages,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isPinned,
    bool? isFlagged,
  }) {
    return ConversationModel(
      id: id,
      conversationType: conversationType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      propertyCover: propertyCover,
      propertyAddress: propertyAddress,
      avatarUrl: avatarUrl,
      membershipCode: membershipCode,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isFlagged: isFlagged ?? this.isFlagged,
      messages: messages ?? this.messages,
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.conversationId = 0,
    this.senderName = '',
    this.senderType = 'visitor',
    this.senderAvatarUrl = '',
    this.imageUrl = '',
    this.imageName = '',
    this.isRecalled = false,
    this.isHearted = false,
    this.heartCount = 0,
  });

  static const String ownerOfflineToken = '[[AUTO_OWNER_OFFLINE_MESSAGE]]';
  static const String imageMessagePrefix = '[[CHAT_IMAGE]]|';

  final int id;
  final int conversationId;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final String senderName;
  final String senderType;
  final String senderAvatarUrl;
  final String imageUrl;
  final String imageName;
  final bool isRecalled;
  final bool isHearted;
  final int heartCount;

  bool get isSystem => senderType.toLowerCase() == 'system';
  bool get isImage => imageUrl.trim().isNotEmpty;

  String get displayText {
    if (text == ownerOfflineToken) {
      return 'Môi giới hiện đang ngoại tuyến và sẽ phản hồi sớm.';
    }
    if (isImage) return '📷 Hình ảnh';
    return text;
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    final rawDate = (json['sentAt'] ?? json['createdAt'] ?? '').toString();
    final parsedDate = DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now();
    final rawText =
        (json['text'] ?? json['message'] ?? json['messageText'] ?? '').toString();
    var imageUrl = (json['imageUrl'] ?? '').toString().trim();
    var imageName = (json['imageName'] ?? '').toString().trim();
    if (imageUrl.isEmpty && rawText.startsWith(imageMessagePrefix)) {
      final payload = rawText.substring(imageMessagePrefix.length);
      final separatorIndex = payload.indexOf('|');
      imageUrl = separatorIndex < 0
          ? payload.trim()
          : payload.substring(0, separatorIndex).trim();
      if (imageName.isEmpty && separatorIndex >= 0) {
        imageName = payload.substring(separatorIndex + 1).trim();
      }
    }
    return ChatMessageModel(
      id: toInt(json['id'] ?? json['messageId']),
      conversationId: toInt(json['conversationId']),
      text: rawText,
      sentAt: parsedDate,
      isMine: toBool(json['isMine']),
      senderName: (json['senderName'] ?? '').toString(),
      senderType: (json['senderType'] ?? 'visitor').toString(),
      senderAvatarUrl: MediaUrlResolver.resolve(
        (json['senderAvatarUrl'] ?? json['avatarUrl'] ?? '').toString(),
      ),
      imageUrl: MediaUrlResolver.resolve(imageUrl),
      imageName: imageName,
      isRecalled: toBool(json['isRecalled']),
      isHearted: toBool(json['isHearted'] ?? json['isHeartedByMe']),
      heartCount: toInt(json['heartCount']),
    );
  }

  ChatMessageModel copyWith({
    String? text,
    DateTime? sentAt,
    bool? isMine,
    String? senderName,
    String? senderType,
    String? senderAvatarUrl,
    String? imageUrl,
    String? imageName,
    bool? isRecalled,
    bool? isHearted,
    int? heartCount,
  }) {
    return ChatMessageModel(
      id: id,
      conversationId: conversationId,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      isMine: isMine ?? this.isMine,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      imageName: imageName ?? this.imageName,
      isRecalled: isRecalled ?? this.isRecalled,
      isHearted: isHearted ?? this.isHearted,
      heartCount: heartCount ?? this.heartCount,
    );
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.propertyId,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final int? propertyId;
  final bool isRead;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      propertyId: propertyId,
      isRead: isRead ?? this.isRead,
    );
  }
}

class MembershipPlanModel {
  const MembershipPlanModel({
    required this.code,
    required this.name,
    required this.priceLabel,
    required this.dailyPostLimit,
    required this.monthlyPostLimit,
    required this.freeTopLimit,
    required this.benefits,
    this.isRecommended = false,
  });

  final String code;
  final String name;
  final String priceLabel;
  final int dailyPostLimit;
  final int monthlyPostLimit;
  final int freeTopLimit;
  final List<String> benefits;
  final bool isRecommended;
}

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.createdAt,
  });

  final int id;
  final String title;
  final double amount;
  final DateTime createdAt;

  bool get isCredit => amount >= 0;
}

class SearchFilterModel {
  const SearchFilterModel({
    this.keyword = '',
    this.city = 'Tất cả',
    this.ward = 'Tất cả',
    this.kind,
    this.propertyType = 'Tất cả',
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
  });

  final String keyword;
  final String city;
  final String ward;
  final ListingKind? kind;
  final String propertyType;
  final double? minPrice;
  final double? maxPrice;

  /// Giá trị dùng chung với Web/API:
  /// newest, oldest, price_asc, price_desc.
  final String sortBy;

  SearchFilterModel copyWith({
    String? keyword,
    String? city,
    String? ward,
    ListingKind? kind,
    bool clearKind = false,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    String? sortBy,
  }) {
    return SearchFilterModel(
      keyword: keyword ?? this.keyword,
      city: city ?? this.city,
      ward: ward ?? this.ward,
      kind: clearKind ? null : (kind ?? this.kind),
      propertyType: propertyType ?? this.propertyType,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
