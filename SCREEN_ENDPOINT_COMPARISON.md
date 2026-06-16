# 🎯 AIN Flutter App - Screen & Endpoint Comparison Matrix

> **Quick Reference**: Compare each implemented screen with its corresponding API endpoint(s) and identify gaps

---

## 📊 IMPLEMENTATION STATUS MATRIX

| # | Feature | Screen | Endpoint(s) | Status | Issues |
|---|---------|--------|-----------|--------|--------|
| **AUTH FLOWS** |
| 1 | Login | Login Page | `POST /api/account/login` | ✅ Complete | None |
| 2 | Signup Step 1 | Basic Info | `POST /api/account/signup-stepOne` | ✅ Complete | None |
| 3 | Signup Step 2 | OTP Verification | `POST /api/account/verify-otp`, `resend-otp` | ✅ Complete | Timer inconsistency |
| 4 | Signup Step 3 | ID Upload | `POST /api/account/upload-idCard` | ✅ Complete | None |
| 5 | Signup Step 4 | Profile Photo | `POST /api/account/upload-profile-photo` | ✅ Complete | None |
| 6 | Signup Step 5 | Confirmation | `POST /api/account/complete-signup` | ✅ Complete | None |
| 7 | Forgot Password | ForgotPasswordScreen | `POST /api/account/forgot-password` | ❌ MISSING | **HIGH PRIORITY** |
| 8 | Reset Password | ResetPasswordScreen | `POST /api/account/reset-password` | ❌ MISSING | **HIGH PRIORITY** |
| 9 | Change Password | ChangePasswordScreen | `POST /api/account/change-password` | ❌ MISSING | **HIGH PRIORITY** |
| 10 | Logout | Settings (embedded) | `POST /api/account/signOut` | ✅ Complete | None |
| **REPORTS** |
| 11 | Public Feed | HomePage (Feed Tab) | `GET /api/reports/public` | ✅ Complete | Pagination working |
| 12 | Add Report Step 1 | Report Details | Manual (form prep) | ✅ Complete | None |
| 13 | Add Report Step 2 | Location Picker | Manual (map selection) | ✅ Complete | None |
| 14 | Add Report Step 3 | Attachments | Manual (file selection) | ✅ Complete | Multiple files support |
| 15 | Create Report | Success Screen | `POST /api/reports` | ✅ Complete | None |
| 16 | Report Detail | ReportDetailPage | `GET /api/reports/{id}` | ⚠️ Partial | Missing reporter info masking |
| 17 | View Attachments | FullscreenPhotoPage | Inline display | ✅ Complete | No gallery view |
| 18 | Change Visibility | Report Detail (menu) | `PUT /api/reports/{id}/visibility` | ✅ Complete | None |
| 19 | Delete Report | Report Detail (menu) | `DELETE /api/reports/{id}` | ✅ Complete | Needs confirmation |
| 20 | Nearby Reports | MAP ONLY (not feed) | `GET /api/reports/nearby` | ⚠️ Partial | Endpoint exists but no dedicated screen |
| 21 | My Reports | HomePageMyReportsTab | `GET /api/reports/my-reports` | ✅ Complete | None |
| **MAP & LOCATION** |
| 22 | Map View | MapPage | `GET /api/reports/map-data` | ✅ Complete | Clustering works |
| 23 | Select Location | SelectReportLocationPage | Manual (map interaction) | ✅ Complete | None |
| 24 | Update User Location | Background service | `POST /api/location/` | ⚠️ Background Only | No user-facing UI |
| **PROFILE** |
| 25 | My Profile | ProfilePage | `GET /api/profile/my-profile` | ✅ Complete | None |
| 26 | Edit Profile | EditProfilePage | `PUT /api/profile/update-profile` | ✅ Complete | None |
| 27 | View Trust Profile | TrustPage (minimal) | `GET /api/social/me/trust` | ⚠️ Partial | **LOW DETAIL** |
| 28 | Leaderboard | LeaderboardPage | `GET /api/users/leaderboard` *(not in API)* | ❌ MISSING | **NO BACKEND ENDPOINT** |
| 29 | Settings | SettingsPage | Various | ✅ Complete | None |
| **COMMUNITIES** |
| 30 | Communities List | CommunityPage | `GET /api/community` | ✅ Complete | None |
| 31 | Create Community | CreateCommunityPage | `POST /api/community` | ✅ Complete | None |
| 32 | Community Detail | CommunityDetailPage | `GET /api/community/{id}` | ⚠️ Partial | Limited member interaction |
| 33 | Join by Code | JoinByCodePage | `POST /api/community/join` | ✅ Complete | None |
| 34 | Add Member | AddMemberPage | `POST /api/communitymember/{id}` | ✅ Complete | None |
| 35 | Community SOS History | SOS HISTORY PAGE | `GET /api/sosalerts/community/{id}` | ❌ MISSING | **MED PRIORITY** |
| 36 | Leave Community | Community Detail (menu) | `DELETE /api/communitymember/{id}/leave` | ✅ Complete | None |
| **SOS ALERTS** |
| 37 | SOS Page | SOSPage | `POST /api/sosalerts/trigger` | ⚠️ Partial | No active alert display |
| 38 | Active SOS Display | IN COMMUNITY DETAIL | N/A (embedded) | ⚠️ Partial | Should be own screen |
| 39 | Update SOS Location | Background Service | `POST /api/sosalerts/{id}/location` | ✅ Complete | Background only |
| 40 | Batch Location Upload | Background Service | `POST /api/sosalerts/{id}/locations/batch` | ✅ Complete | Background only |
| 41 | Get SOS Detail | None (not displayed) | `GET /api/sosalerts/{id}` | ❌ MISSING | **LOW PRIORITY** |
| 42 | Get Nearby SOS | None | `GET /api/sosalerts/nearby` | ❌ MISSING | **LOW PRIORITY** |
| 43 | Cancel SOS | SOS Page (assumed) | `PUT /api/sosalerts/{id}/cancel` | ⚠️ Assumed | No UI confirmation |
| **SOCIAL/COMMENTS** |
| 44 | View Comments | ReportDetailPage | `GET /api/social/reports/{id}/comments` | ⚠️ Minimal | Threaded comments not full featured |
| 45 | Add Comment | ReportDetailPage | `POST /api/social/reports/{id}/comments` | ✅ Complete | None |
| 46 | Like Report | ReportDetailPage | `POST /api/social/reports/{id}/like` | ✅ Complete | None |
| 47 | Delete Comment | IN COMMENT WIDGET | `DELETE /api/comments/{id}` | ❌ MISSING | No delete button in UI |
| 48 | Like Comment | IN COMMENT WIDGET | `POST /api/social/comments/{id}/like` | ❌ MISSING | No like button on comments |
| **NOTIFICATIONS** |
| 49 | Notifications List | NotificationsPage | Local/Push | ⚠️ Partial | No categorization by type |
| 50 | Mark as Read | NotificationsPage | Local storage | ⚠️ Partial | No API sync |
| **ADMIN/AUTHORITY** |
| 51-60 | Authority-only endpoints | N/A | Various admin endpoints | N/A | **CITIZEN APP ONLY - SKIP** |

