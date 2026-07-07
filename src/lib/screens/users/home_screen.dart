import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:src/models/requests.dart';
import 'package:src/screens/auth/login_screen.dart';
import 'package:src/screens/users/add_request_screen.dart';
import 'package:src/screens/users/profile_screen.dart';
import 'package:src/services/request_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "...";
  int totalRequest = 0;
  int inProgressRequests = 0;
  int completedRequests = 0;

  List<Requests> _requests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _autoRefreshTimer;
  final RequestService _requestService = RequestService();

  Future<void> _logout() async {
    _stopAutoRefresh();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (mounted) {
        setState(() {
          username = doc['username'] ?? 'Пользователь';
        });
      }
    } catch (e) {
      print("Error loading user info: $e");
    }
  }

  Future<void> _loadRequests() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      List<Requests> requests = await _requestService.loadUserRequest();

      requests.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));

      int total = requests.length;
      int inProgress = requests.where((r) => r.status == Status.in_progress).length;
      int completed = requests.where((r) => r.status == Status.completed).length;

      if (mounted) {
        setState(() {
          _requests = requests;
          totalRequest = total;
          inProgressRequests = inProgress;
          completedRequests = completed;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print("Error loading requests: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _manualRefresh() async {
    await _loadRequests();
    await _loadUserInfo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Данные обновлены!"),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      await _requestService.deleteRequest(requestId);
      await _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Заявка удалена"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Ошибка удаления: $e"),
          ),
        );
      }
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: 60),
          (timer) {
        if (mounted) {
          _loadRequests();
          _loadUserInfo();
        }
      },
    );
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadRequests();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[400],
          title: const Text("..."),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.home, color: Colors.black, size: 30),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      onPressed: _isRefreshing ? null : _manualRefresh,
                      icon: Icon(
                        Icons.refresh,
                        size: 28,
                        color: _isRefreshing ? Colors.grey : Colors.black,
                      ),
                      tooltip: 'Обновить',
                    ),
                    if (_isRefreshing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                    if (result == true) {
                      _loadUserInfo();
                    }
                  },
                  icon: const Icon(Icons.person, color: Colors.black, size: 30),
                  tooltip: 'Мой профиль',
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_outlined, color: Colors.black, size: 30),
                  tooltip: 'Выйти',
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue[400],
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _manualRefresh,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Пользователь:",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                        const SizedBox(width: 20),
                        Text(username, style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Статистика заявок",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Всего: $totalRequest",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.assessment, color: Colors.blue[800]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "В работе: $inProgressRequests / $totalRequest",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.warning, color: Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "Выполнено: $completedRequests / $totalRequest",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle, color: Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Список заявок",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "(${_requests.length})",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: _requests.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "У вас пока нет заявок",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Нажмите на кнопку + чтобы создать заявку",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    Requests request = _requests[index];
                    return Dismissible(
                      key: Key(request.id!),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteRequest(request.id!);
                      },
                      child: Card(
                        color: request.priority == Priority.low
                            ? Colors.green[50]
                            : request.priority == Priority.medium
                            ? Colors.orange[50]
                            : Colors.red[50],
                        child: ListTile(
                          title: Text(
                            request.content,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Приоритет: ${request.priority.ruNameWithEmoji}"),
                              Text("Статус: ${request.status.ruNameWithEmoji}"),
                              Text(
                                "Создано: ${_formatDate(request.submissionTime)}",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                request.status == Status.completed
                                    ? Icons.check_circle
                                    : request.status == Status.in_progress
                                    ? Icons.hourglass_empty
                                    : Icons.pending,
                                color: request.status == Status.completed
                                    ? Colors.green
                                    : request.status == Status.in_progress
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request.status.ruName,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRequestScreen(),
            ),
          );
          _loadRequests();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}