import 'package:shared_preferences/shared_preferences.dart';

import '../models/occurrence.dart';

class PreferencesService {
  static const _lastTypeKey = 'last_occurrence_type';

  Future<OccurrenceType> getLastOccurrenceType() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastTypeKey);
    if (value == null) {
      return OccurrenceType.request;
    }
    return OccurrenceType.fromValue(value);
  }

  Future<void> setLastOccurrenceType(OccurrenceType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTypeKey, type.value);
  }
}
