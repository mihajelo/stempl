// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, unused_local_variable
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'registracija.dart';
import 'registracija_delavca.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../delavec/bottom_bar.dart';
import 'package:firebase_database/firebase_database.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      appId: "1:252279026147:android:23c26baf654d36368e70d6",
      messagingSenderId: '252279026147',
      apiKey: "AIzaSyBF4xvBRRIT--UDOLyH81lRg2JdJvWpJVo",
      authDomain: 'stempl-a0d50.firebaseapp.com',
      projectId: 'stempl-a0d50',
      databaseURL:
          "https://stempl-a0d50-default-rtdb.europe-west1.firebasedatabase.app",
    ),
  );

  Intl.defaultLocale = 'sl_SI';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Login and Registration',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();

    retrieveLoginData();
    if (rememberMe) {
      _autoSignIn(context);
    }
  }




void _signIn(BuildContext context) async {
  final String name = usernameController.text.trim();
  final String password = passwordController.text;

  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: name,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      if (rememberMe) {
        saveLoginData(name, password);
      }
      // (opcijsko) zapiši uspeh v audit log
      await _logAuthSuccess(email: name, uid: user.uid, stage: 'sign_in');

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BottomBar(currentIndex: 1)),
      );
    }
  } on FirebaseAuthException catch (e) {
    // zapiši neuspešno prijavo v audit log
    await _logAuthError(email: name, stage: 'sign_in', code: e.code, message: e.message);
    debugPrint('Auth error: code=${e.code} message=${e.message}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("NAPAKA PRI PRIJAVI"),
          content: const Text("Preverite, če ste vpisali pravilno uporabniško ime in geslo."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  } catch (e) {
    // generični catch (npr. mreža)
    await _logAuthError(email: name, stage: 'sign_in', code: 'unknown', message: e.toString());
    // ignore: avoid_print
    print('Nepričakovana napaka pri prijavi: $e');
  }
}

void _autoSignIn(BuildContext context) async {
  final String name = usernameController.text.trim();
  final String password = passwordController.text;

  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: name,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await _logAuthSuccess(email: name, uid: user.uid, stage: 'auto_sign_in');

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BottomBar(currentIndex: 1)),
      );
    }
  } on FirebaseAuthException catch (e) {
    await _logAuthError(email: name, stage: 'auto_sign_in', code: e.code, message: e.message);

    print('Auto sign-in failed: ${e.code}');
  } catch (e) {
    await _logAuthError(email: name, stage: 'auto_sign_in', code: 'unknown', message: e.toString());
  }
}

  // Save data when the user logs in
  void saveLoginData(String username, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', rememberMe ? username : '');
    prefs.setString('password', rememberMe ? password : '');
  }

// Retrieve data when initializing the login page
  void retrieveLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      usernameController.text = prefs.getString('username') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      rememberMe = prefs.getString('username') != null &&
          prefs.getString('password') != null;
    });
  }
String _maskEmail(String email) {
  // "miha@example.com" -> "m***a@e******.com"
  final parts = email.split('@');
  if (parts.length != 2) return 'masked';
  final user = parts[0];
  final domain = parts[1];
  String mask(String s) =>
      s.length <= 2 ? '*' * s.length : s[0] + ('*' * (s.length - 2)) + s[s.length - 1];
  return '${mask(user)}@${mask(domain)}';
}

Future<void> _logAuthError({
  required String email,
  required String stage, // npr. "sign_in" ali "auto_sign_in"
  required String code,
  String? message,
}) async {
  try {
    final ref = FirebaseDatabase.instance.ref('audit_logs/auth').push();
    await ref.set({
      'timestamp': DateTime.now().toIso8601String(),
      'stage': stage,
      'result': 'error',
      'email_masked': _maskEmail(email),
      'code': code,
      'message': message ?? '',
      // po želji še naprava/platforma
      'platform': 'flutter',
    });
  } catch (_) {
    // fallback: vsaj izpiši v konzolo
    // ignore: avoid_print
    print('Audit log (error) write failed');
  }
}

