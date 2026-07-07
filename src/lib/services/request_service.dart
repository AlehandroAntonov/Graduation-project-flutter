import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:src/models/requests.dart';
import 'package:src/models/users.dart';

class RequestService {
  Future<String> createRequests(String content, Priority priority) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Получаем ВСЕ данные пользователя
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      String username = userDoc['username'] ?? 'Unknown';
      String userEmail = userDoc['email'] ?? '';
      String? userPhone = userDoc['phoneNumber'];
      String? userOffice = userDoc['officeNumber'];
      String? userComputer = userDoc['computerName'];

      Requests newRequest = Requests(
        userId: userId,
        content: content,
        status: Status.newly_created,
        priority: priority,
        submissionTime: DateTime.now(),
        username: username,
        userEmail: userEmail,
        userPhone: userPhone,
        userOffice: userOffice,
        userComputer: userComputer,
        imageUrls: [],
      );

      Map<String, dynamic> data = newRequest.toMap();
      await FirebaseFirestore.instance.collection('requests').add(data);

      return "Requests created successfully";
    } catch (e) {
      throw Exception("Error at create request: $e");
    }
  }

  Future<List<Requests>> loadAllRequests() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .get();

      List<Requests> requests = snapshot.docs.map((doc) {
        return Requests.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      return requests;
    } catch (e) {
      print("Error loading all requests: $e");
      return [];
    }
  }

  // delete request
  Future<void> deleteRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .delete();
    } catch (e) {
      throw Exception("$e");
    }
  }

  Future<List<Requests>> loadUserRequest() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: userId)
          .get();

      List<Requests> requests = snapshot.docs.map((doc) {
        return Requests.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Сортируем по дате (новые сверху)
      requests.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));
      return requests;
    } catch (e) {
      print("Error loading user requests: $e");
      return [];
    }
  }

  Future<List<Requests>> loadRequestsByPriority(List<String> priority) async {
    try {
      List<Requests> allRequests = await loadAllRequests();

      if (priority.isEmpty) {
        return allRequests;
      }

      return allRequests
          .where((request) => priority.contains(request.priority.name))
          .toList();
    } catch (e) {
      print("Error loading requests by priority: $e");
      return [];
    }
  }

  Future<List<Requests>> loadRequestsByStatus(List<String> status) async {
    try {
      List<Requests> allRequests = await loadAllRequests();

      if (status.isEmpty) {
        return allRequests;
      }

      return allRequests
          .where((request) => status.contains(request.status.name))
          .toList();
    } catch (e) {
      print("Error loading requests by status: $e");
      return [];
    }
  }

  Future<int> getInProgressRequests() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'in_progress')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error getting in progress requests: $e");
      return 0;
    }
  }

  Future<int> getRequests() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error getting requests count: $e");
      return 0;
    }
  }

  Future<int> getCompletedRequests() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'completed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error getting completed requests: $e");
      return 0;
    }
  }

  Future<String> getUsernameById(String userId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return snapshot['username'] ?? 'Unknown';
    } catch (e) {
      print("Error getting username: $e");
      return 'Unknown';
    }
  }

  Future<List<Users>> getStaffList() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: "staff")
          .get();
      List<Users> user = snapshot.docs.map((doc) {
        return Users.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      return user;
    } catch (e) {
      print("Error getting staff list: $e");
      return [];
    }
  }

  Future<void> assignStaff(String requestId, String staffId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'staffId': staffId});
    } catch (e) {
      throw Exception("Error assigning staff: $e");
    }
  }

  Future<void> updateStatus(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': 'in_progress'});
    } catch (e) {
      throw Exception("Error when update status: $e");
    }
  }

  Future<void> updateRequestStatus(String requestId, String staffId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'staffId': staffId, 'status': 'in_progress'});
    } catch (e) {
      throw Exception("Error updating request: $e");
    }
  }

  Future<void> markRequestCompleted(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': 'completed'});
    } catch (e) {
      throw Exception("Error marking completed: $e");
    }
  }

  Future<void> updateRequestDate(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'submissionTime': DateTime.now()});
    } catch (e) {
      throw Exception("Error updating date: $e");
    }
  }

  Future<List<Requests>> getRequestsByStaffId(String staffId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('staffId', isEqualTo: staffId)
          .where('status', isEqualTo: 'in_progress')
          .get();

      List<Requests> requests = [];
      for (var doc in snapshot.docs) {
        Requests request = Requests.fromMap(doc.data() as Map<String, dynamic>, doc.id);

        if (request.username == null && request.userId.isNotEmpty) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(request.userId)
              .get();
          if (userDoc.exists) {
            request.username = userDoc['username'] ?? 'Unknown';
            request.userEmail = userDoc['email'] ?? '';
            request.userPhone = userDoc['phoneNumber'];
            request.userOffice = userDoc['officeNumber'];
            request.userComputer = userDoc['computerName'];
          }
        }

        requests.add(request);
      }

      // Сортируем по дате (новые сверху)
      requests.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));
      return requests;
    } catch (e) {
      print("Error getting requests by staffId: $e");
      return [];
    }
  }

  Future<List<Requests>> getCompletedRequestsByStaffId(String staffId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('staffId', isEqualTo: staffId)
          .where('status', isEqualTo: 'completed')
          .get();
      List<Requests> requests = snapshot.docs.map((doc) {
        return Requests.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Сортируем по дате (новые сверху)
      requests.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));
      return requests;
    } catch (e) {
      print("Error getting completed requests: $e");
      return [];
    }
  }

  Future<List<Users>> getRequestersList() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      List<Users> users = snapshot.docs.map((doc) {
        return Users.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Filter client-side: role != 'staff' and role != 'admin'
      users = users
          .where((user) => user.role != 'staff' && user.role != 'admin')
          .toList();
      return users;
    } catch (e) {
      print("Error getting requesters list: $e");
      return [];
    }
  }

  Future<List<Requests>> getUnassignedRequests() async {
    try {
      QuerySnapshot allSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .get();

      List<Requests> requests = [];
      for (var doc in allSnapshot.docs) {
        Requests request = Requests.fromMap(doc.data() as Map<String, dynamic>, doc.id);

        // Если данных пользователя нет, пробуем получить из users
        if (request.username == null && request.userId.isNotEmpty) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(request.userId)
              .get();
          if (userDoc.exists) {
            request.username = userDoc['username'] ?? 'Unknown';
            request.userEmail = userDoc['email'] ?? '';
            request.userPhone = userDoc['phoneNumber'];
            request.userOffice = userDoc['officeNumber'];
            request.userComputer = userDoc['computerName'];
          }
        }

        if ((request.staffId == null || request.staffId!.isEmpty) &&
            request.status != Status.completed &&
            request.status != Status.in_progress) {
          requests.add(request);
        }
      }

      // Сортируем по дате (новые сверху)
      requests.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));
      return requests;
    } catch (e) {
      print("Error getting unassigned requests: $e");
      return [];
    }
  }

  // Метод для назначения заявки на себя
  Future<void> assignToMe(String requestId, String staffId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
        'staffId': staffId,
        'status': 'in_progress'
      });
      print("Request $requestId assigned to $staffId");
    } catch (e) {
      print("Error assigning request: $e");
      throw Exception("Error assigning request: $e");
    }
  }

  Future<void> addImageUrlsToRequest(String requestId, List<String> imageUrls) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
        'imageUrls': FieldValue.arrayUnion(imageUrls),
      });
    } catch (e) {
      throw Exception("Error adding image URLs: $e");
    }
  }

