import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserState extends ChangeNotifier{
  User user;
  void setUser(User currentUser){
    user = currentUser;
    notifyListeners();
  }
}

class RootPage extends StatefulWidget {
  RootPage({Key key}) : super(key: key);

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  @override
  void checkUser() async{
    final UserState userState = Provider.of<UserState>(context);
    final currentUser = await FirebaseAuth.instance.currentUser;
    if(currentUser == null){
      Navigator.pushReplacementNamed(context,"/signin");
    }else{
      //userState.setUser(currentUser);
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  void initState(){
    super.initState();
    checkUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Text("Loading..."),
        ),
      ),
    );
  }
}