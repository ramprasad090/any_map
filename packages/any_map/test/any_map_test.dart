import 'package:flutter_test/flutter_test.dart';
import 'package:any_map/any_map.dart';

void main() {
  group('AnyLatLng', () {
    test('equality', () {
      const a = AnyLatLng(37.7749, -122.4194);
      const b = AnyLatLng(37.7749, -122.4194);
      expect(a, equals(b));
    });

    test('distanceTo returns meters', () {
      const sf = AnyLatLng(37.7749, -122.4194);
      const la = AnyLatLng(34.0522, -118.2437);
      final distance = sf.distanceTo(la);
      // SF to LA is ~559 km
      expect(distance, greaterThan(500000));
      expect(distance, lessThan(600000));
    });

    test('fromJson / toJson roundtrip', () {
      const original = AnyLatLng(51.5074, -0.1278);
      final json = original.toJson();
      final restored = AnyLatLng.fromJson(json);
      expect(restored, equals(original));
    });
  });

  group('AnyLatLngBounds', () {
    test('fromPoints computes correct bounds', () {
      final bounds = AnyLatLngBounds.fromPoints(const [
        AnyLatLng(10, 20),
        AnyLatLng(30, 40),
        AnyLatLng(20, 30),
      ]);
      expect(bounds.southwest, equals(const AnyLatLng(10, 20)));
      expect(bounds.northeast, equals(const AnyLatLng(30, 40)));
    });

    test('contains returns true for points inside', () {
      const bounds = AnyLatLngBounds(
        southwest: AnyLatLng(10, 20),
        northeast: AnyLatLng(30, 40),
      );
      expect(bounds.contains(const AnyLatLng(20, 30)), isTrue);
      expect(bounds.contains(const AnyLatLng(5, 30)), isFalse);
    });
  });

  group('PolylineCodec', () {
    test('encode then decode roundtrip', () {
      const points = [
        AnyLatLng(38.5, -120.2),
        AnyLatLng(40.7, -120.95),
        AnyLatLng(43.252, -126.453),
      ];
      final encoded = PolylineCodec.encode(points);
      final decoded = PolylineCodec.decode(encoded);

      for (int i = 0; i < points.length; i++) {
        expect(decoded[i].latitude, closeTo(points[i].latitude, 0.00001));
        expect(decoded[i].longitude, closeTo(points[i].longitude, 0.00001));
      }
    });
  });

  group('AnyClusterEngine', () {
    test('clusters nearby markers', () {
      final engine = AnyClusterEngine(
        config: const ClusterConfig(radius: 160, maxZoom: 18),
      );
      final markers = List.generate(
        10,
        (i) => AnyMarker(
          id: 'marker_$i',
          position: AnyLatLng(37.7749 + i * 0.0001, -122.4194 + i * 0.0001),
        ),
      );
      engine.load(markers);

      const bounds = AnyLatLngBounds(
        southwest: AnyLatLng(37.0, -123.0),
        northeast: AnyLatLng(38.0, -122.0),
      );
      final clusters = engine.getClusters(bounds, zoom: 10);
      // At zoom 10 with tight markers, should cluster into fewer groups
      expect(clusters.length, lessThan(markers.length));
    });

    test('shows all markers at max zoom', () {
      final engine = AnyClusterEngine(
        config: const ClusterConfig(maxZoom: 18),
      );
      final markers = List.generate(
        5,
        (i) => AnyMarker(
          id: 'marker_$i',
          position: AnyLatLng(37.7749 + i * 0.0001, -122.4194 + i * 0.0001),
        ),
      );
      engine.load(markers);

      const bounds = AnyLatLngBounds(
        southwest: AnyLatLng(37.0, -123.0),
        northeast: AnyLatLng(38.0, -122.0),
      );
      final clusters = engine.getClusters(bounds, zoom: 19);
      expect(clusters.length, equals(markers.length));
    });
  });
}
