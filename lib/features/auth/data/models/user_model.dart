import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.isVerified,
    super.phoneNumber,
    super.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'is_verified': isVerified,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      isVerified: isVerified,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
    );
  }
}
