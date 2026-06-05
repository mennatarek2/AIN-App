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

  factory UserModel.fromApiJson(Map<String, dynamic> json) {
    final id = _readString(json, ['id', 'userId', 'user_id', 'uid']) ?? '';
    final email = _readString(json, ['email', 'userEmail']) ?? '';
    final name = _readString(
          json,
          ['displayName', 'name', 'fullName', 'userName', 'username'],
        ) ??
        (email.isNotEmpty ? email : '');
    final isVerified = _readBool(
          json,
          ['isVerified', 'emailConfirmed', 'is_verified'],
        ) ??
        false;

    // Try all possible field names the backend may use for profile photo
    final profileImageUrl = _readString(json, [
      'profilePhotoUrl',   // Profile API field name
      'profilePhoto',
      'profilePictureUrl',
      'profilePicture',
      'avatarUrl',
      'avatar',
      'photoUrl',
      'profileImageUrl',   // Legacy local key
      'profile_image_url',
      'imageUrl',
      'picture',
    ]);

    print('[UserModel] fromApiJson - profileImageUrl resolved: $profileImageUrl');

    return UserModel(
      id: id.isNotEmpty ? id : email,
      email: email,
      name: name,
      isVerified: isVerified,
      phoneNumber: _readString(json, ['phoneNumber', 'phone_number']),
      profileImageUrl: profileImageUrl,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      phoneNumber: json['phone_number']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
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

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
      if (value is num) {
        if (value == 1) return true;
        if (value == 0) return false;
      }
    }
    return null;
  }
}
