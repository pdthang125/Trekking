import 'package:equatable/equatable.dart';
import '../entities/navigation_entities.dart';

// ─── States ──────────────────────────────────────────────────────────────────

abstract class NavigationState extends Equatable {
  const NavigationState();
  @override List<Object?> get props => [];
}

class NavigationInitial extends NavigationState { const NavigationInitial(); }

class NavigationLoading extends NavigationState { const NavigationLoading(); }

class NavigationTracking extends NavigationState {
  final GpsPoint currentPosition;
  final List<GpsPoint> trackPoints;
  final List<WaypointEntity> waypoints;
  final bool isTracking;

  const NavigationTracking({
    required this.currentPosition,
    required this.trackPoints,
    required this.waypoints,
    required this.isTracking,
  });

  @override
  List<Object?> get props => [currentPosition, trackPoints.length, isTracking];
}

class NavigationError extends NavigationState {
  final String message;
  const NavigationError({required this.message});
  @override List<Object?> get props => [message];
}

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();
  @override List<Object?> get props => [];
}

class StartTrackingEvent extends NavigationEvent { const StartTrackingEvent(); }
class StopTrackingEvent extends NavigationEvent { const StopTrackingEvent(); }
class AddWaypointEvent extends NavigationEvent {
  final String name;
  final GpsPoint position;
  const AddWaypointEvent({required this.name, required this.position});
  @override List<Object?> get props => [name, position];
}
class RemoveWaypointEvent extends NavigationEvent {
  final String waypointId;
  const RemoveWaypointEvent({required this.waypointId});
  @override List<Object?> get props => [waypointId];
}
class LocationUpdatedEvent extends NavigationEvent {
  final GpsPoint position;
  const LocationUpdatedEvent({required this.position});
  @override List<Object?> get props => [position];
}
