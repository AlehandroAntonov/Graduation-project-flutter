import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:src/models/requests.dart';
import 'package:src/screens/auth/login_screen.dart';
import 'package:src/screens/staff/history_screen.dart';
import 'package:src/screens/staff/request_detail_screen.dart';
import 'package:src/services/request_service.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<StaffHomeScreen> {
  late String staffId;
  List<Requests> _myRequests = [];
  List<Requests> _availableRequests = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _currentIndex = 0;
  Timer? _autoRefreshTimer;
  final RequestService _requestService = RequestService();

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    staffId = FirebaseAuth.instance.currentUser!.uid;
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
          (timer) {
        if (mounted) {
          _loadData();
        }
      },
    );
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final results = await Future.wait([
        _requestService.getRequestsByStaffId(staffId),
        _requestService.getUnassignedRequests(),
      ]);

      List<Requests> myRequests = results[0];
      myRequests.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));

      List<Requests> availableRequests = results[1];
      availableRequests.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));

      if (mounted) {
        setState(() {
          _myRequests = myRequests;
          _availableRequests = availableRequests;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Ошибка загрузки: $e"),
          ),
        );
      }
    }
  }

  Future<void> _manualRefresh() async {
    await _loadData();
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

  Future<void> _markCompleted(Requests request) async {
    try {
      await _requestService.markRequestCompleted(request.id!);
      await _requestService.updateRequestDate(request.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("✅ Заявка завершена"),
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Ошибка: $e"),
          ),
        );
      }
    }
  }

  Future<void> _assignToMe(String requestId) async {
    try {
      await _requestService.assignToMe(requestId, staffId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("📋 Заявка назначена на вас!"),
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Ошибка: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[400],
          title: const Text("Портал сотрудника"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _currentIndex == 0
                  ? "Мои заявки (${_myRequests.length})"
                  : _currentIndex == 1
                  ? "Доступные заявки (${_availableRequests.length})"
                  : "История",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_outlined, size: 28, color: Colors.black),
                  tooltip: 'Выйти',
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _currentIndex == 0
            ? _buildMyRequestsTab()
            : _currentIndex == 1
            ? _buildAvailableRequestsTab()
            : const HistoryScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Мои заявки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Доступные',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'История',
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    if (_myRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Нет назначенных заявок",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Перейдите во вкладку 'Доступные' чтобы взять заявку",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _myRequests.length,
      itemBuilder: (context, index) {
        Requests request = _myRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          color: request.priority == Priority.low
              ? Colors.green[50]
              : request.priority == Priority.medium
              ? Colors.orange[50]
              : Colors.red[50],
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestDetailScreen(
                    request: request,
                    staffId: staffId,
                  ),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  request.username ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text("Приоритет: ${request.priority.ruName}"),
                        backgroundColor: request.priority == Priority.low
                            ? Colors.green[200]
                            : request.priority == Priority.medium
                            ? Colors.orange[200]
                            : Colors.red[200],
                      ),
                      Chip(
                        label: Text("Статус: ${request.status.ruName}"),
                        backgroundColor: Colors.blue[200],
                      ),
                      Chip(
                        avatar: const Icon(Icons.access_time, size: 14),
                        label: Text(_formatDate(request.submissionTime)),
                        backgroundColor: Colors.grey[200],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RequestDetailScreen(
                                  request: request,
                                  staffId: staffId,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadData();
                            }
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text("Подробнее"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markCompleted(request),
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Завершить"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableRequestsTab() {
    if (_availableRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              "Нет доступных заявок",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Все заявки уже назначены",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _availableRequests.length,
      itemBuilder: (context, index) {
        Requests request = _availableRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          color: request.priority == Priority.low
              ? Colors.green[50]
              : request.priority == Priority.medium
              ? Colors.orange[50]
              : Colors.red[50],
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestDetailScreen(
                    request: request,
                    staffId: staffId,
                  ),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    request.username ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text("Приоритет: ${request.priority.ruName}"),
                        backgroundColor: request.priority == Priority.low
                            ? Colors.green[200]
                            : request.priority == Priority.medium
                            ? Colors.orange[200]
                            : Colors.red[200],
                      ),
                      Chip(
                        label: Text("Статус: ${request.status.ruName}"),
                        backgroundColor: Colors.grey[200],
                      ),
                      Chip(
                        avatar: const Icon(Icons.access_time, size: 14),
                        label: Text(_formatDate(request.submissionTime)),
                        backgroundColor: Colors.grey[200],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestDetailScreen(
                              request: request,
                              staffId: staffId,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text("Подробнее"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}