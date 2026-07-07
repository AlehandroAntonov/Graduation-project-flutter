import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:src/models/requests.dart';
import 'dart:async';
import 'package:src/screens/admin/assign_request_screen.dart';
import 'package:src/screens/admin/manage_staff_screen.dart';
import 'package:src/screens/admin/manage_requester_screen.dart';
import 'package:src/screens/auth/login_screen.dart';
import 'package:src/services/request_service.dart';
import 'package:src/models/requests.dart';
import 'package:src/models/requests.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<StatefulWidget> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  int totalRequest = 0;
  int totalInProgress = 0;
  int totalCompleted = 0;
  int currentIndex = 0;

  List<Requests> allRequests = [];
  List<Requests> filteredList = [];

  bool isLoadingAllRequests = true;

  late List<Widget> _screens = [
    const ManageStaffScreen(),
    const ManageRequesterScreen()
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _loadStatistics() async {
    try {
      int inProgressCount = await RequestService().getInProgressRequests();
      int requestCount = await RequestService().getRequests();
      int completedCount = await RequestService().getCompletedRequests();

      if (mounted) {
        setState(() {
          totalRequest = requestCount;
          totalInProgress = inProgressCount;
          totalCompleted = completedCount;
        });
      }
    } catch (e) {
      print("Error loading statistics: $e");
    }
  }

  void _onSearchChanged(String searchQuery) {
    String query = searchQuery.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredList = allRequests;
      } else if (query == 'низкий' || query == 'low') {
        filteredList = allRequests.where((r) {
          return r.priority == Priority.low;
        }).toList();
      } else if (query == 'средний' || query == 'medium') {
        filteredList = allRequests.where((r) {
          return r.priority == Priority.medium;
        }).toList();
      } else if (query == 'высокий' || query == 'high') {
        filteredList = allRequests.where((r) {
          return r.priority == Priority.high;
        }).toList();
      } else {
        filteredList = allRequests.where((r) {
          return r.content.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadAllRequests();
  }

  Future<void> _loadAllRequests() async {
    setState(() {
      isLoadingAllRequests = true;
    });
    try {
      List<Requests> list = await RequestService().loadAllRequests();
      if (mounted) {
        setState(() {
          allRequests = list;
          filteredList = allRequests;
        });
      }
    } catch (e) {
      print("Error loading requests: $e");
      if (mounted) {
        setState(() {
          allRequests = [];
          filteredList = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAllRequests = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }

  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStatistics();
        await _loadAllRequests();
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              children: [
                Card(
                  color: Colors.blue[100],
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment,
                            size: 26,
                            color: Colors.blue[800],
                          ),
                          const Text(
                            "Всего",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$totalRequest",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  color: Colors.orange[100],
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_bottom,
                            size: 26,
                            color: Colors.orange[800],
                          ),
                          const Text(
                            "В работе",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$totalInProgress",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  color: Colors.green[100],
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 26,
                            color: Colors.green[800],
                          ),
                          const Text(
                            "Выполнено",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$totalCompleted",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.search_outlined),
                labelText: "Поиск по описанию или приоритету...",
                hintText: "Например: проблема, высокий",
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoadingAllRequests
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Ничего не найдено",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  Requests request = filteredList[index];
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignRequestScreen(
                            request: request,
                          ),
                        ),
                      );
                      if (result == true) {
                        await _loadStatistics();
                        await _loadAllRequests();
                      }
                    },
                    child: Card(
                      color: request.priority == Priority.low
                          ? Colors.green[50]
                          : request.priority == Priority.medium
                          ? Colors.orange[50]
                          : Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
                          leading: Icon(
                            request.priority == Priority.low
                                ? Icons.trending_down
                                : request.priority == Priority.medium
                                ? Icons.trending_flat
                                : Icons.trending_up,
                            color: request.priority == Priority.low
                                ? Colors.green[800]
                                : request.priority == Priority.medium
                                ? Colors.orange[800]
                                : Colors.red[800],
                            size: 30,
                          ),
                          title: Text(
                            request.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Приоритет: ${request.priority.ruNameWithEmoji}"),
                              Text(
                                "Статус: ${request.status.ruNameWithEmoji}",
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(request.submissionTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: const Text(
          "Панель администратора",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_outlined, color: Colors.black, size: 28),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: currentIndex == 0
          ? _buildHome()
          : IndexedStack(index: currentIndex - 1, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Сотрудники',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Пользователи',
          ),
        ],
      ),
    );
  }
}