import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/exchange_rate_service.dart';
import '../theme.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  final _service = ExchangeRateService();
  final _amount = TextEditingController(text: '100');
  String _base = 'PHP';
  late Future<RateResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetch(_base);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _future = _service.fetch(_base));

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amount.text) ?? 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Exchange rates',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink)),
        const SizedBox(height: 5),
        const Text('Retrieve current exchange rates from a public API.',
            style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 18),
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              DropdownButtonFormField<String>(
                  initialValue: _base,
                  decoration: const InputDecoration(labelText: 'Base currency'),
                  items: const ['PHP', 'USD', 'EUR', 'JPY', 'GBP', 'SGD']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      _base = v;
                      _refresh();
                    }
                  }),
              const SizedBox(height: 12),
              TextField(
                  controller: _amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration:
                      const InputDecoration(labelText: 'Amount to convert'),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              FilledButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh rates'))
            ])),
        const SizedBox(height: 16),
        FutureBuilder<RateResult>(
            future: _future,
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()));
              }
              if (s.hasError) {
                return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 36, color: AppTheme.orange),
                      const SizedBox(height: 8),
                      const Text('Could not load rates',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text(
                          'Check internet access and try again. The budget tracker still works offline.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.muted)),
                      TextButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'))
                    ]));
              }
              final r = s.data!;
              final entries = r.rates.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));
              return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rates for 1 ${r.base}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                        Text('API date: ${r.date}',
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 12)),
                        const SizedBox(height: 8),
                        if (entries.isEmpty)
                          const Text(
                              'No rates available for this base currency.',
                              style: TextStyle(color: AppTheme.muted))
                        else ...[
                          const Divider(height: 24),
                          ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entries.length,
                              itemBuilder: (c, i) {
                                final e = entries[i];
                                return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                        backgroundColor: AppTheme.purple
                                            .withValues(alpha: .12),
                                        child: Text(e.key,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800))),
                                    title: Text(
                                        '1 ${r.base} = ${e.value.toStringAsFixed(4)} ${e.key}'),
                                    trailing: Text(
                                        (e.value * amount).toStringAsFixed(2),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.purple)));
                              }),
                        ],
                        const Text(
                            'Informational rates may differ from bank rates.',
                            style:
                                TextStyle(fontSize: 11, color: AppTheme.muted))
                      ]));
            })
      ],
    );
  }
}
