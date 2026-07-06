import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/occurrence.dart';
import '../services/location_service.dart';
import '../services/occurrence_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/occurrence_type_selector.dart';
import '../widgets/photo_capture_field.dart';
import '../widgets/primary_button.dart';

class NewOccurrenceScreen extends StatefulWidget {
  const NewOccurrenceScreen({super.key});

  static const routeName = '/new-occurrence';

  @override
  State<NewOccurrenceScreen> createState() => _NewOccurrenceScreenState();
}

class _NewOccurrenceScreenState extends State<NewOccurrenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationService = LocationService();
  final _occurrenceService = OccurrenceService();

  OccurrenceType _type = OccurrenceType.request;
  String? _category = OccurrenceOptions.requestCategories.first;
  String? _stage = OccurrenceOptions.workStages.first;
  XFile? _photo;
  double? _latitude;
  double? _longitude;
  Locality? _locality;
  Occurrence? _editingOccurrence;
  bool _readArguments = false;
  bool _locating = true;
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readArguments) return;
    _readArguments = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Occurrence) {
      _editingOccurrence = args;
      _type = args.type;
      _category = args.category ?? OccurrenceOptions.requestCategories.first;
      _stage = args.stage ?? OccurrenceOptions.workStages.first;
      _descriptionController.text = args.description;
      _latitude = args.latitude;
      _longitude = args.longitude;
      _locality = Locality(city: args.city, state: args.state);
      _locating = false;
    } else {
      _loadLocation();
    }
  }

  Future<void> _loadLocation() async {
    setState(() => _locating = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final locality = await _locationService.reverseGeocode(position);
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locality = locality;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final editingOccurrence = _editingOccurrence;

    if (_photo == null && editingOccurrence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture uma foto do local.')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atualize a localizacao antes de salvar.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (editingOccurrence == null) {
        await _occurrenceService.createOccurrence(
          type: _type,
          description: _descriptionController.text.trim(),
          status: 'registered',
          photo: _photo!,
          latitude: _latitude!,
          longitude: _longitude!,
          city: _locality?.city,
          state: _locality?.state,
          category: _type == OccurrenceType.request ? _category : null,
          stage: _type == OccurrenceType.publicWork ? _stage : null,
        );
      } else {
        await _occurrenceService.updateOccurrence(
          occurrence: editingOccurrence,
          type: _type,
          description: _descriptionController.text.trim(),
          status: editingOccurrence.status,
          photo: _photo,
          category: _type == OccurrenceType.request ? _category : null,
          stage: _type == OccurrenceType.publicWork ? _stage : null,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editingOccurrence == null
                ? 'Registro salvo com sucesso.'
                : 'Registro atualizado com sucesso.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editingOccurrence == null ? 'Novo registro' : 'Editar registro',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              OccurrenceTypeSelector(
                value: _type,
                onChanged: (type) {
                  setState(() => _type = type);
                },
              ),
              const SizedBox(height: 16),
              _buildSpecificField(),
              const SizedBox(height: 14),
              AppTextField(
                label: _type == OccurrenceType.request
                    ? 'Descricao do problema'
                    : 'Descricao do status da obra',
                hintText: _type == OccurrenceType.request
                    ? 'Informe o problema observado no local'
                    : 'Informe o andamento observado na obra',
                controller: _descriptionController,
                maxLines: 4,
                prefixIcon: Icons.notes_outlined,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 12) {
                    return 'Descreva com pelo menos 12 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              if (_editingOccurrence != null) ...[
                _CurrentPhotoCard(occurrence: _editingOccurrence!),
                const SizedBox(height: 14),
              ],
              PhotoCaptureField(
                photo: _photo,
                onPhotoCaptured: (photo) => setState(() => _photo = photo),
              ),
              const SizedBox(height: 14),
              _LocationCard(
                locating: _locating,
                latitude: _latitude,
                longitude: _longitude,
                locality: _locality,
                onRefresh: _editingOccurrence == null ? _loadLocation : null,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: _editingOccurrence == null
                    ? 'Salvar registro'
                    : 'Atualizar registro',
                icon: Icons.cloud_upload_outlined,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificField() {
    final values = _type == OccurrenceType.request
        ? OccurrenceOptions.requestCategories
        : OccurrenceOptions.workStages;
    final value = _type == OccurrenceType.request ? _category : _stage;

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: _type == OccurrenceType.request
            ? 'Categoria do problema'
            : 'Estagio da obra',
        prefixIcon: Icon(
          _type == OccurrenceType.request
              ? Icons.category_outlined
              : Icons.timeline_outlined,
        ),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          if (_type == OccurrenceType.request) {
            _category = value;
          } else {
            _stage = value;
          }
        });
      },
      validator: (value) => value == null ? 'Selecione uma opcao.' : null,
    );
  }
}

class _CurrentPhotoCard extends StatelessWidget {
  const _CurrentPhotoCard({required this.occurrence});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foto atual',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
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
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture uma nova foto somente se quiser substituir a atual.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.locating,
    required this.latitude,
    required this.longitude,
    required this.locality,
    required this.onRefresh,
  });

  final bool locating;
  final double? latitude;
  final double? longitude;
  final Locality? locality;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.my_location_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Localizacao',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar localizacao',
                  onPressed: locating ? null : onRefresh,
                  icon: locating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(locality?.label ?? 'Aguardando localizacao'),
            const SizedBox(height: 4),
            Text(
              latitude == null || longitude == null
                  ? 'Coordenadas indisponiveis'
                  : '${latitude!.toStringAsFixed(6)}, '
                        '${longitude!.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