---

## 🔍 DETAILED GAP ANALYSIS

### ❌ CRITICAL GAPS (Must Implement)

#### Gap 1: Password Management (3 Screens Missing)
```
ENDPOINTS DEFINED:
✓ POST /api/account/forgot-password
✓ POST /api/account/reset-password  
✓ POST /api/account/change-password

SCREENS NEEDED:
1. /forgot-password           → Email input → Recovery email sent
2. /reset-password?token=XXX  → Deep link → New password form
3. /change-password           → In Settings → Old + New password

IMPACT: Users cannot recover lost passwords
PRIORITY: 🔴 HIGH (User retention risk)
```

#### Gap 2: SOS Community History
```
ENDPOINT DEFINED:
✓ GET /api/sosalerts/community/{communityId}

SCREEN NEEDED:
1. /communities/:id/sos-history  → Timeline of SOS alerts

CURRENT WORKAROUND:
- SOS alerts shown in community detail (embedded)
- No dedicated history/timeline

IMPACT: Users cannot track SOS history in their community
PRIORITY: 🟡 MEDIUM (Nice-to-have feature)
```

#### Gap 3: Reporter Info Masking
```
ISSUE:
- API returns visibility-based reporter data
- App doesn't implement full masking rules

VISIBILITY MATRIX (Per API):
┌──────────────┬────────────┬──────────────┐
│ Report Type  │ Citizen    │ Authority    │
├──────────────┼────────────┼──────────────┤
│ Public       │ Name+Photo │ Full ID data │
│ Confidential  │ HIDDEN     │ Full ID data │
│ Anonymous    │ HIDDEN     │ "مجهول..."    │
└──────────────┴────────────┴──────────────┘

CURRENT IMPLEMENTATION:
- Shows reporter name if not null
- Doesn't implement visibility-based masking

IMPACT: Privacy breach for confidential/anonymous reports
PRIORITY: 🔴 HIGH (Security issue)
```

