import 'package:flutter/material.dart';

import '../models/occurrence.dart';
import '../widgets/app_text_field.dart';
import '../widgets/occurrence_type_selector.dart';
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

  OccurrenceType _type = OccurrenceType.request;
  String? _category = OccurrenceOptions.requestCategories.first;
  String? _stage = OccurrenceOptions.workStages.first;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de submissao em desenvolvimento.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo registro'),
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
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Salvar registro',
                icon: Icons.cloud_upload_outlined,
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