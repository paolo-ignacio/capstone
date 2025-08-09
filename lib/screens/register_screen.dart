import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:legallyai/screens/login_screen.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final fnameCtrl = TextEditingController();
  final lnameCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool hidePassword = true;
  bool isAgree = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/logoBlack.png',
                      height: 167, fit: BoxFit.contain),
                  const Gap(24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Join LegallyAI!",
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 32),
                          textAlign: TextAlign.start,
                        ),
                        const Gap(8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Please login with your credentials",
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: Color(0xFF868686), fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Card-style form container
                  Column(
                    children: [
                      TextFormField(
                        controller: fnameCtrl,
                        decoration: setTextDecoration('First Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? "*First name is required."
                            : null,
                      ),
                      const Gap(16),
                      TextFormField(
                        controller: lnameCtrl,
                        decoration: setTextDecoration('Last Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? "*Last name is required."
                            : null,
                      ),
                      const Gap(16),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: setTextDecoration('Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "*Email is required.";
                          if (!EmailValidator.validate(value))
                            return "*Invalid email address.";
                          return null;
                        },
                      ),
                      const Gap(16),
                      TextFormField(
                          controller: passwordCtrl,
                          obscureText: hidePassword,
                          decoration: setTextDecoration('Password',
                              isPasswordFieldTrue: true),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "*Password is required.";
                            if (value.length < 8)
                              return "*Password must be at least 8 characters.";
                            if (!RegExp(
                                    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$')
                                .hasMatch(value)) {
                              return "*Password must include letters and numbers.";
                            }
                            return null;
                          }),
                      const Gap(16),
                      TextFormField(
                          controller: confirmPassCtrl,
                          obscureText: hidePassword,
                          decoration: setTextDecoration('Confirm Password',
                              isPasswordFieldTrue: true),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "*Confirm password is required.";
                            if (value != passwordCtrl.text)
                              return "*Passwords do not match.";
                          }),
                      const Gap(16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: isAgree,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (value) =>
                                setState(() => isAgree = value!),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                  children: [
                                    TextSpan(
                                        text: "I understand and agree to the "),
                                    TextSpan(
                                      text:
                                          "LegallyAI terms of service including User Agreement and Privacy Policy.",
                                      style:
                                          TextStyle(color: Color(0xFFD4AF37)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => doRegister(),
                          child: const Text("Sign up"),
                        ),
                      )
                    ],
                  ),
                  const Gap(15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  InputDecoration setTextDecoration(String label,
      {bool isPasswordFieldTrue = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        // borderSide: BorderSide(color: Color(0xFF1D1A2F)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      suffixIcon: isPasswordFieldTrue
          ? IconButton(
              icon: Icon(
                hidePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () => setState(() => hidePassword = !hidePassword),
            )
          : null,
    );
  }

  void doRegister() {
    if (!formKey.currentState!.validate()) return;
    if (!isAgree) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Agreement Required',
        text: 'Please agree to the terms and conditions.',
      );
      return;
    }
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Are you sure you want to create this account?',
      cancelBtnText: 'No',
      confirmBtnText: 'Yes',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
        setState(() {});
        registerClient();
      },
    );
  }

  void registerClient() async {
    try {
      QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: 'Please Wait',
          text: 'Registering your account');

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailCtrl.text.trim(), password: passwordCtrl.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'fname': fnameCtrl.text.trim(),
        'lname': lnameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
      });

      Navigator.of(context).pop(); // Close loading
      setState(() {});

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'User Registration',
        text: 'Your account has been registered. You can now login',
      );
    } on FirebaseAuthException catch (ex) {
      Navigator.of(context).pop();
      setState(() {});

      String message = ex.code == 'email-already-in-use'
          ? 'This email is already registered.'
          : ex.message ?? 'An error occurred.';

      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: message,
      );
    }
  }
}
