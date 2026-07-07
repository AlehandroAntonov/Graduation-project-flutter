import 'package:cloud_firestore/cloud_firestore.dart';

enum Status {
  newly_created,
  in_progress,
  completed
}

enum Priority {
  low,
  medium,
  high
}

// Расширения для получения русских названий
extension StatusExtension on Status {
  String get ruName {
    switch (this) {
      case Status.newly_created:
        return 'Новая';
      case Status.in_progress:
        return 'В работе';
      case Status.completed:
        return 'Завершена';
    }
  }

  String get ruNameWithEmoji {
    switch (this) {
      case Status.newly_created:
        return '🆕 Новая';
      case Status.in_progress:
        return '🔄 В работе';
      case Status.completed:
        return '✅ Завершена';
    }
  }
}

extension PriorityExtension on Priority {
  String get ruName {
    switch (this) {
      case Priority.low:
        return 'Низкий';
      case Priority.medium:
        return 'Средний';
      case Priority.high:
        return 'Высокий';
    }
  }

  String get ruNameWithEmoji {
    switch (this) {
      case Priority.low:
        return '🟢 Низкий';
      case Priority.medium:
        return '🟡 Средний';
      case Priority.high:
        return '🔴 Высокий';
    }
  }
}

class Requests {
  String? id;
  String userId;
  String? staffId;
  String content;
  Status status;
  Priority priority;
  DateTime submissionTime;
  String? username;
  String? userEmail;
  String? userPhone;
  String? userOffice;
  String? userComputer;
  List<String>? imageUrls;

  Requests({
    this.id,
    required this.userId,
    this.staffId,
    required this.content,
    required this.status,
    required this.priority,
    required this.submissionTime,
    this.username,
    this.userEmail,
    this.userPhone,
    this.userOffice,
    this.userComputer,
    this.imageUrls,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'staffId': staffId,
      'content': content,
      'status': status.name,
      'priority': priority.name,
      'submissionTime': submissionTime,
      'username': username,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userOffice': userOffice,
      'userComputer': userComputer,
      'imageUrls': imageUrls ?? [],
    };
  }

  factory Requests.fromMap(Map<String, dynamic> map, String id) {
    return Requests(
      id: id,
      userId: map['userId'],
      staffId: map['staffId'],
      content: map['content'],
      status: Status.values.firstWhere(
            (status) => status.name == map['status'],
      ),
      priority: Priority.values.firstWhere(
            (priority) => priority.name == map['priority'],
      ),
      submissionTime: (map['submissionTime'] as Timestamp).toDate(),
      username: map['username'],
      userEmail: map['userEmail'],
      userPhone: map['userPhone'],
      userOffice: map['userOffice'],
      userComputer: map['userComputer'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}