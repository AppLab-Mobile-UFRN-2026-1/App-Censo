import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class Locality {
  const Locality({this.city, this.state});

  final String? city;
  final String? state;

  String get label {
    if ((city == null || city!.isEmpty) && (state == null || state!.isEmpty)) {
      return 'Localidade nao identificada';
    }
    return [
      city,
      state,
    ].whereType<String>().where((v) => v.isNotEmpty).join(' - ');
  }
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Ative a localizacao do dispositivo para continuar.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Permissao de localizacao negada.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permissao de localizacao bloqueada. Altere nas configuracoes.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<Locality> reverseGeocode(Position position) async {
    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty) {
        return const Locality();
      }

      final place = places.first;
      return Locality(
        city: _firstNonEmpty([
          place.locality,
          place.subAdministrativeArea,
          place.subLocality,
        ]),
        state: _firstNonEmpty([place.administrativeArea]),
      );
    } catch (_) {
      return const Locality();
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
