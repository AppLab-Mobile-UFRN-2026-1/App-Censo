import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/occurrence.dart';
import '../services/occurrence_service.dart';
import '../theme/app_theme.dart';
import 'new_occurrence_screen.dart';

class OccurrenceDetailsScreen extends StatefulWidget {
  const OccurrenceDetailsScreen({super.key});

  static const routeName = '/occurrence-details';

  @override
  State<OccurrenceDetailsScreen> createState() =>
      _OccurrenceDetailsScreenState();
}

class _OccurrenceDetailsScreenState extends State<OccurrenceDetailsScreen> {
  final _occurrenceService = OccurrenceService();
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final occurrence =
        ModalRoute.of(context)!.settings.arguments! as Occurrence;
    final date = DateFormat('dd/MM/yyyy HH:mm').format(occurrence.createdAt);
    final isOwner = occurrence.userId == _occurrenceService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do ponto'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Editar',
              onPressed: _deleting ? null : () => _edit(occurrence),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (isOwner)
            IconButton(
              tooltip: 'Excluir',
              onPressed: _deleting ? null : () => _confirmDelete(occurrence),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
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
                  if (isOwner) ...[
                    const Divider(height: 28),
                    Text(
                      'Este registro foi criado por voce.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Occurrence occurrence) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(NewOccurrenceScreen.routeName, arguments: occurrence);
    if (!mounted) return;
    if (changed == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmDelete(Occurrence occurrence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: const Text(
          'Esta acao remove o ponto do mapa para todos os usuarios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _occurrenceService.deleteOccurrence(occurrence);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro excluido.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $error')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
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
