import 'package:flutter/material.dart';
import 'theme.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard(
      {super.key,
      required this.title,
      required this.value,
      required this.icon,
      required this.color});
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext c) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDECF4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const Spacer(),
        Text(title,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 5),
        FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppTheme.ink)))
      ]));
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      required this.title,
      required this.message,
      required this.icon});
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        Icon(icon, size: 36, color: AppTheme.purple),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted))
      ]));
}