---

### ⚠️ PARTIAL IMPLEMENTATIONS (Need Enhancement)

#### Enhancement 1: Comments UI
```
CURRENT:
- Basic comment list
- Create comment form
- Delete/like endpoints NOT shown in UI

MISSING:
- Threaded reply visualization
- Comment edit functionality
- Comment delete button (endpoint exists)
- Comment like count + button
- Reply count visualization

IMPACT: Poor social engagement
PRIORITY: 🟡 MEDIUM (UX improvement)
```

#### Enhancement 2: Trust Profile
```
ENDPOINT:
✓ GET /api/social/me/trust

CURRENT UI:
- Trust score displayed on profile
- No detailed breakdown

MISSING:
- Badge unlock history
- Points breakdown by action
- Milestone achievements
- Progress to next badge

IMPACT: Users don't understand trust system
PRIORITY: 🟡 MEDIUM (Gamification)
```

#### Enhancement 3: SOS Active Display
```
ENDPOINT:
✓ POST /api/sosalerts/trigger
✓ GET /api/sosalerts/{id}

CURRENT:
- SOS trigger form
- Active SOS shown in community detail (embedded)

MISSING:
- Dedicated active SOS card/screen
- Live location tracking visualization
- Countdown timer display
- Cancel SOS UI (endpoint exists but no button)

IMPACT: Users don't see their active SOS clearly
PRIORITY: 🟡 MEDIUM (UX improvement)
```

---

### 📋 DATA MODEL ISSUES

#### Issue 1: Profile Photo URL Inconsistency
```
BACKEND RETURNS ONE OF:
- profilePhotoUrl (standard)
- profilePhoto
- profilePictureUrl
- photoUrl
- avatar
- + 7 more variants

CURRENT CODE:
✓ Checks all 12+ variants (fragile!)

FIX:
- Standardize backend to always return: profilePhotoUrl
- Remove variant checking

RISK LEVEL: 🟡 MEDIUM (Will break if backend changes)
```

#### Issue 2: SOS Status/Severity Enum
```
API RETURNS:
- status: integer (0,1,2,3)
- severity: integer (0,1,2)

CURRENT CODE:
✓ Hardcoded array mapping: ['Active', 'Resolved', ...][index]

RISK:
- If backend adds new status, app breaks
- No error if index out of bounds

FIX:
- Backend should return string enums
- App should validate with switch statement

RISK LEVEL: 🔴 HIGH (Will break on backend changes)
```

#### Issue 3: User ID Field Variants
```
BACKEND MAY RETURN:
- id
- userId
- user_id
- uid
- + 1 more

CURRENT CODE:
✓ Checks all variants (fragile!)

FIX:
- Standardize to: "id" (per API spec)
- Single field access

RISK LEVEL: 🟡 MEDIUM
```

---

## 📊 COVERAGE STATISTICS

