import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:src/models/requests.dart';
import 'package:src/screens/auth/login_screen.dart';
import 'package:src/services/request_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HistoryState();
}

class _HistoryState extends State<HistoryScreen> {
  late String staffId;
  late Future<List<Requests>> _futureRequests;
  final RequestService _requestService = RequestService();

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    staffId = FirebaseAuth.instance.currentUser!.uid;
    _futureRequests = _requestService.getCompletedRequestsByStaffId(staffId);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.red,
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       const Text(
      //         "История заявок",
      //         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      //       ),
      //       IconButton(
      //         onPressed: _logout,
      //         icon: const Icon(Icons.logout_outlined, size: 28, color: Colors.black),
      //         tooltip: 'Выйти',
      //       ),
      //     ],
      //   ),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: _futureRequests,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Ошибка: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "Нет завершенных заявок",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }

                  List<Requests> requests = snapshot.data!;
                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      Requests request = requests[index];
                      return Card(
                        color: request.priority == Priority.low
                            ? Colors.green[50]
                            : request.priority == Priority.medium
                            ? Colors.orange[50]
                            : Colors.red[50],
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
                                    child: Text(
                                      request.content,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                    backgroundColor: Colors.green[200],
                                  ),
                                  Chip(
                                    avatar: const Icon(Icons.access_time, size: 14),
                                    label: Text(_formatDate(request.submissionTime)),
                                    backgroundColor: Colors.grey[200],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}