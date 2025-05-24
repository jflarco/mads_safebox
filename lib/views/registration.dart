
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mads_safebox/global/colors.dart';
import 'package:mads_safebox/services/auth_service.dart';
import 'package:mads_safebox/widgets/custom_snack_bar.dart';
import 'package:mads_safebox/widgets/loading.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService auth = AuthService();

  final formkey = GlobalKey<FormState>();

  bool loading = false;

  String? validateEmail({required String? email}) {
    if (email == null) {
      return null;
    }
    RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
    if (email.isEmpty) {
      return 'Insert an email';
    }
    else if (!emailRegExp.hasMatch(email)) {
      return 'Insert a valid email';
    }
    return null;
  }


  @override
  void initState() {
    super.initState();
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: mainColor,
        centerTitle: true,
        leadingWidth: 50,
        title: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.orange, size: 30),
                SizedBox(width: 8),
                Text(
                  'SafeBoX',
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 50),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: !loading ? SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              'Register',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: mainColor),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: formkey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: usernameController,
                      validator: (val) => val!.isEmpty ? 'Insert a name' : null,
                      decoration: InputDecoration(
                        hintText: 'Username',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: emailController,
                      validator: (val) => validateEmail(email: val!.trim()),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      validator: (val) => val!.trim().length < 6 ? 'Password must have at least 6 characters' : null,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formkey.currentState!.validate()) {
                          return;
                        }
                        setState(() {
                          loading = true;
                        });
                        try {
                          await auth.signUp(emailController.text.trim(), passwordController.text.trim(), usernameController.text.trim());
                        } on Exception {
                          showCustomSnackBar(context, 'Error creating account');
                        }
                        loading = false;
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold, color: mainTextColor)),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      )
      : const Center(
          child: Loading(),
        ),
    );
  }
}