// Удалить URL изображения из заявки
  Future<void> removeImageUrlFromRequest(String requestId, String imageUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
        'imageUrls': FieldValue.arrayRemove([imageUrl]),
      });
    } catch (e) {
      throw Exception("Error removing image URL: $e");
    }
  }
  // Обновить приоритет заявки
  Future<void> updateRequestPriority(String requestId, Priority newPriority) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
        'priority': newPriority.name,
      });
      print("✅ Priority updated to ${newPriority.name} for request $requestId");
    } catch (e) {
      print("Error updating priority: $e");
      throw Exception("Ошибка обновления приоритета: $e");
    }
  }

// Обновить назначенного сотрудника и статус
  Future<void> updateRequestStaff(String requestId, String staffId, String status) async {
    try {
      Map<String, dynamic> updates = {
        'staffId': staffId.isEmpty ? null : staffId,
        'status': status,
      };

      // Удаляем поле staffId если пустая строка
      if (staffId.isEmpty) {
        updates.remove('staffId');
      }

      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update(updates);

      print("✅ Staff updated for request $requestId");
    } catch (e) {
      print("Error updating staff: $e");
      throw Exception("Ошибка назначения сотрудника: $e");
    }
  }

// Получить заявку по ID (опционально)
  Future<Requests?> getRequestById(String requestId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .get();

      if (doc.exists) {
        return Requests.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Error getting request: $e");
      return null;
    }
  }
}