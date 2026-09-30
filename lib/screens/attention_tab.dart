import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import 'case_detail_screen.dart';

// ---------------------------------------------------------------------------
// The two things the hospital owner actually needs to see:
//   1. claims that are blocked and need a human to act, and
//   2. claims approved/paid for LESS than was raised.
// Classification lives in models.dart (isShortPaid / blockedKind / claimedOf)
// so this screen and notifications.dart always agree. Everything is derived
// from the `cases` table alone, so no extra fetch.
// ---------------------------------------------------------------------------

class AttentionGroup {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bg;
  final Color fg;
  final List<ClaimCase> cases;
  const AttentionGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.cases,
  });
}

/// Blocked claims, most urgent first. Only non-empty groups are returned.
List<AttentionGroup> attentionGroups(List<ClaimCase> cases) {
  final rejected = <ClaimCase>[];
  final feedback = <ClaimCase>[];
  final failed = <ClaimCase>[];

  for (final c in cases) {
    switch (blockedKind(c)) {
      case 'failed':
        failed.add(c);
      case 'feedback':
        feedback.add(c);
      case 'rejected':
        rejected.add(c);
    }
  }

  final groups = <AttentionGroup>[
    AttentionGroup(
      title: 'Rejected',
      subtitle: 'Rejected or cancelled by the Trust — review and decide',
      icon: Icons.cancel_outlined,
      bg: AppColors.redBg,
      fg: AppColors.redFg,
      cases: rejected,
    ),
    AttentionGroup(
      title: 'Patient feedback pending',
      subtitle: 'Payment is stopped until the patient submits feedback',
      icon: Icons.record_voice_over_outlined,
      bg: AppColors.amberBg,
      fg: AppColors.amberFg,
      cases: feedback,
    ),
    AttentionGroup(
      title: 'Payment failed',
      subtitle: 'Approved, but the bank transfer did not go through',
      icon: Icons.error_outline,
      bg: AppColors.redBg,
      fg: AppColors.redFg,
      cases: failed,
    ),
  ];
  return groups.where((g) => g.cases.isNotEmpty).toList();
}

// ---------------------------------------------------------------------------

class AttentionTab extends StatefulWidget {
  final List<ClaimCase> cases;
  final Future<void> Function() onRefresh;

  /// Money is admin-only, matching the Dashboard gate: non-admin staff get the
  /// blocked-claims work queue but never the rupee figures.
  final bool showMoney;

  const AttentionTab({
    super.key,
    required this.cases,
    required this.onRefresh,
    required this.showMoney,
  });
  @override
  State<AttentionTab> createState() => _AttentionTabState();
}

class _AttentionTabState extends State<AttentionTab> {
  // 'all' | 'half' — 'half' narrows to claims that lost 50%+ of their value.
  String _cut = 'all';

