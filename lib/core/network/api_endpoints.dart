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
  static const String reportsMapData = '/api/Reports/map-data';
  static const String myReports = '/api/Reports/my-reports';
  static String reportById(String id) => '/api/Reports/$id';
  static String reportVisibility(String id) => '/api/Reports/$id/visibility';
  static String reportDelete(String id) => '/api/Reports/$id';

  // ── SOS ──────────────────────────────────────────────────────────────────────
  static const String sosTrigger = '/api/SOSAlerts/trigger';
  static const String sosNearby = '/api/SOSAlerts/nearby';
  static String sosById(String id) => '/api/SOSAlerts/$id';
  static String sosCancel(String id) => '/api/SOSAlerts/$id/cancel';
  static String sosResolve(String id) => '/api/SOSAlerts/$id/resolve';
  static String sosLocationUpdate(String id) => '/api/SOSAlerts/$id/location';
  /// Batch upload of offline-queued location pings (max 50)
  static String sosBatchLocation(String id) => '/api/SOSAlerts/$id/locations/batch';
  /// Full snapshot — call on map screen load or SignalR reconnect
  static String sosLiveState(String id) => '/api/SOSAlerts/$id/live-state';

  // ── Community ─────────────────────────────────────────────────────────────────
  static const String community = '/api/Community';
  static String communityById(String id) => '/api/Community/$id';
  /// POST /api/Community/join  body: { inviteCode }
  static const String communityJoinByCode = '/api/Community/join';
  /// GET /api/Community/nearby?lat=&lng=&radiusKm=
  static const String communityNearby = '/api/Community/nearby';
  /// POST /api/Community/{id}/regenerate-code
  static String communityRegenerateCode(String id) =>
      '/api/Community/$id/regenerate-code';
  /// DELETE /api/Community/{id}/invite-code
  static String communityRevokeCode(String id) =>
      '/api/Community/$id/invite-code';
  /// POST /api/Community/{id}/members/{mid}/remind-location
  static String communityRemindLocation(String communityId, String memberId) =>
      '/api/Community/$communityId/members/$memberId/remind-location';

  // Legacy member endpoints (still used by add_member_page)
  static String communityMembers(String communityId) =>
      '/api/CommunityMember/$communityId';
  static String communityLeave(String communityId) =>
      '/api/CommunityMember/$communityId/leave';
  static String sosCommunityHistory(String communityId) =>
      '/api/SOSAlerts/community/$communityId';

  // ── Profile ───────────────────────────────────────────────────────────────────
  static const String myProfile = '/api/Profile/my-profile';
  static const String updateProfile = '/api/Profile/update-profile';

  // Categories & subcategories
  static const String categories = '/api/categories';
  static String categoryById(String id) => '/api/categories/$id';
  static const String subcategories = '/api/subcategories';
  static String subcategoriesByCategory(String categoryId) =>
      '/api/subcategories/by-category?categoryId=$categoryId';

  // Social interactions
  static String reportComments(String id) =>
      '/api/social/reports/$id/comments';
  static String reportLike(String id) => '/api/social/reports/$id/like';

  // Trust profile
  static const String myTrust = '/api/social/me/trust';
}
