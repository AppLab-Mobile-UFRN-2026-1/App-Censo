import 'package:latlong2/latlong.dart';

enum OccurrenceType {
  request('request', 'Solicitacao de obra'),
  publicWork('public_work', 'Obra em execucao');

  const OccurrenceType(this.value, this.label);

  final String value;
  final String label;

  static OccurrenceType fromValue(String value) {
    return OccurrenceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => OccurrenceType.request,
    );
  }
}

class OccurrenceOptions {
  static const requestCategories = [
    'Pavimentacao',
    'Iluminacao',
    'Saneamento',
    'Estrutura publica',
    'Outro',
  ];

  static const workStages = ['Inicio', 'Andamento', 'Conclusao'];
}

class Occurrence {
  const Occurrence({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.status,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.category,
    this.stage,
    this.city,
    this.state,
  });

  final String id;
  final String userId;
  final OccurrenceType type;
  final String? category;
  final String? stage;
  final String description;
  final String status;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final DateTime createdAt;

  LatLng get point => LatLng(latitude, longitude);

  String get displayKind {
    if (type == OccurrenceType.publicWork) {
      return stage == null ? type.label : '${type.label} - $stage';
    }
    return category == null ? type.label : '${type.label} - $category';
  }

  factory Occurrence.fromMap(Map<String, dynamic> map) {
    return Occurrence(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: OccurrenceType.fromValue(map['type'] as String),
      category: map['category'] as String?,
      stage: map['stage'] as String?,
      description: map['description'] as String,
      status: map['status'] as String,
      photoUrl: map['photo_url'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      city: map['city'] as String?,
      state: map['state'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'type': type.value,
      'category': category,
      'stage': stage,
      'description': description,
      'status': status,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
    };
  }
}
