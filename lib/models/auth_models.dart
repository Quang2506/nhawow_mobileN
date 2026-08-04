import 'models.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    required this.roleLabel,
    required this.isBroker,
    required this.isGoldAgent,
    required this.membershipCode,
    required this.emailVerified,
    required this.canManageListings,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String role;
  final String roleLabel;
  final bool isBroker;
  final bool isGoldAgent;
  final String membershipCode;
  final bool emailVerified;
  final bool canManageListings;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool toBool(Object? value) {
      if (value is bool) return value;
      final normalized = value?.toString().trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    return AuthUserModel(
      id: toInt(json['id']),
      name: (json['name'] ?? json['displayName'] ?? '').toString().trim(),
      email: (json['email'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString().trim(),
      avatarUrl: (json['avatarUrl'] ?? '').toString().trim(),
      role: (json['role'] ?? '').toString().trim(),
      roleLabel: (json['roleLabel'] ?? '').toString().trim(),
      isBroker: toBool(json['isBroker']),
      isGoldAgent: toBool(json['isGoldAgent']),
      membershipCode: (json['membershipCode'] ?? 'FREE').toString().trim(),
      emailVerified: toBool(json['emailVerified']),
      canManageListings: toBool(json['canManageListings']),
    );
  }

  AgentModel toAgentModel() {
    return AgentModel(
      id: id,
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
      roleLabel: roleLabel.isEmpty
          ? (isBroker ? 'Môi giới bất động sản' : 'Người dùng')
          : roleLabel,
      level: isBroker ? 1 : 0,
      verifiedListingCount: 0,
      membershipCode: membershipCode,
      isBroker: isBroker,
    );
  }
}

class AuthSessionModel {
  const AuthSessionModel({
    required this.token,
    required this.user,
    this.expiresInSeconds = 0,
  });

  final String token;
  final AuthUserModel user;
  final int expiresInSeconds;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final userValue = json['user'];
    final userMap = userValue is Map
        ? Map<String, dynamic>.from(userValue)
        : const <String, dynamic>{};
    final rawExpires = json['expiresInSeconds'];
    return AuthSessionModel(
      token: (json['token'] ?? '').toString().trim(),
      user: AuthUserModel.fromJson(userMap),
      expiresInSeconds: rawExpires is num
          ? rawExpires.toInt()
          : int.tryParse('$rawExpires') ?? 0,
    );
  }
}

class RegistrationResult {
  const RegistrationResult({
    required this.email,
    required this.needVerify,
    required this.otpExpireSeconds,
    this.message = '',
  });

  final String email;
  final bool needVerify;
  final int otpExpireSeconds;
  final String message;
}

class FavoriteToggleModel {
  const FavoriteToggleModel({
    required this.isFavorite,
    required this.favoriteIds,
  });

  final bool isFavorite;
  final List<int> favoriteIds;
}
