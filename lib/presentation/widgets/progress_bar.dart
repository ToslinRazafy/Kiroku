import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final String? label;

  const AppProgressBar({super.key, required this.progress, this.label});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            '$label · $pct%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
