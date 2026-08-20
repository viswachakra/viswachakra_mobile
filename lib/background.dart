import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'config.dart';
import 'data.dart';
import 'notifications.dart';

const _bgTask = 'vc_bg_sync';

/// Runs in a background isolate (app can be closed). Re-initialises Supabase,
/// restores the persisted login session, fetches cases and fires notifications
/// for anything that changed since the last check.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Supabase.initialize(
        url: Config.supabaseUrl,
        anonKey: Config.supabaseAnonKey,
      );
      // No restored session → not logged in; nothing to read (RLS blocks anon).
      if (Supabase.instance.client.auth.currentSession == null) return true;
      await initNotifications();
      final cases = await fetchAllCases();
      await detectAndNotify(cases);
    } catch (_) {
      // best-effort; let WorkManager reschedule the next run
    }
    return true;
  });
}

/// Registers an hourly background check (Android). Safe to call on every launch —
/// ExistingPeriodicWorkPolicy.keep avoids creating duplicates.
Future<void> initBackground() async {
  // iOS background needs BGTaskScheduler setup (Info.plist + AppDelegate) — a follow-up;
  // foreground/on-open notifications still work on iOS. See IOS_APPSTORE_SETUP.md.
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _bgTask,
    _bgTask,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
