import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await _fln.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
  );
  await _fln
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

Future<void> _show(int id, String title, String body) async {
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'vc_claims',
      'Claim updates',
      channelDescription: 'Payments received and claim status changes',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
  await _fln.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
  );
}

/// Compare the current case list against the last-seen snapshot and notify about
/// newly-paid claims and status changes. First run just sets a baseline (no spam).
Future<void> detectAndNotify(List<ClaimCase> cases) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('vc_snapshot');
    final snapshot =
        raw != null ? (jsonDecode(raw) as Map).cast<String, dynamic>() : null;

    // new snapshot: case_no -> "isPaid|status"
    final current = <String, String>{
      for (final c in cases) c.caseNo: '${c.isPaid ? 1 : 0}|${c.claimStatus ?? ''}'
    };
    await prefs.setString('vc_snapshot', jsonEncode(current));

    if (snapshot == null) return; // baseline only on first run

    int newlyPaid = 0;
    num paidSum = 0;
    int statusChanged = 0;
    for (final c in cases) {
      final old = snapshot[c.caseNo]?.toString();
      if (old == null) continue; // brand-new case
      final wasPaid = old.startsWith('1|');
      final oldStatus =
          old.contains('|') ? old.substring(old.indexOf('|') + 1) : '';
      if (c.isPaid && !wasPaid) {
        newlyPaid++;
        paidSum += c.paidAmount ?? 0;
      } else if ((c.claimStatus ?? '') != oldStatus) {
        statusChanged++;
      }
    }

    if (newlyPaid > 0) {
      await _show(1, '💰 Payment received',
          '$newlyPaid claim${newlyPaid > 1 ? 's' : ''} paid — ${inrShort(paidSum)}');
    }
    if (statusChanged > 0) {
      await _show(2, '📋 Claim updates',
          '$statusChanged claim${statusChanged > 1 ? 's' : ''} changed status');
    }
  } catch (_) {
    // notifications are best-effort; never block the app
  }
}
