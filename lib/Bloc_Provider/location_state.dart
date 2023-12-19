part of 'location_cubit.dart';

@immutable
abstract class LocationState {
  LocationState();
}

class LocationInitial extends LocationState {
 LocationInitial();
}
class LocationLoading extends LocationState{
  LocationLoading();
}
class LocationLoaded extends LocationState{
  final Position currentPosition;
  LocationLoaded(this.currentPosition);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationLoaded &&
          runtimeType == other.runtimeType &&
          currentPosition == other.currentPosition;

  @override
  int get hashCode => currentPosition.hashCode;
}
class LocationError extends LocationState{
  final String message;
  LocationError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
