import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/occurrence.dart';
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

  final List<Occurrence> _occurrences = [];
  OccurrenceType? _typeFilter;
  int _page = 0;
  bool _loading = false;
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
                onTypeChanged: (type) {
                  setState(() => _typeFilter = type);
                  _loadFirstPage();
                },
                onSearch: _loadFirstPage,
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
                  message: 'Tente ajustar os termos da sua busca.',
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
    required this.onTypeChanged,
    required this.onSearch,
  });

  final TextEditingController searchController;
  final OccurrenceType? typeFilter;
  final ValueChanged<OccurrenceType?> onTypeChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros e Busca',
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Text('Pesquisar'),
              ),
            ),
          ],
        ),
      ),
    );
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
