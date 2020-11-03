import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gps_tracker/main.dart';
class MapPage extends StatefulWidget{
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Marker> a = [];
  Geoflutterfire geo = Geoflutterfire();

  @override
  Widget build(BuildContext context) {
    final navi = Provider.of<NavigatorHistoryStore>(context,listen: false);
    final CameraPosition _initPosition = CameraPosition(
        target: LatLng(35.6809591,139.7673068),
        zoom: 15
    );

    return new Scaffold(
        body: new Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                bottom: 50.0,
                right: 0,
                left: 0,
                child:
                GoogleMap(
                  initialCameraPosition: _initPosition,
                  onMapCreated: (GoogleMapController controller){
                    navi.gmap_controller = controller;
                    setState(() {
                      markerUpdate(navi);
                    });
                    moveToMe(navi.gmap_controller);
                  },
                  markers: Set.from(navi.markers),
                ),
              ),
              Positioned(
                  bottom: 150.0,
                  right: 5.0,
                  child:
                  Column(
                    children: <Widget>[
                      FloatingActionButton(
                          onPressed: ()async{
                            setState(() {
                              markerUpdate(navi);
                            });
                          },
                          backgroundColor: Colors.deepOrange,
                          child: Icon(Icons.sync),
                          heroTag: "update_tracker",
                      ),
                      FloatingActionButton(
                        child: Icon(Icons.adjust),
                        heroTag: "update",
                        backgroundColor: Colors.deepOrange,
                        onPressed: (){
                          moveToMe(navi.gmap_controller);
                        },

                      )
                    ],
                  )

              ),

            ]
        )
    );
  }

}

void markerUpdate(NavigatorHistoryStore navi){
  FirebaseFirestore.instance.collection('devices').doc(navi.device.docid).collection('affiliation').get().then((groups){
    if(groups.docs.isNotEmpty){
      navi.clearMarkers();
      for(var group in groups.docs){
        FirebaseFirestore.instance.collection('groups').doc(group['docid']).collection('member').get().then((mems) {
          if(mems.docs.isNotEmpty){
            for(var mem in mems.docs){
              FirebaseFirestore.instance.collection('devices').doc(mem['docid']).collection('log').orderBy('date').get().then((friendLog) {
                if (friendLog.docs.isNotEmpty) {
                  GeoPoint pos = friendLog.docs[0]['location'];
                  navi.addMarker(Marker(
                    markerId: MarkerId(mem['did']),
                    icon: BitmapDescriptor.defaultMarker,
                    position: LatLng(pos.latitude, pos.longitude),
                    infoWindow: InfoWindow(title: mem['name']),

                  ));
                }
              });
            }
          };
        });
      }
    }
  });
}

Future<bool> checkLocation() async {
  Location location = new Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;

  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return false;
    }
  }
  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      return false;
    }
  }
  return true;
}

Future<LocationData> getLocation() async {
  Location location = new Location();
  LocationData _locationData = await location.getLocation();
  return _locationData;
}
Future moveToMe(GoogleMapController _controller) async {
  LocationData _loc = await getLocation();
  _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(_loc.latitude, _loc.longitude), zoom: 15)));
}



void push(){
  final _mainReference = FirebaseDatabase.instance.reference().child("widgets");
  _mainReference.push().set(res().toJson());
}

class res{
  res();
  toJson() {
    return {
      'wid': 1,
      'uid': 1,
      'date':DateTime.now().millisecondsSinceEpoch,
      'lat':0,
      'lng':0
    };
  }
}
