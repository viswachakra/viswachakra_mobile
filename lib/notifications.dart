import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart' show isAdminUser;
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

/// Compare the current case list against the last-seen snapshot and raise the
/// three alerts that matter to the hospital owner:
///   1. a claim was paid in full,
///   2. a claim was approved for LESS than it was raised for, and
///   3. a claim just became blocked and needs him to act.
/// First run only sets a baseline, so installing the app never spams.
Future<void> detectAndNotify(List<ClaimCase> cases) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // v3 key: the stored shape changed, so older snapshots are ignored and the
    // next run simply re-baselines instead of mis-reading old values.
    final raw = prefs.getString('vc_snapshot_v3');
    final snapshot =
        raw != null ? (jsonDecode(raw) as Map).cast<String, dynamic>() : null;

    // case_no -> "isPaid|shortApproved|blockedKind|status"
    String key(ClaimCase c) => [
          c.isPaid ? 1 : 0,
          isShortApproved(c) ? 1 : 0,
          blockedKind(c) ?? '',
          c.claimStatus ?? '',
        ].join('|');
    final current = <String, String>{for (final c in cases) c.caseNo: key(c)};
    await prefs.setString('vc_snapshot_v3', jsonEncode(current));

    if (snapshot == null) return; // baseline only on first run

    int paidFull = 0;
    num paidSum = 0;
    final earlyShort = <ClaimCase>[]; // sanctioned low, money not yet paid
    final paidShort = <ClaimCase>[]; // paid short without an earlier warning
    int newlyBlocked = 0;

    for (final c in cases) {
      final old = snapshot[c.caseNo]?.toString();
      if (old == null) continue; // brand-new case, not a change
      final parts = old.split('|');
      if (parts.length < 4) continue;
      final wasPaid = parts[0] == '1';
      final wasShortApproved = parts[1] == '1';
      final wasBlocked = parts[2].isNotEmpty;

      if (c.isPaid && !wasPaid) {
        if (isShortPaid(c)) {
          // Only shout again if we never warned at approval time.
          if (!wasShortApproved) paidShort.add(c);
        } else {
          paidFull++;
          paidSum += c.paidAmount ?? 0;
        }
      } else if (isShortApproved(c) && !wasShortApproved) {
        earlyShort.add(c);
      } else if (blockedKind(c) != null && !wasBlocked) {
        newlyBlocked++;
      }
    }

    // Blocked claims are everyone's work; rupee figures are admin-only, matching
    // the Alerts screen and the Dashboard gate.
    if (newlyBlocked > 0) {
      await _show(3, '🚫 Needs your attention',
          '$newlyBlocked claim${newlyBlocked > 1 ? 's' : ''} blocked — open Alerts to see why');
    }
    if (!isAdminUser) return;

    if (paidFull > 0) {
      await _show(1, '💰 Payment received',
          '$paidFull claim${paidFull > 1 ? 's' : ''} paid in full — ${inrShort(paidSum)}');
    }

    // The early warning — fires when the Trust sanctions below the amount
    // raised, typically months before the money moves.
    if (earlyShort.length == 1) {
      final c = earlyShort.first;
      await _show(
          2,
          '⚠️ Approved for less than raised',
          '${c.patientName ?? c.caseNo}: ${inr(c.claimedAmount)} raised, '
              '${inr(c.approvedAmount)} sanctioned — ${inr(shortfallOf(c))} short');
    } else if (earlyShort.length > 1) {
      final cut = earlyShort.fold<int>(0, (s, c) => s + shortfallOf(c));
      await _show(2, '⚠️ Approved for less than raised',
          '${earlyShort.length} claims sanctioned short — ${inr(cut)} short');
    }

    // Fallback: paid below the raised amount with no approval row to warn from.
    if (paidShort.isNotEmpty) {
      final cut = paidShort.fold<int>(0, (s, c) => s + (c.deduction ?? 0));
      final c = paidShort.first;
      await _show(
          4,
          '⚠️ Paid less than raised',
          paidShort.length == 1
              ? '${c.patientName ?? c.caseNo}: ${inr(claimedOf(c))} raised, '
                  '${inr(c.paidAmount)} received — ${inr(c.deduction)} not paid'
              : '${paidShort.length} claims paid short — ${inr(cut)} not paid');
    }
  } catch (_) {
    // notifications are best-effort; never block the app
  }
}
