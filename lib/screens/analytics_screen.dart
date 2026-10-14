import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen(
      {super.key,
      required this.storage,
      required this.userId,
      required this.currency});

  final StorageService storage;
  final String userId;
  final String currency;

  static const List<Color> colors = [
    AppTheme.purple,
    AppTheme.green,
    AppTheme.orange,
    Color(0xFF4387D8),
    Color(0xFFE5B23D),
    Color(0xFFB75AA6),
    Color(0xFF8D8CA3)
  ];

  @override
  Widget build(BuildContext context) {
    final map = categoryTotals(storage.expenses(userId));
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Analytics',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink)),
        const SizedBox(height: 5),
        const Text('Understand where your money goes.',
            style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 18),
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Spending by category',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              if (total == 0)
                const EmptyState(
                    icon: Icons.pie_chart_outline,
                    title: 'Nothing to chart yet',
                    message: 'Add expenses to see a category breakdown.')
              else ...[
                SizedBox(
                    height: 230,
                    child: PieChart(PieChartData(
                        centerSpaceRadius: 52,
                        sectionsSpace: 3,
                        sections: entries.asMap().entries.map((e) {
                          final pct = e.value.value / total * 100;
                          return PieChartSectionData(
                              value: e.value.value,
                              color: colors[e.key % colors.length],
                              title:
                                  pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                              radius: 58,
                              titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800));
                        }).toList()))),
                Center(
                    child: Column(children: [
                  const Text('Total spent',
                      style: TextStyle(color: AppTheme.muted)),
                  Text(money(total, currency),
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w900))
                ])),
                const SizedBox(height: 18),
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    itemBuilder: (c, i) {
                      final e = entries[i];
                      return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                              radius: 6,
                              backgroundColor: colors[i % colors.length]),
                          title: Text(e.key),
                          subtitle: Text(
                              '${(e.value / total * 100).toStringAsFixed(1)}%'),
                          trailing: Text(money(e.value, currency),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)));
                    })
              ]
            ])),
      ],
    );
  }
}
