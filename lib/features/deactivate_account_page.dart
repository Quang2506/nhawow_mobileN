import 'package:flutter/material.dart';

import 'delete_account_page.dart';

/// Compatibility wrapper for older navigation code.
///
/// The old "deactivate account" feature has been replaced by permanent
/// account deletion after the 1-hour cancellation window. Keeping this class
/// prevents older imports/routes from breaking while ensuring the user sees
/// the new permanent-delete UI and behavior.
@Deprecated('Use DeleteAccountPage')
class DeactivateAccountPage extends StatelessWidget {
  const DeactivateAccountPage({super.key});

  @override
  Widget build(BuildContext context) => const DeleteAccountPage();
}
