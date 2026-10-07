import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import 'case_detail_screen.dart';

class CasesTab extends StatefulWidget {
  final List<ClaimCase> cases;
  final Future<void> Function() onRefresh;
  const CasesTab({super.key, required this.cases, required this.onRefresh});
  @override
  State<CasesTab> createState() => _CasesTabState();
}

class _CasesTabState extends State<CasesTab> {
  String _q = '';
  String _pay = 'all'; // all | paid | unpaid

  List<ClaimCase> get _filtered {
    var list = widget.cases;
    if (_pay == 'paid') list = list.where((c) => c.isPaid).toList();
    if (_pay == 'unpaid') list = list.where((c) => !c.isPaid).toList();
    final q = _q.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((c) => c.searchText.contains(q)).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search case, patient, claim, card, phone…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chip('All', 'all'),
                  const SizedBox(width: 8),
                  _chip('Paid', 'paid'),
                  const SizedBox(width: 8),
                  _chip('Unpaid', 'unpaid'),
                  const Spacer(),
                  Text('${list.length}',
                      style: const TextStyle(
                          color: AppColors.text3,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: list.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 120),
                    Center(
                        child: Text('No cases found',
                            style: TextStyle(color: AppColors.text3)))
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _CaseCard(c: list[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String val) {
    final on = _pay == val;
    return GestureDetector(
      onTap: () => setState(() => _pay = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: on ? Colors.white : AppColors.text2,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final ClaimCase c;
  const _CaseCard({required this.c});
  @override
  Widget build(BuildContext context) {
    final sc = statusColors(c.claimStatus);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CaseDetailScreen(caseNo: c.caseNo))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // case number and status on separate lines: a long status such
              // "Claim Stopped Due to Patient Feedback not Submitted - CEO"
              // otherwise squeezes the case number to one character per line
              Text(c.caseNo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppColors.primaryDark)),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: sc.bg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(c.claimStatus ?? '–',
                      style: TextStyle(
                          color: sc.fg,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 6),
              Text(c.patientName ?? '(no name)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _amt('Claimed', inr(c.claimedAmount), AppColors.text),
                  const SizedBox(width: 20),
                  _amt('Paid', c.paidAmount != null ? inr(c.paidAmount) : '–',
                      c.paidAmount != null ? AppColors.greenFg : AppColors.text3),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.text3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amt(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.text3, fontSize: 10, letterSpacing: .3)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
