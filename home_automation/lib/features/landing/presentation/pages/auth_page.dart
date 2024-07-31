import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_automation/features/intro/presentation/pages/loading.pages.dart';
import 'package:home_automation/features/landing/presentation/pages/login_or_reg.dart';

class AuthPage extends StatelessWidget {
  static const String route = '/auth';
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder:(context,snapshot){

          if(snapshot.hasData){
            return LoadingPage();
            
          }

          else{
            return LoginOrReg();
          }
        },
      ),
    );
  }
}