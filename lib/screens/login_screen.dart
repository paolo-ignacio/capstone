import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:legallyai/screens/main_screen.dart';
import 'package:legallyai/screens/register_screen.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }
  final keyForm = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), // dark background
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 80),
          child: Form(
            key: keyForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              
              children: [
                Center(
                  child: Image.asset(
                    'assets/icons/logoWhite.png',
                    height: 119,
                    fit: BoxFit.contain,
                  ),
                ),
                const Gap(32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16) ,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                     crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back to LegallyAI!",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 32
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const Gap(8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Please login with your credentials",
                          style: theme.textTheme.bodyMedium?.copyWith(color: Color(0xFF868686),
                          fontSize: 16
                          ),
                        
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(32),
                Column(
                  children: [
                    TextFormField(
                      decoration: setTextDecoration('Email'),
                      controller: emailCtrl,
                      style: const TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "*Email is required.";
                        }
                        if (!EmailValidator.validate(value)) {
                          return "*Invalid email address.";
                        }
                        return null;
                      },
                    ),
                    const Gap(16),
                    TextFormField(
                      obscureText: hidePassword,
                      decoration: setTextDecoration('Password', isPasswordField: true),
                      controller: passwordCtrl,
                      style: const TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "*Password is required.";
                        }
                        return null;
                      },
                    ),
                    const Gap(32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          doLogin();
                        },
                        child: const Text("Login"),
                      ),
                    ),
                  ],
                ),
                const Gap(15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                      child: Text(
                        "Register",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration setTextDecoration(String label, {bool isPasswordField = false}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Color(0xFF868686)),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      suffixIcon: isPasswordField
          ? IconButton(
              onPressed: toggleShowPassword,
              icon: Icon(
                hidePassword ? Icons.visibility_off : Icons.visibility,
                color: Color(0xFFC0C0C0),
              ),
            )
          : null,
    );
  }

  void toggleShowPassword() {
    setState(() {
      hidePassword = !hidePassword;
    });
  }
  

  void doLogin() async {
    if (!keyForm.currentState!.validate()) return;

    // Show loading spinner
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Logging In...',
      text: 'Please wait while we verify your credentials',
      barrierDismissible: false,
    );

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      // Dismiss loading and navigate on success
      Navigator.pop(context); // Close the loading alert
      final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userCredential.user!.uid)
      .get();

      if (userDoc.exists) {


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen( uid: userCredential.user!.uid, ),
          ),
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'User account does not exist',
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close the loading alert

      String errorMessage =  "Invalid Credentials. Please try again.";

      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Login Failed',
        text: errorMessage,
        confirmBtnText: 'OK',
      );
    }
  }
}