import 'package:app_censo/models/occurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Occurrence parses Supabase rows', () {
    final occurrence = Occurrence.fromMap({
      'id': '9b0a6a27-8437-46c2-bdb8-19d7d0386721',
      'user_id': '86f908cb-bef3-4cc9-bb04-a5f5ad3763c1',
      'type': 'public_work',
      'category': null,
      'stage': 'Andamento',
      'description': 'Obra de pavimentacao em acompanhamento.',
      'status': 'registered',
      'photo_url': 'https://example.com/photo.jpg',
      'latitude': -3.7319,
      'longitude': -38.5267,
      'city': 'Fortaleza',
      'state': 'CE',
      'created_at': '2026-06-28T00:00:00.000Z',
    });

    expect(occurrence.type, OccurrenceType.publicWork);
    expect(occurrence.stage, 'Andamento');
    expect(occurrence.city, 'Fortaleza');
    expect(occurrence.point.latitude, -3.7319);
  });
}
