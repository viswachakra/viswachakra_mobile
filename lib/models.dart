// Data models + formatting helpers, mirroring the web app's logic.

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final n = int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), ''));
  return n;
}

class ClaimCase {
  final String caseNo;
  final String? claimNo;
  final String? patientName;
  final String? cardNo;
  final String? district;
  final String? mandal;
  final String? village;
  final String? contactNo;
  final String? nwhName;
  final String? ipNo;
  final String? ipRegistrationDt;
  final String? category;
  final String? procedureName;
  final String? claimStatus;
  final String? statusDate;
  final String? paidDate;
  final String? latestComment;
  final String? workflowNote;
  final int? claimedAmount;
  final int? paidAmount;
  final int? approvedAmount;
  final int? deduction;
  final int? settlementDays;
  final bool isPaid;

  ClaimCase.fromMap(Map<String, dynamic> m)
      : caseNo = m['case_no']?.toString() ?? '',
        claimNo = m['claim_no']?.toString(),
        patientName = m['patient_name']?.toString(),
        cardNo = m['card_no']?.toString(),
        district = m['district']?.toString(),
        mandal = m['mandal']?.toString(),
        village = m['village']?.toString(),
        contactNo = m['contact_no']?.toString(),
        nwhName = m['nwh_name']?.toString(),
        ipNo = m['ip_no']?.toString(),
        ipRegistrationDt = m['ip_registration_dt']?.toString(),
        category = m['category']?.toString(),
        procedureName = m['procedure_name']?.toString(),
        claimStatus = m['claim_status']?.toString(),
        statusDate = m['status_date']?.toString(),
        paidDate = m['paid_date']?.toString(),
        latestComment = m['latest_comment']?.toString(),
        workflowNote = m['workflow_note']?.toString(),
        claimedAmount = _toInt(m['claimed_amount']),
        paidAmount = _toInt(m['paid_amount']),
        approvedAmount = _toInt(m['approved_amount']),
        deduction = _toInt(m['deduction']),
        settlementDays = _toInt(m['settlement_days']),
        isPaid = m['is_paid'] == true ||
            RegExp(r'paid|payment done', caseSensitive: false)
                .hasMatch(m['claim_status']?.toString() ?? '');

  String get searchText => [
        caseNo,
        patientName ?? '',
        claimNo ?? '',
        cardNo ?? '',
        contactNo ?? ''
      ].join(' ').toLowerCase();
}

class WorkflowRow {
  final int rowIndex;
  final String? dateTime;
  final String? roleName;
  final String? remarks;
  final String? action;
  final String? amount;

  WorkflowRow.fromMap(Map<String, dynamic> m)
      : rowIndex = _toInt(m['row_index']) ?? 0,
        dateTime = m['date_time']?.toString(),
        roleName = m['role_name']?.toString(),
        remarks = m['remarks']?.toString(),
        action = m['action']?.toString(),
        amount = m['amount']?.toString();
}

class SyncRun {
  final String? startedAt;
  final String? status;
  final String? fromDt;
  final String? toDt;
  final int? totalFound;
  final int? deepScraped;
  final String? message;

  SyncRun.fromMap(Map<String, dynamic> m)
      : startedAt = m['started_at']?.toString(),
        status = m['status']?.toString(),
        fromDt = m['from_dt']?.toString(),
        toDt = m['to_dt']?.toString(),
        totalFound = _toInt(m['total_found']),
        deepScraped = _toInt(m['deep_scraped']),
        message = m['message']?.toString();

  bool get ok => RegExp(r'success', caseSensitive: false).hasMatch(status ?? '');
}

// ---- what needs the owner's attention -------------------------------------
// One definition, shared by the Alerts screen and the notification check, so
// the badge and the push can never disagree.

/// Settled for less than it was raised for (the ₹35,000 → ₹25,000 case).
bool isShortPaid(ClaimCase c) => c.isPaid && (c.deduction ?? 0) > 0;

/// The amount raised, whether or not the claim has been paid yet.
int claimedOf(ClaimCase c) =>
    c.isPaid ? ((c.paidAmount ?? 0) + (c.deduction ?? 0)) : (c.claimedAmount ?? 0);

/// Sanctioned below the amount raised, but the money has NOT arrived yet.
/// This is the early warning: the approval figure shows up on the workflow
/// months before the payment does.
bool isShortApproved(ClaimCase c) {
  if (c.isPaid) return false;
  final a = c.approvedAmount;
  final claimed = c.claimedAmount ?? 0;
  return a != null && claimed > 0 && a < claimed;
}

/// The gap between what was raised and what was sanctioned — from the approval
/// figure before payment, from the paid figure after. 0 when there is no gap.
int shortfallOf(ClaimCase c) {
  if (c.isPaid) return c.deduction ?? 0;
  if (!isShortApproved(c)) return 0;
  return (c.claimedAmount ?? 0) - (c.approvedAmount ?? 0);
}

/// What the Trust sanctioned, if known.
int? sanctionedOf(ClaimCase c) => c.isPaid ? c.paidAmount : c.approvedAmount;

/// Why a claim is stuck, or null if it is not blocked.
/// 'failed' | 'feedback' | 'rejected'
String? blockedKind(ClaimCase c) {
  if (c.isPaid) return null;
  final s = c.claimStatus ?? '';
  bool m(String p) => RegExp(p, caseSensitive: false).hasMatch(s);
  if (m(r'failed transaction')) return 'failed';
  if (m(r'patient feedback not submitted')) return 'feedback';
  if (m(r'reject|cancelled by trust')) return 'rejected';
  return null;
}

// ---- formatting ----
String inrShort(num? n) {
  final v = (n ?? 0).round();
  if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
  return '₹$v';
}

// Indian-grouped rupee format, e.g. ₹7,55,68,026.
String inr(num? n) {
  if (n == null) return '–';
  final neg = n < 0;
  var s = n.abs().round().toString();
  if (s.length > 3) {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    s = '${parts.join(',')},$last3';
  }
  return '${neg ? '-' : ''}₹$s';
}

// Parse the portal date formats used in the DB.
const _mon = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
};

// "DD-Mon-YYYY h:mm AM/PM" (paid_date, workflow date_time)
DateTime? parseWfDate(String? s) {
  if (s == null) return null;
  final m = RegExp(r'(\d{1,2})-([A-Za-z]{3})-(\d{4})\s+(\d{1,2}):(\d{2})\s*(AM|PM)?',
          caseSensitive: false)
      .firstMatch(s);
  if (m == null) return null;
  var h = int.parse(m.group(4)!);
  final ap = (m.group(6) ?? '').toUpperCase();
  if (ap == 'PM' && h < 12) h += 12;
  if (ap == 'AM' && h == 12) h = 0;
  return DateTime(int.parse(m.group(3)!), _mon[m.group(2)!.toLowerCase()] ?? 1,
      int.parse(m.group(1)!), h, int.parse(m.group(5)!));
}

// "dd/mm/yyyy hh:mm:ss" (status_date, ip_registration_dt)
DateTime? parseSlashDate(String? s) {
  if (s == null) return null;
  final m = RegExp(r'(\d{2})/(\d{2})/(\d{4})').firstMatch(s);
  if (m == null) return null;
  return DateTime(
      int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
}

String dOnly(String? s) {
  final m = RegExp(r'\d{2}/\d{2}/\d{4}').firstMatch(s ?? '');
  return m?.group(0) ?? '';
}
