import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';
import 'dart:async';


//
// 全面表示のローディング
//
class OverlayLoadingMolecules extends StatelessWidget {
  OverlayLoadingMolecules({@required this.visible});

  //表示状態
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return visible
        ? Container(
      decoration: new BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, 0.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.white))
        ],
      ),
    )
        : Container();
  }
}

class Loading extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<Loading> {
  var _value = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
            CircularProgressIndicator(),
    );
  }
}

class SettingPage extends StatelessWidget {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    final navi = Provider.of<NavigatorHistoryStore>(context,listen: false);
    List<String> dataname = ['User name', 'E-mail','User id','Logout'];
    List<String> datakey = ['name', 'email','did','login'];

    return Scaffold(
      body: FutureBuilder(
        future:  FirebaseFirestore.instance.collection('devices').doc(navi.device.docid).get(),
        builder: (context, snapshot){
          if(!snapshot.hasData)return Container(color: Colors.white);;
          if(snapshot == null)return Text('Error');
          return ListView.builder(
              itemCount: 4,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black38),
                      ),
                    ),
                    child: ListTile(
                      title: Text(dataname[index]),
                      subtitle: Text(snapshot.data[datakey[index]]),
                      onTap: ()async {
                        switch(datakey[index]){
                          case 'did':
                            await showDialog<int>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    content: Container(
                                        height: 300,
                                        width: 500,
                                        child:Column(children: <Widget>[
                                          FlatButton(
                                            child: QrImage(
                                              data: snapshot.data[datakey[index]],
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
                            break;
                          case 'login':
                            await FirebaseAuth.instance.signOut();
                            final currentUser = await FirebaseAuth.instance.currentUser;
                            navi.setUser(currentUser);
                            Navigator.of(context).pop(0);
                            Navigator.of(context).pushNamed('/signin');
                            break;
                          default: ;
                        }
                      },
                    )
                );
              }
          );
        },
      ),
    );
  }
}