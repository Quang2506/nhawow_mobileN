import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../data/remote/api_transport.dart';
import '../features/login_page.dart';
import '../l10n/app_localizations.dart';

class AuthGate {
  const AuthGate._();

  static Future<bool> ensureLoggedIn(BuildContext context) async {
    final store = AppScope.of(context);
    if (store.isLoggedIn) return true;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const LoginPage()),
    );
    if (!context.mounted) return false;
    return result == true || store.isLoggedIn;
  }

  static Future<bool> ensurePostingPermission(BuildContext context) async {
    final loggedIn = await ensureLoggedIn(context);
    if (!loggedIn || !context.mounted) return false;

    final store = AppScope.of(context);
    try {
      final allowed = await store.ensurePostingPermission();
      if (!context.mounted) return false;
      if (!allowed) {
        _showMessage(
          context,
          context.tr('Tài khoản chưa được cấp quyền đăng tin.'),
        );
      }
      return allowed;
    } on ApiTransportException catch (error) {
      if (error.needLogin && context.mounted) {
        final loggedInAgain = await ensureLoggedIn(context);
        if (loggedInAgain && context.mounted) {
          try {
            return await AppScope.of(context).ensurePostingPermission();
          } catch (retryError) {
            if (context.mounted) {
              _showMessage(context, context.tr(retryError.toString()));
            }
            return false;
          }
        }
      }
      if (context.mounted) _showMessage(context, context.tr(error.message));
      return false;
    } catch (error) {
      if (context.mounted) _showMessage(context, context.tr(error.toString()));
      return false;
    }
  }

  static Future<bool> toggleFavorite(
    BuildContext context,
    int propertyId,
  ) async {
    final storeBeforeLogin = AppScope.of(context);
    final wasLoggedIn = storeBeforeLogin.isLoggedIn;
    final loggedIn = await ensureLoggedIn(context);
    if (!loggedIn || !context.mounted) return false;

    final store = AppScope.of(context);
    // Khi khách bấm tim rồi mới đăng nhập, danh sách tải lại có thể cho biết
    // tin này vốn đã được lưu trong tài khoản. Khi đó không toggle lần nữa để
    // tránh vô tình xóa tin yêu thích.
    if (!wasLoggedIn && store.propertyById(propertyId)?.isFavorite == true) {
      return true;
    }

    try {
      await store.toggleFavorite(propertyId);
      return true;
    } on ApiTransportException catch (error) {
      if (error.needLogin && context.mounted) {
        final loggedInAgain = await ensureLoggedIn(context);
        if (loggedInAgain && context.mounted) {
          try {
            await AppScope.of(context).toggleFavorite(propertyId);
            return true;
          } catch (retryError) {
            if (context.mounted) {
              _showMessage(context, context.tr(retryError.toString()));
            }
            return false;
          }
        }
      }
      if (context.mounted) _showMessage(context, context.tr(error.message));
      return false;
    } catch (error) {
      if (context.mounted) _showMessage(context, context.tr(error.toString()));
      return false;
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }
}
