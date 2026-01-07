class NexoraUser {
  String username;
  String email;
  String? firstName;
  String? lastName;
  String? school;
  int? age;
  String? grade;
  String? address;

  NexoraUser({
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.school,
    this.age,
    this.grade,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'school': school,
        'age': age,
        'grade': grade,
        'address': address,
      };

  factory NexoraUser.fromJson(Map<String, dynamic> j) => NexoraUser(
        username: j['username'] ?? '',
        email: j['email'] ?? '',
        firstName: j['firstName'],
        lastName: j['lastName'],
        school: j['school'],
        age: j['age'],
        grade: j['grade'],
        address: j['address'],
      );
}
