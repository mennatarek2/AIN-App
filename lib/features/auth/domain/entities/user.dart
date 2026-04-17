import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final bool isVerified;
  final String? phoneNumber;
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.isVerified,
    this.phoneNumber,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    isVerified,
    phoneNumber,
    profileImageUrl,
  ];
}