  @override
  Widget build(BuildContext context) {
    final groups = attentionGroups(widget.cases);

    var short = widget.cases.where((c) => shortfallOf(c) > 0).toList();
    final shortAll = short.length;
    final earlyCount = short.where(isShortApproved).length;
    final totalCut = short.fold<int>(0, (s, c) => s + shortfallOf(c));
    if (_cut == 'early') {
      short = short.where(isShortApproved).toList();
    } else if (_cut == 'half') {
      short = short.where((c) {
        final cl = claimedOf(c);
        return cl > 0 && shortfallOf(c) / cl >= 0.5;
      }).toList();
    }
    // Not-yet-paid first — those are the ones still worth contesting.
    short.sort((a, b) {
      if (a.isPaid != b.isPaid) return a.isPaid ? 1 : -1;
      return shortfallOf(b).compareTo(shortfallOf(a));
    });

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          // ---- how fresh is any of this? --------------------------------
          _FreshnessBanner(hours: dataAgeHours(widget.cases)),
          const SizedBox(height: 14),

          // ---- blocked claims -------------------------------------------
          const _SectionTitle('Needs your attention'),
          if (groups.isEmpty)
            const _AllClear()
          else
            ...groups.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _GroupCard(group: g, showMoney: widget.showMoney),
                )),

          // ---- short-paid: rupee figures, admin only --------------------
          if (widget.showMoney) ...[
            const SizedBox(height: 22),
            const _SectionTitle('Settled claims'),
            _PaidSplit(cases: widget.cases),
            const SizedBox(height: 22),
            const _SectionTitle('Approved for less than raised'),
            _ShortSummary(count: shortAll, total: totalCut, early: earlyCount),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip('All $shortAll', 'all'),
                _chip('Not yet paid $earlyCount', 'early'),
                _chip('Lost 50%+', 'half'),
              ],
            ),
            const SizedBox(height: 10),
            if (short.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                    child: Text('Nothing here',
                        style: TextStyle(color: AppColors.text3))),
              )
            else
              ...short.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ShortPaidCard(c: c),
                  )),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String val) {
    final on = _cut == val;
    return GestureDetector(
      onTap: () => setState(() => _cut = val),
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

/// Says how old the data is, and shouts when the sync has stopped.
/// Green under 6h, amber to 24h, red beyond - a red bar here is the signal
/// that would have caught the 8-day September outage on day one.
class _FreshnessBanner extends StatelessWidget {
  final double? hours;
  const _FreshnessBanner({required this.hours});

  @override
  Widget build(BuildContext context) {
    final h = hours;
    late final Color bg, fg;
    late final IconData icon;
    late final String text;

    if (h == null) {
      bg = AppColors.amberBg; fg = AppColors.amberFg; icon = Icons.help_outline;
      text = "Can't tell how fresh this data is";
    } else if (h < 6) {
      bg = AppColors.greenBg; fg = AppColors.greenFg; icon = Icons.cloud_done_outlined;
      text = 'Up to date — synced ${agoText(h)}';
    } else if (h < 24) {
      bg = AppColors.amberBg; fg = AppColors.amberFg; icon = Icons.schedule;
      text = 'Last synced ${agoText(h)}';
    } else {
      bg = AppColors.redBg; fg = AppColors.redFg; icon = Icons.cloud_off;
      text = 'Sync may be down — last updated ${agoText(h)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5, color: fg, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.text)),
      );
}

class _AllClear extends StatelessWidget {
  const _AllClear();
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.greenFg, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text('Nothing is blocked. No claim is waiting on you.',
                    style: TextStyle(fontSize: 13.5, color: AppColors.text2)),
              ),
            ],
          ),
        ),
      );
}

/// A collapsible bucket of blocked claims.
class _GroupCard extends StatefulWidget {
  final AttentionGroup group;
  final bool showMoney;
  const _GroupCard({required this.group, required this.showMoney});
  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Card(
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: g.bg, borderRadius: BorderRadius.circular(9)),
                    child: Icon(g.icon, color: g.fg, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${g.title} · ${g.cases.length}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(g.subtitle,
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.text3)),
                      ],
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.text3),
                ],
              ),
            ),
          ),
          if (_open)
            ...g.cases
                .map((c) => _BlockedRow(c: c, showMoney: widget.showMoney)),
        ],
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  final ClaimCase c;
  final bool showMoney;
  const _BlockedRow({required this.c, required this.showMoney});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CaseDetailScreen(caseNo: c.caseNo))),
      child: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border))),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.patientName ?? '(no name)',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      showMoney
                          ? '${c.caseNo}  ·  ${inr(claimedOf(c))}'
                          : c.caseNo,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.text3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.text3, size: 20),
          ],
        ),
      ),
    );
  }
}

/// "Paid" on its own hides the thing that matters. Three quarters of settled
/// claims arrive in full; the rest arrive short, and that gap is the money the
/// hospital never sees.
class _PaidSplit extends StatelessWidget {
  final List<ClaimCase> cases;
  const _PaidSplit({required this.cases});

