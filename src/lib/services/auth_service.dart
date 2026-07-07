import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:src/models/users.dart';
import 'package:src/services/user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  Future<String> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw Exception("User data not found in database");
      }

      String role = doc['role'];
      return role;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('User not found');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      } else {
        throw Exception("Login error: ${e.message}");
      }
    } catch (e) {
      throw Exception("Error at login: $e");
    }
  }

  Future<String> register(
      String username,
      String password,
      String email,
      ) async {
    try {
      // 1. Создаем пользователя в Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password
      );

      // 2. Получаем uuid созданного пользователя
      String uuid = userCredential.user!.uid;

      // 3. Создаем объект Users
      Users newUser = Users(
        userId: uuid,
        username: username,
        email: email.trim(),
        role: "requester", // По умолчанию все новые пользователи - requester
      );

      // 4. Сохраняем пользователя в Firestore через UserService
      await _userService.createUser(newUser);

      return "Register successful";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered');
      } else if (e.code == 'weak-password') {
        throw Exception('Password is too weak (minimum 6 characters)');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      } else {
        throw Exception("Registration failed: ${e.message}");
      }
    } catch (e) {
      throw Exception("Error at register: $e");
    }
  }

  // Выход из аккаунта
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Получить текущего пользователя
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Получить роль текущего пользователя
  Future<String?> getCurrentUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return doc['role'];
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }



}