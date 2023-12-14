import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dailyexpenses.dart';
import 'package:transparent_image/transparent_image.dart';

void main() {
  runApp(const MaterialApp(
    home: LoginScreen(),
  ));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController ipaddressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Screen'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FadeInImage.memoryNetwork(
                      placeholder: kTransparentImage,
                      image: "https://rukminim2.flixcart.com/image/850/1000/km3s1ow0/poster/0/q/d/"
                          "medium-shin-chan-cartoon-wall-poster-for-room-with-gloss-original"
                          "-imagf2uzgant2zgd.jpeg?q=90")),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: ipaddressController,
                  decoration: const InputDecoration(
                    labelText: 'REST API address',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  String username = usernameController.text;
                  String password = passwordController.text;
                  String ipconfig = ipaddressController.text;
                  if (username == 'Kiruthikga' && password == '123456789') {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString("username", username);
                    await prefs.setBool("isLogin", true);
                    await prefs.setString("ipconfig", "http://$ipconfig");
                    print("Entered IP Address: $ipconfig");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DailyExpensesApp(username: username),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Login Failed'),
                          content: const Text('Invalid username or password.'),
                          actions: [
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
