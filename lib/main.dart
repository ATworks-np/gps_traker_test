import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

import 'package:gps_tracker/map_page.dart';
import 'package:gps_tracker/tracker_page.dart';
import 'package:gps_tracker/setting_page.dart';
import 'package:gps_tracker/signin.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'dart:async' show Future;

import 'schedule_notifications.dart';




void main() => runApp(MyApp());

class UserState extends ChangeNotifier{
  User user;
  String userdocid;
  void setUser(User currentUser){
    user = currentUser;
    notifyListeners();
  }
  void setUserDocId(String id){
    userdocid = id;
    notifyListeners();
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return Container(color: Colors.deepOrange);
        }
        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return App();
        }
        // Otherwise, show something whilst waiting for initialization to complete
        return Container(color: Colors.deepOrange);
      },
    );
  }
}


class App extends StatelessWidget {
  final NavigatorHistoryStore navi = NavigatorHistoryStore();
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NavigatorHistoryStore>(
        create: (context) => NavigatorHistoryStore(),
        child: MaterialApp(
          //デバックラベル非表示
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: LoginCheck(),
          initialRoute: "/",
          routes:<String, WidgetBuilder>{
            "/signin":(BuildContext context) => SigninPage(),
            "/home":(BuildContext context) => MainPage(),
          },
        )
    );
  }
}

class LoginCheck extends StatefulWidget{
  LoginCheck({Key key}) : super(key: key);
  @override
  _LoginCheckState createState() => _LoginCheckState();
}
class _LoginCheckState extends State<LoginCheck>{

  void checkUser() async{
    final currentUser = await FirebaseAuth.instance.currentUser;
    final navi = Provider.of<NavigatorHistoryStore>(context,listen: false);

    if(currentUser == null){
      Navigator.pushReplacementNamed(context,"/signin");
    }else{
      navi.setUser(currentUser);
      await FirebaseFirestore.instance.collection('devices').where('did',isEqualTo: navi.user.uid).get().then((user){
        navi.device.setDocid(user.docs[0].id);
        navi.device.setName(user.docs[0]['name']);
      });
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  @override
  void initState(){
    super.initState();
    checkUser();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(color: Colors.deepOrange)
      ),
    );
  }
}


class HomeApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    final navi = Provider.of<NavigatorHistoryStore>(context,listen: false);
    return CupertinoTabScaffold(
            controller: navi.controller,
            tabBar: CupertinoTabBar(
              activeColor: Colors.deepOrange,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.location_on_outlined),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_remote_rounded),
                  label: 'Devices',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Setting',
                ),
              ],
            ),
              tabBuilder: (BuildContext context, int index) => <Widget>[
                MapPage(),
                TrackerPage(),
                SettingPage()
              ][index]
    );
  }
}

class Device extends ChangeNotifier{
  String docid;
  String name;

  void setDocid(String id){
    docid = id;
    notifyListeners();
  }
  void setName(String na){
    name = na;
    notifyListeners();
  }
}

class NavigatorHistoryStore extends ChangeNotifier {
  NavigatorHistoryStore() {
    controller.addListener(push);
  }
  final CupertinoTabController controller = CupertinoTabController();
  GoogleMapController gmap_controller;

  int _prevIndex = 0;
  bool _onPop = false;
  List<int> histories = <int>[];
  bool get hasHistory => histories.isNotEmpty;

  Device device = new Device();

  List<Marker> markers = [];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void gmoveTo(double lat, double lng){
    gmap_controller.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  void moveTo(int index) {
    if (controller.index == index) {
      return;
    }
    controller.index = index;
  }

  void push() {
    if (_prevIndex == controller.index) {
      return;
    }
    if (_onPop) {
      _onPop = false;
    } else {
      histories.add(_prevIndex);
    }
    _prevIndex = controller.index;
    notifyListeners();
  }

  void pop() {
    _onPop = true;
    if (histories.isNotEmpty) {
      controller.index = histories.removeLast();
    }
  }

  User user;
  void setUser(User currentUser){
    user = currentUser;
    notifyListeners();
  }

  void addMarker(Marker marker){
    markers.add(marker);
    notifyListeners();
  }
  void clearMarkers(){
    markers = [];
    notifyListeners();
  }
}

