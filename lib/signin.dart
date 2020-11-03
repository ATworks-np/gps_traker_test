import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:gps_tracker/main.dart';


class SigninPage extends StatefulWidget {
  @override
  _SigninPageState createState() => _SigninPageState();
}


class _SigninPageState extends State<SigninPage>{
  String _text = '';
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<User> signInAnon() async {
    UserCredential user = await firebaseAuth.signInAnonymously();
    final currentUser = await FirebaseAuth.instance.currentUser;
    return currentUser;
  }

  void _handleText(String e) {
    setState(() {
      _text = e;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navi = Provider.of<NavigatorHistoryStore>(context,listen: false);

    return Scaffold(
      //backgroundColor: Colors.deepOrange,
      body: Center(
        child: Container(
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              new TextField(
                enabled: true,
                style: TextStyle(fontSize: 40, color: Colors.deepOrange),
                obscureText: false,
                textAlign: TextAlign.center,
                maxLines:1 ,
                onChanged: _handleText,
                decoration: const InputDecoration(
                  hintText: 'Your name',
                ),
              ),
              RaisedButton(
                  child: Text("Next"),
                  color: Colors.deepOrange,
                  textColor: Colors.white,
                  onPressed: ()async{
                    if(_text.length==0){
                      await showDialog<int>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          String title = '';
                          return AlertDialog(
                            content: Text('Your name is needed!'),
                            actions: <Widget>[
                              FlatButton(
                                child: Text('Close'),
                                onPressed: () => Navigator.of(context).pop(0),
                              ),
                            ]
                          );
                        }
                      );
                    }else {
                      signInAnon().then((User currentUser) async {
                        FirebaseFirestore.instance.collection("devices").doc(
                            currentUser.uid).set({
                          "name": _text,
                          "os": Platform.operatingSystem,
                          "date": DateTime.now(),
                          "login": '',
                          "email": '',
                          "did": currentUser.uid,
                        });
                        navi.setUser(currentUser);
                        await FirebaseFirestore.instance.collection('devices')
                            .doc(currentUser.uid).get()
                            .then((user) {
                          navi.device.setDocid(user.id);
                          navi.device.setName(user['name']);
                        });
                      });
                      Navigator.of(context).pushNamed("/home");
                    }
                  },
              )
            ],)


        ),

            // RaisedButton(
            //   child: Text("Guest sign in"),
            //   color: Colors.orange,
            //   textColor: Colors.white,
            //   onPressed: () async {
            //     // ダイアログを表示------------------------------------
            //     var result = await showDialog<int>(
            //       context: context,
            //       barrierDismissible: false,
            //       builder: (BuildContext context) {
            //         String title = '';
            //         return AlertDialog(
            //           content: Row(
            //             children: <Widget>[
            //               new Expanded(
            //                   child: new TextField(
            //                     autofocus: true,
            //                     decoration: new InputDecoration(
            //                         labelText: '', hintText: 'Your name'),
            //                     onChanged: (value) {
            //                       title = value;
            //                     },
            //                   )),
            //             ],
            //           ),
            //           actions: <Widget>[
            //             FlatButton(
            //               child: Text('Cancell'),
            //               onPressed: () => Navigator.of(context).pop(0),
            //             ),
            //             FlatButton(
            //               child: Text('Resister'),
            //               onPressed: () async {
            //                 signInAnon().then((User currentUser) async{
            //                   FirebaseFirestore.instance.collection("devices").doc(currentUser.uid).set({
            //                     "name": title,
            //                     "os" : Platform.operatingSystem,
            //                     "date": DateTime.now(),
            //                     "login":'',
            //                     "email":'',
            //                     "did":currentUser.uid,
            //                   });
            //                   navi.setUser(currentUser);
            //                   await FirebaseFirestore.instance.collection('devices').doc(currentUser.uid).get().then((user){
            //                     navi.device.setDocid(user.id);
            //                     navi.device.setName(user['name']);
            //                   });
            //                 });
            //                 Navigator.of(context).pushNamed("/home");
            //               },
            //             ),
            //           ],
            //         );
            //       },
            //     );
            //     // --
            //   },
            // )
      ),
    );
  }
}