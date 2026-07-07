class Users {
  String userId;
  String username;
  String email;
  String role;
  String? phoneNumber;      // Номер телефона
  String? officeNumber;     // Номер кабинета
  String? computerName;     // Имя компьютера

  Users({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.officeNumber,
    this.computerName,
  });

  factory Users.fromMap(Map<String, dynamic> data, String userId) {
    return Users(
      userId: userId,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'requester',
      phoneNumber: data['phoneNumber'],
      officeNumber: data['officeNumber'],
      computerName: data['computerName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'officeNumber': officeNumber,
      'computerName': computerName,
    };
  }
}