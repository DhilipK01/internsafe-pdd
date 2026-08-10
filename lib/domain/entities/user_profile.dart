import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.college,
  });

  final String id;
  final String email;
  final String name;
  final String? college;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? 'User',
      college: json['college'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, email, name, college];
}
