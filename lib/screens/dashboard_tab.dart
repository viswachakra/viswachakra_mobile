import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import 'charts.dart';

class DashboardTab extends StatelessWidget {
  final List<ClaimCase> cases;
  final Future<void> Function() onRefresh;
  const DashboardTab({super.key, required this.cases, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final s = computeDashboard(cases);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Hero(s: s),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _Kpi(
                  label: 'Total claimed',
                  value: inrShort(s.totalClaimed),
                  sub: '${s.totalCases} claims',
                  c1: const Color(0xFFC9A227),
                  c2: const Color(0xFFA8841C)),
              _Kpi(
                  label: 'Total received',
                  value: inrShort(s.totalPaid),
                  sub: '${s.paidCount} settled',
                  c1: const Color(0xFF10B981),
                  c2: const Color(0xFF059669)),
              _Kpi(
                  label: 'Deducted by insurer',
                  value: inrShort(s.totalDeducted),
                  sub: '${s.deductionPct.toStringAsFixed(1)}% of settled',
                  c1: const Color(0xFFFB7185),
                  c2: const Color(0xFFE11D48)),
              _Kpi(
                  label: 'Stuck / pending',
                  value: inrShort(s.pending),
                  sub: '${s.pendingCount} unpaid',
                  c1: const Color(0xFFFBBF24),
                  c2: const Color(0xFFF97316)),
              _Kpi(
                  label: 'Avg settlement',
                  value: '${s.avgSettlement}',
                  sub: 'days to pay',
                  c1: const Color(0xFFB07A3A),
                  c2: const Color(0xFF7E5420)),
              _Kpi(
                  label: 'Paid claims',
                  value: '${s.paidCount}',
                  sub: 'settled to date',
                  c1: const Color(0xFF2DD4BF),
                  c2: const Color(0xFF0D9488)),
            ],
          ),
          const SizedBox(height: 14),
          CashFlowChart(points: computeMonthly(cases)),
          const SizedBox(height: 12),
          SettlementChart(dist: settlementDistribution(cases)),
          const SizedBox(height: 16),
          const _LastSync(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final DashboardStats s;
  const _Hero({required this.s});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E1A24), Color(0xFFB4232E), Color(0xFFC9A227)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${s.avgSettlement}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Text('days to get paid',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'average wait from claim to payment — about ${(s.avgSettlement / 30).toStringAsFixed(1)} months',
              style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(label: 'Deducted', value: inrShort(s.totalDeducted)),
              const SizedBox(width: 28),
              _HeroStat(label: 'Stuck / unpaid', value: inrShort(s.pending)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withValues(alpha: .85),
                fontSize: 11,
                letterSpacing: .4)),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label, value, sub;
  final Color c1, c2;
  const _Kpi(
      {required this.label,
      required this.value,
      required this.sub,
      required this.c1,
      required this.c2});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .92),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .4)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 3),
          Text(sub,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .85), fontSize: 11)),
        ],
      ),
    );
  }
}

class _LastSync extends StatelessWidget {
  const _LastSync();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: latestSync(),
      builder: (ctx, snap) {
        String text = 'Checking last sync…';
        if (snap.connectionState == ConnectionState.done) {
          final iso = snap.data;
          if (iso != null) {
            final dt = DateTime.tryParse(iso)?.toLocal();
            text = dt != null ? 'Last synced ${dt.toString().substring(0, 16)}' : 'Last sync unknown';
          } else {
            text = 'No sync recorded yet';
          }
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sync, size: 14, color: AppColors.text3),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(color: AppColors.text3, fontSize: 12)),
          ],
        );
      },
    );
  }
}
