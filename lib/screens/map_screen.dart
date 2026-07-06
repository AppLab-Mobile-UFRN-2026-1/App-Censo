import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/occurrence.dart';
import '../services/location_service.dart';
import '../services/occurrence_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'profile_screen.dart';
import 'new_occurrence_screen.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  static const routeName = '/map';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _occurrenceService = OccurrenceService();
  final _locationService = LocationService();

  List<Occurrence> _occurrences = [];
  LatLng? _currentPoint;
  double _zoom = 13;
  bool _loading = true;
  String? _error;

  static const _fallbackCenter = LatLng(-3.7319, -38.5267);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentPoint = await _loadCurrentPoint();
      final occurrences = await _occurrenceService.fetchOccurrences();

      if (!mounted) return;
      setState(() {
        _occurrences = occurrences;
        _currentPoint = currentPoint;
      });

      if (currentPoint != null) {
        _zoom = 15;
        _mapController.move(currentPoint, _zoom);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<LatLng?> _loadCurrentPoint() async {
    try {
      final position = await _locationService.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openNewOccurrence() async {
    final created = await Navigator.of(
      context,
    ).pushNamed(NewOccurrenceScreen.routeName);
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPoint ?? _fallbackCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de ocorrencias'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_outlined),
          ),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () =>
                Navigator.of(context).pushNamed(ProfileScreen.routeName),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.applab.app_censo',
              ),
              MarkerLayer(
                markers: [
                  if (_currentPoint != null)
                    Marker(
                      point: _currentPoint!,
                      width: 44,
                      height: 44,
                      child: _CurrentLocationMarker(),
                    ),
                  ..._occurrences.map(_buildOccurrenceMarker),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          if (_loading)
            const Positioned(
              left: 16,
              right: 16,
              top: 12,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: _MapSummary(
              count: _occurrences.length,
              error: _error,
              onRetry: _load,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewOccurrence,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Novo registro'),
      ),
    );
  }

  Marker _buildOccurrenceMarker(Occurrence occurrence) {
    final color = occurrence.type == OccurrenceType.request
        ? Theme.of(context).colorScheme.tertiary
        : AppTheme.workColor;

    return Marker(
      point: occurrence.point,
      width: 48,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Icon(
          occurrence.type == OccurrenceType.request
              ? Icons.report_problem_outlined
              : Icons.construction_outlined,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({
    required this.count,
    required this.error,
    required this.onRetry,
  });

  final int count;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Nao foi possivel atualizar',
        message: error!,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.layers_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count == 1 ? '1 ponto no mapa' : '$count pontos no mapa',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.sync_outlined, size: 18),
              label: const Text('Sincronizar'),
            ),
          ],
        ),
      ),
    );
  }
}
