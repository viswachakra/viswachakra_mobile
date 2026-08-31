import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseNo;
  const CaseDetailScreen({super.key, required this.caseNo});
  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late Future<(ClaimCase?, List<WorkflowRow>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(ClaimCase?, List<WorkflowRow>)> _load() async {
    final results = await Future.wait([
      fetchCase(widget.caseNo),
      fetchWorkflow(widget.caseNo),
    ]);
    return (results[0] as ClaimCase?, results[1] as List<WorkflowRow>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseNo,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<(ClaimCase?, List<WorkflowRow>)>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(child: Text("Couldn't load: ${snap.error}"));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (c, rows) = snap.data!;
          if (c == null) {
            return const Center(child: Text('Case not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(c),
              const SizedBox(height: 16),
              _amountRow(c),
              const SizedBox(height: 20),
              _infoGrid(c),
              const SizedBox(height: 24),
              const Text('Claim approval timeline',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                      color: AppColors.text2)),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Text(c.workflowNote ?? 'No claim workflow captured yet.',
                    style: const TextStyle(color: AppColors.text3))
              else
                ...rows.map((r) => _Step(r: r, last: r == rows.last)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _header(ClaimCase c) {
    final sc = statusColors(c.claimStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.patientName ?? '(no name)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (c.nwhName != null && c.nwhName!.isNotEmpty)
          Text(c.nwhName!,
              style: const TextStyle(color: AppColors.text2, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration:
              BoxDecoration(color: sc.bg, borderRadius: BorderRadius.circular(12)),
          child: Text(c.claimStatus ?? '–',
              style: TextStyle(
                  color: sc.fg, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _amountRow(ClaimCase c) {
    // Use claimedOf() rather than the raw claimed_amount column. Some older
    // rows had claimed_amount overwritten with the PAID figure, which rendered
    // impossible cards like "Claimed 15,000 / Deducted 20,500". Deriving it as
    // paid + deduction reconstructs the real raised amount and keeps this
    // screen consistent with the Alerts list even if the column regresses.
    return Row(
      children: [
        _amtCard('Claimed', inr(claimedOf(c)), AppColors.indigo),
        const SizedBox(width: 10),
        _amtCard('Paid', c.paidAmount != null ? inr(c.paidAmount) : '–',
            AppColors.greenFg),
        const SizedBox(width: 10),
        _amtCard(
            'Deducted',
            c.deduction != null ? inr(c.deduction) : '–',
            AppColors.redFg),
      ],
    );
  }

  Widget _amtCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.text3, fontSize: 10, letterSpacing: .3)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(value,
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoGrid(ClaimCase c) {
    final items = <(String, String?)>[
      ('Claim no', c.claimNo),
      ('Card no', c.cardNo),
      ('Contact', c.contactNo),
      ('IP no', c.ipNo),
      ('District', c.district),
      ('Mandal', c.mandal),
      ('IP registration', dOnly(c.ipRegistrationDt)),
      ('Settlement days', c.settlementDays?.toString()),
      ('Procedure', c.procedureName),
    ].where((e) => (e.$2 ?? '').isNotEmpty).toList();
    return Wrap(
      runSpacing: 14,
      children: items
          .map((e) => SizedBox(
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 120,
                        child: Text(e.$1.toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.text3,
                                fontSize: 10.5,
                                letterSpacing: .3,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        child: Text(e.$2!,
                            style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _Step extends StatelessWidget {
  final WorkflowRow r;
  final bool last;
  const _Step({required this.r, required this.last});
  @override
  Widget build(BuildContext context) {
    Color dot = AppColors.primary;
    final act = (r.action ?? '').toLowerCase();
    if (RegExp(r'hold|stopped|reject').hasMatch(act)) dot = const Color(0xFFF59E0B);
    if (RegExp(r'paid|approv').hasMatch(act)) dot = const Color(0xFF10B981);
    final hasAmt = (r.amount ?? '').trim().isNotEmpty && r.amount!.trim() != '-';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: dot, width: 3)),
              ),
              if (!last)
                Expanded(
                    child: Container(
                        width: 2, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 2))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.action ?? ''}${(r.roleName ?? '').isNotEmpty ? ' · ${r.roleName}' : ''}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${r.dateTime ?? ''}${hasAmt ? ' · ₹${r.amount}' : ''}',
                    style: const TextStyle(color: AppColors.text3, fontSize: 11.5),
                  ),
                  if ((r.remarks ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border)),
                      child: Text(r.remarks!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.text2, height: 1.5)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
