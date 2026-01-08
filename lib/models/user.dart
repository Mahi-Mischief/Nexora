class NexoraUser {
  int? id;
  String username;
  String email;
  String? firstName;
  String? lastName;
  String? school;
  int? age;
  String? grade;
  String? address;
  String? role;

  NexoraUser({
    this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.school,
    this.age,
    this.grade,
    this.address,
    this.role,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'school': school,
        'age': age,
        'grade': grade,
        'address': address,
        'role': role,
      };

  factory NexoraUser.fromJson(Map<String, dynamic> j) => NexoraUser(
        id: j['id'] ?? j['user_id'],
        username: j['username'] ?? j['user'] ?? '',
        email: j['email'] ?? '',
        firstName: j['first_name'] ?? j['firstName'],
        lastName: j['last_name'] ?? j['lastName'],
        school: j['school'],
        age: j['age'],
        grade: j['grade'],
        address: j['address'],
        role: j['role'],
      );
}
