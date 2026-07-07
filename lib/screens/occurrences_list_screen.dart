import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/occurrence.dart';
import '../services/location_service.dart';
import '../services/occurrence_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';
import 'occurrence_details_screen.dart';

class OccurrencesListScreen extends StatefulWidget {
  const OccurrencesListScreen({super.key});

  static const routeName = '/occurrences-list';

  @override
  State<OccurrencesListScreen> createState() => _OccurrencesListScreenState();
}

class _OccurrencesListScreenState extends State<OccurrencesListScreen> {
  static const _pageSize = 20;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _occurrenceService = OccurrenceService();
  final _locationService = LocationService();

  final List<Occurrence> _occurrences = [];
  OccurrenceType? _typeFilter;
  double? _radiusKm;
  LatLng? _searchCenter;
  String _areaLabel = 'Sem área definida';
  int _page = 0;
  bool _loading = false;
  bool _loadingLocation = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 280) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _page = 0;
      _hasMore = true;
      _occurrences.clear();
    });
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_loading || !_hasMore) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await _occurrenceService.fetchOccurrencesPage(
        page: _page,
        pageSize: _pageSize,
        type: _typeFilter,
        search: _searchController.text,
        center: _searchCenter,
        radiusKm: _radiusKm,
      );

      if (!mounted) return;
      setState(() {
        _occurrences.addAll(page);
        _page++;
        _hasMore = page.length == _pageSize;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _radiusKm ??= 10;
        _searchCenter = LatLng(position.latitude, position.longitude);
        _areaLabel = 'Centro: sua localização';
      });
      await _loadFirstPage();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _clearRadius() {
    setState(() {
      _radiusKm = null;
      _searchCenter = null;
      _areaLabel = 'Sem área definida';
    });
    _loadFirstPage();
  }

  Future<void> _pickArea() async {
    final result = await Navigator.of(context).push<_AreaSelection>(
      MaterialPageRoute(
        builder: (_) => AreaPickerScreen(
          initialCenter: _searchCenter,
          initialRadiusKm: _radiusKm ?? 10,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _searchCenter = result.center;
      _radiusKm = result.radiusKm;
      _areaLabel = 'Centro escolhido no mapa';
    });
    await _loadFirstPage();
  }

  String get _areaPreview {
    final center = _searchCenter;
    if (center == null) {
      return _areaLabel;
    }
    return '${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}';
  }

  Future<void> _openDetails(Occurrence occurrence) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(OccurrenceDetailsScreen.routeName, arguments: occurrence);
    if (changed == true) {
      await _loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrências')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFirstPage,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _FiltersCard(
                searchController: _searchController,
                typeFilter: _typeFilter,
                radiusKm: _radiusKm,
                areaLabel: _areaLabel,
                areaPreview: _areaPreview,
                areaCenter: _searchCenter,
                loadingLocation: _loadingLocation,
                onTypeChanged: (type) {
                  setState(() => _typeFilter = type);
                  _loadFirstPage();
                },
                onSearch: _loadFirstPage,
                onUseCurrentLocation: _useCurrentLocation,
                onPickArea: _pickArea,
                onRadiusChanged: (radius) {
                  setState(() => _radiusKm = radius);
                  if (_searchCenter != null) {
                    _loadFirstPage();
                  }
                },
                onClearRadius: _clearRadius,
              ),
              const SizedBox(height: 12),
              if (_error != null)
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Falha ao carregar',
                  message: _error!,
                )
              else if (_occurrences.isEmpty && !_loading)
                const EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Nenhuma ocorrência encontrada',
                  message: 'Ajuste os filtros ou amplie o raio da busca.',
                )
              else
                ..._occurrences.map(
                  (occurrence) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OccurrenceListTile(
                      occurrence: occurrence,
                      isOwner:
                          occurrence.userId == _occurrenceService.currentUserId,
                      onTap: () => _openDetails(occurrence),
                    ),
                  ),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_hasMore && _occurrences.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Fim da lista',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.searchController,
    required this.typeFilter,
    required this.radiusKm,
    required this.areaLabel,
    required this.areaPreview,
    required this.areaCenter,
    required this.loadingLocation,
    required this.onTypeChanged,
    required this.onSearch,
    required this.onUseCurrentLocation,
    required this.onPickArea,
    required this.onRadiusChanged,
    required this.onClearRadius,
  });

  final TextEditingController searchController;
  final OccurrenceType? typeFilter;
  final double? radiusKm;
  final String areaLabel;
  final String areaPreview;
  final LatLng? areaCenter;
  final bool loadingLocation;
  final ValueChanged<OccurrenceType?> onTypeChanged;
  final VoidCallback onSearch;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onPickArea;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onClearRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Buscar',
              hintText: 'Descrição, cidade, categoria ou estágio',
              controller: searchController,
              prefixIcon: Icons.search_outlined,
              onFieldSubmitted: (_) => onSearch(),
            ),
            const SizedBox(height: 12),
            _TypeFilterBar(value: typeFilter, onChanged: onTypeChanged),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE7DAF5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Área de busca',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    radiusKm == null
                        ? areaLabel
                        : '$areaLabel - raio ${radiusKm!.toStringAsFixed(0)} km',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (areaPreview != 'Sem área definida') ...[
                    const SizedBox(height: 4),
                    Text(
                      areaPreview,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (areaCenter != null && radiusKm != null) ...[
                    const SizedBox(height: 10),
                    _AreaPreviewMap(center: areaCenter!, radiusKm: radiusKm!),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RadiusChip(
                        value: 5,
                        selectedValue: radiusKm,
                        onSelected: onRadiusChanged,
                      ),
                      _RadiusChip(
                        value: 10,
                        selectedValue: radiusKm,
                        onSelected: onRadiusChanged,
                      ),
                      _RadiusChip(
                        value: 20,
                        selectedValue: radiusKm,
                        onSelected: onRadiusChanged,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: loadingLocation
                              ? null
                              : onUseCurrentLocation,
                          icon: loadingLocation
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_outlined),
                          label: const Text('Meu local'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPickArea,
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Escolher'),
                        ),
                      ),
                    ],
                  ),
                  if (radiusKm != null || areaLabel != 'Sem área definida')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onClearRadius,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Limpar área'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.tune_outlined),
                label: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip({
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final double value;
  final double? selectedValue;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selectedValue == value,
      label: Text('${value.toStringAsFixed(0)} km'),
      onSelected: (_) => onSelected(value),
    );
  }
}

