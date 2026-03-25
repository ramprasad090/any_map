import '../models/lat_lng.dart';

/// Decodes an encoded polyline string into a list of coordinates.
///
/// Supports both Google's Encoded Polyline Algorithm (precision 5)
/// and OSRM/Valhalla polyline6 (precision 6).
class PolylineCodec {
  const PolylineCodec._();

  /// Decode a polyline with precision 5 (Google / OSRM default).
  static List<AnyLatLng> decode(String encoded) =>
      _decode(encoded, precision: 5);

  /// Decode a polyline with precision 6 (Valhalla / OSRM polyline6).
  static List<AnyLatLng> decode6(String encoded) =>
      _decode(encoded, precision: 6);

  static List<AnyLatLng> _decode(String encoded, {required int precision}) {
    final List<AnyLatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;
    final factor = _pow10(precision);

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(AnyLatLng(lat / factor, lng / factor));
    }

    return points;
  }

  /// Encode a list of coordinates to a polyline string (precision 5).
  static String encode(List<AnyLatLng> points) =>
      _encode(points, precision: 5);

  static String _encode(List<AnyLatLng> points, {required int precision}) {
    final factor = _pow10(precision);
    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final point in points) {
      final lat = (point.latitude * factor).round();
      final lng = (point.longitude * factor).round();
      _encodeValue(lat - prevLat, buffer);
      _encodeValue(lng - prevLng, buffer);
      prevLat = lat;
      prevLng = lng;
    }

    return buffer.toString();
  }

  static void _encodeValue(int value, StringBuffer buffer) {
    int v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1F)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

  static int _pow10(int exp) {
    int result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}
