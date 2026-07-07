import 'package:flutter/material.dart';
import 'package:src/screens/admin/dashboard_screen.dart';
import 'package:src/screens/auth/register_screen.dart';
import 'package:src/screens/staff/home_screen.dart';
import 'package:src/screens/users/home_screen.dart';
import 'package:src/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailInputController = TextEditingController();
  final TextEditingController _passwordInputController =
      TextEditingController();


  bool isLoading = false;

  // скрыть/показать пароль
  bool _obsecurePassword = true;

  bool _validInput() {
    String email = _emailInputController.text;
    String password = _passwordInputController.text;

    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Введите корректный e-mail"),
        ),
      );
      setState(() => isLoading = false);
      return false;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Введите пароль более 6 знаков"),
        ),
      );
      setState(() => isLoading = false);
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    setState(() => isLoading = true);

    if (!_validInput()) {
      return;
    }

    String email = _emailInputController.text;
    String password = _passwordInputController.text;

    try {
      final result = await AuthService().login(email, password);
      if (result == "requester") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Успешно"),
          ),
        );
        await Future.delayed(
          Duration(seconds: 3),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else if (result == "staff") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Успешно"),
          ),
        );
        await Future.delayed(
          Duration(seconds: 2),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StaffHomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Упешно"),
          ),
        );
        await Future.delayed(
          Duration(seconds: 2),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error at login: $e"),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailInputController.dispose();
    _passwordInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Авторизация",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue[400],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
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
                  onPressed: () {
                    setState(() {
                      _obsecurePassword = !_obsecurePassword;
                    });
                  },
                  icon: _obsecurePassword
                      ? Icon(Icons.visibility_off)
                      : Icon(Icons.visibility),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Нет аккаунта?", style: TextStyle(fontSize: 18)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: Text(
                    "Регистрация",
                    style: TextStyle(fontSize: 18, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: isLoading ? null : _login,
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text("Войти", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
