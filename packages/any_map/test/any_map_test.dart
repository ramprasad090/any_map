import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:any_map/any_map.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // AnyLatLng
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyLatLng', () {
    test('equality', () {
      const a = AnyLatLng(37.7749, -122.4194);
      const b = AnyLatLng(37.7749, -122.4194);
      expect(a, equals(b));
    });

    test('distanceTo returns meters (SF→LA ~559 km)', () {
      const sf = AnyLatLng(37.7749, -122.4194);
      const la = AnyLatLng(34.0522, -118.2437);
      final distance = sf.distanceTo(la);
      expect(distance, greaterThan(500000));
      expect(distance, lessThan(600000));
    });

    test('distanceTo same point returns zero', () {
      const p = AnyLatLng(17.3850, 78.4867);
      expect(p.distanceTo(p), closeTo(0, 0.001));
    });

    test('fromJson / toJson roundtrip', () {
      const original = AnyLatLng(51.5074, -0.1278);
      final json = original.toJson();
      final restored = AnyLatLng.fromJson(json);
      expect(restored, equals(original));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyLatLngBounds
  // ────────────────────────────────────────────────────────────────────────────

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

    test('contains returns true for point inside', () {
      const bounds = AnyLatLngBounds(
        southwest: AnyLatLng(10, 20),
        northeast: AnyLatLng(30, 40),
      );
      expect(bounds.contains(const AnyLatLng(20, 30)), isTrue);
    });

    test('contains returns false for point outside', () {
      const bounds = AnyLatLngBounds(
        southwest: AnyLatLng(10, 20),
        northeast: AnyLatLng(30, 40),
      );
      expect(bounds.contains(const AnyLatLng(5, 30)), isFalse);
      expect(bounds.contains(const AnyLatLng(20, 50)), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PolylineCodec
  // ────────────────────────────────────────────────────────────────────────────

  group('PolylineCodec', () {
    test('encode then decode roundtrip preserves coordinates', () {
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

    test('decode known Google polyline string', () {
      // '_p~iF~ps|U_ulLnnqC_mqNvxq`@' encodes the standard example
      final decoded = PolylineCodec.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(decoded.length, 3);
      expect(decoded[0].latitude, closeTo(38.5, 0.001));
      expect(decoded[0].longitude, closeTo(-120.2, 0.001));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyClusterEngine
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyClusterEngine', () {
    test('clusters nearby markers at low zoom', () {
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
      expect(clusters.length, lessThan(markers.length));
    });

    test('shows all markers at max zoom', () {
      final engine = AnyClusterEngine(config: const ClusterConfig(maxZoom: 18));
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

  // ────────────────────────────────────────────────────────────────────────────
  // AnyMatrixCell
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyMatrixCell', () {
    test('durationText formats minutes', () {
      const cell = AnyMatrixCell(durationSeconds: 720); // 12 min
      expect(cell.durationText, '12 min');
    });

    test('durationText formats hours and minutes', () {
      const cell = AnyMatrixCell(durationSeconds: 5400); // 1h 30m
      expect(cell.durationText, '1h 30m');
    });

    test('durationText returns null when durationSeconds is null', () {
      const cell = AnyMatrixCell();
      expect(cell.durationText, isNull);
    });

    test('distanceText formats meters', () {
      const cell = AnyMatrixCell(distanceMeters: 500);
      expect(cell.distanceText, '500 m');
    });

    test('distanceText formats kilometers', () {
      const cell = AnyMatrixCell(distanceMeters: 9400);
      expect(cell.distanceText, '9.4 km');
    });

    test('distanceText returns null when distanceMeters is null', () {
      const cell = AnyMatrixCell();
      expect(cell.distanceText, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyDistanceMatrixResult
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyDistanceMatrixResult', () {
    test('failure factory sets isSuccess=false and stores error', () {
      final result = AnyDistanceMatrixResult.failure('test error');
      expect(result.isSuccess, isFalse);
      expect(result.error, 'test error');
      expect(result.matrix, isEmpty);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyOptimizedRoute
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyOptimizedRoute', () {
    test('failure factory sets isSuccess=false', () {
      final result = AnyOptimizedRoute.failure('no stops');
      expect(result.isSuccess, isFalse);
      expect(result.error, 'no stops');
    });

    test('distanceText formats correctly', () {
      const route = AnyOptimizedRoute(
        isSuccess: true,
        distanceMeters: 12500,
        durationSeconds: 900,
      );
      expect(route.distanceText, '12.5 km');
    });

    test('distanceText uses meters for < 1 km', () {
      const route = AnyOptimizedRoute(
        isSuccess: true,
        distanceMeters: 800,
        durationSeconds: 120,
      );
      expect(route.distanceText, '800 m');
    });

    test('durationText formats minutes', () {
      const route = AnyOptimizedRoute(
        isSuccess: true,
        distanceMeters: 0,
        durationSeconds: 1200, // 20 min
      );
      expect(route.durationText, '20 min');
    });

    test('durationText formats hours', () {
      const route = AnyOptimizedRoute(
        isSuccess: true,
        distanceMeters: 0,
        durationSeconds: 7200, // 2h 0m
      );
      expect(route.durationText, '2h 0m');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyMapMatchResult
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyMapMatchResult', () {
    test('failure factory sets isSuccess=false', () {
      final result = AnyMapMatchResult.failure('need 2 points');
      expect(result.isSuccess, isFalse);
      expect(result.error, 'need 2 points');
      expect(result.snappedPoints, isEmpty);
    });

    test('toPolyline uses provided id and width', () {
      const result = AnyMapMatchResult(
        isSuccess: true,
        snappedPoints: [
          AnyLatLng(17.0, 78.0),
          AnyLatLng(17.1, 78.1),
        ],
      );
      final poly = result.toPolyline(id: 'snap', width: 6.0);
      expect(poly.id, 'snap');
      expect(poly.width, 6.0);
      expect(poly.points.length, 2);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyRoute
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyRoute', () {
    const sampleBounds = AnyLatLngBounds(
      southwest: AnyLatLng(0, 0),
      northeast: AnyLatLng(1, 1),
    );

    test('distanceText formats km correctly', () {
      const route = AnyRoute(
        geometry: [],
        distanceMeters: 15200,
        durationSeconds: 900,
        bounds: sampleBounds,
      );
      expect(route.distanceText, '15.2 km');
    });

    test('distanceText formats meters for short routes', () {
      const route = AnyRoute(
        geometry: [],
        distanceMeters: 750,
        durationSeconds: 120,
        bounds: sampleBounds,
      );
      expect(route.distanceText, '750 m');
    });

    test('durationText formats minutes', () {
      const route = AnyRoute(
        geometry: [],
        distanceMeters: 0,
        durationSeconds: 1380, // 23 min
        bounds: sampleBounds,
      );
      expect(route.durationText, '23 min');
    });

    test('durationText formats hours and minutes', () {
      const route = AnyRoute(
        geometry: [],
        distanceMeters: 0,
        durationSeconds: 5400, // 1h 30m
        bounds: sampleBounds,
      );
      expect(route.durationText, '1h 30m');
    });

    test('hasTolls is false when no toll segments', () {
      const route = AnyRoute(
        geometry: [],
        distanceMeters: 0,
        durationSeconds: 0,
        bounds: sampleBounds,
        segments: [
          AnyRouteSegment(
            start: AnyLatLng(0, 0),
            end: AnyLatLng(1, 1),
            annotation: AnyRouteAnnotation(isToll: false),
          ),
        ],
      );
      expect(route.hasTolls, isFalse);
    });

    test('hasTolls is true when toll segment present', () {
      const route = AnyRoute(
        geometry: [],
        distanceMeters: 0,
        durationSeconds: 0,
        bounds: sampleBounds,
        segments: [
          AnyRouteSegment(
            start: AnyLatLng(0, 0),
            end: AnyLatLng(1, 1),
            annotation: AnyRouteAnnotation(isToll: true),
          ),
        ],
      );
      expect(route.hasTolls, isTrue);
    });

    test('hasBridges and hasTunnels work correctly', () {
      const route = AnyRoute(
        geometry: [],
        distanceMeters: 0,
        durationSeconds: 0,
        bounds: sampleBounds,
        segments: [
          AnyRouteSegment(
            start: AnyLatLng(0, 0),
            end: AnyLatLng(1, 1),
            annotation: AnyRouteAnnotation(isBridge: true, isTunnel: false),
          ),
        ],
      );
      expect(route.hasBridges, isTrue);
      expect(route.hasTunnels, isFalse);
    });

    test('toPolyline uses default id and returns all geometry points', () {
      const p1 = AnyLatLng(10.0, 20.0);
      const p2 = AnyLatLng(11.0, 21.0);
      const route = AnyRoute(
        geometry: [p1, p2],
        distanceMeters: 0,
        durationSeconds: 0,
        bounds: sampleBounds,
      );
      final poly = route.toPolyline();
      expect(poly.id, 'route');
      expect(poly.points, [p1, p2]);
    });

    test('toTrafficPolylines returns one polyline per segment', () {
      const route = AnyRoute(
        geometry: [],
        distanceMeters: 0,
        durationSeconds: 0,
        bounds: sampleBounds,
        segments: [
          AnyRouteSegment(
            start: AnyLatLng(0, 0),
            end: AnyLatLng(1, 1),
            congestion: AnyCongestionLevel.freeFlow,
          ),
          AnyRouteSegment(
            start: AnyLatLng(1, 1),
            end: AnyLatLng(2, 2),
            congestion: AnyCongestionLevel.congested,
          ),
        ],
      );
      final polys = route.toTrafficPolylines();
      expect(polys.length, 2);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnySpeedLimit
  // ────────────────────────────────────────────────────────────────────────────

  group('AnySpeedLimit', () {
    test('speedMph converts correctly', () {
      const limit = AnySpeedLimit(speedKmh: 100);
      expect(limit.speedMph, closeTo(62.14, 0.01));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyFuelConfig
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyFuelConfig', () {
    test('estimateFuelLiters: 100 km at 8 L/100km = 8 L', () {
      const config = AnyFuelConfig(consumptionPer100km: 8.0);
      expect(config.estimateFuelLiters(100000), closeTo(8.0, 0.001));
    });

    test('estimateFuelLiters: 50 km = 4 L', () {
      const config = AnyFuelConfig(consumptionPer100km: 8.0);
      expect(config.estimateFuelLiters(50000), closeTo(4.0, 0.001));
    });

    test('estimateCO2Grams: petrol default CO2 factor', () {
      const config = AnyFuelConfig(
        fuelType: AnyFuelType.petrol,
        consumptionPer100km: 8.0,
      );
      // 8 L * 2310 g/L = 18480 g for 100 km
      expect(config.estimateCO2Grams(100000), closeTo(18480, 1));
    });

    test('estimateCO2Grams: diesel uses higher factor (2640 g/L)', () {
      const config = AnyFuelConfig(
        fuelType: AnyFuelType.diesel,
        consumptionPer100km: 8.0,
      );
      expect(config.estimateCO2Grams(100000), closeTo(21120, 1));
    });

    test('default co2GramsPerLiter is 2310 for petrol', () {
      const config = AnyFuelConfig(fuelType: AnyFuelType.petrol);
      expect(config.co2GramsPerLiter, 2310.0);
    });

    test('default co2GramsPerLiter is 2640 for diesel', () {
      const config = AnyFuelConfig(fuelType: AnyFuelType.diesel);
      expect(config.co2GramsPerLiter, 2640.0);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyTripLogger
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyTripLogger', () {
    late AnyTripLogger logger;
    final base = DateTime(2024, 1, 1, 10, 0, 0);

    setUp(() => logger = AnyTripLogger());

    test('isRecording is false before start', () {
      expect(logger.isRecording, isFalse);
    });

    test('isRecording is true after start', () {
      logger.start();
      expect(logger.isRecording, isTrue);
      logger.stop();
    });

    test('isRecording is false after stop', () {
      logger.start();
      logger.stop();
      expect(logger.isRecording, isFalse);
    });

    test('addWaypoint before start is ignored', () {
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.0, 78.0),
        timestamp: base,
      ));
      final summary = logger.stop();
      expect(summary.distanceMeters, 0);
      expect(summary.waypoints, isEmpty);
    });

    test('distance accumulates across waypoints', () {
      logger.start();
      // Two points exactly 1 degree lat apart (~111 km)
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.0, 78.0),
        timestamp: base,
      ));
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(18.0, 78.0),
        timestamp: base.add(const Duration(minutes: 1)),
      ));
      final summary = logger.stop();
      expect(summary.distanceMeters, greaterThan(100000));
      expect(summary.distanceMeters, lessThan(120000));
    });

    test('maxSpeed is tracked correctly', () {
      logger.start();
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.0, 78.0),
        speed: 10.0,
        timestamp: base,
      ));
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.001, 78.0),
        speed: 25.0,
        timestamp: base.add(const Duration(seconds: 5)),
      ));
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.002, 78.0),
        speed: 15.0,
        timestamp: base.add(const Duration(seconds: 10)),
      ));
      final summary = logger.stop();
      expect(summary.maxSpeed, 25.0);
    });

    test('detects harsh braking (accel < -4 m/s²)', () {
      logger.start();
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.0, 78.0),
        speed: 30.0, // 30 m/s
        timestamp: base,
      ));
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.001, 78.0),
        speed: 10.0, // drops 20 m/s in 1s → -20 m/s²
        timestamp: base.add(const Duration(seconds: 1)),
      ));
      final summary = logger.stop();
      expect(summary.harshBrakingCount, greaterThan(0));
    });

    test('detects harsh acceleration (accel > 4 m/s²)', () {
      logger.start();
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.0, 78.0),
        speed: 0.0,
        timestamp: base,
      ));
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.001, 78.0),
        speed: 20.0, // +20 m/s in 1s → +20 m/s²
        timestamp: base.add(const Duration(seconds: 1)),
      ));
      final summary = logger.stop();
      expect(summary.harshAccelerationCount, greaterThan(0));
    });

    test('eco score reduces for harsh events', () {
      logger.start();
      // Trigger harsh braking multiple times
      for (int i = 0; i < 4; i++) {
        logger.addWaypoint(AnyTripWaypoint(
          position: AnyLatLng(17.0 + i * 0.001, 78.0),
          speed: 30.0,
          timestamp: base.add(Duration(seconds: i * 2)),
        ));
        logger.addWaypoint(AnyTripWaypoint(
          position: AnyLatLng(17.0 + i * 0.001 + 0.0005, 78.0),
          speed: 5.0,
          timestamp: base.add(Duration(seconds: i * 2 + 1)),
        ));
      }
      final summary = logger.stop();
      expect(summary.ecoScore, lessThan(100));
    });

    test('eco score is 100 for smooth driving', () {
      logger.start();
      // Smooth constant speed
      for (int i = 0; i < 5; i++) {
        logger.addWaypoint(AnyTripWaypoint(
          position: AnyLatLng(17.0 + i * 0.001, 78.0),
          speed: 14.0,
          timestamp: base.add(Duration(seconds: i * 5)),
        ));
      }
      final summary = logger.stop();
      expect(summary.ecoScore, 100);
    });

    test('fuelConsumedLiters is estimated when fuelConfig provided', () {
      final loggerWithFuel = AnyTripLogger(
        fuelConfig: const AnyFuelConfig(consumptionPer100km: 8.0),
      );
      loggerWithFuel.start();
      loggerWithFuel.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.0, 78.0),
        timestamp: base,
      ));
      loggerWithFuel.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(18.0, 78.0),
        timestamp: base.add(const Duration(minutes: 10)),
      ));
      final summary = loggerWithFuel.stop();
      expect(summary.fuelConsumedLiters, isNotNull);
      expect(summary.fuelConsumedLiters!, greaterThan(0));
    });

    test('fuelConsumedLiters is null when no fuelConfig', () {
      logger.start();
      logger.addWaypoint(AnyTripWaypoint(
        position: const AnyLatLng(17.0, 78.0),
        timestamp: base,
      ));
      final summary = logger.stop();
      expect(summary.fuelConsumedLiters, isNull);
    });

    test('durationText formats correctly', () {
      final t = DateTime(2024);
      final summary = AnyTripSummary(
        distanceMeters: 10000,
        durationSeconds: 1800, // 30 min
        averageSpeed: 5.5,
        maxSpeed: 20.0,
        startTime: t,
        endTime: t,
      );
      expect(summary.durationText, '30 min');
    });

    test('averageSpeedKmh converts m/s to km/h', () {
      final t = DateTime(2024);
      final summary = AnyTripSummary(
        distanceMeters: 0,
        durationSeconds: 0,
        averageSpeed: 10.0, // 10 m/s = 36 km/h
        maxSpeed: 10.0,
        startTime: t,
        endTime: t,
      );
      expect(summary.averageSpeedKmh, closeTo(36.0, 0.01));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyGeofence.contains
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyGeofence.contains', () {
    test('circular geofence: point inside returns true', () {
      const fence = AnyGeofence(
        id: 'f1',
        center: AnyLatLng(17.0, 78.0),
        radius: 500,
      );
      // Same center → 0 distance → inside
      expect(fence.contains(const AnyLatLng(17.0, 78.0)), isTrue);
    });

    test('circular geofence: point far away returns false', () {
      const fence = AnyGeofence(
        id: 'f1',
        center: AnyLatLng(17.0, 78.0),
        radius: 100,
      );
      expect(fence.contains(const AnyLatLng(18.0, 79.0)), isFalse);
    });

    test('polygon geofence: point inside returns true', () {
      const fence = AnyGeofence(
        id: 'poly',
        center: AnyLatLng(0, 0),
        polygon: [
          AnyLatLng(0, 0),
          AnyLatLng(0, 10),
          AnyLatLng(10, 10),
          AnyLatLng(10, 0),
        ],
      );
      expect(fence.contains(const AnyLatLng(5, 5)), isTrue);
    });

    test('polygon geofence: point outside returns false', () {
      const fence = AnyGeofence(
        id: 'poly',
        center: AnyLatLng(0, 0),
        polygon: [
          AnyLatLng(0, 0),
          AnyLatLng(0, 10),
          AnyLatLng(10, 10),
          AnyLatLng(10, 0),
        ],
      );
      expect(fence.contains(const AnyLatLng(15, 15)), isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyGeofenceEngine
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyGeofenceEngine', () {
    late AnyGeofenceEngine engine;

    setUp(() => engine = AnyGeofenceEngine());
    tearDown(() => engine.dispose());

    test('fires enter event when entering geofence', () async {
      const fence = AnyGeofence(
        id: 'zone1',
        center: AnyLatLng(17.0, 78.0),
        radius: 500,
      );
      engine.addGeofence(fence);

      final events = <AnyGeofenceTrigger>[];
      final sub = engine.events.listen(events.add);

      engine.updateLocation(const AnyLatLng(18.0, 79.0)); // outside
      engine.updateLocation(const AnyLatLng(17.0, 78.0)); // inside → enter

      await Future.delayed(Duration.zero);
      expect(events.length, 1);
      expect(events.first.event, AnyGeofenceEvent.enter);
      expect(events.first.geofence.id, 'zone1');
      await sub.cancel();
    });

    test('fires exit event when leaving geofence', () async {
      const fence = AnyGeofence(
        id: 'zone2',
        center: AnyLatLng(17.0, 78.0),
        radius: 500,
      );
      engine.addGeofence(fence);

      final events = <AnyGeofenceTrigger>[];
      final sub = engine.events.listen(events.add);

      engine.updateLocation(const AnyLatLng(17.0, 78.0)); // enter
      engine.updateLocation(const AnyLatLng(20.0, 80.0)); // exit

      await Future.delayed(Duration.zero);
      expect(events.length, 2);
      expect(events[0].event, AnyGeofenceEvent.enter);
      expect(events[1].event, AnyGeofenceEvent.exit);
      await sub.cancel();
    });

    test('dwell event fires after dwellTime', () async {
      const fence = AnyGeofence(
        id: 'zone3',
        center: AnyLatLng(17.0, 78.0),
        radius: 500,
        dwellTime: Duration(milliseconds: 10),
      );
      engine.addGeofence(fence);

      final events = <AnyGeofenceTrigger>[];
      final sub = engine.events.listen(events.add);

      engine.updateLocation(const AnyLatLng(17.0, 78.0)); // enter

      // Wait longer than dwellTime then update again
      await Future.delayed(const Duration(milliseconds: 20));
      engine.updateLocation(const AnyLatLng(17.0, 78.0)); // dwell check

      await Future.delayed(Duration.zero);
      final types = events.map((e) => e.event).toList();
      expect(types, contains(AnyGeofenceEvent.dwell));
      await sub.cancel();
    });

    test('removeGeofence stops future events', () async {
      const fence = AnyGeofence(
        id: 'zone4',
        center: AnyLatLng(17.0, 78.0),
        radius: 500,
      );
      engine.addGeofence(fence);
      engine.removeGeofence('zone4');

      final events = <AnyGeofenceTrigger>[];
      final sub = engine.events.listen(events.add);

      engine.updateLocation(const AnyLatLng(17.0, 78.0));

      await Future.delayed(Duration.zero);
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('clearGeofences removes all fences', () async {
      for (int i = 0; i < 3; i++) {
        engine.addGeofence(AnyGeofence(
          id: 'fence_$i',
          center: AnyLatLng(17.0 + i, 78.0),
          radius: 500,
        ));
      }
      engine.clearGeofences();

      final events = <AnyGeofenceTrigger>[];
      final sub = engine.events.listen(events.add);

      engine.updateLocation(const AnyLatLng(17.0, 78.0));
      engine.updateLocation(const AnyLatLng(18.0, 78.0));
      engine.updateLocation(const AnyLatLng(19.0, 78.0));

      await Future.delayed(Duration.zero);
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('no duplicate enter events on repeated updates inside', () async {
      const fence = AnyGeofence(
        id: 'zone5',
        center: AnyLatLng(17.0, 78.0),
        radius: 500,
      );
      engine.addGeofence(fence);

      final events = <AnyGeofenceTrigger>[];
      final sub = engine.events.listen(events.add);

      engine.updateLocation(const AnyLatLng(17.0, 78.0)); // enter
      engine.updateLocation(const AnyLatLng(17.0001, 78.0001)); // still inside
      engine.updateLocation(const AnyLatLng(17.0002, 78.0002)); // still inside

      await Future.delayed(Duration.zero);
      final enterEvents =
          events.where((e) => e.event == AnyGeofenceEvent.enter).toList();
      expect(enterEvents.length, 1);
      await sub.cancel();
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyCachingTileProvider
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyCachingTileProvider', () {
    test('fetches from network on cache miss', () async {
      int fetchCount = 0;
      final provider = AnyCachingTileProvider(
        fetcher: (url) async {
          fetchCount++;
          return [1, 2, 3];
        },
      );

      final bytes = await provider.fetch('http://tile/1');
      expect(bytes, [1, 2, 3]);
      expect(fetchCount, 1);
      expect(provider.stats.misses, 1);
      expect(provider.stats.hits, 0);
    });

    test('serves from memory cache on second fetch', () async {
      int fetchCount = 0;
      final provider = AnyCachingTileProvider(
        fetcher: (url) async {
          fetchCount++;
          return [4, 5, 6];
        },
      );

      await provider.fetch('http://tile/2');
      await provider.fetch('http://tile/2');

      expect(fetchCount, 1);
      expect(provider.stats.hits, 1);
      expect(provider.stats.misses, 1);
    });

    test('different URLs are cached separately', () async {
      int fetchCount = 0;
      final provider = AnyCachingTileProvider(
        fetcher: (url) async {
          fetchCount++;
          return [fetchCount];
        },
      );

      final a = await provider.fetch('http://tile/a');
      final b = await provider.fetch('http://tile/b');

      expect(fetchCount, 2);
      expect(a, [1]);
      expect(b, [2]);
    });

    test('evicts LRU entry when maxMemoryEntries reached', () async {
      int fetchCount = 0;
      final provider = AnyCachingTileProvider(
        fetcher: (url) async {
          fetchCount++;
          return [fetchCount];
        },
        maxMemoryEntries: 2,
      );

      await provider.fetch('http://tile/x');
      await provider.fetch('http://tile/y');
      // This should evict 'x' (LRU)
      await provider.fetch('http://tile/z');

      expect(provider.stats.memoryEntries, 2);
      // Fetching 'x' again should cause another network request
      final preMiss = provider.stats.misses;
      await provider.fetch('http://tile/x');
      expect(provider.stats.misses, preMiss + 1);
    });

    test('evict removes specific url from memory', () async {
      final provider = AnyCachingTileProvider(
        fetcher: (url) async => [1],
      );
      await provider.fetch('http://tile/evict');
      expect(provider.stats.memoryEntries, 1);

      await provider.evict('http://tile/evict');
      expect(provider.stats.memoryEntries, 0);
    });

    test('clearMemory empties in-memory cache', () async {
      final provider = AnyCachingTileProvider(
        fetcher: (url) async => [1],
      );
      await provider.fetch('http://tile/clear1');
      await provider.fetch('http://tile/clear2');

      provider.clearMemory();
      expect(provider.stats.memoryEntries, 0);
    });

    test('resetStats zeroes hit/miss counters', () async {
      final provider = AnyCachingTileProvider(
        fetcher: (url) async => [1],
      );
      await provider.fetch('http://tile/stat');
      await provider.fetch('http://tile/stat');

      provider.resetStats();
      expect(provider.stats.hits, 0);
      expect(provider.stats.misses, 0);
    });

    test('uses persistent store on cache miss', () async {
      final store = _FakeTileStore();
      store.data['http://tile/persist'] = [7, 8, 9];

      int networkFetches = 0;
      final provider = AnyCachingTileProvider(
        fetcher: (url) async {
          networkFetches++;
          return [];
        },
        persistentStore: store,
      );

      final bytes = await provider.fetch('http://tile/persist');
      expect(bytes, [7, 8, 9]);
      expect(networkFetches, 0);
      expect(provider.stats.hits, 1);
    });

    test('writes fetched bytes to persistent store', () async {
      final store = _FakeTileStore();
      final provider = AnyCachingTileProvider(
        fetcher: (url) async => [10, 11],
        persistentStore: store,
      );

      await provider.fetch('http://tile/write');
      expect(store.data['http://tile/write'], [10, 11]);
    });

    test('TTL expiry: stale entry triggers re-fetch', () async {
      int fetchCount = 0;
      final provider = AnyCachingTileProvider(
        fetcher: (url) async {
          fetchCount++;
          return [fetchCount];
        },
        maxAge: const Duration(milliseconds: 10),
      );

      await provider.fetch('http://tile/ttl');
      expect(fetchCount, 1);

      await Future.delayed(const Duration(milliseconds: 20));
      await provider.fetch('http://tile/ttl');
      expect(fetchCount, 2);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyGeoJsonLayer.fromString + parse methods
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyGeoJsonLayer', () {
    const pointGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "p1",
      "geometry": {"type": "Point", "coordinates": [78.4867, 17.3850]},
      "properties": {"name": "Hyderabad"}
    }
  ]
}
''';

    const lineGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "l1",
      "geometry": {
        "type": "LineString",
        "coordinates": [[78.0, 17.0], [79.0, 18.0], [80.0, 19.0]]
      },
      "properties": {}
    }
  ]
}
''';

    const polygonGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "poly1",
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [[78.0, 17.0], [79.0, 17.0], [79.0, 18.0], [78.0, 18.0], [78.0, 17.0]]
        ]
      },
      "properties": {}
    }
  ]
}
''';

    const mixedGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {"type": "Point", "coordinates": [78.0, 17.0]},
      "properties": {}
    },
    {
      "type": "Feature",
      "geometry": {"type": "LineString", "coordinates": [[78.0, 17.0], [79.0, 18.0]]},
      "properties": {}
    }
  ]
}
''';

    test('fromString creates layer with correct id', () {
      final layer = AnyGeoJsonLayer.fromString(id: 'test', geoJson: pointGeoJson);
      expect(layer.id, 'test');
      expect(layer.geoJson, pointGeoJson);
    });

    test('parseFeatures returns one feature from FeatureCollection', () {
      final layer = AnyGeoJsonLayer.fromString(id: 'l', geoJson: pointGeoJson);
      final features = layer.parseFeatures();
      expect(features.length, 1);
      expect(features.first.id, 'p1');
      expect(features.first.geometryType, 'Point');
    });

    test('parseFeatures handles single Feature (not FeatureCollection)', () {
      const singleFeature = '''
{
  "type": "Feature",
  "geometry": {"type": "Point", "coordinates": [78.0, 17.0]},
  "properties": {"name": "test"}
}
''';
      final layer =
          AnyGeoJsonLayer.fromString(id: 'sf', geoJson: singleFeature);
      final features = layer.parseFeatures();
      expect(features.length, 1);
      expect(features.first.geometryType, 'Point');
    });

    test('toMarkers extracts Point features as AnyMarker', () {
      final layer = AnyGeoJsonLayer.fromString(id: 'pts', geoJson: pointGeoJson);
      final markers = layer.toMarkers();
      expect(markers.length, 1);
      expect(markers.first.id, 'p1');
      expect(markers.first.position.latitude, closeTo(17.3850, 0.0001));
      expect(markers.first.position.longitude, closeTo(78.4867, 0.0001));
      expect(markers.first.title, 'Hyderabad');
    });

    test('toPolylines extracts LineString features', () {
      final layer = AnyGeoJsonLayer.fromString(id: 'lines', geoJson: lineGeoJson);
      final polylines = layer.toPolylines();
      expect(polylines.length, 1);
      expect(polylines.first.id, 'l1');
      expect(polylines.first.points.length, 3);
      expect(polylines.first.points.first.latitude, closeTo(17.0, 0.0001));
    });

    test('toPolygons extracts Polygon features', () {
      final layer =
          AnyGeoJsonLayer.fromString(id: 'polys', geoJson: polygonGeoJson);
      final polygons = layer.toPolygons();
      expect(polygons.length, 1);
      expect(polygons.first.id, 'poly1');
      expect(polygons.first.points.length, 5);
    });

    test('toMarkers returns only Point features (ignores others)', () {
      final layer =
          AnyGeoJsonLayer.fromString(id: 'mixed', geoJson: mixedGeoJson);
      final markers = layer.toMarkers();
      expect(markers.length, 1);
    });

    test('toPolylines returns only LineString features (ignores others)', () {
      final layer =
          AnyGeoJsonLayer.fromString(id: 'mixed2', geoJson: mixedGeoJson);
      final polylines = layer.toPolylines();
      expect(polylines.length, 1);
    });

    test('custom styling is preserved', () {
      const customColor = Color(0xFFFF0000);
      final layer = AnyGeoJsonLayer.fromString(
        id: 'styled',
        geoJson: lineGeoJson,
        lineColor: customColor,
        lineWidth: 8.0,
      );
      expect(layer.lineColor, customColor);
      expect(layer.lineWidth, 8.0);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // AnyCacheStats toString
  // ────────────────────────────────────────────────────────────────────────────

  group('AnyCacheStats', () {
    test('toString includes all fields', () {
      const stats = AnyCacheStats(
        memoryEntries: 5,
        memoryBytes: 1024,
        hits: 10,
        misses: 3,
      );
      final str = stats.toString();
      expect(str, contains('entries=5'));
      expect(str, contains('bytes=1024'));
      expect(str, contains('hits=10'));
      expect(str, contains('misses=3'));
    });
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Fake in-memory [AnyTileStore] for testing [AnyCachingTileProvider].
class _FakeTileStore implements AnyTileStore {
  final data = <String, List<int>>{};

  @override
  Future<List<int>?> get(String key) async => data[key];

  @override
  Future<void> put(String key, List<int> bytes) async => data[key] = bytes;

  @override
  Future<void> evict(String key) async => data.remove(key);

  @override
  Future<void> clear() async => data.clear();
}
