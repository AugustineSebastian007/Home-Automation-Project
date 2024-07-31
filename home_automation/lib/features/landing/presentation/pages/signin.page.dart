import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:home_automation/features/landing/presentation/pages/signin.page.dart';
import 'package:home_automation/features/landing/presentation/components/my_button.dart';
import 'package:home_automation/features/landing/presentation/components/my_textfield.dart';
import 'package:home_automation/features/landing/presentation/components/square_tile.dart';
import 'package:home_automation/features/landing/presentation/pages/auth_service.dart';


class SigninPage extends StatefulWidget {

  static const String route = '/signin';
  final Function()? onTap;

   SigninPage({super.key,required this.onTap});
  
  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
    // text editing controllers
  final usernameController = TextEditingController();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // sign user in method
  void signUserUp() async{
    //loading circle
    showDialog(context: context, builder: (context){
      return const Center(
        child: CircularProgressIndicator(),
      );
    });




    try {
      if(passwordController.text == confirmPasswordController.text){
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: usernameController.text, 
      password: passwordController.text,);
      Navigator.pop(context);

    }else{
      Navigator.pop(context);
      showDialog(context: context, builder: (context){
        
      return const AlertDialog(
        title: Text('Password Does not Match'),
      );
    });
    }
      }
    on FirebaseAuthException catch (e){

      Navigator.pop(context);

      if (e.code == 'user-not-found'){
        wrongEmailMsg();
    }
    else if (e.code == 'wrong-password'){
      wrongPasswordMsg();
    }
    }
  }

  void wrongEmailMsg(){
    showDialog(context: context, builder: (context){
      return const AlertDialog(
        title: Text('Incorrect Email'),
      );
    });
  }

  void wrongPasswordMsg(){
    showDialog(context: context, builder: (context){
      return const AlertDialog(
        title: Text('Incorrect Password'),
      );
    });
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
            
                // logo
                const Icon(
                  Icons.lock,
                  size: 50,
                ),
            
                const SizedBox(height: 25),
            
                // welcome back, you've been missed!
                Text(
                  'Let\'s Create an account for you!',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
            
                const SizedBox(height: 25),
            
                // username textfield
                MyTextField(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false,
                ),
            
                const SizedBox(height: 10),
            
                // password textfield
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
            
                const SizedBox(height: 10),

                // password textfield
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                        
                
            
                const SizedBox(height: 25),
            
                // sign in button
                MyButton(
                  text: "Sign Up",
                  onTap: signUserUp,
                ),
            
                const SizedBox(height: 50),
            
                // or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
            
                const SizedBox(height: 50),
            
                // google + apple sign in buttons
                 Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // google button
                    SquareTile(
                      onTap: () => AuthService().signInWithGoogle(),
                      imagePath: 'lib/images/google.png'),
            
                    // SizedBox(width: 25),
            
                    // // apple button
                    // SquareTile(
                    //   onTap: () {},
                    //   imagePath: 'lib/images/apple.png')
                  ],
                ),
            
                const SizedBox(height: 50),
            
                // not a member? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already a member?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Login now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

