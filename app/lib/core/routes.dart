import 'package:flutter/material.dart';

import '../ui/screens/export_screen.dart';
import '../ui/screens/import_review_screen.dart';
import '../ui/screens/lock_screen.dart';
import '../ui/screens/rate_settings_screen.dart';
import '../ui/screens/rate_setup_screen.dart';
import '../ui/screens/root_shell.dart';
import '../ui/screens/session_timer_screen.dart';
import '../ui/screens/shift_detail_screen.dart';
import '../ui/screens/shift_form_screen.dart';
import '../ui/screens/sign_in_screen.dart';

/// Named routes for every screen in the navigation map.
///
/// The four tab routes all open [RootShell]; the tab is chosen with
/// [RootShell.initialIndex]. Day details and Filter are bottom sheets, so
/// they have no route.
abstract final class AppRoutes {
  static const signIn = '/';
  static const rateSetup = '/rate-setup';

  static const home = '/home';
  static const history = '/history';
  static const statistics = '/statistics';
  static const settings = '/settings';

  static const timer = '/timer';
  static const shiftDetail = '/shift';
  static const shiftForm = '/shift/form';
  static const rateSettings = '/settings/rate';
  static const export = '/settings/export';
  static const importReview = '/settings/import';
  static const lock = '/lock';

  static const _tabs = [home, history, statistics, settings];

  static Route<void>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      signIn => const SignInScreen(),
      rateSetup => const RateSetupScreen(),
      home ||
      history ||
      statistics ||
      AppRoutes.settings =>
        RootShell(initialIndex: _tabs.indexOf(settings.name!)),
      timer => const SessionTimerScreen(),
      shiftDetail => const ShiftDetailScreen(),
      shiftForm => ShiftFormScreen(editing: settings.arguments == true),
      rateSettings => const RateSettingsScreen(),
      export => const ExportScreen(),
      importReview => const ImportReviewScreen(),
      lock => const LockScreen(),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}