class _AreaPreviewMap extends StatelessWidget {
  const _AreaPreviewMap({required this.center, required this.radiusKm});

  final LatLng center;
  final double radiusKm;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 128,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: _zoomForRadius(radiusKm),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.applab.app_censo',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: AppTheme.primaryColor.withValues(alpha: 0.16),
                    borderColor: AppTheme.primaryColor,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 34,
                    height: 34,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 5) return 12;
    if (radiusKm <= 10) return 11;
    if (radiusKm <= 20) return 10;
    return 9;
  }
}

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({required this.value, required this.onChanged});

  final OccurrenceType? value;
  final ValueChanged<OccurrenceType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth < 360;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TypeFilterPill(
              selected: value == null,
              icon: Icons.done_all_outlined,
              label: 'Todos',
              width: fullWidth ? constraints.maxWidth : null,
              onTap: () => onChanged(null),
            ),
            _TypeFilterPill(
              selected: value == OccurrenceType.request,
              icon: Icons.report_problem_outlined,
              label: 'Solicitações',
              width: fullWidth ? constraints.maxWidth : null,
              onTap: () => onChanged(OccurrenceType.request),
            ),
            _TypeFilterPill(
              selected: value == OccurrenceType.publicWork,
              icon: Icons.construction_outlined,
              label: 'Obras',
              width: fullWidth ? constraints.maxWidth : null,
              onTap: () => onChanged(OccurrenceType.publicWork),
            ),
          ],
        );
      },
    );
  }
}

class _TypeFilterPill extends StatelessWidget {
  const _TypeFilterPill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.width,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFD8C5E8),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AreaPickerScreen extends StatefulWidget {
  const AreaPickerScreen({
    required this.initialRadiusKm,
    this.initialCenter,
    super.key,
  });

  final LatLng? initialCenter;
  final double initialRadiusKm;

  @override
  State<AreaPickerScreen> createState() => _AreaPickerScreenState();
}

class _AreaPickerScreenState extends State<AreaPickerScreen> {
  final _mapController = MapController();
  static const _fallbackCenter = LatLng(-3.7319, -38.5267);

  late LatLng _center = widget.initialCenter ?? _fallbackCenter;
  late double _radiusKm = widget.initialRadiusKm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolher área')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: (tapPosition, point) => setState(() => _center = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.applab.app_censo',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _center,
                    radius: _radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: AppTheme.primaryColor.withValues(alpha: 0.16),
                    borderColor: AppTheme.primaryColor,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryColor,
                      size: 40,
                    ),
                  ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Toque no mapa para mover o centro',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Raio: ${_radiusKm.toStringAsFixed(0)} km'),
                    Slider(
                      min: 1,
                      max: 30,
                      divisions: 29,
                      value: _radiusKm,
                      label: '${_radiusKm.toStringAsFixed(0)} km',
                      onChanged: (value) => setState(() => _radiusKm = value),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(
                        _AreaSelection(center: _center, radiusKm: _radiusKm),
                      ),
                      icon: const Icon(Icons.check_outlined),
                      label: const Text('Usar esta área'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaSelection {
  const _AreaSelection({required this.center, required this.radiusKm});

  final LatLng center;
  final double radiusKm;
}

class _OccurrenceListTile extends StatelessWidget {
  const _OccurrenceListTile({
    required this.occurrence,
    required this.isOwner,
    required this.onTap,
  });

  final Occurrence occurrence;
  final bool isOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = occurrence.type == OccurrenceType.request
        ? Theme.of(context).colorScheme.tertiary
        : AppTheme.workColor;
    final date = DateFormat('dd/MM/yyyy').format(occurrence.createdAt);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(
            occurrence.type == OccurrenceType.request
                ? Icons.report_problem_outlined
                : Icons.construction_outlined,
            color: color,
          ),
        ),
        title: Text(
          occurrence.displayKind,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${occurrence.city ?? 'Cidade não identificada'} - $date\n${occurrence.description}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isOwner
            ? Icon(
                Icons.verified_user_outlined,
                color: Theme.of(context).colorScheme.primary,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
