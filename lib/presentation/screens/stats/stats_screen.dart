import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/media_repository.dart';
import '../../providers/providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (stats) {
          final totalWorks = stats.totalAnime + stats.totalManga + stats.totalManhwa;
          if (totalWorks == 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ajoute des contenus pour voir apparaître tes statistiques !',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: [
                  _NumberCard(label: 'Animes', value: stats.totalAnime),
                  _NumberCard(label: 'Mangas', value: stats.totalManga),
                  _NumberCard(label: 'Manhwas', value: stats.totalManhwa),
                  _NumberCard(label: 'Terminés', value: stats.completed),
                  _NumberCard(label: 'En cours', value: stats.inProgress),
                  _NumberCard(label: 'Abandonnés', value: stats.dropped),
                  _NumberCard(
                      label: 'Épisodes vus', value: stats.totalEpisodesWatched),
                  _NumberCard(
                      label: 'Chapitres lus', value: stats.totalChaptersRead),
                ],
              ),
              const SizedBox(height: 24),
              Text('Répartition par type',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _TypePieChart(stats: stats),
              ),
              const SizedBox(height: 24),
              Text('Répartition par statut',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _StatusBarChart(stats: stats, totalWorks: totalWorks),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  final String label;
  final int value;
  const _NumberCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value.toString(),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TypePieChart extends StatelessWidget {
  final LibraryStats stats;
  const _TypePieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = [
      (label: 'Anime', value: stats.totalAnime, color: scheme.primary),
      (label: 'Manga', value: stats.totalManga, color: scheme.secondary),
      (label: 'Manhwa', value: stats.totalManhwa, color: scheme.tertiary),
    ].where((e) => e.value > 0).toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: data
                  .map((e) => PieChartSectionData(
                        value: e.value.toDouble(),
                        title: e.value.toString(),
                        color: e.color,
                        radius: 60,
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                            width: 10, height: 10, color: e.color),
                        const SizedBox(width: 6),
                        Text(e.label),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _StatusBarChart extends StatelessWidget {
  final LibraryStats stats;
  final int totalWorks;
  const _StatusBarChart({required this.stats, required this.totalWorks});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final toConsume =
        (totalWorks - stats.completed - stats.inProgress - stats.dropped)
            .clamp(0, totalWorks);

    final bars = [
      (label: 'À faire', value: toConsume, color: scheme.outline),
      (label: 'En cours', value: stats.inProgress, color: scheme.primary),
      (label: 'Terminé', value: stats.completed, color: Colors.green),
      (label: 'Abandonné', value: stats.dropped, color: Colors.redAccent),
    ];

    final maxY = (bars.map((b) => b.value).fold<int>(0, (a, b) => a > b ? a : b))
            .toDouble() +
        1;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: [
          for (int i = 0; i < bars.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: bars[i].value.toDouble(),
                color: bars[i].color,
                width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(bars[i].label,
                      style: Theme.of(context).textTheme.bodySmall),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
