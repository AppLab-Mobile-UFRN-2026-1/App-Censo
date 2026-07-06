import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/occurrence.dart';

class OccurrenceService {
  static const _table = 'occurrences';
  static const _bucket = 'occurrence-photos';

  final _uuid = const Uuid();

  SupabaseClient get _client => Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Occurrence>> fetchOccurrences() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return _parseOccurrences(rows);
  }

  Future<List<Occurrence>> fetchOccurrencesPage({
    required int page,
    required int pageSize,
    OccurrenceType? type,
    String? search,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final cleanSearch = search?.trim();

    var query = _client.from(_table).select();

    if (type != null) {
      query = query.eq('type', type.value);
    }

    if (cleanSearch != null && cleanSearch.isNotEmpty) {
      final escapedSearch = _escapePostgrestPattern(cleanSearch);
      query = query.or(
        'description.ilike.%$escapedSearch%,city.ilike.%$escapedSearch%,state.ilike.%$escapedSearch%,category.ilike.%$escapedSearch%,stage.ilike.%$escapedSearch%',
      );
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return _parseOccurrences(rows);
  }

  List<Occurrence> _parseOccurrences(List<dynamic> rows) {
    return rows
        .map((row) => Occurrence.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  String _escapePostgrestPattern(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_')
        .replaceAll(',', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .trim();
  }

  Future<Occurrence> createOccurrence({
    required OccurrenceType type,
    required String description,
    required String status,
    required XFile photo,
    required double latitude,
    required double longitude,
    required String? city,
    required String? state,
    String? category,
    String? stage,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario nao autenticado.');
    }

    final photoUrl = await _uploadPhoto(user.id, photo);
    final payload = Occurrence(
      id: _uuid.v4(),
      userId: user.id,
      type: type,
      category: category,
      stage: stage,
      description: description,
      status: status,
      photoUrl: photoUrl,
      latitude: latitude,
      longitude: longitude,
      city: city,
      state: state,
      createdAt: DateTime.now(),
    ).toInsertMap();

    final rows = await _client.from(_table).insert(payload).select().single();
    return Occurrence.fromMap(Map<String, dynamic>.from(rows));
  }

  Future<Occurrence> updateOccurrence({
    required Occurrence occurrence,
    required OccurrenceType type,
    required String description,
    required String status,
    XFile? photo,
    String? category,
    String? stage,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario nao autenticado.');
    }

    var photoUrl = occurrence.photoUrl;
    if (photo != null) {
      photoUrl = await _uploadPhoto(user.id, photo);
    }

    final row = await _client
        .from(_table)
        .update({
          'type': type.value,
          'category': type == OccurrenceType.request ? category : null,
          'stage': type == OccurrenceType.publicWork ? stage : null,
          'description': description,
          'status': status,
          'photo_url': photoUrl,
        })
        .eq('id', occurrence.id)
        .eq('user_id', user.id)
        .select()
        .single();

    return Occurrence.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteOccurrence(Occurrence occurrence) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario nao autenticado.');
    }

    await _client
        .from(_table)
        .delete()
        .eq('id', occurrence.id)
        .eq('user_id', user.id);
  }

  Future<String> _uploadPhoto(String userId, XFile photo) async {
    final extension = photo.name.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty || extension.length > 5
        ? 'jpg'
        : extension;
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}-'
        '${_uuid.v4()}.$safeExtension';
    final bytes = await photo.readAsBytes();

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