Future<void> _logAuthSuccess({
  required String email,
  required String uid,
  required String stage,
}) async {
  try {
    final ref = FirebaseDatabase.instance.ref('audit_logs/auth').push();
    await ref.set({
      'timestamp': DateTime.now().toIso8601String(),
      'stage': stage,
      'result': 'success',
      'email_masked': _maskEmail(email),
      'uid': uid,
      'platform': 'flutter',
    });
  } catch (_) {
    // ignore: avoid_print
    print('Audit log (success) write failed');
  }
}

  Future<bool> checkLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      // Permission is granted
      return true;
    } else if (status.isDenied) {
      // Permission is denied, request it
      var result = await Permission.location.request();

      if (result.isGranted) {
        // Permission granted
        return true;
      } else {
        // Permission denied
        return false;
      }
    } else {
      // First time requesting permission
      var result = await Permission.location.request();

      if (result.isGranted) {
        // Permission granted
        return true;
      } else {
        // Permission denied
        return false;
      }
    }
  }

  void _signInAdmin(BuildContext context) async {
    const String adminEmail = 'admin@gmail.com';
    const String adminPassword = 'admin123';

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      User? user = userCredential.user;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomBar(
            currentIndex: 1,
          ),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Admin Sign-In Error"),
            content: Text("An error occurred during admin sign-in: $e"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void clearLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    prefs.remove('password');
  }

  void _resetPassword(BuildContext context) async {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ponastavi geslo"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Vpišite svoj email naslov:"),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Email",
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Prekliči"),
            ),
            TextButton(
              onPressed: () async {
                final String email = emailController.text;

                try {
                  // Attempt to create a user with a dummy password
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email,
                    password: "dummyPassword",
                  );

                  // If successful, the email is not registered
                  Navigator.of(context).pop(); // Close the dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Neveljaven email naslov"),
                        content: const Text(
                            "Vpisan email naslov ni shranjen v našem sistemu."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                } catch (e) {
                  // If an error occurs, check if it's an email already registered error
                  if (e is FirebaseAuthException &&
                      e.code == 'email-already-in-use') {
                    // Email is registered, send password reset email
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: email,
                    );

                    Navigator.of(context).pop(); // Close the dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Ponastavitev gesla."),
                          content: Text(
                            "Email z navodili za ponastavitev gesla je bil poslan na $email.",
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    // Handle other errors, e.g., network issues
                    print("Error: $e");
                  }
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII
//GADNIKIIIIIIIIIIII

  Widget ozadje(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(199, 119, 192, 252),
            Colors.white,
          ],
        ),
      ),
    );
  }

  Widget topNotch(BuildContext context) {
    EdgeInsets padding = MediaQuery.of(context).padding;
    double topPadding = padding.top;
    return Container(
      height: topPadding,
      color: Colors.black,
    );
  }

  Widget logo(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Image.asset(
      'StemplLogo1.png',
      height: screenHeight * 0.25,
      width: screenHeight * 0.25,
    );
  }

  Widget adminButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _signInAdmin(context),
      child: Text('Sign In as Admin'),
    );
  }

  Widget email_field(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return TextField(
      controller: usernameController,
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.02,
          horizontal: screenWidth * 0.044,
        ),
        labelStyle: TextStyle(
          fontSize: screenHeight * 0.025,
        ),
      ),
      onSubmitted: (_) => _signIn(context),
    );
  }

  Widget password_field(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return TextField(
      controller: passwordController,
      decoration: InputDecoration(
        labelText: 'Geslo',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0), // Adjust the border radius
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01, // Adjust the vertical padding
          horizontal: screenWidth * 0.044,
        ),
        labelStyle: TextStyle(
          fontSize: screenHeight * 0.025,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
          iconSize: screenHeight * 0.03,
          icon: Icon(
            obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
        ),
      ),
      obscureText: obscurePassword,
      onSubmitted: (_) => _signIn(context),
    );
  }

  Widget check_box(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Checkbox(
      value: rememberMe,
      onChanged: (value) {
        setState(() {
          rememberMe = value!;
          if (!rememberMe) {
            clearLoginData();
          }
        });
      },
      activeColor: rememberMe ? Colors.green : Colors.red,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      checkColor: Colors.white,
      tristate: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.015),
      ),
      side: const BorderSide(
        color: Colors.grey,
      ),
    );
  }

  Widget check_box_text(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return TextButton(
      onPressed: () {
        _resetPassword(context);
      },
      child: Text(
        'Pozabljeno geslo?',
        style: TextStyle(
          color: Colors.blue,
          fontSize: screenHeight * 0.02,
        ),
      ),
    );
  }

  Widget prijava_button(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth / 2,
      height: screenHeight * 0.06,
      child: ElevatedButton(
        onPressed: () {
          _signIn(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.06),
          ),
        ),
        child: Text(
          'Prijava',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenHeight * 0.025,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget crta_pri_registracij(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth / 2.5,
      height: screenHeight * 0.0012,
      color: const Color.fromARGB(255, 197, 193, 193),
    );
  }

  Widget text_registracija(BuildContext context) {
    return const Text(
      'REGISTRACIJA',
      style: TextStyle(
        color: Color.fromARGB(255, 197, 193, 193),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget textZapomnisme(BuildContext context) {
    return const Text(
      'Zapomni si me',
    );
  }

  Widget registracija_podjetja(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth / 3,
      height: screenHeight * 0.062,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrationPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          primary: const Color.fromARGB(0, 33, 149, 243),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.06),
          ),
        ),
        child: Text(
          'Podjetja',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenHeight * 0.025,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget registracija_delavca(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth / 3,
      height: screenHeight * 0.062,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrationWorkerPage(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          primary: const Color.fromARGB(0, 33, 149, 243),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.06),
          ),
        ),
        child: Text(
          'Delavca',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenHeight * 0.025,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top notch widget above the background
          topNotch(context),
          // Stack for background and content
          Expanded(
            child: Stack(
              children: [
                // Background
                ozadje(context),
                // Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        logo(context),
                        SizedBox(height: 20),
                        email_field(context),
                        SizedBox(height: 20),
                        password_field(context),
                        Row(
                          children: [
                            check_box(context),
                            textZapomnisme(context),
                            Expanded(child: Container()),
                            check_box_text(context),
                          ],
                        ),
                        SizedBox(height: 20),
                        prijava_button(context),
                        SizedBox(height: 20),
                        adminButton(context),
                        Row(
                          children: [
                            Expanded(child: crta_pri_registracij(context)),
                            SizedBox(width: 10),
                            text_registracija(context),
                            SizedBox(width: 10),
                            Expanded(child: crta_pri_registracij(context)),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Container()),
                            registracija_podjetja(context),
                            SizedBox(width: 10),
                            registracija_delavca(context),
                            Expanded(child: Container()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
