import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gps_tracker/map_page.dart';
import 'dart:io';
class TrackerPage extends StatefulWidget {
  final Future<List> quiz;
  TrackerPage({this.quiz});

  @override
  _TrackerPage createState() => new _TrackerPage();
}
class _TrackerPage extends State<TrackerPage> {
  TabController _tcontroller;
  GoogleMapController _controller;
  String _scanBarcode = 'Unknown';

  startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
        "#ff6666", "Cancel", true, ScanMode.BARCODE)
        .listen((barcode) => print(barcode));
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  deviceIcon(String os){
    switch(os){
      case 'android': return Icon(Icons.android_outlined);
      case 'ios': return Icon(Icons.phone_android);
      default:return Icon(Icons.group);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navi = Provider.of<NavigatorHistoryStore>(context,listen: false);
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar:AppBar(
              leading: Container(child:Text('ssss')),
              backgroundColor: Colors.deepOrange,
              bottom:new TabBar(
                tabs: [
                  Tab(text: 'Devices'),
                  Tab(text: 'Group'),
                ],
                controller: _tcontroller,
                labelColor: Colors.white,
                indicatorColor: Colors.white,
              ),
            ),
            body:new TabBarView(
                controller: _tcontroller,
                children: <Widget>[
                  Stack(
                      children: <Widget>[
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('devices')
                              .doc(navi.device.docid)
                              .collection('friends')
                              .snapshots(),
                          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                            if (!snapshot.hasData) return Text("Loading habits...");
                            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
                            if (snapshot.data == null) return new Text('Error: null');
                            return ListView.builder(
                                itemCount: snapshot.data.docs.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Colors.black38),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: const Icon(Icons.settings_remote_rounded,
                                            color: Colors.deepOrange),
                                        title: Text(snapshot.data.docs[0]['name']),
                                        onTap: () {
                                          FirebaseFirestore.instance.collection('devices').doc(snapshot.data.docs[0]['did']).collection('log').orderBy('date', descending: true).limit(1).get().then((docs) {
                                            if (docs.docs == null) return new Text('Error: null');
                                            GeoPoint pos = docs.docs[0]['location'];
                                            navi.gmap_controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15)));
                                          });
                                          navi.moveTo(0);
                                        },
                                      )
                                  );
                                }
                            );
                          },
                        ),

                        Positioned(
                            bottom: 60,
                            right:  5,
                            child:
                              FloatingActionButton(
                                child: Icon(Icons.qr_code_scanner),
                                heroTag: "update",
                                backgroundColor: Colors.deepOrange,
                                onPressed: ()async{
                                  await scanQR();
                                  FirebaseFirestore.instance.collection('devices').doc(_scanBarcode).get().then((device){
                                    FirebaseFirestore.instance.collection('devices').doc(navi.device.docid).collection('friends').add({
                                      'did': _scanBarcode,
                                      'name': device['name'],
                                    });
                                  });

                                },
                              )
                        )
                      ]
                  ),
                  Stack(
                      children: <Widget>[
                        StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('devices')
                                .doc(navi.device.docid)
                                .collection('affiliation')
                                .snapshots(),
                            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (!snapshot.hasData) return Text("Loading habits...");
                              return ListView(children: snapshot.data.docs.map((group) => StreamBuilder<QuerySnapshot>(//List group show
                                stream: FirebaseFirestore.instance.collection('groups')
                                    .where('gid', isEqualTo: group['gid'])
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return Text("Loading habits...");
                                  if (snapshot.data == null) return new Text('Error: null');
                                  return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Colors.black38),
                                        ),
                                      ),
                                      child: GestureDetector(
                                          onTap: () async{// if group tapped
                                            var result = await showDialog<int>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                      content: Container(
                                                          height: MediaQuery.of(context).size.height*0.8,
                                                          width: MediaQuery.of(context).size.width*0.8,
                                                          child:
                                                            Stack(children: [
                                                              Positioned(
                                                                  right: 0,
                                                                  bottom: 0,
                                                                  child: IconButton(
                                                                    icon: Icon(Icons.group_add,color: Colors.deepOrange),
                                                                    onPressed: ()async{
                                                                      await scanQR();
                                                                      FirebaseFirestore.instance.collection('groups').doc(group['docid']).collection('member').where('did',isEqualTo: _scanBarcode).get().then((isdevice){
                                                                        if(isdevice.docs.length==0){
                                                                          FirebaseFirestore.instance.collection('devices').where('did',isEqualTo: _scanBarcode).get().then((user){
                                                                            FirebaseFirestore.instance.collection('groups').doc(group['docid']).collection('member').add({
                                                                              'did': _scanBarcode,
                                                                              'name':user.docs[0]['name'],
                                                                              'os':user.docs[0]['os'],
                                                                              'docid':user.docs[0].id.toString(),
                                                                            });
                                                                            FirebaseFirestore.instance.collection('devices').doc(user.docs[0].id.toString()).collection('affiliation').add({
                                                                              'gid': group['gid'],
                                                                              'docid': group.id.toString(),
                                                                            });
                                                                          });
                                                                        }
                                                                        else{
                                                                          showDialog(
                                                                            context: context,
                                                                            builder: (_) {
                                                                              return AlertDialog(
                                                                                content: Text('He is allready joinded'),
                                                                                actions: <Widget>[
                                                                                  FlatButton(
                                                                                    child: Text("Close"),
                                                                                    onPressed: () => Navigator.pop(context),
                                                                                  ),
                                                                                ],
                                                                              );
                                                                            },
                                                                          );
                                                                        }
                                                                      });



                                                                    },
                                                                  )
                                                              ),
                                                              Column(children: [
                                                                Container(
                                                                  height: MediaQuery.of(context).size.height*0.8-100,
                                                                  child: StreamBuilder<QuerySnapshot>(
                                                                      stream: FirebaseFirestore.instance.collection('groups')
                                                                          .doc(snapshot.data.docs[0].id.toString())
                                                                          .collection('member')
                                                                          .snapshots(),
                                                                      builder: (context, snapshot) {
                                                                        if (!snapshot.hasData) return Text("Loading habits...");
                                                                        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
                                                                        if (snapshot.data.docs.length == 0) return new Text('Error: null');
                                                                        return ListView(children: snapshot.data.docs.map((mem)=>
                                                                            Container(
                                                                                decoration: BoxDecoration(
                                                                                  border: Border(
                                                                                    bottom: BorderSide(color: Colors.black38),
                                                                                  ),
                                                                                ),
                                                                                child: GestureDetector(
                                                                                    onTap:(){
                                                                                      Navigator.of(context).pop(0);
                                                                                      FirebaseFirestore.instance.collection('devices').where('did',isEqualTo: mem['did']).get().then((memdoc){
                                                                                        FirebaseFirestore.instance.collection('devices').doc(memdoc.docs[0].id.toString()).collection('log').orderBy('date').limit(1).get().then((docs) {
                                                                                          if (docs.docs == null) return new Text('Error: null');
                                                                                          setState(() {
                                                                                            markerUpdate(navi);
                                                                                          });
                                                                                          GeoPoint pos = docs.docs[0]['location'];
                                                                                          navi.gmap_controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15)));
                                                                                        });
                                                                                        navi.moveTo(0);
                                                                                      });

                                                                                    },
                                                                                    child: ListTile(
                                                                                      leading: deviceIcon(mem['os'].toString()),
                                                                                      title: Text(mem['name']),
                                                                                    )
                                                                                )
                                                                            )
                                                                        ).toList());
                                                                      }
                                                                  ),
                                                                ),
                                                                Positioned(
                                                                  bottom: 30,
                                                                  right: 0,
                                                                  child: Ink(
                                                                      decoration: const ShapeDecoration(
                                                                        color: Colors.deepOrange,
                                                                        shape: CircleBorder(),
                                                                      ),
                                                                      child:SizedBox(
                                                                        height: 100.0,
                                                                        width: 100.0,
                                                                        child: IconButton(
                                                                          icon: Icon(Icons.qr_code,size:70),
                                                                          color: Colors.white,
                                                                          onPressed: () async{
                                                                            await showDialog<int>(
                                                                              context: context,
                                                                              barrierDismissible: false,
                                                                              builder: (BuildContext context) {
                                                                                return AlertDialog(
                                                                                    content: Container(
                                                                                        height:MediaQuery.of(context).size.width,
                                                                                        child: FlatButton(
                                                                                          child: QrImage(
                                                                                            data: group['gid'],
                                                                                          ),
                                                                                          onPressed:  () => Navigator.of(context).pop(0),
                                                                                        )
                                                                                    ));
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                      )

                                                                  ),

                                                                )
                                                              ],)
                                                            ])

                                                      )
                                                  );
                                                });
                                          },

                                          onLongPress: () async {
                                            var result = await showDialog<int>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                    content: Container(

                                                        child:Column(children: <Widget>[
                                                          FlatButton(
                                                            child: QrImage(
                                                              size: 100,
                                                              data: snapshot.data.docs[0]['gid'],
                                                            ),
                                                            onPressed:  () => Navigator.of(context).pop(0),
                                                          ),
                                                          FlatButton(
                                                            child: Text("close"),
                                                            onPressed: () => Navigator.of(context).pop(0),
                                                          )
                                                        ])
                                                    ));
                                              },
                                            );
                                          },
                                          child: ListTile(
                                            leading: const Icon(Icons.group,
                                                color: Colors.deepOrange),
                                            title: Text(snapshot.data.docs[0]['name']),
                                          )
                                      )
                                  );
                                }

                              )).toList());
                            }
                        ),
                        Positioned(
                            bottom: 60,
                            right:  5,
                            child:
                            Column(children: [
                              FloatingActionButton(
                                child: Icon(Icons.add_circle_outlined),
                                heroTag: "update",
                                backgroundColor: Colors.deepOrange,
                                onPressed: ()async{
                                  var result = await showDialog<int>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        String title = '';
                                        var v4 = Uuid().v4().toUpperCase();
                                        return AlertDialog(
                                          content: Row(
                                            children: <Widget>[
                                              new Expanded(
                                                  child: new TextField(
                                                    autofocus: true,
                                                    decoration: new InputDecoration(
                                                        labelText: '', hintText: 'Group name'),
                                                    onChanged: (value) {
                                                      title = value;
                                                    },
                                                  )),
                                            ],
                                          ),
                                          actions: <Widget>[
                                            FlatButton(
                                              child: Text('Cancell'),
                                              onPressed: () => Navigator.of(context).pop(0),
                                            ),
                                            FlatButton(
                                                child: Text('OK'),
                                                onPressed: () {
                                                  FirebaseFirestore.instance.collection("groups").add({
                                                    'name': title,
                                                    'gid': v4,
                                                    'host': navi.user.uid,
                                                  });
                                                  FirebaseFirestore.instance.collection("devices").where('did',isEqualTo: navi.user.uid).get().then((usr) {
                                                    FirebaseFirestore.instance.collection('groups').where('gid',isEqualTo: v4).get().then((group){
                                                      FirebaseFirestore.instance.collection("groups").doc(group.docs[0].id.toString()).collection('member').add({
                                                        'did': navi.user.uid,
                                                        'docid': navi.device.docid,
                                                        'name': navi.device.name,
                                                        'os': Platform.operatingSystem,
                                                      });
                                                      FirebaseFirestore.instance.collection("devices").doc(usr.docs[0].id.toString()).collection('affiliation').add({
                                                        'gid': v4,
                                                        'docid': group.docs[0].id.toString()
                                                      });
                                                    });

                                                  });
                                                  Navigator.of(context).pop(0);
                                                }
                                            ),
                                          ],
                                        );
                                      }
                                  );
                                },
                              ),
                              FloatingActionButton(
                                child: Icon(Icons.qr_code_scanner),
                                heroTag: "update",
                                backgroundColor: Colors.deepOrange,
                                onPressed: ()async{
                                  await scanQR();
                                  FirebaseFirestore.instance.collection('groups').where('gid', isEqualTo: _scanBarcode).get().then((group) {
                                    if(group.docs == 0) return;
                                    FirebaseFirestore.instance.collection('devices').doc(navi.device.docid).collection('affiliation').add({
                                      'gid': _scanBarcode,
                                      'docid': _scanBarcode,
                                    });
                                  });
                                },
                              )
                            ])


                        )
                      ]
                  )

                ])
        )
    );
  }


}
/*
class _TrackerPage extends State<TrackerPage> {
  TabController _tcontroller;
  GoogleMapController _controller;
  // H. _MyHomePageStateのbuildメソッド
  @override
  Widget build(BuildContext context) {
    final navi = Provider.of<NavigatorHistoryStore>(context,listen: false);
    return DefaultTabController(
        length: 2,
        child: Scaffold(
      appBar:AppBar(
        bottom:new TabBar(
            tabs: [
              Tab(text: 'Devices'),
              Tab(text: 'Group'),
            ],
            controller: _tcontroller,
          ),
        ),
      body:new TabBarView(
          controller: _tcontroller,
          children: <Widget>[

        StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('widgets')
                .where('uid', isEqualTo:navi.user.uid)
                .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          if (snapshot.data == null) return new Text('Error: null');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting: return new Text('Loading...');
            default:
              List<DocumentSnapshot> widgets = snapshot.data.docs;
              return ListView.builder(
                itemCount: widgets.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black38),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.settings_remote_rounded,
                                            color: Colors.deepOrange),
                        title: Text(widgets[index]['name']),
                        subtitle: Text(widgets[index]['wid']),
                        onTap: () {
                          FirebaseFirestore.instance.collection('widgets').doc(widgets[index].id.toString()).collection('log').orderBy('date').limit(1).get().then((docs) {
                            GeoPoint pos = docs.docs[0]['location'];
                            navi.gmap_controller.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
                          });
                          navi.moveTo(0);
                        },
                      ));
                  },
              );
          }
        },
      ),

          Text("abc")
      ])
    )
    );
  }


}
*/
/*
class _TrackerPage extends State<TrackerPage> {
  // G. 状態の保持と更新
  var listItem = ["メルカリ","Yahoo","Amazon"];

  _TrackerPage(){
    print(getDocuments('users'));
  }

  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      listItem.add("楽天");
    });
  }

  // H. _MyHomePageStateのbuildメソッド
  @override
  Widget build(BuildContext context) {
    // K. ページはScaffoldで組む
    return Scaffold(
      // M. bodyでページの中身をレイアウト
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black38),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.dashboard),
                title: Text(listItem[index]),
                subtitle: Text('password'),
                onTap: () { /* react to the tile being tapped */ },
              ));
        }, itemCount: listItem.length,),
      // J. ボタン操作に応じて_counterを増やす
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

Future<String> getDocuments(String collection) async {
  QuerySnapshot res = await FirebaseFirestore.instance.collection(collection).get();
  print(res.toString());
  return res.toString();
}

 */