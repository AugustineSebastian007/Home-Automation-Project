import 'package:flutter/material.dart';
import 'package:home_automation/features/landing/presentation/pages/login.page.dart';
import 'package:home_automation/features/landing/presentation/pages/signin.page.dart';

class LoginOrReg extends StatefulWidget {
  const LoginOrReg({super.key});

  @override
  State<LoginOrReg> createState() => _LoginOrRegState();
}

class _LoginOrRegState extends State<LoginOrReg> {

  bool showLoginPage = true;

  void togglePages(){
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if(showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
  }
  else{
    return SigninPage(
      onTap: togglePages,
    );
  }
}
}