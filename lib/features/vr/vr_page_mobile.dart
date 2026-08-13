import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import '../../app/app_store.dart';
import '../../data/remote/nhawow_api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';

/// Trình xem VR 360° trực tiếp bằng Flutter trên Android, iOS và Web.
///
/// Màn hình này không mở WebView, trình duyệt ngoài hoặc /Property/Vr/{id}.
/// Scene, panorama và hotspot được lấy trực tiếp từ Mobile API.
/// Trên Flutter Web, cảm biến xoay được ẩn vì panorama_viewer không dùng sensor.
class VrPage extends StatefulWidget {
  const VrPage({required this.property, super.key});

  final PropertyModel property;

  @override
  State<VrPage> createState() => _VrPageState();
}

class _VrPageState extends State<VrPage> {
  static const Color _background = Color(0xFF030507);
  static const Duration _imageTimeout = Duration(seconds: 35);
  static const Duration _preloadDelay = Duration(milliseconds: 1400);

  final NhaWowApiService _api = NhaWowApiService();
  PanoramaController? _panoramaController;
  Widget? _panoramaLayer;
  int _viewerRevision = 0;
  int _readyRevision = -1;
  final Connectivity _connectivity = Connectivity();

  VrTourModel? _tour;
  VrSceneModel? _activeScene;

  Timer? _preloadTimer;
  int _loadGeneration = 0;

  bool _loadingTour = true;
  bool _switchingScene = false;
  bool _textureReady = false;
  bool _sensorEnabled = false;
  bool _autoRotateEnabled = false;
  String? _error;
  String? _pendingSceneKey;
  String? _preloadedSceneKey;
  String? _preloadedPanoramaUrl;
  String? _previousPanoramaUrlToEvict;

  double _entryPitch = 0;
  double _entryYaw = 0;
  double _entryHfov = 110;
  double _currentPitch = 0;
  double _currentYaw = 0;

