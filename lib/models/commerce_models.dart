import 'models.dart';

num _asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value) => _asNum(value).toInt();
double _asDouble(Object? value) => _asNum(value).toDouble();

bool _asBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1';
}

DateTime? parseApiDate(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return null;
  final direct = DateTime.tryParse(text);
  if (direct != null) return direct;

  final match = RegExp(r'/Date\((\d+)(?:[+-]\d+)?\)/').firstMatch(text);
  if (match != null) {
    final milliseconds = int.tryParse(match.group(1) ?? '');
    if (milliseconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    }
  }
  return null;
}

class MembershipUsageModel {
  const MembershipUsageModel({
    this.walletBalance = 0,
    this.currentPlanCode = 'free',
    this.currentPlanName = '',
    this.dailyUsed = 0,
    this.dailyRemaining = 0,
    this.dailyLimit = 0,
    this.monthlyUsed = 0,
    this.monthlyRemaining = 0,
    this.monthlyLimit = 0,
    this.freeTopUsed = 0,
    this.freeTopRemaining = 0,
    this.freeTopLimit = 0,
    this.monthEndUtc,
  });

  final double walletBalance;
  final String currentPlanCode;
  final String currentPlanName;
  final int dailyUsed;
  final int dailyRemaining;
  final int dailyLimit;
  final int monthlyUsed;
  final int monthlyRemaining;
  final int monthlyLimit;
  final int freeTopUsed;
  final int freeTopRemaining;
  final int freeTopLimit;
  final DateTime? monthEndUtc;

  factory MembershipUsageModel.fromJson(Map<String, dynamic> json) {
    return MembershipUsageModel(
      walletBalance: _asDouble(json['walletBalance']),
      currentPlanCode: (json['currentPlanCode'] ?? 'free').toString(),
      currentPlanName: (json['currentPlanName'] ?? '').toString(),
      dailyUsed: _asInt(json['dailyUsed']),
      dailyRemaining: _asInt(json['dailyRemaining']),
      dailyLimit: _asInt(json['dailyLimit']),
      monthlyUsed: _asInt(json['monthlyUsed']),
      monthlyRemaining: _asInt(json['monthlyRemaining']),
      monthlyLimit: _asInt(json['monthlyLimit']),
      freeTopUsed: _asInt(json['freeTopUsed']),
      freeTopRemaining: _asInt(json['freeTopRemaining']),
      freeTopLimit: _asInt(json['freeTopLimit']),
      monthEndUtc: parseApiDate(json['monthEndUtc']),
    );
  }
}

class ActiveMembershipModel {
  const ActiveMembershipModel({
    required this.id,
    required this.planCode,
    required this.planName,
    required this.status,
    this.startedAt,
    this.expiresAt,
  });

