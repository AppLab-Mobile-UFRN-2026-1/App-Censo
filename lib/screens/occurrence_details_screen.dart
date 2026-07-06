import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/occurrence.dart';
import '../theme/app_theme.dart';

class OccurrenceDetailsScreen extends StatelessWidget {
  const OccurrenceDetailsScreen({super.key});

  static const routeName = '/occurrence-details';

  @override
  Widget build(BuildContext context) {
    final occurrence =
        ModalRoute.of(context)!.settings.arguments! as Occurrence;
    final date = DateFormat('dd/MM/yyyy HH:mm').format(occurrence.createdAt);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do ponto')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: occurrence.photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.black.withValues(alpha: 0.05),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black.withValues(alpha: 0.05),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 42),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeBadge(occurrence: occurrence),
                  const SizedBox(height: 14),
                  Text(
                    occurrence.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Divider(height: 28),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Status',
                    value: occurrence.status,
                  ),
                  _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: 'Municipio',
                    value: occurrence.city ?? 'Nao identificado',
                  ),
                  _InfoRow(
                    icon: Icons.map_outlined,
                    label: 'Estado',
                    value: occurrence.state ?? 'Nao identificado',
                  ),
                  _InfoRow(
                    icon: Icons.pin_drop_outlined,
                    label: 'Coordenadas',
                    value:
                        '${occurrence.latitude.toStringAsFixed(6)}, ${occurrence.longitude.toStringAsFixed(6)}',
                  ),
                  _InfoRow(
                    icon: Icons.event_outlined,
                    label: 'Data',
                    value: date,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.occurrence});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final color = occurrence.type == OccurrenceType.request
        ? Theme.of(context).colorScheme.tertiary
        : AppTheme.workColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            occurrence.type == OccurrenceType.request
                ? Icons.report_problem_outlined
                : Icons.construction_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              occurrence.displayKind,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