  final Set<String> _memoryTouchedUrls = <String>{};

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadTour());
    });
  }

  Future<void> _loadTour() async {
    final generation = ++_loadGeneration;
    _preloadTimer?.cancel();

    if (mounted) {
      setState(() {
        _loadingTour = true;
        _switchingScene = false;
        _textureReady = false;
        _error = null;
        _pendingSceneKey = null;
        _preloadedSceneKey = null;
        _preloadedPanoramaUrl = null;
      });
    }

    VrTourModel tour;
    try {
      tour = await _api.fetchPropertyVr(
        widget.property.id,
        language: AppScope.of(context).apiLanguageCode,
      );
    } catch (error) {
      // Giữ khả năng mở VR khi detail API đã trả scene nhưng endpoint VR riêng
      // chưa được publish đồng thời. Hotspot chỉ đầy đủ khi endpoint mới hoạt động.
      final fallbackScenes = widget.property.vrScenes
          .where((scene) => scene.canOpenNatively)
          .toList(growable: false);
      if (fallbackScenes.isEmpty) {
        if (!mounted || generation != _loadGeneration) return;
        setState(() {
          _loadingTour = false;
          _error = _friendlyError(error);
        });
        return;
      }

      final defaultScene = _firstWhereOrNull(
        fallbackScenes,
        (scene) => scene.isDefault,
      );
      tour = VrTourModel(
        propertyId: widget.property.id,
        isVrAvailable: widget.property.isVrAvailable,
        defaultSceneKey: defaultScene?.sceneKey ?? fallbackScenes.first.sceneKey,
        scenes: fallbackScenes,
      );
    }

    if (!mounted || generation != _loadGeneration) return;

    final nativeScenes = tour.nativeScenes;
    if (!tour.isVrAvailable || nativeScenes.isEmpty) {
      setState(() {
        _loadingTour = false;
        _error = context.tr('Căn nhà này chưa có ảnh VR 360° phù hợp với ứng dụng.');
      });
      return;
    }

    final initialScene = _resolveInitialScene(tour, nativeScenes);
    _tour = tour;

    try {
      await _warmScene(initialScene);
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loadingTour = false;
        _error = context.tr(
          'Không tải được ảnh VR đầu tiên. {error}',
          {'error': _friendlyError(error)},
        );
      });
      return;
    }

    if (!mounted || generation != _loadGeneration) return;
    _setActiveScene(
      initialScene,
      pitch: initialScene.pitch,
      yaw: initialScene.yaw,
      hfov: initialScene.hfov,
    );
    setState(() => _loadingTour = false);
  }

  VrSceneModel _resolveInitialScene(
    VrTourModel tour,
    List<VrSceneModel> scenes,
  ) {
    final wantedKey = tour.defaultSceneKey.trim().toLowerCase();
    if (wantedKey.isNotEmpty) {
      final byKey = _firstWhereOrNull(
        scenes,
        (scene) => scene.sceneKey.trim().toLowerCase() == wantedKey,
      );
      if (byKey != null) return byKey;
    }
    return _firstWhereOrNull(scenes, (scene) => scene.isDefault) ?? scenes.first;
  }

  Future<void> _switchToScene(
    VrSceneModel target, {
    double? pitch,
    double? yaw,
    double? hfov,
  }) async {
    final current = _activeScene;
    if (current == null || _switchingScene) return;

    if (_sameScene(current, target)) {
      _setView(
        pitch ?? target.pitch,
        yaw ?? target.yaw,
        hfov ?? target.hfov,
      );
      return;
    }

    // Dừng toàn bộ chuyển động trước khi đổi scene. Bản cũ cố xoay/zoom về
    // hotspot rồi mới đổi ảnh, vì vậy người dùng có cảm giác panorama quay tròn
    // và giật. Hiệu ứng chọn hotspot giờ được xử lý ngay trên icon bước chân.
    _panoramaController?.setAnimSpeed(0);
    _autoRotateEnabled = false;

    if (!mounted) return;
    final generation = ++_loadGeneration;
    setState(() {
      _switchingScene = true;
      _pendingSceneKey = target.sceneKey;
      _error = null;
    });

    try {
      // Nếu người dùng chọn một phòng khác với phòng đã preload, bỏ ngay bản
      // giải mã preload khỏi RAM trước khi tải target. Nhờ vậy tối đa chỉ giữ
      // texture scene hiện tại + scene đích trong lúc chuyển phòng.
      await _dropUnusedPreload(target.panoramaUrl);

      // Ảnh cũ vẫn được hiển thị trong khi ảnh mới tải và giải mã vào RAM.
      await _warmScene(target);
      if (!mounted || generation != _loadGeneration) return;

      _setActiveScene(
        target,
        pitch: pitch ?? target.pitch,
        yaw: yaw ?? target.yaw,
        hfov: hfov ?? target.hfov,
      );
      // Giữ trạng thái chuyển phòng cho tới khi texture mới thực sự sẵn sàng.
      // _onTextureReady sẽ tắt badge và mở lại thao tác.
      setState(() {});
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _switchingScene = false;
        _pendingSceneKey = null;
      });
      _showMessage(
        context.tr(
          'Không tải được phòng VR này. {error}',
          {'error': _friendlyError(error)},
        ),
      );
    }
  }

  void _setActiveScene(
    VrSceneModel scene, {
    required double pitch,
    required double yaw,
    required double hfov,
  }) {
    _preloadTimer?.cancel();
    final previousUrl = _activeScene?.panoramaUrl.trim() ?? '';
    final nextUrl = scene.panoramaUrl.trim();
    if (previousUrl.isNotEmpty && previousUrl != nextUrl) {
      _previousPanoramaUrlToEvict = previousUrl;
    }
    final stalePreloadUrl = _preloadedPanoramaUrl;
    if (stalePreloadUrl != null &&
        stalePreloadUrl.isNotEmpty &&
        stalePreloadUrl != nextUrl) {
      unawaited(_evictMemoryImage(stalePreloadUrl));
    }
    _activeScene = scene;
    _entryPitch = _clampPitch(pitch);
    _entryYaw = _normalizeYaw(yaw);
    _entryHfov = _normalizeHfov(hfov);
    _currentPitch = _entryPitch;
    _currentYaw = _entryYaw;
    _textureReady = false;
    _preloadedSceneKey = null;
    _preloadedPanoramaUrl = null;
    _memoryTouchedUrls.add(scene.panoramaUrl);
    _installPanoramaLayer(scene);
  }

  void _installPanoramaLayer(VrSceneModel scene) {
    final previousController = _panoramaController;
    final controller = PanoramaController();
    final revision = ++_viewerRevision;

    _readyRevision = -1;
    _panoramaController = controller;
    _panoramaLayer = _createPanoramaLayer(scene, controller, revision);

    // Mỗi scene dùng một PanoramaViewer/Controller mới. Điều này tránh lỗi của
    // panorama_viewer trên Web: didUpdateWidget tải lại texture ở mọi setState,
    // tích lũy listener và báo "setState() called during build". Controller cũ
    // chỉ được dispose sau frame thay widget để không chạm vào renderer cũ.
    if (previousController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previousController.dispose();
      });
    }
  }

  Widget _createPanoramaLayer(
    VrSceneModel scene,
    PanoramaController controller,
    int revision,
  ) {
    return PanoramaViewer(
      key: ValueKey<String>('vr-${scene.sceneKey}-$revision'),
      latitude: _entryPitch,
      longitude: _entryYaw,
      zoom: _hfovToZoom(_entryHfov),
      minLatitude: -85,
      maxLatitude: 85,
      minZoom: 0.72,
      maxZoom: 2.75,
      sensitivity: 0.82,
      latSegments: kIsWeb ? 20 : 24,
      lonSegments: kIsWeb ? 40 : 48,
      sensorControl: !kIsWeb && _sensorEnabled
          ? SensorControl.orientation
          : SensorControl.none,
      panoramaController: controller,
      hotspots: _buildHotspots(scene),
      onImageLoad: () => _onTextureReady(revision),
      onViewChanged: (longitude, latitude, tilt) {
        if (revision != _viewerRevision) return;
        _currentYaw = _normalizeYaw(longitude);
        _currentPitch = _clampPitch(latitude);
      },
      child: Image(
        image: _panoramaImageProvider(scene.panoramaUrl),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: kIsWeb ? FilterQuality.low : FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          final message = context.tr(
            'Không thể giải mã ảnh panorama trên thiết bị này.',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                revision != _viewerRevision ||
                _error == message) {
              return;
            }
            setState(() {
              _textureReady = false;
              _switchingScene = false;
              _pendingSceneKey = null;
              _error = message;
            });
          });
          return const SizedBox.expand();
        },
      ),
    );
  }

  Future<void> _handleHotspot(VrHotspotModel hotspot) async {
    if (_switchingScene) return;

    if (!hotspot.isNavigation) {
      _showMessage(
        hotspot.text.trim().isEmpty
            ? context.tr('Điểm thông tin VR.')
            : hotspot.text,
      );
      return;
    }

    final target = _sceneByKey(hotspot.targetSceneKey);
    if (target == null) {
      _showMessage(context.tr('Phòng liên kết không còn tồn tại.'));
      return;
    }

    await _switchToScene(
      target,
      pitch: hotspot.targetPitch,
      yaw: hotspot.targetYaw,
      hfov: hotspot.targetHfov,
    );
  }

  VrSceneModel? _sceneByKey(String key) {
    final normalized = key.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return _firstWhereOrNull(
      _nativeScenes,
      (scene) => scene.sceneKey.trim().toLowerCase() == normalized,
    );
  }

  List<VrSceneModel> get _nativeScenes =>
      _tour?.nativeScenes ?? const <VrSceneModel>[];

  Future<void> _warmScene(VrSceneModel scene) async {
    final url = scene.panoramaUrl.trim();
    if (url.isEmpty) {
      throw StateError(context.tr('URL ảnh panorama trống.'));
    }

    _memoryTouchedUrls.add(url);
    final provider = _panoramaImageProvider(url);
    await _resolveImage(provider).timeout(_imageTimeout);
  }

  ImageProvider<Object> _panoramaImageProvider(String url) {
    // Trên Web, NetworkImage dùng trực tiếp cache HTTP của trình duyệt và
    // tránh thêm một lớp cache-manager không cần thiết. Ảnh vẫn cần header
    // Access-Control-Allow-Origin vì PanoramaViewer dựng texture WebGL.
    if (kIsWeb) return NetworkImage(url);
    return CachedNetworkImageProvider(url);
  }

  Future<void> _evictMemoryImage(String url) async {
    await _panoramaImageProvider(url).evict();
  }

  Future<void> _dropUnusedPreload(String targetUrl) async {
    final preloadedUrl = _preloadedPanoramaUrl?.trim() ?? '';
    if (preloadedUrl.isEmpty || preloadedUrl == targetUrl.trim()) return;

    _preloadedSceneKey = null;
    _preloadedPanoramaUrl = null;
    await _evictMemoryImage(preloadedUrl);
  }

  Future<void> _resolveImage(ImageProvider<Object> provider) {
    final completer = Completer<void>();
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  void _onTextureReady(int revision) {
    // panorama_viewer có thể gọi onImageLoad ngay trong quá trình build khi ảnh
    // đã nằm trong cache. Chuyển toàn bộ cập nhật sang frame kế tiếp để tránh
    // "setState() or markNeedsBuild() called during build" và vòng lặp dựng ảnh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revision != _viewerRevision) return;
      if (_readyRevision == revision) return;
      _readyRevision = revision;

      setState(() {
        _textureReady = true;
        _switchingScene = false;
        _pendingSceneKey = null;
        if (_error ==
            context.tr('Không thể giải mã ảnh panorama trên thiết bị này.')) {
          _error = null;
        }
      });

      _setView(_entryPitch, _entryYaw, _entryHfov);
      _applyAutoRotate();
      _releasePreviousSceneMemory();
      _scheduleNeighborPreload();
    });
  }

  void _releasePreviousSceneMemory() {
    final previousUrl = _previousPanoramaUrlToEvict;
    _previousPanoramaUrlToEvict = null;
    if (previousUrl == null || previousUrl.isEmpty) return;

    // Chờ frame mới dùng texture ổn định rồi bỏ bản giải mã của scene cũ.
    // CachedNetworkImageProvider.evict chỉ xóa ImageCache trong RAM; file cache
    // trên ổ đĩa vẫn còn để người dùng quay lại phòng nhanh hơn.
    Future<void>.delayed(const Duration(milliseconds: 220), () async {
      await _evictMemoryImage(previousUrl);
    });
  }

  void _scheduleNeighborPreload() {
    _preloadTimer?.cancel();
    final current = _activeScene;
    if (current == null || _nativeScenes.length < 2) return;

    _preloadTimer = Timer(_preloadDelay, () {
      if (!mounted || _switchingScene) return;
      unawaited(_preloadOneNeighbor(current));
    });
  }

  Future<void> _preloadOneNeighbor(VrSceneModel current) async {
    try {
      final connections = await _connectivity.checkConnectivity();
      final allow = kIsWeb ||
          connections.contains(ConnectivityResult.wifi) ||
          connections.contains(ConnectivityResult.ethernet);
      if (!allow || !mounted) return;

      final candidate = _neighborCandidate(current);
      if (candidate == null ||
          candidate.sceneKey == _preloadedSceneKey ||
          _sameScene(candidate, current)) {
        return;
      }

      await _warmScene(candidate);
      final activeAfterPreload = _activeScene;
      if (!mounted ||
          activeAfterPreload == null ||
          !_sameScene(activeAfterPreload, current)) {
        await _evictMemoryImage(candidate.panoramaUrl);
        return;
      }
      _preloadedSceneKey = candidate.sceneKey;
      _preloadedPanoramaUrl = candidate.panoramaUrl;
    } catch (_) {
      // Preload chạy nền; lỗi mạng không được ảnh hưởng scene đang xem.
    }
  }

  VrSceneModel? _neighborCandidate(VrSceneModel current) {
    for (final hotspot in current.hotspots) {
      if (!hotspot.isNavigation) continue;
      final linked = _sceneByKey(hotspot.targetSceneKey);
      if (linked != null && !_sameScene(linked, current)) return linked;
    }

    final scenes = _nativeScenes;
    final index = scenes.indexWhere((scene) => _sameScene(scene, current));
    if (index < 0 || scenes.length < 2) return null;
    return scenes[(index + 1) % scenes.length];
  }

  List<Hotspot> _buildHotspots(VrSceneModel scene) {
    return scene.hotspots.map((hotspot) {
      final navigates = hotspot.isNavigation &&
          _sceneByKey(hotspot.targetSceneKey) != null;
      return Hotspot(
        name: 'vr-hotspot-${hotspot.id}',
        latitude: _clampPitch(hotspot.pitch),
        longitude: _normalizeYaw(hotspot.yaw),
        // Hotspot bước chân giảm gần một nửa so với bản cũ.
        // Vùng 50x50 vẫn đủ bấm trên điện thoại nhưng không che nhiều ảnh.
        width: navigates ? 50 : 42,
        height: navigates ? 50 : 42,
        widget: _VrHotspotButton(
          label: hotspot.text,
          isNavigation: navigates,
          onTap: () => _handleHotspot(hotspot),
        ),
      );
    }).toList(growable: false);
  }

  void _toggleSensor() {
    final scene = _activeScene;
    if (scene == null || _switchingScene) return;

    _rememberCurrentView();
    final enabled = !_sensorEnabled;
    _panoramaController?.setAnimSpeed(0);

    setState(() {
      _autoRotateEnabled = false;
      _sensorEnabled = enabled;
      _entryPitch = _currentPitch;
      _entryYaw = _currentYaw;
      _entryHfov = _zoomToHfov(_safeControllerZoom());
      _textureReady = false;
      _installPanoramaLayer(scene);
    });
  }

  void _toggleAutoRotate() {
    final scene = _activeScene;
    if (scene == null || _switchingScene) return;

    final next = !_autoRotateEnabled;
    final mustDisableSensor = next && _sensorEnabled;
    if (mustDisableSensor) _rememberCurrentView();

    setState(() {
      _autoRotateEnabled = next;
      if (mustDisableSensor) {
        _sensorEnabled = false;
        _entryPitch = _currentPitch;
        _entryYaw = _currentYaw;
        _entryHfov = _zoomToHfov(_safeControllerZoom());
        _textureReady = false;
        _installPanoramaLayer(scene);
      }
    });
    _applyAutoRotate();
  }

  void _applyAutoRotate() {
    _panoramaController?.setAnimSpeed(_autoRotateEnabled ? -0.65 : 0);
  }

  void _resetView() {
    final scene = _activeScene;
    if (scene == null) return;
    _setView(scene.pitch, scene.yaw, scene.hfov);
  }

  void _setView(double pitch, double yaw, double hfov) {
    final controller = _panoramaController;
    if (controller == null) return;
    controller.setView(_clampPitch(pitch), _normalizeYaw(yaw));
    controller.setZoom(_hfovToZoom(hfov));
  }

  void _zoomBy(double factor) {
    final controller = _panoramaController;
    if (controller == null || !_textureReady) return;
    final next = (_safeControllerZoom() * factor).clamp(0.72, 2.75);
    controller.setZoom(next.toDouble());
  }

  void _rememberCurrentView() {
    final controller = _panoramaController;
    if (controller == null) return;
    try {
      _currentPitch = controller.getLatitude();
      _currentYaw = controller.getLongitude();
    } catch (_) {
      // Controller chưa gắn vào viewer: giữ giá trị callback gần nhất.
    }
  }

  double _safeControllerZoom() {
    final controller = _panoramaController;
    if (controller == null) return _hfovToZoom(_entryHfov);
    try {
      final zoom = controller.getZoom();
      if (zoom.isFinite && zoom > 0) return zoom;
    } catch (_) {
      // Viewer chưa sẵn sàng.
    }
    return _hfovToZoom(_entryHfov);
  }

  double _hfovToZoom(double hfov) {
    final normalized = _normalizeHfov(hfov);
    return (110 / normalized).clamp(0.72, 2.75).toDouble();
  }

  double _zoomToHfov(double zoom) {
    final normalized = zoom.clamp(0.72, 2.75).toDouble();
    return _normalizeHfov(110 / normalized);
  }

  double _normalizeHfov(double value) {
    if (!value.isFinite || value <= 0) return 110;
    return value.clamp(40, 135).toDouble();
  }

  double _clampPitch(double value) {
    if (!value.isFinite) return 0;
    return value.clamp(-85, 85).toDouble();
  }

  double _normalizeYaw(double value) {
    if (!value.isFinite) return 0;
    var normalized = value % 360;
    if (normalized > 180) normalized -= 360;
    if (normalized < -180) normalized += 360;
    return normalized;
  }

  bool _sameScene(VrSceneModel a, VrSceneModel b) =>
      a.sceneKey.trim().toLowerCase() == b.sceneKey.trim().toLowerCase();

  T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T) test) {
    for (final value in values) {
      if (test(value)) return value;
    }
    return null;
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = text.toLowerCase();
    if (kIsWeb &&
        (lower.contains('encodingerror') ||
            lower.contains('cannot be decoded') ||
            lower.contains('failed to fetch'))) {
      return context.tr(
        'Trình duyệt không đọc được ảnh VR. Hãy kiểm tra CORS của thư mục /Assets/Vr và tải lại ứng dụng.',
      );
    }
    if (text.isEmpty) {
      return context.tr('Vui lòng kiểm tra mạng và thử lại.');
    }
    return text;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr(message)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _close() {
    unawaited(Navigator.of(context).maybePop().then<void>((_) {}));
  }

  @override
  void dispose() {
    _loadGeneration++;
    _preloadTimer?.cancel();
    // Không gọi setAnimSpeed trong dispose: panorama_viewer không gỡ listener
    // controller khi State con bị hủy. Dispose thẳng controller để xóa listener.
    _panoramaController?.dispose();

    // Chỉ giải phóng bản giải mã trong ImageCache. File trên ổ đĩa vẫn được
    // CachedNetworkImage giữ lại, nên lần mở sau không cần tải lại từ Internet.
    for (final url in _memoryTouchedUrls) {
      unawaited(_evictMemoryImage(url));
    }

    if (!kIsWeb) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingTour) return _buildInitialLoading();
    if (_error != null && _activeScene == null) return _buildError();

    final scene = _activeScene;
    if (scene == null) return _buildError();

    final panoramaLayer = _panoramaLayer;
    if (panoramaLayer == null) return _buildError();

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPreview(scene),
        panoramaLayer,
        if (!_textureReady) _buildTextureLoading(scene),
        _buildTopBar(scene),
        _buildRightControls(),
        _buildSceneBar(scene),
        if (_switchingScene) _buildSwitchingBadge(),
        if (_error != null) _buildNonBlockingError(),
      ],
    );
  }

  Widget _buildPreview(VrSceneModel scene) {
    final previewUrl = scene.previewUrl.trim().isNotEmpty
        ? scene.previewUrl.trim()
        : widget.property.thumbnailUrl.trim();
    if (previewUrl.isEmpty) return const ColoredBox(color: _background);

    return CachedNetworkImage(
      imageUrl: previewUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      errorWidget: (_, __, ___) => const ColoredBox(color: _background),
    );
  }

  Widget _buildInitialLoading() {
    final previewUrl = widget.property.thumbnailUrl.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (previewUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: previewUrl,
            fit: BoxFit.cover,
            color: Colors.black54,
            colorBlendMode: BlendMode.darken,
            errorWidget: (_, __, ___) =>
                const ColoredBox(color: _background),
          )
        else
          const ColoredBox(color: _background),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                context.tr('Đang tải dữ liệu VR 360°…'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _RoundIconButton(
                tooltip: context.tr('Quay lại'),
                icon: Icons.arrow_back_rounded,
                onPressed: _close,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.vrpano_outlined,
                    size: 58,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _error ?? context.tr('Không có dữ liệu VR.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loadTour,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.tr('Tải lại')),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _RoundIconButton(
              tooltip: context.tr('Quay lại'),
              icon: Icons.arrow_back_rounded,
              onPressed: _close,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextureLoading(VrSceneModel scene) {
    // Khi đổi phòng, ảnh đích đã được warm vào cache. Không phủ màn hình bằng
    // vòng quay lớn vì dễ tạo cảm giác lag; giữ preview và badge chuyển cảnh.
    if (_switchingScene) return const SizedBox.shrink();

    return IgnorePointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.22),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Text(
                  context.tr(
                    'Đang dựng {scene}…',
                    {'scene': _sceneTitle(scene)},
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(VrSceneModel scene) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              _RoundIconButton(
                tooltip: context.tr('Quay lại'),
                icon: Icons.arrow_back_rounded,
                onPressed: _close,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _sceneTitle(scene),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        context.tr('Kéo để nhìn quanh • Chụm để thu phóng'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightControls() {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 46),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb) ...[
                _RoundIconButton(
                  tooltip: _sensorEnabled
                      ? context.tr('Tắt cảm biến')
                      : context.tr('Bật cảm biến'),
                  icon: _sensorEnabled
                      ? Icons.screen_rotation_rounded
                      : Icons.screen_lock_rotation_rounded,
                  selected: _sensorEnabled,
                  onPressed: _toggleSensor,
                ),
                const SizedBox(height: 9),
              ],
              _RoundIconButton(
                tooltip: _autoRotateEnabled
                    ? context.tr('Dừng tự xoay')
                    : context.tr('Tự xoay'),
                icon: _autoRotateEnabled
                    ? Icons.pause_rounded
                    : Icons.threesixty_rounded,
                selected: _autoRotateEnabled,
                onPressed: _toggleAutoRotate,
              ),
              const SizedBox(height: 9),
              _RoundIconButton(
                tooltip: context.tr('Đặt lại góc nhìn'),
                icon: Icons.center_focus_strong_rounded,
                onPressed: _resetView,
              ),
              const SizedBox(height: 9),
              _RoundIconButton(
                tooltip: context.tr('Phóng to'),
                icon: Icons.add_rounded,
                onPressed: () => _zoomBy(1.16),
              ),
              const SizedBox(height: 9),
              _RoundIconButton(
                tooltip: context.tr('Thu nhỏ'),
                icon: Icons.remove_rounded,
                onPressed: () => _zoomBy(1 / 1.16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSceneBar(VrSceneModel active) {
    final scenes = _nativeScenes;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              scrollDirection: Axis.horizontal,
              itemCount: scenes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final scene = scenes[index];
                final selected = _sameScene(scene, active);
                final pending = _pendingSceneKey?.trim().toLowerCase() ==
                    scene.sceneKey.trim().toLowerCase();
                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: pending
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          selected
                              ? Icons.vrpano_rounded
                              : Icons.meeting_room_outlined,
                          size: 17,
                        ),
                  label: Text(_sceneTitle(scene)),
                  onSelected: _switchingScene
                      ? null
                      : (_) {
                          if (!selected) {
                            unawaited(_switchToScene(scene));
                          }
                        },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchingBadge() {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 82),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF041A34).withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF54D8FF).withValues(alpha: 0.62),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    color: Color(0xFF75E6FF),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('Đang chuyển cảnh…'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNonBlockingError() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 82),
          child: Material(
            color: Colors.red.shade800.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _sceneTitle(VrSceneModel scene) {
    final title = scene.title.trim();
    return context.tr(title.isEmpty ? scene.sceneKey : title);
  }
}

class _VrHotspotButton extends StatefulWidget {
  const _VrHotspotButton({
    required this.label,
    required this.isNavigation,
    required this.onTap,
  });

  final String label;
  final bool isNavigation;
  final Future<void> Function() onTap;

  @override
  State<_VrHotspotButton> createState() => _VrHotspotButtonState();
}

class _VrHotspotButtonState extends State<_VrHotspotButton>
    with SingleTickerProviderStateMixin {
  static const Duration _effectDuration = Duration(milliseconds: 2100);

  late final AnimationController _effectController;
  bool _hovered = false;
  bool _focused = false;
  bool _activating = false;

  @override
  void initState() {
    super.initState();

    // Chỉ animation riêng hotspot được chạy, không setState liên tục cho
    // PanoramaViewer. RepaintBoundary ở dưới giúp hiệu ứng không làm dựng lại
    // toàn bộ ảnh panorama.
    _effectController = AnimationController(
      vsync: this,
      duration: _effectDuration,
    )..repeat();
  }

  Future<void> _activate() async {
    if (_activating) return;

    setState(() => _activating = true);
    try {
      await widget.onTap();
    } finally {
      if (!mounted) return;
      setState(() => _activating = false);
    }
  }

  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeLabel = widget.label.trim().isEmpty
        ? (widget.isNavigation
            ? context.tr('Đi tới phòng')
            : context.tr('Thông tin'))
        : context.tr(widget.label.trim());

    if (!widget.isNavigation) {
      return Tooltip(
        message: safeLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _activate,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.68),
                border: Border.all(color: Colors.white70, width: 1),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: safeLabel,
      child: Tooltip(
        message: safeLabel,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (value) {
            if (mounted) setState(() => _hovered = value);
          },
          onShowFocusHighlight: (value) {
            if (mounted) setState(() => _focused = value);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _activate,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _effectController,
                builder: (context, child) {
                  final progress = _effectController.value;

                  // 0 -> 1 -> 0, tạo nhịp thở mềm và chậm.
                  final breath =
                      (math.sin(progress * math.pi * 2 - math.pi / 2) + 1) / 2;

                  final emphasized = _hovered || _focused || _activating;
                  final scale = 0.96 +
                      breath * 0.07 +
                      (emphasized ? 0.035 : 0) +
                      (_activating ? 0.035 : 0);

                  return Transform.scale(
                    scale: scale,
                    child: CustomPaint(
                      // Bản cũ 86px; bản mới 44px, gần đúng một nửa.
                      size: const Size.square(44),
                      painter: _VrFootstepHotspotPainter(
                        emphasis: emphasized ? 1.0 : 0.72,
                        rippleProgress: progress,
                        breath: breath,
                        activating: _activating,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VrFootstepHotspotPainter extends CustomPainter {
  const _VrFootstepHotspotPainter({
    required this.emphasis,
    required this.rippleProgress,
    required this.breath,
    required this.activating,
  });

  final double emphasis;
  final double rippleProgress;
  final double breath;
  final bool activating;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // Phần lõi chỉ còn khoảng 27px đường kính. Phần còn lại dành cho hai vòng
    // gợn nước, nên tổng hotspot vẫn nhỏ mà hiệu ứng vẫn nhìn rõ.
    final baseRadius = size.shortestSide * 0.275;
    final coreRadius = baseRadius * (0.97 + breath * 0.06);
    final strength = activating ? 1.0 : emphasis;

    _drawRipple(
      canvas,
      center,
      baseRadius,
      rippleProgress,
      strength,
    );
    _drawRipple(
      canvas,
      center,
      baseRadius,
      (rippleProgress + 0.5) % 1.0,
      strength * 0.78,
    );

    final glowRadius = coreRadius * (1.48 + breath * 0.10);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF56E6FF).withValues(alpha: 0.42 * strength),
          const Color(0xFF159BFF).withValues(alpha: 0.16 * strength),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: glowRadius),
      );
    canvas.drawCircle(center, glowRadius, glowPaint);

    final basePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF194D7C),
          Color(0xFF071B33),
        ],
        stops: [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );
    canvas.drawCircle(center, coreRadius, basePaint);

    final outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..color = const Color(0xFF9AF3FF)
          .withValues(alpha: 0.88 * strength);
    canvas.drawCircle(center, coreRadius, outerRing);

    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF35BFFF)
          .withValues(alpha: 0.78 * strength);
    canvas.drawCircle(center, coreRadius * 0.77, innerRing);

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF64DFFF)
          .withValues(alpha: 0.48 * strength);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: coreRadius * 1.22),
      -0.32,
      2.05,
      false,
      orbitPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: coreRadius * 1.22),
      2.80,
      1.34,
      false,
      orbitPaint,
    );

    final footPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;

    final footGlow = Paint()
      ..color = const Color(0xFF9DF5FF)
          .withValues(alpha: 0.58 * strength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);

    // Giữ đúng tỷ lệ đôi dấu chân của bản cũ nhưng thu nhỏ theo coreRadius.
    final footScale = coreRadius / 31.0;
    _drawFoot(
      canvas,
      center.translate(-coreRadius * 0.29, coreRadius * 0.02),
      -0.13,
      footScale,
      footGlow,
      footPaint,
    );
    _drawFoot(
      canvas,
      center.translate(coreRadius * 0.29, -coreRadius * 0.02),
      0.13,
      footScale,
      footGlow,
      footPaint,
    );
  }

  void _drawRipple(
    Canvas canvas,
    Offset center,
    double baseRadius,
    double progress,
    double strength,
  ) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final radius = baseRadius * (1.12 + progress * 0.70);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15 - progress * 0.42
      ..color = const Color(0xFF69E7FF).withValues(
        alpha: opacity * 0.48 * strength,
      );

    canvas.drawCircle(center, radius, paint);
  }

  void _drawFoot(
    Canvas canvas,
    Offset center,
    double angle,
    double scale,
    Paint glowPaint,
    Paint fillPaint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(scale);

    final toe = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-6.2, -16.2, 12.4, 17.5),
      const Radius.elliptical(7, 9),
    );
    final heel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-5.4, 4.0, 10.8, 13.6),
      const Radius.circular(5.4),
    );
    final soleLine = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-5.4, 0.4, 10.8, 2.8),
      const Radius.circular(1.4),
    );

    canvas.drawRRect(toe, glowPaint);
    canvas.drawRRect(heel, glowPaint);
    canvas.drawRRect(toe, fillPaint);
    canvas.drawRRect(heel, fillPaint);

    final cutPaint = Paint()
      ..color = const Color(0xFF0A2A4C)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(soleLine, cutPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VrFootstepHotspotPainter oldDelegate) {
    return oldDelegate.emphasis != emphasis ||
        oldDelegate.rippleProgress != rippleProgress ||
        oldDelegate.breath != breath ||
        oldDelegate.activating != activating;
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? const Color(0xFF009FE3).withValues(alpha: 0.92)
            : Colors.black.withValues(alpha: 0.58),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 23),
          ),
        ),
      ),
    );
  }
}
