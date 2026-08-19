import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

SupabaseClient get _db => Supabase.instance.client;

const _caseCols =
    'case_no,claim_no,patient_name,card_no,contact_no,district,mandal,village,'
    'nwh_name,ip_no,category,ip_registration_dt,procedure_name,claim_status,'
    'status_date,paid_date,latest_comment,workflow_note,claimed_amount,'
    'paid_amount,deduction,settlement_days,is_paid';

Future<List<ClaimCase>> fetchAllCases() async {
  final out = <ClaimCase>[];
  int from = 0;
  const size = 1000;
  while (true) {
    final data = await _db
        .from('cases')
        .select(_caseCols)
        .order('status_date', ascending: false)
        .range(from, from + size - 1);
    final list = (data as List).cast<Map<String, dynamic>>();
    out.addAll(list.map(ClaimCase.fromMap));
    if (list.length < size) break;
    from += size;
  }
  return out;
}

Future<ClaimCase?> fetchCase(String caseNo) async {
  final data =
      await _db.from('cases').select('*').eq('case_no', caseNo).maybeSingle();
  if (data == null) return null;
  return ClaimCase.fromMap(data);
}

Future<List<WorkflowRow>> fetchWorkflow(String caseNo) async {
  final data = await _db
      .from('claim_workflow')
      .select('row_index,date_time,role_name,remarks,action,amount')
      .eq('case_no', caseNo)
      .order('row_index');
  return (data as List)
      .cast<Map<String, dynamic>>()
      .map(WorkflowRow.fromMap)
      .toList();
}

Future<List<SyncRun>> fetchSyncRuns() async {
  final data = await _db
      .from('sync_runs')
      .select('*')
      .order('started_at', ascending: false)
      .limit(200);
  return (data as List)
      .cast<Map<String, dynamic>>()
      .map(SyncRun.fromMap)
      .toList();
}

Future<String?> latestSync() async {
  final data = await _db
      .from('cases')
      .select('last_synced')
      .not('last_synced', 'is', null)
      .order('last_synced', ascending: false)
      .limit(1);
  final list = (data as List);
  if (list.isEmpty) return null;
  return list.first['last_synced']?.toString();
}

class DashboardStats {
  final int totalCases;
  final int paidCount;
  final num totalClaimed;
  final num totalPaid;
  final num totalDeducted;
  final num pending;
  final num oldStuckValue;
  final int oldStuckCount;
  final int avgSettlement;
  final int maxSettlement;
  final int pendingCount;
  final double deductionPct;

  DashboardStats({
    required this.totalCases,
    required this.paidCount,
    required this.totalClaimed,
    required this.totalPaid,
    required this.totalDeducted,
    required this.pending,
    required this.oldStuckValue,
    required this.oldStuckCount,
    required this.avgSettlement,
    required this.maxSettlement,
    required this.pendingCount,
    required this.deductionPct,
  });
}

class MonthPoint {
  final String label;
  final num raised;
  final num received;
  MonthPoint(this.label, this.raised, this.received);
}

String _mk(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
String _monLabel(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return "${m[d.month - 1]} '${(d.year % 100).toString().padLeft(2, '0')}";
}

/// Claims raised (by registration month) vs payments received (by payment month), last N months.
List<MonthPoint> computeMonthly(List<ClaimCase> cases, {int months = 12}) {
  final raised = <String, num>{};
  final received = <String, num>{};
  for (final c in cases) {
    final claimed =
        c.isPaid ? ((c.paidAmount ?? 0) + (c.deduction ?? 0)) : (c.claimedAmount ?? 0);
    final reg = parseSlashDate(c.ipRegistrationDt) ?? parseSlashDate(c.statusDate);
    if (reg != null && claimed > 0) raised[_mk(reg)] = (raised[_mk(reg)] ?? 0) + claimed;
    if (c.isPaid) {
      final pd = parseWfDate(c.paidDate);
      if (pd != null) received[_mk(pd)] = (received[_mk(pd)] ?? 0) + (c.paidAmount ?? 0);
    }
  }
  final now = DateTime.now();
  final points = <MonthPoint>[];
  for (int i = months - 1; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i, 1);
    final k = _mk(d);
    points.add(MonthPoint(_monLabel(d), raised[k] ?? 0, received[k] ?? 0));
  }
  return points;
}

/// How long settled claims took, in bands.
Map<String, int> settlementDistribution(List<ClaimCase> cases) {
  final d = {'0–30': 0, '31–60': 0, '61–90': 0, '91–180': 0, '180+': 0};
  for (final c in cases) {
    if (c.isPaid && c.settlementDays != null) {
      final s = c.settlementDays!;
      if (s <= 30) {
        d['0–30'] = d['0–30']! + 1;
      } else if (s <= 60) {
        d['31–60'] = d['31–60']! + 1;
      } else if (s <= 90) {
        d['61–90'] = d['61–90']! + 1;
      } else if (s <= 180) {
        d['91–180'] = d['91–180']! + 1;
      } else {
        d['180+'] = d['180+']! + 1;
      }
    }
  }
  return d;
}

DashboardStats computeDashboard(List<ClaimCase> cases) {
  num totClaimed = 0, totPaid = 0, totDed = 0, pend = 0, oldVal = 0;
  int paidCount = 0, tatSum = 0, tatN = 0, tatMax = 0, oldN = 0;
  final now = DateTime.now();
  for (final c in cases) {
    final paid = c.isPaid;
    final received = c.paidAmount ?? 0;
    final ded = c.deduction ?? 0;
    final claimed = paid ? (received + ded) : (c.claimedAmount ?? 0);
    if (claimed > 0) totClaimed += claimed;
    if (paid) {
      totPaid += received;
      paidCount++;
      totDed += ded;
      final d = c.settlementDays;
      if (d != null && d >= 0) {
        tatSum += d;
        tatN++;
        if (d > tatMax) tatMax = d;
      }
    } else {
      pend += claimed;
      final sd = parseSlashDate(c.statusDate) ?? parseSlashDate(c.ipRegistrationDt);
      final age = sd != null ? now.difference(sd).inDays : 0;
      if (age > 90) {
        oldVal += claimed;
        oldN++;
      }
    }
  }
  final dedPct = (totPaid + totDed) > 0 ? totDed / (totPaid + totDed) * 100 : 0.0;
  return DashboardStats(
    totalCases: cases.length,
    paidCount: paidCount,
    totalClaimed: totClaimed,
    totalPaid: totPaid,
    totalDeducted: totDed,
    pending: pend,
    oldStuckValue: oldVal,
    oldStuckCount: oldN,
    avgSettlement: tatN > 0 ? (tatSum / tatN).round() : 0,
    maxSettlement: tatMax,
    pendingCount: cases.length - paidCount,
    deductionPct: dedPct.toDouble(),
  );
}
