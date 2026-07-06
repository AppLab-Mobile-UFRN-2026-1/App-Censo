import 'package:flutter/material.dart';

import '../models/occurrence.dart';

class OccurrenceTypeSelector extends StatelessWidget {
  const OccurrenceTypeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final OccurrenceType value;
  final ValueChanged<OccurrenceType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<OccurrenceType>(
      segments: const [
        ButtonSegment(
          value: OccurrenceType.request,
          icon: Icon(Icons.report_problem_outlined),
          label: Text('Solicitacao'),
        ),
        ButtonSegment(
          value: OccurrenceType.publicWork,
          icon: Icon(Icons.construction_outlined),
          label: Text('Obra'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (values) => onChanged(values.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
