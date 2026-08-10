import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/constants/app_options.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/utils/debouncer.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/section_title.dart';
import 'package:internsfe/core/share/shareable_item.dart';
import 'package:internsfe/core/widgets/content_item_menu.dart';
import 'package:internsfe/domain/repositories/history_repository.dart';
import 'package:internsfe/presentation/features/history/library_navigation.dart';

final historyFilterProvider = StateProvider<HistoryFilter>((ref) {
  return const HistoryFilter();
});

final historyListProvider = FutureProvider.autoDispose((ref) async {
  final filter = ref.watch(historyFilterProvider);
  return ref.read(historyRepositoryProvider).fetchHistory(filter);
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyListProvider);
    final filter = ref.watch(historyFilterProvider);

    return AppScaffold(
      title: 'History & Stats',
      showBackToHome: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search activity...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                _debouncer.run(() {
                  ref.read(historyFilterProvider.notifier).state =
                      HistoryFilter(type: filter.type, query: v.trim());
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Type: '),
                DropdownButton<String?>(
                  value: filter.type,
                  hint: const Text('All'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...AppOptions.historyTypes.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    ),
                  ],
                  onChanged: (v) {
                    ref.read(historyFilterProvider.notifier).state =
                        HistoryFilter(type: v, query: filter.query);
                  },
                ),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(historyFilterProvider.notifier).state =
                        const HistoryFilter();
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No activity matches your filters.'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  children: [
                    SizedBox(
                      height: 120,
                      child: _ActivityChart(count: items.length),
                    ),
                    const SectionTitle(title: 'Activity Timeline'),
                    ...items.asMap().entries.map(
                          (e) => Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ListTile(
                              title: Text(e.value.title),
                              subtitle: Text(
                                '${e.value.subtitle} · ${e.value.resultLabel}\n${e.value.displayTime}',
                              ),
                              isThreeLine: true,
                              onTap: () => openHistoryReport(context, e.value),
                              trailing: ContentItemMenu(
                                item: ShareableItem.fromActivity(e.value),
                                activityId: e.value.id,
                                onDeleted: () =>
                                    ref.invalidate(historyListProvider),
                              ),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: (count + 2).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                width: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
