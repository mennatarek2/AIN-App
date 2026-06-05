abstract final class ApiEndpoints {
  static const String signUpStepOne = '/api/Account/signup-stepOne';
  static const String verifyOtp = '/api/Account/verify-otp';
  static const String resendOtp = '/api/Account/resend-otp';
  static const String login = '/api/Account/login';
  static const String completeSignUp = '/api/Account/complete-signup';
  static const String uploadIdCard = '/api/Account/upload-idCard';
  static const String uploadProfilePhoto = '/api/Account/upload-profile-photo';
  static const String signOut = '/api/Account/signOut';

  static const String reports = '/api/Reports';
  static const String reportsPublic = '/api/Reports/public';
  static const String reportsVisible = '/api/Reports/visible';
  static String reportById(String id) => '/api/Reports/$id';

  static const String sosTrigger = '/api/SOSAlerts/trigger';
  static const String sosNearby = '/api/SOSAlerts/nearby';
  static String sosById(String id) => '/api/SOSAlerts/$id';

  static const String communities = '/api/Communities';
  static String communityById(String id) => '/api/Communities/$id';

  static String communityMembers(String communityId) =>
      '/api/CommunityMember/$communityId';
  static String communityLeave(String communityId) =>
      '/api/CommunityMember/$communityId/leave';

  static const String myProfile = '/api/Profile/my-profile';
  static const String updateProfile = '/api/Profile/update-profile';
}