```
TOTAL ENDPOINTS IN API: 35
ENDPOINTS WITH UI: 32 (91%)
ENDPOINTS MISSING UI: 3 (9%)

BREAKDOWN:
✅ Auth:              8/8    (100%)
✅ Reports:           8/8    (100%)
✅ Categories:        3/3    (100%)
✅ Profile:           2/2    (100%)
⚠️  SOS:              5/7    (71%)  ← Missing: community history, nearby
⚠️  Community:        5/7    (71%)  ← Limited member interaction
⚠️  Social:           2/5    (40%)  ← Missing: comment delete, comment like
⚠️  Notifications:    1/2    (50%)  ← No categorization

MISSING SCREENS: 6
- Forgot Password Screen
- Reset Password Screen  
- Change Password Screen
- SOS Community History
- Trust Profile Detail
- Leaderboard
```

---

## 🚨 PRIORITY ACTION ITEMS

### 🔴 RED (Critical - Do First)
- [ ] Implement Password Recovery Screens (3 screens)
- [ ] Fix Reporter Info Masking (privacy issue)
- [ ] Fix SOS Enum Mapping (will break on updates)

### 🟡 YELLOW (Important - Do Second)
- [ ] Enhance Comment UI (threaded replies)
- [ ] Create SOS Community History Screen
- [ ] Improve SOS Active Alert Display
- [ ] Add comment delete/like UI

### 🟢 GREEN (Nice-to-Have - Do Last)
- [ ] Create Leaderboard Screen
- [ ] Enhance Trust Profile Detail
- [ ] Standardize data model field names
- [ ] Add more SOS detail views

---

## 📱 SCREEN REDESIGN PRIORITY

| Priority | Screen | Reason | Est. Time |
|----------|--------|--------|-----------|
| 1 | Forgot Password | User retention | 2-3 hrs |
| 2 | Reset Password | User retention | 2-3 hrs |
| 3 | Change Password | User account security | 2-3 hrs |
| 4 | Comment Thread UI | Social engagement | 3-4 hrs |
| 5 | SOS History | Community features | 2-3 hrs |
| 6 | SOS Active Display | Emergency UX | 2-3 hrs |
| 7 | Reporter Info Masking | Privacy/Security | 2-3 hrs |
| 8 | Trust Profile Detail | Gamification | 2-3 hrs |
| 9 | Leaderboard | Gamification | 2-3 hrs |

---

## ✅ IMPLEMENTATION CHECKLIST

Use this to track implementation progress:

### Phase 1: Security & Account (Week 1)
- [ ] Create ForgotPasswordScreen
- [ ] Create ResetPasswordScreen
- [ ] Create ChangePasswordScreen
- [ ] Test password recovery flow
- [ ] Fix reporter info masking
- [ ] Add validation for password fields

### Phase 2: Social Enhancement (Week 2)
- [ ] Enhance comment UI with threading
- [ ] Add comment delete button
- [ ] Add comment like functionality
- [ ] Add nested reply visualization
- [ ] Test comment interactions

### Phase 3: SOS & Community (Week 2-3)
- [ ] Create SOS Community History screen
- [ ] Enhance SOS trigger UI with active display
- [ ] Add SOS countdown timer
- [ ] Improve member interaction in community
- [ ] Add member trust profile cards

### Phase 4: Gamification (Week 3)
- [ ] Create detailed Trust Profile screen
- [ ] Create Leaderboard screen
- [ ] Show badge unlock history
- [ ] Show points breakdown
- [ ] Add achievement animations

### Phase 5: Data Model Fix (Week 4)
- [ ] Fix profile photo URL standardization
- [ ] Fix SOS enum mapping
- [ ] Fix user ID field variants
- [ ] Add comprehensive error handling
- [ ] Test all API integrations

---

## 🎯 FINAL NOTES

**Total Gaps**: 9 (3 missing screens, 3 enhancements, 3 data issues)  
**Estimated Fix Time**: 2-3 weeks  
**Risk Level**: Medium (Privacy & Security concerns)  
**Documentation**: Complete in APP_SCREENS_REDESIGN_PROMPT.md

**Next Step**: Start with Phase 1 (Password Management) - highest impact on user retention.
