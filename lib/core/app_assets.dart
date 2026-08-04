class AppAssets {
  AppAssets._();

  static const String _root = 'assets/web_assets';

  static const String brandLogo = '$_root/Cities/logo.png';
  static const String homeHeroDesktop = '$_root/Cities/ninhbinh.jpg';
  static const String homeHeroTablet = '$_root/Cities/ninhbinh_pad2_1.jpg';
  static const String homeHeroMobile = '$_root/Cities/ninhbinh_mobile.jpg';
  static const String homeHeroDesigned = '$_root/Cities/home_hero_modern.png';
  static const String homeHeroFull = '$_root/Cities/home_hero_full.png';
  static const String agentHero = '$_root/Cities/Agent.jpg';
  static const String accountBackground = '$_root/Cities/AcountBg.jpg';
  static const String landlordHeroDesktop = '$_root/Cities/landlord-hero-bg.jpg';
  static const String landlordHeroTablet = '$_root/Cities/landlord-hero-bgpad2_1.jpg';
  static const String landlordHeroMobile = '$_root/Cities/landlord-hero-bg_mobile.jpg';
  static const String landlordProblem = '$_root/Cities/owner-problem.jpg';
  static const String landlordPhone = '$_root/Cities/phone-visual.jpg';
  static const String vrService = '$_root/Cities/vr-service.jpg';
  static const String vrCameraBox = '$_root/Cities/vr-camera-box.jpg';
  static const String vrChart = '$_root/Cities/vr-chart.jpg';
  static const String zaloQr = '$_root/Cities/QrZalo.png';

  static const String postingGuideOverview = '$_root/Guide/guide_overview.png';
  static const List<String> postingGuideSteps = <String>[
    '$_root/Guide/01_login_dang_ky.png',
    '$_root/Guide/02_form_dang_ky.png',
    '$_root/Guide/03_xac_thuc_email_otp.png',
    '$_root/Guide/04_form_tao_bat_dong_san.png',
    '$_root/Guide/05_quan_ly_bai_dang.png',
    '$_root/Guide/06_form_dang_ky_vr360.png',
    '$_root/Guide/07_minh_hoa_vr360_phone.png',
  ];

  static String? amenityIcon(String amenityName) {
    final value = _foldVietnamese(amenityName);

    if (_containsAny(value, <String>['wifi', 'wi-fi'])) {
      return '$_root/Amenities/wifi.png';
    }
    if (_containsAny(value, <String>['internet', 'mang'])) {
      return '$_root/Amenities/internet.png';
    }
    if (_containsAny(value, <String>['dieu hoa', 'air conditioning'])) {
      return '$_root/Amenities/air-conditioner.png';
    }
    if (_containsAny(value, <String>['bon tam', 'bathtub'])) {
      return '$_root/Amenities/bathtub.png';
    }
    if (_containsAny(value, <String>['giuong', 'bed'])) {
      return '$_root/Amenities/bed.png';
    }
    if (_containsAny(value, <String>['ban an', 'dining table'])) {
      return '$_root/Amenities/dining_table.png';
    }
    if (_containsAny(value, <String>['thang may', 'elevator'])) {
      return '$_root/Amenities/elevator.png';
    }
    if (_containsAny(value, <String>['quat', 'fan'])) {
      return '$_root/Amenities/fan.png';
    }
    if (_containsAny(value, <String>['full noi that', 'day du noi that', 'noi that day du'])) {
      return '$_root/Amenities/full_nt.png';
    }
    if (_containsAny(value, <String>['nuoc nong', 'nong lanh', 'hot water'])) {
      return '$_root/Amenities/hot_water.png';
    }
    if (_containsAny(value, <String>['tu bep', 'kitchen cabinet'])) {
      return '$_root/Amenities/kitchen_cabinet.png';
    }
    if (_containsAny(value, <String>['bep', 'kitchen'])) {
      return '$_root/Amenities/kitchen.png';
    }
    if (_containsAny(value, <String>['cho de xe', 'bai do xe', 'parking'])) {
      return '$_root/Amenities/parking.png';
    }
    if (_containsAny(value, <String>['tu lanh', 'refrigerator'])) {
      return '$_root/Amenities/refrigerator.png';
    }
    if (_containsAny(value, <String>['khoa thong minh', 'smart lock'])) {
      return '$_root/Amenities/smart_lock.png';
    }
    if (_containsAny(value, <String>['tivi', 'ti vi', 'television'])) {
      return '$_root/Amenities/television.png';
    }
    if (_containsAny(value, <String>['tu quan ao', 'wardrobe'])) {
      return '$_root/Amenities/wardrobe.png';
    }
    if (_containsAny(value, <String>['may giat', 'washing machine'])) {
      return '$_root/Amenities/washing-machine.png';
    }
    if (_containsAny(value, <String>['binh nong lanh', 'may nuoc nong', 'water heater'])) {
      return '$_root/Amenities/water-heater.png';
    }
    if (_containsAny(value, <String>['may loc nuoc', 'water purifier'])) {
      return '$_root/Amenities/water_purifier.png';
    }

    return null;
  }

  static bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }

  static String _foldVietnamese(String value) {
    var result = value.trim().toLowerCase();
    const groups = <String, String>{
      'àáạảãâầấậẩẫăằắặẳẵ': 'a',
      'èéẹẻẽêềếệểễ': 'e',
      'ìíịỉĩ': 'i',
      'òóọỏõôồốộổỗơờớợởỡ': 'o',
      'ùúụủũưừứựửữ': 'u',
      'ỳýỵỷỹ': 'y',
      'đ': 'd',
    };
    for (final entry in groups.entries) {
      for (final character in entry.key.split('')) {
        result = result.replaceAll(character, entry.value);
      }
    }
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }
}
