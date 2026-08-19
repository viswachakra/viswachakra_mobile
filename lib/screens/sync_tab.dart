import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';

class SyncTab extends StatefulWidget {
  const SyncTab({super.key});
  @override
  State<SyncTab> createState() => _SyncTabState();
}

class _SyncTabState extends State<SyncTab> {
  late Future<List<SyncRun>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchSyncRuns();
  }

  Future<void> _reload() async {
    setState(() => _future = fetchSyncRuns());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<SyncRun>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return ListView(children: [
              const SizedBox(height: 120),
              Center(child: Text("Couldn't load: ${snap.error}"))
            ]);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final today = DateTime.now();
          bool isToday(SyncRun r) {
            final d = DateTime.tryParse(r.startedAt ?? '')?.toLocal();
            return d != null &&
                d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          }

          final runs = snap.data!.where(isToday).toList();
          final fails = runs.where((r) => !r.ok).length;
          SyncRun? lastOk;
          for (final r in runs) {
            if (r.ok) {
              lastOk = r;
              break;
            }
          }
          final hrs = lastOk != null
              ? today
                      .difference(DateTime.parse(lastOk.startedAt!).toLocal())
                      .inMinutes /
                  60.0
              : double.infinity;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _banner(lastOk, hrs, fails, runs.length),
              const SizedBox(height: 14),
              Row(
                children: [
                  _kpi('Runs today', '${runs.length}', AppColors.text),
                  const SizedBox(width: 10),
                  _kpi('Failures today', '$fails',
                      fails > 0 ? AppColors.amberFg : AppColors.greenFg),
                ],
              ),
              const SizedBox(height: 16),
              if (runs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child: Text('No sync runs today yet.',
                          style: TextStyle(color: AppColors.text3))),
                )
              else
                ...runs.map(_runTile),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _banner(SyncRun? lastOk, double hrs, int fails, int total) {
    Color bg, fg;
    String text;
    String ago(double h) =>
        h < 1 ? '${(h * 60).clamp(1, 60).round()} min' : '${h.round()}h';
    if (lastOk == null) {
      bg = AppColors.redBg;
      fg = AppColors.redFg;
      text = total > 0
          ? 'No successful sync yet today — every run so far has failed. Needs attention.'
          : 'No sync has run yet today.';
    } else if (hrs > 3) {
      bg = AppColors.redBg;
      fg = AppColors.redFg;
      text = 'Last successful sync was ${ago(hrs)} ago — the hourly sync looks broken.';
    } else if (fails > 0) {
      bg = AppColors.amberBg;
      fg = AppColors.amberFg;
      text = '$fails failed run(s) today, but the latest sync succeeded ${ago(hrs)} ago.';
    } else {
      bg = AppColors.greenBg;
      fg = AppColors.greenFg;
      text = 'Sync is healthy — last successful run ${ago(hrs)} ago.';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(
              lastOk != null && hrs <= 3 && fails == 0
                  ? Icons.check_circle
                  : Icons.warning_amber_rounded,
              color: fg,
              size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.text2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3)),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    color: valueColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _runTile(SyncRun r) {
    final dt = DateTime.tryParse(r.startedAt ?? '')?.toLocal();
    final time = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '–';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: r.ok ? Colors.white : AppColors.redBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(time,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: r.ok ? AppColors.greenBg : AppColors.redBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(r.ok ? 'success' : (r.status ?? '?'),
                    style: TextStyle(
                        color: r.ok ? AppColors.greenFg : AppColors.redFg,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              if (r.totalFound != null)
                Text('found ${r.totalFound} · deep ${r.deepScraped ?? 0}',
                    style: const TextStyle(
                        color: AppColors.text3, fontSize: 11.5)),
            ],
          ),
          if ((r.message ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.message!,
                style: const TextStyle(color: AppColors.redFg, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
