/// The client-side profile available after an authentication repository succeeds.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.school = '',
    this.gender = '',
    this.age,
    this.profileComplete = true,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String school;
  final String gender;
  final int? age;
  final bool profileComplete;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? phone : name;
  }
}
