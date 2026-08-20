import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data.dart';
import '../models.dart';
import '../notifications.dart';
import '../theme.dart';
import 'dashboard_tab.dart';
import 'cases_tab.dart';
import 'sync_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _isAdmin = false;
  late Future<List<ClaimCase>> _casesFuture;

  @override
  void initState() {
    super.initState();
    final email =
        (Supabase.instance.client.auth.currentUser?.email ?? '').trim().toLowerCase();
    _isAdmin = email == 'admin@vvistech.com';
    _casesFuture = _loadCases();
  }

  // Dashboard is admin-only; everyone else gets Cases + Sync.
  List<String> get _tabs =>
      _isAdmin ? const ['dash', 'cases', 'sync'] : const ['cases', 'sync'];
  String get _title {
    switch (_tabs[_index]) {
      case 'dash':
        return 'Dashboard';
      case 'cases':
        return 'Cases';
      default:
        return 'Sync History';
    }
  }

  // Load cases, then run change-detection notifications (fire-and-forget).
  Future<List<ClaimCase>> _loadCases() async {
    final cases = await fetchAllCases();
    detectAndNotify(cases);
    return cases;
  }

  Future<void> _reload() async {
    setState(() => _casesFuture = _loadCases());
    await _casesFuture;
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(_title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: tab == 'sync'
          ? const SyncTab()
          : FutureBuilder<List<ClaimCase>>(
              future: _casesFuture,
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return _ErrorView(
                      message: snap.error.toString(), onRetry: _reload);
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cases = snap.data!;
                return tab == 'dash'
                    ? DashboardTab(cases: cases, onRefresh: _reload)
                    : CasesTab(cases: cases, onRefresh: _reload);
              },
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          if (_isAdmin)
            const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard'),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Cases'),
          const NavigationDestination(
              icon: Icon(Icons.sync_outlined),
              selectedIcon: Icon(Icons.sync),
              label: 'Sync'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.text3, size: 40),
            const SizedBox(height: 12),
            Text("Couldn't load data",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text3, fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
