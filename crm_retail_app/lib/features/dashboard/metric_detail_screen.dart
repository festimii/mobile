import 'package:flutter/material.dart';
import '../../models/dashboard_models.dart';

class MetricDetailScreen extends StatelessWidget {
  final SummaryMetric metric;

  const MetricDetailScreen({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subKpis = metric.subMetrics;

    return Scaffold(
      appBar: AppBar(title: Text(metric.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: metric.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(metric.icon, size: 32, color: metric.color),
                ),
                const SizedBox(width: 16),
                Text(
                  metric.value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: subKpis.isEmpty
                  ? Center(
                      child: Text(
                        'No additional data',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: subKpis.map((kpi) {
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(kpi.icon, color: kpi.color, size: 28),
                                const SizedBox(height: 10),
                                Text(
                                  kpi.title,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  kpi.value,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

