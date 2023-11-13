import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  CameraPosition? myLocation;

  Set<Marker> markers = {};
  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 80.440717697143555,
      zoom: 19.151926040649414);

  int index = 0;

  @override
  Widget build(BuildContext context) {
    getUserLocation();
    return Scaffold(
      body: myLocation == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.hybrid,
              markers: markers,
              onTap: (argument) {
                index++;
                markers.add(Marker(
                    markerId: MarkerId("marker$index"), position: argument));
              },
              initialCameraPosition: myLocation!,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Location location = Location();

  PermissionStatus status = PermissionStatus.denied;

  LocationData? locationData;

  StreamSubscription<LocationData>? subscription;

  bool isServiceEnabled = false;

  Future<bool> checkPermission() async {
    status = await location.hasPermission();
    if (status == PermissionStatus.denied) {
      status = await location.requestPermission();
    }
    return (status == PermissionStatus.granted ||
        status == PermissionStatus.grantedLimited);
  }

  Future<bool> checkService() async {
    isServiceEnabled = await location.serviceEnabled();
    if (!isServiceEnabled) {
      isServiceEnabled = await location.requestService();
    }
    return isServiceEnabled;
  }

  getUserLocation() async {
    bool permission = await checkPermission();
    if (!permission) return;
    bool service = await checkService();
    if (!service) return;

    locationData = await location.getLocation();
    location.changeSettings(
      accuracy: LocationAccuracy.high,
    );
    subscription = location.onLocationChanged.listen((event) {
      locationData = event;
      markers.add(Marker(
        markerId: MarkerId("MyLocation"),
        position: LatLng(event.latitude!, event.longitude!),
      ));
      myLocation = CameraPosition(
        target: LatLng(event.latitude!, event.longitude!),
        zoom: 17,
      );
      setState(() {});
      print("lat : ${event?.latitude} , Long : ${locationData?.longitude}");
    });
  }

//AIzaSyCL0kbAwJi5_j-3NfDy1dajoH60FFLKucw
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    subscription?.cancel();
  }
}
