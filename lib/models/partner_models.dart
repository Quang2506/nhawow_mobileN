class PartnerLookupItem {
  const PartnerLookupItem({
    required this.id,
    required this.code,
    required this.name,
    this.cityId,
    this.category = '',
    this.listingMode = '',
    this.iconUrl = '',
    this.propertyTypes = const <String>[],
  });

  final int id;
  final String code;
  final String name;
  final int? cityId;
  final String category;
  final String listingMode;
  final String iconUrl;
  final List<String> propertyTypes;

  factory PartnerLookupItem.fromJson(Map<String, dynamic> json) {
    Object? read(String key) {
      if (json.containsKey(key)) return json[key];
      final pascalKey = key.isEmpty
          ? key
          : '${key.substring(0, 1).toUpperCase()}${key.substring(1)}';
      if (json.containsKey(pascalKey)) return json[pascalKey];

      final normalizedKey = key.toLowerCase();
      for (final entry in json.entries) {
        if (entry.key.toLowerCase() == normalizedKey) return entry.value;
      }
      return null;
    }

    int parseInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    List<String> parseStrings(Object? value) {
      if (value is! List) return const <String>[];
      return value
          .where((item) => item != null)
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final rawCityId = read('cityId');
    return PartnerLookupItem(
      id: parseInt(read('id')),
      code: (read('code') ?? '').toString().trim(),
      name: (read('name') ?? '').toString().trim(),
      cityId: rawCityId == null ? null : parseInt(rawCityId),
      category: (read('category') ?? '').toString().trim().toLowerCase(),
      listingMode:
          (read('listingMode') ?? '').toString().trim().toLowerCase(),
      iconUrl: (read('iconUrl') ?? '').toString().trim(),
      propertyTypes: parseStrings(read('propertyTypes')),
    );
  }
}

class PartnerFormLookups {
  const PartnerFormLookups({
    this.cities = const <PartnerLookupItem>[],
    this.wards = const <PartnerLookupItem>[],
    this.propertyTypes = const <PartnerLookupItem>[],
    this.amenities = const <PartnerLookupItem>[],
    this.premisesAmenities = const <PartnerLookupItem>[],
    this.inforTags = const <PartnerLookupItem>[],
    this.orientations = const <PartnerLookupItem>[],
    this.statuses = const <PartnerLookupItem>[],
  });

  final List<PartnerLookupItem> cities;
  final List<PartnerLookupItem> wards;
  final List<PartnerLookupItem> propertyTypes;
  final List<PartnerLookupItem> amenities;
  final List<PartnerLookupItem> premisesAmenities;
  final List<PartnerLookupItem> inforTags;
  final List<PartnerLookupItem> orientations;
  final List<PartnerLookupItem> statuses;

  bool get isEmpty => cities.isEmpty && propertyTypes.isEmpty;

  factory PartnerFormLookups.fromJson(Map<String, dynamic> json) {
    Object? read(String key) {
      if (json.containsKey(key)) return json[key];
      final pascalKey = key.isEmpty
          ? key
          : '${key.substring(0, 1).toUpperCase()}${key.substring(1)}';
      if (json.containsKey(pascalKey)) return json[pascalKey];

      final normalizedKey = key.toLowerCase();
      for (final entry in json.entries) {
        if (entry.key.toLowerCase() == normalizedKey) return entry.value;
      }
      return null;
    }

    List<PartnerLookupItem> parse(Object? value) {
      if (value is! List) return const <PartnerLookupItem>[];
      return value
          .whereType<Map>()
          .map(
            (item) => PartnerLookupItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.name.isNotEmpty || item.code.isNotEmpty)
          .toList(growable: false);
    }

    return PartnerFormLookups(
      cities: parse(read('cities')),
      wards: parse(read('wards')),
      propertyTypes: parse(read('propertyTypes')),
      amenities: parse(read('amenities')),
      premisesAmenities: parse(read('premisesAmenities')),
      inforTags: parse(read('inforTags')),
      orientations: parse(read('orientations')),
      statuses: parse(read('statuses')),
    );
  }
}


class PartnerExistingImage {
  const PartnerExistingImage({
    required this.imageId,
    required this.url,
    this.isCover = false,
    this.sortOrder = 0,
  });

  final int imageId;
  final String url;
  final bool isCover;
  final int sortOrder;

  factory PartnerExistingImage.fromJson(Map<String, dynamic> json) {
    Object? read(String key) {
      if (json.containsKey(key)) return json[key];
      final pascalKey = key.isEmpty
          ? key
          : '${key.substring(0, 1).toUpperCase()}${key.substring(1)}';
      if (json.containsKey(pascalKey)) return json[pascalKey];
      final normalized = key.toLowerCase();
      for (final entry in json.entries) {
        if (entry.key.toLowerCase() == normalized) return entry.value;
      }
      return null;
    }

    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    return PartnerExistingImage(
      imageId: toInt(read('imageId')),
      url: (read('url') ?? '').toString().trim(),
      isCover: toBool(read('isCover')),
      sortOrder: toInt(read('sortOrder')),
    );
  }
}

class PartnerPropertyEditData {
  const PartnerPropertyEditData({
    required this.propertyId,
    required this.listingType,
    required this.propertyType,
    required this.cityId,
    required this.wardId,
    required this.title,
    required this.description,
    required this.newAddressDetail,
    required this.useOldAddressDisplay,
    required this.oldAddressLine,
    required this.price,
    required this.areaSqm,
    this.orientationCode = '',
    this.moveInStatus = '',
    this.viewingNote = '',
    this.saleFrontage = '',
    this.saleRoadWidth = '',
    this.saleLegalInfo = '',
    this.floorInfo = '',
    this.waterInfo = '',
    this.electricityInfo = '',
    this.leaseTerm = '',
    this.amenities = const <String>[],
    this.inforTags = const <PartnerInforTagValue>[],
    this.images = const <PartnerExistingImage>[],
  });

  final int propertyId;
  final String listingType;
  final String propertyType;
  final int cityId;
  final int wardId;
  final String title;
  final String description;
  final String newAddressDetail;
  final bool useOldAddressDisplay;
  final String oldAddressLine;
  final double price;
  final double areaSqm;
  final String orientationCode;
  final String moveInStatus;
  final String viewingNote;
  final String saleFrontage;
  final String saleRoadWidth;
  final String saleLegalInfo;
  final String floorInfo;
  final String waterInfo;
  final String electricityInfo;
  final String leaseTerm;
  final List<String> amenities;
  final List<PartnerInforTagValue> inforTags;
  final List<PartnerExistingImage> images;

  factory PartnerPropertyEditData.fromJson(Map<String, dynamic> json) {
    Object? read(String key) {
      if (json.containsKey(key)) return json[key];
      final pascalKey = key.isEmpty
          ? key
          : '${key.substring(0, 1).toUpperCase()}${key.substring(1)}';
      if (json.containsKey(pascalKey)) return json[pascalKey];
      final normalized = key.toLowerCase();
      for (final entry in json.entries) {
        if (entry.key.toLowerCase() == normalized) return entry.value;
      }
      return null;
    }

    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double toDouble(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    List<String> strings(Object? value) {
      if (value is! List) return const <String>[];
      return value
          .where((item) => item != null)
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    List<PartnerInforTagValue> tags(Object? value) {
      if (value is! List) return const <PartnerInforTagValue>[];
      return value.whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        final code = (map['code'] ?? map['Code'] ?? '').toString().trim();
        final rawQuantity = map['quantity'] ?? map['Quantity'];
        final quantity = rawQuantity is num
            ? rawQuantity.toInt()
            : int.tryParse(rawQuantity?.toString() ?? '') ?? 1;
        return PartnerInforTagValue(
          code: code,
          quantity: quantity > 0 ? quantity : 1,
        );
      }).where((item) => item.code.isNotEmpty).toList(growable: false);
    }

    List<PartnerExistingImage> images(Object? value) {
      if (value is! List) return const <PartnerExistingImage>[];
      return value
          .whereType<Map>()
          .map((item) => PartnerExistingImage.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => item.imageId > 0 && item.url.isNotEmpty)
          .toList(growable: false);
    }

    return PartnerPropertyEditData(
      propertyId: toInt(read('propertyId')),
      listingType: (read('listingType') ?? '').toString().trim(),
      propertyType: (read('propertyType') ?? '').toString().trim(),
      cityId: toInt(read('cityId')),
      wardId: toInt(read('wardId')),
      title: (read('title') ?? '').toString(),
      description: (read('description') ?? '').toString(),
      newAddressDetail: (read('newAddressDetail') ?? '').toString(),
      useOldAddressDisplay: toBool(read('useOldAddressDisplay')),
      oldAddressLine: (read('oldAddressLine') ?? '').toString(),
      price: toDouble(read('price')),
      areaSqm: toDouble(read('areaSqm')),
      orientationCode: (read('orientationCode') ?? '').toString(),
      moveInStatus: (read('moveInStatus') ?? '').toString(),
      viewingNote: (read('viewingNote') ?? '').toString(),
      saleFrontage: (read('saleFrontage') ?? '').toString(),
      saleRoadWidth: (read('saleRoadWidth') ?? '').toString(),
      saleLegalInfo: (read('saleLegalInfo') ?? '').toString(),
      floorInfo: (read('floorInfo') ?? '').toString(),
      waterInfo: (read('waterInfo') ?? '').toString(),
      electricityInfo: (read('electricityInfo') ?? '').toString(),
      leaseTerm: (read('leaseTerm') ?? '').toString(),
      amenities: strings(read('amenities')),
      inforTags: tags(read('inforTags')),
      images: images(read('images')),
    );
  }
}

class PartnerInforTagValue {
  const PartnerInforTagValue({required this.code, required this.quantity});

  final String code;
  final int quantity;

  factory PartnerInforTagValue.fromJson(Map<String, dynamic> json) {
    final rawQuantity = json['quantity'] ?? json['Quantity'];
    final quantity = rawQuantity is num
        ? rawQuantity.toInt()
        : int.tryParse(rawQuantity?.toString() ?? '') ?? 1;
    return PartnerInforTagValue(
      code: (json['code'] ?? json['Code'] ?? '').toString().trim(),
      quantity: quantity > 0 ? quantity : 1,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'quantity': quantity,
      };
}

class PartnerImagePayload {
  const PartnerImagePayload({
    required this.fileName,
    required this.base64Data,
    required this.sortOrder,
    this.isCover = false,
  });

  final String fileName;
  final String base64Data;
  final int sortOrder;
  final bool isCover;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fileName': fileName,
        'base64Data': base64Data,
        'sortOrder': sortOrder,
        'isCover': isCover,
      };
}

class PartnerPropertyCreateRequest {
  const PartnerPropertyCreateRequest({
    required this.listingType,
    required this.propertyType,
    required this.cityId,
    required this.wardId,
    required this.title,
    required this.description,
    required this.newAddressDetail,
    required this.useOldAddressDisplay,
    required this.oldAddressLine,
    required this.price,
    required this.areaSqm,
    this.orientationCode = '',
    this.moveInStatus = '',
    this.viewingNote = '',
    this.saleFrontage = '',
    this.saleRoadWidth = '',
    this.saleLegalInfo = '',
    this.floorInfo = '',
    this.waterInfo = '',
    this.electricityInfo = '',
    this.leaseTerm = '',
    this.amenities = const <String>[],
    this.inforTags = const <PartnerInforTagValue>[],
    this.images = const <PartnerImagePayload>[],
    this.existingCoverImageId,
    this.removeImageIds = const <int>[],
  });

  final String listingType;
  final String propertyType;
  final int cityId;
  final int wardId;
  final String title;
  final String description;
  final String newAddressDetail;
  final bool useOldAddressDisplay;
  final String oldAddressLine;
  final double price;
  final double areaSqm;
  final String orientationCode;
  final String moveInStatus;
  final String viewingNote;
  final String saleFrontage;
  final String saleRoadWidth;
  final String saleLegalInfo;
  final String floorInfo;
  final String waterInfo;
  final String electricityInfo;
  final String leaseTerm;
  final List<String> amenities;
  final List<PartnerInforTagValue> inforTags;
  final List<PartnerImagePayload> images;
  final int? existingCoverImageId;
  final List<int> removeImageIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'listingType': listingType,
        'propertyType': propertyType,
        'cityId': cityId,
        'wardId': wardId,
        'title': title,
        'description': description,
        'newAddressDetail': newAddressDetail,
        'useOldAddressDisplay': useOldAddressDisplay,
        'oldAddressLine': oldAddressLine,
        'price': price,
        'areaSqm': areaSqm,
        'orientationCode': orientationCode,
        'moveInStatus': moveInStatus,
        'viewingNote': viewingNote,
        'saleFrontage': saleFrontage,
        'saleRoadWidth': saleRoadWidth,
        'saleLegalInfo': saleLegalInfo,
        'floorInfo': floorInfo,
        'waterInfo': waterInfo,
        'electricityInfo': electricityInfo,
        'leaseTerm': leaseTerm,
        'amenities': amenities,
        'inforTags': inforTags.map((item) => item.toJson()).toList(),
        'images': images.map((item) => item.toJson()).toList(),
        'existingCoverImageId': existingCoverImageId,
        'removeImageIds': removeImageIds,
      };
}

class PartnerPropertyCreateResult {
  const PartnerPropertyCreateResult({
    required this.propertyId,
    required this.status,
    required this.message,
    this.hasImageWarning = false,
  });

  final int propertyId;
  final String status;
  final String message;
  final bool hasImageWarning;

  factory PartnerPropertyCreateResult.fromJson(Map<String, dynamic> json) {
    final rawId = json['propertyId'];
    return PartnerPropertyCreateResult(
      propertyId: rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? '') ?? 0,
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      hasImageWarning: json['hasImageWarning'] == true,
    );
  }
}
