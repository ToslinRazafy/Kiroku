import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';
import '../../data/models/media_item.dart';
import 'progress_bar.dart';

class ContentCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;

  const ContentCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cover(path: item.coverImagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeChip(type: item.type),
                        const SizedBox(width: 6),
                        _WorkStatusDot(status: item.workStatus),
                        const Spacer(),
                        if (item.rating != null) ...[
                          Icon(Icons.star_rounded,
                              size: 16, color: colorScheme.tertiary),
                          const SizedBox(width: 2),
                          Text(item.rating!.toStringAsFixed(1)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _PersonalStatusChip(item: item),
                    const SizedBox(height: 8),
                    AppProgressBar(
                      progress: item.progress,
                      label: item.progressLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? path;
  const _Cover({required this.path});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 64,
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.image_outlined,
          color: Theme.of(context).colorScheme.outline),
    );

    if (path == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(path!),
        width: 64,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ContentType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

/// Petit indicateur du statut RÉEL de publication de l'œuvre (distinct
/// du statut personnel affiché plus bas sur la carte).
class _WorkStatusDot extends StatelessWidget {
  final PublicationStatus status;
  const _WorkStatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PublicationStatus.ongoing => Colors.blueAccent,
      PublicationStatus.completed => Colors.grey,
      PublicationStatus.upcoming => Colors.purpleAccent,
    };
    return Tooltip(
      message: "Œuvre : ${status.label}",
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontSize: 10),
        ),
      ),
    );
  }
}

class _PersonalStatusChip extends StatelessWidget {
  final MediaItem item;
  const _PersonalStatusChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (item.personalStatus) {
      PersonalStatus.completed => Colors.green,
      PersonalStatus.inProgress => scheme.primary,
      PersonalStatus.dropped => Colors.redAccent,
      PersonalStatus.rewatch => Colors.orange,
      PersonalStatus.toConsume => scheme.outline,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(item.personalStatus.labelFor(item.type),
            style: Theme.of(context).textTheme.bodySmall),
        if (item.isCaughtUpButOngoing) ...[
          const SizedBox(width: 6),
          Text('· à jour',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline, fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }
}
