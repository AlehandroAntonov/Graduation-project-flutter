import 'package:flutter/material.dart';
import 'package:src/models/users.dart';
import 'package:src/services/request_service.dart';

class ManageRequesterScreen extends StatefulWidget {
  const ManageRequesterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ManageRequesterState();
}

class _ManageRequesterState extends State<ManageRequesterScreen> {
  late Future<List<Users>> _requestersList = RequestService().getRequestersList();

  // Функция для получения русского названия роли
  String _getRoleName(String? role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'staff':
        return 'Сотрудник';
      case 'requester':
        return 'Пользователь';
      default:
        return 'Пользователь';
    }
  }

  // Функция для получения цвета роли
  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'staff':
        return Colors.blue;
      case 'requester':
        return Colors.green;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи системы'),
        backgroundColor: Colors.blue[400],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _requestersList = RequestService().getRequestersList();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<Users>>(
            future: _requestersList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Ошибка: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _requestersList = RequestService().getRequestersList();
                          });
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Нет пользователей',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              List<Users> requesters = snapshot.data!;
              return ListView.builder(
                itemCount: requesters.length,
                itemBuilder: (context, index) {
                  Users r = requesters[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(r.role).withOpacity(0.2),
                        child: Icon(
                          r.role == 'admin'
                              ? Icons.admin_panel_settings
                              : r.role == 'staff'
                              ? Icons.support_agent
                              : Icons.person,
                          color: _getRoleColor(r.role),
                        ),
                      ),
                      title: Text(
                        r.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${r.email}'),
                          if (r.phoneNumber != null && r.phoneNumber!.isNotEmpty)
                            Text('Телефон: ${r.phoneNumber}'),
                          if (r.officeNumber != null && r.officeNumber!.isNotEmpty)
                            Text('Кабинет: ${r.officeNumber}'),
                          if (r.computerName != null && r.computerName!.isNotEmpty)
                            Text('Компьютер: ${r.computerName}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(_getRoleName(r.role)),
                        backgroundColor: _getRoleColor(r.role).withOpacity(0.1),
                        side: BorderSide(
                          color: _getRoleColor(r.role).withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}