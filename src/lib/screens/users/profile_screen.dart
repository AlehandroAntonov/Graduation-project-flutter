import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:src/models/users.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _officeController = TextEditingController();
  final TextEditingController _computerController = TextEditingController();

  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _officeController.dispose();
    _computerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        _usernameController.text = doc['username'] ?? '';
        _email = doc['email'] ?? '';
        _phoneController.text = doc['phoneNumber'] ?? '';
        _officeController.text = doc['officeNumber'] ?? '';
        _computerController.text = doc['computerName'] ?? '';
      }
    } catch (e) {
      print("Ошибка загрузки профиля: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Ошибка загрузки профиля: $e"),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'username': _usernameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'officeNumber': _officeController.text.trim(),
        'computerName': _computerController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Profile updated successfully!"),
          ),
        );
        Navigator.pop(context, true); // Возвращаем true для обновления
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Error saving profile: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Мой профиль"),
          backgroundColor: Colors.blue[400],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Мой профиль",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[400],
        actions: [
          IconButton(
            onPressed: _saveProfile,
            icon: Icon(Icons.save, color: Colors.white),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Email",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 20, color: Colors.blue[400]),
                          SizedBox(width: 8),
                          Text(
                            _email,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Форма с данными
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Персональная информация",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: "Имя",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Пожалуйста введите имя";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: "Номер телефона",
                          prefixIcon: Icon(Icons.phone),
                          hintText: "+7 123 456-78-90",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),

                      SizedBox(height: 16),

                      // Office Number
                      TextFormField(
                        controller: _officeController,
                        decoration: InputDecoration(
                          labelText: "Кабинет / этаж ",
                          prefixIcon: Icon(Icons.meeting_room),
                          hintText: "Кабинет 101, Этаж 2",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Computer Name
                      TextFormField(
                        controller: _computerController,
                        decoration: InputDecoration(
                          labelText: "Имя компьютера",
                          prefixIcon: Icon(Icons.computer),
                          hintText: "PC-123, Laptop-456",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(Icons.save),
                  label: Text(
                    _isSaving ? "Сохранение..." : "Сохранить",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}