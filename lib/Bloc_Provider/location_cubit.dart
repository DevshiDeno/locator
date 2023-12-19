
import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:locator/presentation/Home.dart';
import 'package:meta/meta.dart';

part 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final MyHomePage myHomePage;

  LocationCubit(this.myHomePage) : super(LocationInitial());

  Future<void> _getLocation(position) async {
    try {
      emit(LocationLoading());
     // await myHomePage.getAddressFromLatLng(position);
      emit(LocationLoaded(
          LatLng(position.latitude, position.longitude) as Position));
    } catch (e) {
      emit(LocationError("Error getting location:$e"));
    }
  }
}
