import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/navigation_entities.dart';
import '../../domain/usecases/navigation_usecases.dart';
import '../../domain/usecases/trip_usecases.dart';
import 'navigation_bloc.dart';

@injectable
class NavigationBlocHandler extends Bloc<NavigationEvent, NavigationState> {
  final StartTrackingUseCase startTrackingUseCase;
  final StopTrackingUseCase stopTrackingUseCase;
  final GetCurrentPositionUseCase getCurrentPositionUseCase;
  final AddWaypointUseCase addWaypointUseCase;
  final GetTrackPointsUseCase getTrackPointsUseCase;
  final CreateTripUseCase createTripUseCase;
  final GetActiveTripUseCase getActiveTripUseCase;
  final EndTripUseCase endTripUseCase;

  StreamSubscription? _trackingSubscription;
  String? _activeTripId;

  NavigationBlocHandler({
    required this.startTrackingUseCase,
    required this.stopTrackingUseCase,
    required this.getCurrentPositionUseCase,
    required this.addWaypointUseCase,
    required this.getTrackPointsUseCase,
    required this.createTripUseCase,
    required this.getActiveTripUseCase,
    required this.endTripUseCase,
  }) : super(const NavigationInitial()) {
    on<StartTrackingEvent>(_onStartTracking);
    on<StopTrackingEvent>(_onStopTracking);
    on<AddWaypointEvent>(_onAddWaypoint);
    on<RemoveWaypointEvent>(_onRemoveWaypoint);
    on<LocationUpdatedEvent>(_onLocationUpdated);
  }

  Future<void> _onStartTracking(
    StartTrackingEvent event,
    Emitter<NavigationState> emit,
  ) async {
    emit(const NavigationLoading());

    // 1. Kiểm tra hoặc tạo active trip
    final tripResult = await getActiveTripUseCase(NoParams());
    tripResult.fold(
      (failure) => null,
      (trip) async {
        if (trip != null) {
          _activeTripId = trip.id;
        } else {
          final newTrip = await createTripUseCase(
            CreateTripParams(
              name: 'Chuyến đi ${DateTime.now().day}/${DateTime.now().month}',
            ),
          );
          newTrip.fold(
            (f) => null,
            (t) => _activeTripId = t.id,
          );
        }
      },
    );

    // 2. Lấy vị trí ban đầu
    final initialPos = await getCurrentPositionUseCase(NoParams());
    GpsPoint? currentPoint;
    initialPos.fold(
      (f) => null,
      (pos) => currentPoint = pos,
    );

    final defaultPoint = currentPoint ??
        GpsPoint(
          latitude: 16.1189,
          longitude: 108.2782,
          altitude: 621,
          recordedAt: DateTime.now(),
        );

    emit(NavigationTracking(
      currentPosition: defaultPoint,
      trackPoints: [defaultPoint],
      waypoints: const [],
      isTracking: true,
    ));

    // 3. Bắt đầu lắng nghe GPS stream
    await _trackingSubscription?.cancel();
    _trackingSubscription = startTrackingUseCase().listen(
      (result) {
        result.fold(
          (failure) => add(LocationUpdatedEvent(position: defaultPoint)),
          (point) => add(LocationUpdatedEvent(position: point)),
        );
      },
    );
  }

  Future<void> _onStopTracking(
    StopTrackingEvent event,
    Emitter<NavigationState> emit,
  ) async {
    await _trackingSubscription?.cancel();
    _trackingSubscription = null;
    await stopTrackingUseCase();

    if (_activeTripId != null) {
      await endTripUseCase(_activeTripId!);
      _activeTripId = null;
    }

    if (state is NavigationTracking) {
      final current = state as NavigationTracking;
      emit(NavigationTracking(
        currentPosition: current.currentPosition,
        trackPoints: current.trackPoints,
        waypoints: current.waypoints,
        isTracking: false,
      ));
    }
  }

  Future<void> _onAddWaypoint(
    AddWaypointEvent event,
    Emitter<NavigationState> emit,
  ) async {
    if (state is! NavigationTracking) return;
    final current = state as NavigationTracking;

    if (_activeTripId == null) return;

    final result = await addWaypointUseCase(AddWaypointParams(
      tripId: _activeTripId!,
      name: event.name,
      position: event.position,
    ));

    result.fold(
      (failure) => emit(NavigationError(message: failure.message)),
      (waypoint) {
        emit(NavigationTracking(
          currentPosition: current.currentPosition,
          trackPoints: current.trackPoints,
          waypoints: [...current.waypoints, waypoint],
          isTracking: current.isTracking,
        ));
      },
    );
  }

  Future<void> _onRemoveWaypoint(
    RemoveWaypointEvent event,
    Emitter<NavigationState> emit,
  ) async {
    if (state is! NavigationTracking) return;
    final current = state as NavigationTracking;

    emit(NavigationTracking(
      currentPosition: current.currentPosition,
      trackPoints: current.trackPoints,
      waypoints: current.waypoints.where((w) => w.id != event.waypointId).toList(),
      isTracking: current.isTracking,
    ));
  }

  void _onLocationUpdated(
    LocationUpdatedEvent event,
    Emitter<NavigationState> emit,
  ) {
    if (state is! NavigationTracking) return;
    final current = state as NavigationTracking;

    emit(NavigationTracking(
      currentPosition: event.position,
      trackPoints: [...current.trackPoints, event.position],
      waypoints: current.waypoints,
      isTracking: current.isTracking,
    ));
  }

  @override
  Future<void> close() {
    _trackingSubscription?.cancel();
    return super.close();
  }
}