  final int id;
  final String planCode;
  final String planName;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  factory ActiveMembershipModel.fromJson(Map<String, dynamic> json) {
    return ActiveMembershipModel(
      id: _asInt(json['id']),
      planCode: (json['planCode'] ?? '').toString(),
      planName: (json['planName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startedAt: parseApiDate(json['startedAt']),
      expiresAt: parseApiDate(json['expiresAt']),
    );
  }
}


class PostingPackageModel {
  const PostingPackageModel({
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    this.includedFeatureCode = '',
    this.icon = '',
    this.isCombo = false,
  });

  final String code;
  final String name;
  final String description;
  final double price;
  final String includedFeatureCode;
  final String icon;
  final bool isCombo;

  factory PostingPackageModel.fromJson(Map<String, dynamic> json) {
    return PostingPackageModel(
      code: (json['code'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      price: _asDouble(json['price']),
      includedFeatureCode: (json['includedFeatureCode'] ?? '').toString().trim(),
      icon: (json['icon'] ?? '').toString().trim(),
      isCombo: _asBool(json['isCombo']),
    );
  }
}

class AddonFeatureModel {
  const AddonFeatureModel({
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    this.icon = '',
  });

  final String code;
  final String name;
  final String description;
  final double price;
  final String icon;

  factory AddonFeatureModel.fromJson(Map<String, dynamic> json) {
    return AddonFeatureModel(
      code: (json['code'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      price: _asDouble(json['price']),
      icon: (json['icon'] ?? '').toString().trim(),
    );
  }
}

class MembershipOverviewModel {
  const MembershipOverviewModel({
    this.plans = const <MembershipPlanModel>[],
    this.postingPackages = const <PostingPackageModel>[],
    this.addonFeatures = const <AddonFeatureModel>[],
    this.usage = const MembershipUsageModel(),
    this.activeMembership,
  });

  final List<MembershipPlanModel> plans;
  final List<PostingPackageModel> postingPackages;
  final List<AddonFeatureModel> addonFeatures;
  final MembershipUsageModel usage;
  final ActiveMembershipModel? activeMembership;

  factory MembershipOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawPlans = json['plans'];
    final plans = rawPlans is List
        ? rawPlans
            .whereType<Map>()
            .map((item) => MembershipPlanModel.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.code.isNotEmpty)
            .toList(growable: false)
        : const <MembershipPlanModel>[];
    final rawPostingPackages = json['postingPackages'];
    final postingPackages = rawPostingPackages is List
        ? rawPostingPackages
            .whereType<Map>()
            .map((item) => PostingPackageModel.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.code.isNotEmpty)
            .toList(growable: false)
        : const <PostingPackageModel>[];
    final rawAddonFeatures = json['addonFeatures'];
    final addonFeatures = rawAddonFeatures is List
        ? rawAddonFeatures
            .whereType<Map>()
            .map((item) => AddonFeatureModel.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.code.isNotEmpty)
            .toList(growable: false)
        : const <AddonFeatureModel>[];
    final usageRaw = json['usage'];
    final activeRaw = json['activeMembership'];
    return MembershipOverviewModel(
      plans: plans,
      postingPackages: postingPackages,
      addonFeatures: addonFeatures,
      usage: usageRaw is Map
          ? MembershipUsageModel.fromJson(Map<String, dynamic>.from(usageRaw))
          : const MembershipUsageModel(),
      activeMembership: activeRaw is Map
          ? ActiveMembershipModel.fromJson(Map<String, dynamic>.from(activeRaw))
          : null,
    );
  }
}

class MembershipPurchaseResult {
  const MembershipPurchaseResult({
    required this.message,
    required this.usage,
    this.activeMembership,
  });

  final String message;
  final MembershipUsageModel usage;
  final ActiveMembershipModel? activeMembership;
}

class AddonFeaturePurchaseResult {
  const AddonFeaturePurchaseResult({
    required this.message,
    required this.usage,
    this.propertyId = 0,
    this.featureCode = '',
    this.expiresAtUtc,
  });

  final String message;
  final MembershipUsageModel usage;
  final int propertyId;
  final String featureCode;
  final DateTime? expiresAtUtc;
}

class WalletTopupModel {
  const WalletTopupModel({
    required this.id,
    required this.amount,
    required this.paymentCode,
    required this.paymentProvider,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  final int id;
  final double amount;
  final String paymentCode;
  final String paymentProvider;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isPending => status.toLowerCase() == 'pending';

  factory WalletTopupModel.fromJson(Map<String, dynamic> json) {
    return WalletTopupModel(
      id: _asInt(json['id']),
      amount: _asDouble(json['amount']),
      paymentCode: (json['paymentCode'] ?? '').toString(),
      paymentProvider: (json['paymentProvider'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: parseApiDate(json['createdAt']) ?? DateTime.now(),
      paidAt: parseApiDate(json['paidAt']),
    );
  }
}

class WalletOverviewModel {
  const WalletOverviewModel({
    this.balance = 0,
    this.amountOptions = const <double>[],
    this.topups = const <WalletTopupModel>[],
    this.transactions = const <WalletTransactionModel>[],
  });

  final double balance;
  final List<double> amountOptions;
  final List<WalletTopupModel> topups;
  final List<WalletTransactionModel> transactions;

  factory WalletOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['amountOptions'];
    final rawTopups = json['topups'];
    final rawTransactions = json['transactions'];
    return WalletOverviewModel(
      balance: _asDouble(json['balance']),
      amountOptions: rawOptions is List
          ? rawOptions.map(_asDouble).where((item) => item > 0).toList(growable: false)
          : const <double>[],
      topups: rawTopups is List
          ? rawTopups
              .whereType<Map>()
              .map((item) => WalletTopupModel.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const <WalletTopupModel>[],
      transactions: rawTransactions is List
          ? rawTransactions
              .whereType<Map>()
              .map((item) => WalletTransactionModel.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const <WalletTransactionModel>[],
    );
  }
}

class WalletCheckoutFieldModel {
  const WalletCheckoutFieldModel({required this.name, required this.value});
  final String name;
  final String value;

  factory WalletCheckoutFieldModel.fromJson(Map<String, dynamic> json) {
    return WalletCheckoutFieldModel(
      name: (json['name'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
    );
  }
}

class WalletTopupCheckoutModel {
  const WalletTopupCheckoutModel({
    required this.topupId,
    required this.amount,
    required this.paymentCode,
    required this.paymentProvider,
    required this.status,
    required this.createdAt,
    this.message = '',
    this.checkoutUrl = '',
    this.qrCode = '',
    this.sePayCheckoutUrl = '',
    this.sePayFormFields = const <WalletCheckoutFieldModel>[],
    this.bankName = '',
    this.bankAccountNumber = '',
    this.bankAccountName = '',
  });

  final int topupId;
  final double amount;
  final String paymentCode;
  final String paymentProvider;
  final String status;
  final DateTime createdAt;
  final String message;
  final String checkoutUrl;
  final String qrCode;
  final String sePayCheckoutUrl;
  final List<WalletCheckoutFieldModel> sePayFormFields;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;

  bool get hasQr => qrCode.trim().isNotEmpty;
  bool get hasCheckout => checkoutUrl.trim().isNotEmpty;
  bool get hasSePayForm => sePayCheckoutUrl.trim().isNotEmpty && sePayFormFields.isNotEmpty;

  factory WalletTopupCheckoutModel.fromJson(Map<String, dynamic> json, {String message = ''}) {
    final rawFields = json['sePayFormFields'];
    return WalletTopupCheckoutModel(
      topupId: _asInt(json['topupId']),
      amount: _asDouble(json['amount']),
      paymentCode: (json['paymentCode'] ?? '').toString(),
      paymentProvider: (json['paymentProvider'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: parseApiDate(json['createdAt']) ?? DateTime.now(),
      message: message,
      checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
      qrCode: (json['qrCode'] ?? '').toString(),
      sePayCheckoutUrl: (json['sePayCheckoutUrl'] ?? '').toString(),
      sePayFormFields: rawFields is List
          ? rawFields
              .whereType<Map>()
              .map((item) => WalletCheckoutFieldModel.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.name.isNotEmpty)
              .toList(growable: false)
          : const <WalletCheckoutFieldModel>[],
      bankName: (json['bankName'] ?? '').toString(),
      bankAccountNumber: (json['bankAccountNumber'] ?? '').toString(),
      bankAccountName: (json['bankAccountName'] ?? '').toString(),
    );
  }
}

class WalletTopupStatusModel {
  const WalletTopupStatusModel({
    required this.id,
    required this.status,
    required this.paid,
    required this.balance,
    this.paidAt,
  });

  final int id;
  final String status;
  final bool paid;
  final double balance;
  final DateTime? paidAt;

  factory WalletTopupStatusModel.fromJson(Map<String, dynamic> json) {
    return WalletTopupStatusModel(
      id: _asInt(json['id']),
      status: (json['status'] ?? '').toString(),
      paid: _asBool(json['paid']),
      balance: _asDouble(json['balance']),
      paidAt: parseApiDate(json['paidAt']),
    );
  }
}
