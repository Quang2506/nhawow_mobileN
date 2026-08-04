import 'package:flutter_test/flutter_test.dart';
import 'package:nhawow_mobile/core/media_url_resolver.dart';

void main() {
  group('MediaUrlResolver', () {
    test('keeps Assets URL on the ASP.NET host', () {
      expect(
        MediaUrlResolver.resolve('/Assets/Cities/logo.png'),
        'https://localhost:44323/Assets/Cities/logo.png',
      );
    });

    test('converts legacy media property path to Assets', () {
      expect(
        MediaUrlResolver.resolve('/media/properties/14/gallery/a.png'),
        'https://localhost:44323/Assets/properties/14/gallery/a.png',
      );
    });

    test('converts physical web Assets path', () {
      expect(
        MediaUrlResolver.resolve(
          r'D:\Code\NhaWOW\Homenow\Assets\UserAvatars\20260622\a.jpeg',
        ),
        'https://localhost:44323/Assets/UserAvatars/20260622/a.jpeg',
      );
    });

    test('converts old Content VR path', () {
      expect(
        MediaUrlResolver.resolve('/Content/VR/20260429/17/scene.jpg'),
        'https://localhost:44323/Assets/Vr/20260429/17/scene.jpg',
      );
    });
  });
}
