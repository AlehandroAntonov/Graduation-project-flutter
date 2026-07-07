import 'package:flutter/material.dart';
import 'package:src/screens/auth/login_screen.dart';
import 'package:src/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameInputController =
      TextEditingController();
  final TextEditingController _passwordInputController =
      TextEditingController();
  final TextEditingController _emailInputController = TextEditingController();

  bool isLoading = false;
  bool _obsecurePassword = true;

  Future<void> _register() async {
    setState(() => isLoading = true);
    if (!_validateInput()) {
      return;
    }

    String username = _usernameInputController.text;
    String email = _emailInputController.text;
    String password = _passwordInputController.text;

    try {
      final result = await AuthService().register(username, password, email);

      if (result == "Register successful") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Успешная регистрация"),
          ),
        );
        await Future.delayed(Duration(seconds: 3));

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Ошибка регистрации: $e"),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _validateInput() {
    String username = _usernameInputController.text;
    String email = _emailInputController.text;
    String password = _passwordInputController.text;

    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Пожалуйста введите имя")));
      setState(() => isLoading = false);
      return false;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Пароль должен быть от 6 символов"),
        ),
      );
      setState(() => isLoading = false);
      return false;
    }

    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Введите корректный формат email",
          ),
        ),
      );
      setState(() => isLoading = false);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: Text(
          "Регистрация",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _usernameInputController,
              decoration: InputDecoration(
                label: Text("Имя", style: TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailInputController,
              decoration: InputDecoration(
                label: Text("Email", style: TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordInputController,
              obscureText: _obsecurePassword,
              decoration: InputDecoration(
                label: Text("Пароль", style: TextStyle(fontSize: 20)),
                suffixIcon: IconButton(
                  icon: _obsecurePassword
                      ? Icon(Icons.visibility_off)
                      : Icon(Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obsecurePassword = !_obsecurePassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Есть аккаунт?",
                  style: TextStyle(fontSize: 20),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return LoginScreen();
                        },
                      ),
                    );
                  },
                  child: Text(
                    "Авторизоваться",
                    style: TextStyle(fontSize: 18, color: Colors.blue[400]),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: isLoading ? null : _register,
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text("Регистрация", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