  @override
  Widget build(BuildContext context) {
    final paid = cases.where((c) => c.isPaid && claimedOf(c) > 0).toList();
    if (paid.isEmpty) return const SizedBox.shrink();
    final short = paid.where((c) => (c.deduction ?? 0) > 0).toList();
    final full = paid.length - short.length;
    final cut = short.fold<int>(0, (t, c) => t + (c.deduction ?? 0));
    final received = paid.fold<int>(0, (t, c) => t + (c.paidAmount ?? 0));
    final raised = paid.fold<int>(0, (t, c) => t + claimedOf(c));
    final pctShort = short.length / paid.length * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _fig('RAISED', inr(raised), AppColors.text)),
                Expanded(child: _fig('RECEIVED', inr(received), AppColors.greenFg)),
              ],
            ),
            const SizedBox(height: 14),
            // proportion bar: green = paid in full, red = short
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    flex: full == 0 ? 1 : full,
                    child: Container(height: 8, color: AppColors.greenFg),
                  ),
                  Expanded(
                    flex: short.isEmpty ? 1 : short.length,
                    child: Container(height: 8, color: AppColors.redFg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _row(AppColors.greenFg, 'Paid in full', '$full claims',
                '${(100 - pctShort).toStringAsFixed(0)}%'),
            const SizedBox(height: 7),
            _row(AppColors.redFg, 'Paid short', '${short.length} claims',
                '${pctShort.toStringAsFixed(0)}%'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                  color: AppColors.redBg, borderRadius: BorderRadius.circular(8)),
              child: Text('${inr(cut)} never received',
                  style: const TextStyle(
                      color: AppColors.redFg,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Color dot, String label, String count, String pct) => Row(
        children: [
          Container(width: 9, height: 9,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: AppColors.text2))),
          Text(count,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(pct,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Widget _fig(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.text3, fontSize: 10, letterSpacing: .4)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      );
}

class _ShortSummary extends StatelessWidget {
  final int count;
  final int total;
  final int early;
  const _ShortSummary(
      {required this.count, required this.total, required this.early});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOTAL NOT RECEIVED',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: .4,
                    color: AppColors.text3,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(inr(total),
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.redFg)),
            const SizedBox(height: 4),
            Text('across $count claims approved below the amount raised',
                style: const TextStyle(fontSize: 12, color: AppColors.text2)),
            if (early > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                    color: AppColors.amberBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 15, color: AppColors.amberFg),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                          '$early not paid out yet — sanctioned low, money still to come',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.amberFg,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShortPaidCard extends StatelessWidget {
  final ClaimCase c;
  const _ShortPaidCard({required this.c});
  @override
  Widget build(BuildContext context) {
    final claimed = claimedOf(c);
    final cut = shortfallOf(c);
    final pct = claimed > 0 ? (cut / claimed * 100) : 0.0;
    final awaiting = !c.isPaid;
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
              Row(
                children: [
                  Expanded(
                    child: Text(c.patientName ?? '(no name)',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('−${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: AppColors.redFg,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(c.caseNo,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.text3)),
                  if (awaiting) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.amberBg,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('AWAITING PAYMENT',
                          style: TextStyle(
                              color: AppColors.amberFg,
                              fontSize: 9,
                              letterSpacing: .3,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _fig('RAISED', inr(claimed), AppColors.text),
                  const SizedBox(width: 18),
                  _fig('SANCTIONED', inr(sanctionedOf(c)), AppColors.greenFg),
                  const SizedBox(width: 18),
                  _fig(awaiting ? 'SHORTFALL' : 'NOT PAID', inr(cut),
                      AppColors.redFg),
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

  Widget _fig(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.text3, fontSize: 9.5, letterSpacing: .3)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13.5, fontWeight: FontWeight.bold)),
        ],
      );
}
