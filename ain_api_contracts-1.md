# AIN Backend — Complete API JSON Contract Reference

> Derived directly from C# DTO classes and controller signatures.
> Every field name, type, and optionality is exact.
> Use this as the single source of truth for both the React frontend and Flutter app.

**Base URL:** `http://[server]:5193`
**Auth header:** `Authorization: Bearer <token>`
**Content-Type for JSON:** `application/json`
**Content-Type for uploads:** `multipart/form-data`

---

## ERROR RESPONSE FORMAT

All errors return an `ApiResponse` object:
```json
{
  "statusCode": 400,
  "message": "Bad Request"
}
```

Validation errors from ASP.NET ModelState return standard problem details:
```json
{
  "errors": { "fieldName": ["error message"] },
  "status": 400
}
```

---

## 1. AUTHENTICATION (`/api/account`)

### POST `/api/account/signup-stepOne`
**Auth:** None
**Content-Type:** `application/json`

**Request body:**
```json
{
  "displayName": "string (required)",
  "userName": "string (required)",
  "email": "string (required, valid email)",
  "phoneNumber": "string (required, phone format)",
  "ssn": "string (required, 14-digit national ID)",
  "password": "string (required, min 5 chars)",
  "confirmPassword": "string (required, must match password)"
}
```

**Response 200 — `AuthResult`:**
```json
{
  "isSuccess": true,
  "errors": {},
  "user": null,
  "message": "string or null",
  "signupToken": "string (JWT — use this for steps 2–5)",
  "accessToken": null,
  "refreshToken": null
}
```
> ⚠️ Extract `signupToken` from the response. Send it as `Authorization: Bearer <signupToken>` for all subsequent signup steps.

---

### POST `/api/account/verify-otp`
**Auth:** `Authorization: Bearer <signupToken>`
**Content-Type:** `application/json`

**Request body:**
```json
{
  "otpCode": "string (required, 6-digit OTP)"
}
```

**Response 200 — `AuthResult`:**
```json
{
  "isSuccess": true,
  "errors": {},
  "user": null,
  "message": "OTP verified",
  "signupToken": "string (updated signup token)",
  "accessToken": null,
  "refreshToken": null
}
```

---

### POST `/api/account/resend-otp`
**Auth:** `Authorization: Bearer <signupToken>`
**Content-Type:** `application/json`

**Request body:** `{}` (empty body, user identified from token)

**Response 200 — `AuthResult`:**
```json
{
  "isSuccess": true,
  "message": "OTP sent",
  "signupToken": "string"
}
```

---

### POST `/api/account/upload-idCard`
**Auth:** `Authorization: Bearer <signupToken>`
**Content-Type:** `multipart/form-data`

**Form fields:**
```
IDCardFront: File (required, image)
IDCardBack:  File (required, image)
```

**Response 200 — `AuthResult`:**
```json
{
  "isSuccess": true,
  "message": "ID card uploaded",
  "signupToken": "string"
}
```

---

### POST `/api/account/upload-profile-photo`
**Auth:** `Authorization: Bearer <signupToken>`
**Content-Type:** `multipart/form-data`

**Form fields:**
```
ProfilePhoto: File (required, image)
```

**Response 200 — `AuthResult`:**
```json
{
  "isSuccess": true,
  "message": "Photo uploaded",
  "signupToken": "string"
}
```

---

### POST `/api/account/complete-signup`
**Auth:** `Authorization: Bearer <signupToken>`
**Content-Type:** `application/json`

**Request body:** `{}` (empty — all data was captured in previous steps)

**Response 200 — `AuthResult`:**
```json
{
  "isSuccess": true,
  "errors": {},
  "user": {
    "displayName": "string",
    "email": "string",
    "token": "string (FULL JWT — store this)",
    "refreshToken": "string"
  },
  "message": "Account created",
  "signupToken": null,
  "accessToken": "string (same as user.token)",
  "refreshToken": "string"
}
```
> ⚠️ Store `user.token` OR `accessToken` (same value) as the full Bearer JWT for all authenticated requests. Discard the signupToken.

---

### POST `/api/account/login`
**Auth:** None
**Content-Type:** `application/json`

**Request body:**
```json
{
  "email": "string (required, valid email)",
  "password": "string (required, min 5 chars)"
}
```

**Response 200 — `AuthResult`:**
```json
{
  "isSuccess": true,
  "errors": {},
  "user": {
    "displayName": "string",
    "email": "string",
    "token": "string (full JWT Bearer token)",
    "refreshToken": "string"
  },
  "message": null,
  "signupToken": null,
  "accessToken": "string",
  "refreshToken": "string"
}
```

**Response 401:** User not found or wrong password
```json
{ "statusCode": 401, "message": "Unauthorized" }
```

---

### POST `/api/account/signOut`
**Auth:** `Authorization: Bearer <token>`
**Content-Type:** `application/json`

**Request body:** `{}` (empty)

**Response 200:**
```json
{ "message": "Logged out successfully." }
```

---

### POST `/api/account/forgot-password`
**Auth:** None
**Content-Type:** `application/json`

**Request body:**
```json
{
  "email": "string (required, valid email)"
}
```

**Response 200:** (even if email not found — security)
```json
{ "message": "Reset link sent if email exists" }
```

---

### POST `/api/account/reset-password`
**Auth:** None
**Content-Type:** `application/json`

**Request body:**
```json
{
  "email": "string (required)",
  "token": "string (required, from email link)",
  "newPassword": "string (required, min 5 chars)",
  "confirmPassword": "string (required, must match)"
}
```

**Response 200 — `AuthResult`:**
```json
{ "isSuccess": true, "message": "Password reset successfully" }
```

---

### POST `/api/account/change-password`
**Auth:** `Authorization: Bearer <token>`
**Content-Type:** `application/json`

**Request body:**
```json
{
  "oldPassword": "string (required)",
  "newPassword": "string (required, min 5 chars)",
  "confirmPassword": "string (required, must match newPassword)"
}
```

**Response 200 — `AuthResult`:**
```json
{ "isSuccess": true, "message": "Password changed" }
```

---

## 2. PROFILE (`/api/profile`)

### GET `/api/profile/my-profile`
**Auth:** Bearer (required)

**Response 200 — `ProfileToReturnDto`:**
```json
{
  "id": "string (userId)",
  "displayName": "string",
  "userName": "string",
  "email": "string",
  "ssn": "string",
  "profilePhotoUrl": "string (URL to photo)",
  "trustPoints": 0,
  "badge": "Newcomer"
}
```
> Badge values: `"Newcomer"` | `"Contributor"` | `"Trusted"` | `"Guardian"`

---

### PUT `/api/profile/update-profile`
**Auth:** Bearer (required)
**Content-Type:** `multipart/form-data`

**Form fields:**
```
DisplayName:  string (optional)
PhoneNumber:  string (optional, phone format)
ProfilePhoto: File (optional, image)
```
> ⚠️ This is `[FromForm]` — send as `multipart/form-data`, NOT `application/json`.
> All fields are optional — send only what you want to update.

**Response 200 — `AuthResult`:**
```json
{
  "isSuccess": true,
  "user": {
    "displayName": "string",
    "email": "string",
    "token": "string (new JWT with updated claims)",
    "refreshToken": "string"
  },
  "message": "Profile updated"
}
```

---

## 3. REPORTS (`/api/reports`)

### POST `/api/reports` — Create Report
**Auth:** `[AllowAnonymous]` — send token if available
**Content-Type:** `multipart/form-data`

**Form fields:**
```
Title:          string (required, max 200)
Description:    string (required)
SubCategoryId:  string (required, UUID format)
Visibility:     string (required) — "Public" | "Confidential" | "Anonymous"
Latitude:       number (required, -90 to 90)
Longitude:      number (required, -180 to 180)
Attachments[]:  File[] (optional, multiple files, field name must be "Attachments")
```

**Response 200:**
```json
{
  "id": "uuid",
  "title": "string",
  "status": "UnderReview",
  "message": "Report submitted successfully"
}
```

---

### GET `/api/reports/{id}` — Get Single Report
**Auth:** `[AllowAnonymous]` — token improves access level
**Query params:** none

**Response 200 — `ReportWithAttachmentsDto`:**
```json
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "status": "UnderReview",
  "visibility": "Public",
  "category": "string",
  "subCategory": "string",
  "authorityName": "string or null",
  "createdAt": "2024-01-01T00:00:00Z",
  "attachments": [
    {
      "id": "uuid",
      "fileName": "string",
      "filePath": "string (URL)",
      "contentType": "image/jpeg or null",
      "fileSize": "string",
      "aiValidated": false
    }
  ],
  "location": {
    "latitude": 30.0,
    "longitude": 31.0
  },
  "locationName": "string or null",
  "locationMapUrl": "string or null",
  "reporter": {
    "id": "string or null",
    "name": "string",
    "phone": "string or null",
    "email": "string or null",
    "profilePhotoUrl": "string or null",
    "nationalId": "string or null",
    "idCardUrl": "string or null",
    "idCardBackUrl": "string or null"
  }
}
```
> `status` values: `"UnderReview"` | `"Dispatched"` | `"ReSolved"` | `"Rejected"`
> `visibility` values: `"Public"` | `"Confidential"` | `"Anonymous"`

**Reporter Visibility Matrix — what each role receives in the `reporter` object:**

| Report Type | Citizen | Authority | Admin / SuperAdmin |
|---|---|---|---|
| **Public** | `name` + `profilePhotoUrl` only | All fields: `name`, `phone`, `email`, `profilePhotoUrl`, **`nationalId`**, **`idCardUrl`**, **`idCardBackUrl`** | Same as Authority |
| **Confidential** | `reporter: null` (403) | All fields (same as Public row above) | Same as Authority |
| **Anonymous** | `reporter: null` (403) | `{ "name": "مجهول الهوية", all other fields: null }` — contact Admin for identity | Full identity revealed including `nationalId`, `idCardUrl`, `idCardBackUrl` |

> ⚠️ Always null-check `reporter` before accessing any field.
> ⚠️ Anonymous reports: Authority sees `"مجهول الهوية"` — if identity is needed, Authority must contact Admin.
> ⚠️ `nationalId`, `idCardUrl`, `idCardBackUrl` are `null` for Citizen-level callers always.

---

### GET `/api/reports/public` — Public Feed
**Auth:** `[AllowAnonymous]`
**Query params:** `page`, `pageSize`, `categoryId`, `status`, `search`

**Response 200 — Array of `PublicReportDto`:**
```json
[
  {
    "id": "uuid",
    "title": "string",
    "description": "string",
    "status": "UnderReview",
    "visibility": "Public",
    "category": "string",
    "subCategory": "string",
    "createdAt": "2024-01-01T00:00:00Z",
    "attachments": [ ... ],
    "location": { "latitude": 30.0, "longitude": 31.0 },
    "locationName": "string or null",
    "locationMapUrl": "string or null",
    "reporter": { "id": null, "name": "string", ... }
  }
]
```
> Note: `PublicReportDto` has NO `authorityName` field (unlike `ReportWithAttachmentsDto`).

---

### GET `/api/reports/visible` — Role-Filtered Feed
**Auth:** Bearer (Citizen, Admin, Authority, SuperAdmin)
**Query params:** `page`, `pageSize`, `categoryId`, `status`

**Response 200 — Array of `ReportWithAttachmentsDto`** (same shape as single report above)

---

### GET `/api/reports/my-reports` — My Reports
**Auth:** Bearer (Citizen+)
**Query params:** `page`, `pageSize`, `status`

**Response 200 — Array of `ReportWithAttachmentsDto`**

---

### GET `/api/reports/nearby` — Nearby Reports
**Auth:** `[AllowAnonymous]`
**Query params:**
```
latitude:  number (required)
longitude: number (required)
radiusKm:  number (optional, default 5)
page:      int
pageSize:  int
```

> ✅ **Fixed:** The radius comparison now correctly uses meters (SQL Server `geography.Distance()` returns meters). Pass `radiusKm` in kilometers — the API converts to meters internally.

**Response 200 — Array of `PublicReportDto`**

---

### GET `/api/reports/map-data` — Map Pins
**Auth:** Bearer (Citizen, Authority, Admin, SuperAdmin)
**Query params:** `categoryId`, `status`, `authorityId`

**Response 200 — Array of `ReportMapPinDto`:**
```json
[
  {
    "id": "uuid",
    "latitude": 30.0,
    "longitude": 31.0,
    "locationName": "string",
    "locationMapUrl": "string",
    "title": "string",
    "status": "UnderReview",
    "visibility": "Public",
    "subcategoryName": "string or null",
    "categoryName": "string or null",
    "createdAt": "2024-01-01T00:00:00Z"
  }
]
```

---

### PUT `/api/reports/{id}/visibility` — Change Visibility
**Auth:** Bearer (Citizen, Admin, Authority, SuperAdmin)
**Content-Type:** `application/json`

**Request body:**
```json
{
  "visibility": "Public"
}
```
> Values: `"Public"` | `"Confidential"` | `"Anonymous"`

**Response 200:**
```json
{ "message": "Visibility updated" }
```

---

### PUT `/api/reports/{id}/status` — Update Report Status
**Auth:** Bearer (Authority, Admin, SuperAdmin only)
**Content-Type:** `application/json`

**Request body:**
```json
{
  "status": "ReSolved"
}
```
> Values: `"UnderReview"` | `"Dispatched"` | `"ReSolved"` | `"Rejected"`

**Response 200 — `ReportWithAttachmentsDto`** (full report shape, same as GET by ID)

**Trust point side-effects (automatic, no extra call needed):**
| Status Set To | Trust Point Effect on Report Creator |
|---|---|
| `ReSolved` | **+10 points** awarded to citizen who submitted |
| `Rejected` | **-2 points** deducted from citizen who submitted |
| Any other | No change |

---

### DELETE `/api/Reports/{id}` — Citizen Self-Delete
**Auth:** Bearer (Citizen, Admin, SuperAdmin)
**Roles allowed:** `Citizen`, `Admin`, `SuperAdmin` — **Authority cannot delete reports**

**Request body:** none

**Response 204:** No Content (success)

**Response 403:** Caller is not the report owner
```json
{ "statusCode": 403, "message": "Only the report creator can delete it." }
```

**Response 404:** Report not found

**Trust point side-effect:** Deleting a report **reverses the +2 points** awarded at submission time.
> ⚠️ All attachments, likes, and comments are cascade-deleted automatically via FK constraints.
> ⚠️ Admin deletion (`DELETE /api/admin/reports/{reportId}`) is a separate endpoint that bypasses ownership check.

---

### GET `/api/reports/{id}/timeline` — Report Timeline
**Auth:** Bearer (Authority, Admin, SuperAdmin only)

**Response 200 — Array of `TimelineEntryDto`:**
```json
[
  {
    "type": "string",
    "event": "string",
    "note": "string or null",
    "actorName": "string",
    "createdAt": "2024-01-01T00:00:00Z"
  }
]
```

---

## 4. SOS ALERTS (`/api/sosalerts`)

### POST `/api/sosalerts/trigger` — Trigger SOS
**Auth:** Bearer (Citizen, Admin, Authority)
**Content-Type:** `application/json`

**Request body — `TriggerSOSDto`:**
```json
{
  "communityId": "uuid (required)",
  "latitude": 30.0,
  "longitude": 31.0,
  "accuracyMeters": 15.0,
  "severity": "Standard",
  "message": "string or null",
  "durationMinutes": 30
}
```
> `severity` values: `"Standard"` | `"High"` | `"Critical"` (default: `"Standard"`)
> `durationMinutes` default: 30 (null = no auto-expiry)

**Response 200 — `SOSAlertToReturnDto`:**
```json
{
  "id": "uuid",
  "status": "Active",
  "severity": "Standard",
  "message": "string or null",
  "initiatorUserId": "string",
  "communityId": "uuid",
  "createdAtUtc": "2024-01-01T00:00:00Z",
  "expiresAtUtc": "2024-01-01T00:30:00Z",
  "resolvedAtUtc": null,
  "recentLocations": [
    {
      "latitude": 30.0,
      "longitude": 31.0,
      "accuracyMeters": 15.0,
      "altitudeMeters": null,
      "recordedAtUtc": "2024-01-01T00:00:00Z",
      "locationName": "string or null"
    }
  ],
  "totalLocationUpdates": 1
}
```
> `status` values: `"Active"` | `"Resolved"` | `"Cancelled"` | `"FalseAlarm"` | `"Expired"`

---

### GET `/api/sosalerts/{id}` — Get SOS Alert
**Auth:** Bearer (Citizen, Admin, Authority)

**Response 200 — `SOSAlertToReturnDto`** (same shape as trigger response above)

---

### GET `/api/sosalerts/community/{id}` — Community SOS History
**Auth:** Bearer (Citizen, Admin, Authority)

**Response 200 — Array of `SOSAlertToReturnDto`**

---

### POST `/api/sosalerts/{id}/location` — Update SOS Location
**Auth:** Bearer (Citizen, Admin, Authority)
**Content-Type:** `application/json`

**Request body — `SOSLocationUpdateDto`:**
```json
{
  "latitude": 30.0,
  "longitude": 31.0,
  "accuracyMeters": 10.0,
  "altitudeMeters": null
}
```

**Response 200:**
```json
{ "message": "Location updated" }
```

---

### PUT `/api/sosalerts/{id}/cancel` — Cancel SOS
**Auth:** Bearer (Citizen, Admin, Authority)
**Content-Type:** `application/json`

**Request body:** `{}` (empty)

**Response 200:**
```json
{ "message": "SOS cancelled" }
```

---

### PUT `/api/sosalerts/{id}/resolve` — Resolve SOS
**Auth:** Bearer (Admin, Authority only)
**Content-Type:** `application/json`

**Request body:** `{}` (empty)

**Response 200:**
```json
{ "message": "SOS resolved" }
```

---

### PUT `/api/sosalerts/{id}/false-alarm` — Mark False Alarm
**Auth:** Bearer (Authority, Admin)
**Content-Type:** `application/json`

**Request body:** `{}` (empty)

**Response 200:**
```json
{ "message": "Marked as false alarm" }
```

---

### PUT `/api/sosalerts/{id}/severity` — Change Severity
**Auth:** Bearer (Authority, Admin)
**Content-Type:** `application/json`

**Request body:**
```json
{
  "severity": "High"
}
```
> Values: `"Standard"` | `"High"` | `"Critical"`

**Response 200:**
```json
{ "message": "Severity updated" }
```

---

### GET `/api/sosalerts/{id}/locations` — Location History
**Auth:** Bearer (Citizen, Admin, Authority)

**Response 200 — Array of `SOSLocationDto`:**
```json
[
  {
    "latitude": 30.0,
    "longitude": 31.0,
    "accuracyMeters": 10.0,
    "altitudeMeters": null,
    "recordedAtUtc": "2024-01-01T00:00:00Z",
    "locationName": "string or null"
  }
]
```

---

## 5. COMMUNITIES (`/api/community`)

### POST `/api/community` — Create Community
**Auth:** Bearer (any authenticated)
**Content-Type:** `application/json`

**Request body — `CommunityDto`:**
```json
{
  "name": "string (required)",
  "description": "string or null"
}
```

**Response 200 — `CreateCommunityToReturnDto`:**
```json
{
  "id": "uuid",
  "name": "string",
  "description": "string or null",
  "createdById": "string (userId)",
  "userName": "string",
  "createdAt": "2024-01-01T00:00:00Z",
  "userDetails": {
    "usrId": "string",
    "userName": "string",
    "role": "string",
    "userLocation": {
      "latitude": 30.0,
      "longitude": 31.0
    },
    "lastLocationUpdatedAt": "2024-01-01T00:00:00Z"
  }
}
```

---

### GET `/api/community` — List My Communities
**Auth:** Bearer (any authenticated)

**Response 200 — Array of `CommunityToReturnDto`:**
```json
[
  {
    "id": "uuid",
    "name": "string"
  }
]
```
> ⚠️ This returns minimal data (id + name only). Fetch individual community for full details.

---

### GET `/api/community/{communityId}` — Get Community Detail
**Auth:** Bearer

**Response 200 — `CommunityIdToReturnDto`:**
```json
{
  "id": "uuid",
  "name": "string",
  "description": "string or null",
  "createdAt": "2024-01-01T00:00:00Z",
  "createdById": "string",
  "createdByName": "string",
  "lastModifiedAt": "2024-01-01T00:00:00Z or null",
  "lastModifiedById": "string or null",
  "lastModifiedByName": "string or null",
  "members": [
    {
      "usrId": "string",
      "userName": "string",
      "role": "string",
      "userLocation": { "latitude": 30.0, "longitude": 31.0 },
      "lastLocationUpdatedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

### PUT `/api/community/{communityId}` — Update Community
**Auth:** Bearer
**Content-Type:** `application/json`

**Request body — `CommunityDto`:**
```json
{
  "name": "string (required)",
  "description": "string or null"
}
```

**Response 200 — `UpdateCommunityToReturnDto`:**
```json
{
  "id": "uuid",
  "name": "string",
  "lastModifiedById": "string",
  "lastModifiedName": "string",
  "lastModifiedAt": "2024-01-01T00:00:00Z"
}
```

---

### GET `/api/community/all` — System-Wide Community Listing
**Auth:** Bearer (Admin, SuperAdmin, Authority only)
**Roles allowed:** `Admin`, `SuperAdmin`, `Authority` — Citizens get **403**
**Query params:**
```
pageNumber: int (default 1)
pageSize:   int (default 20, max 50)
```

**Response 200:**
```json
{
  "totalCount": 42,
  "pageNumber": 1,
  "pageSize": 20,
  "totalPages": 3,
  "callerRole": "Admin",
  "items": [
    {
      "id": "uuid",
      "name": "string",
      "description": "string or null",
      "memberCount": 14,
      "createdById": "string (userId)",
      "createdByName": "string",
      "createdAt": "2024-01-01T00:00:00Z",
      "lastModifiedAt": "2024-01-01T00:00:00Z or null",
      "centroidLatitude": 30.05,
      "centroidLongitude": 31.23,
      "isWithinCallerJurisdiction": true
    }
  ]
}
```

**Role-scoping behaviour:**
| Caller Role | Communities Returned |
|---|---|
| **Admin / SuperAdmin** | ALL communities in the system, newest first |
| **Authority** | Only communities where ≥1 member's `LastLocation` falls within `Authority.JurisdictionRadiusKm` of `Authority.Location` |

> `centroidLatitude` / `centroidLongitude` — average lat/lon of all member last known locations. `null` if no members have location data.
> ⚠️ If Authority has no `Location` or `JurisdictionRadiusKm` configured, returns empty list (not an error).

---

## 6. COMMUNITY MEMBERS (`/api/communitymember`)

### POST `/api/communitymember/{communityId}` — Add Member by Email
**Auth:** Bearer
**Content-Type:** `application/json`

**Request body — `AddCommunityMemberByEmailDto`:**
```json
{
  "email": "string (required, email of user to add)"
}
```
> ⚠️ This is NOT a self-join. The authenticated user invites someone else by their email.

**Response 200 — `UserDetailsDto`:**
```json
{
  "usrId": "string",
  "userName": "string",
  "role": "string",
  "userLocation": { "latitude": 30.0, "longitude": 31.0 },
  "lastLocationUpdatedAt": "2024-01-01T00:00:00Z"
}
```

**Response 409 Conflict:** Member already in community

---

### GET `/api/communitymember/{communityId}` — Get Members
**Auth:** Bearer

**Response 200 — Array of `UserDetailsDto`:**
```json
[
  {
    "usrId": "string",
    "userName": "string",
    "role": "string",
    "userLocation": { "latitude": 30.0, "longitude": 31.0 },
    "lastLocationUpdatedAt": "2024-01-01T00:00:00Z"
  }
]
```

---

### DELETE `/api/communitymember/{communityId}/leave` — Leave Community
**Auth:** Bearer

**Request body:** none

**Response 200:**
```json
true
```

---

## 7. CATEGORIES & SUBCATEGORIES

### GET `/api/categories` — All Categories
**Auth:** None

**Response 200:**
```json
[
  {
    "id": "uuid",
    "name": "string",
    "description": "string or null",
    "iconName": "string or null",
    "authorityId": "uuid",
    "specializations": [
      {
        "id": "uuid",
        "name": "string",
        "icon": "string or null",
        "description": "string or null",
        "categoryId": "uuid"
      }
    ],
    "subCategories": [
      {
        "id": "uuid",
        "name": "string",
        "description": "string or null"
      }
    ]
  }
]
```

### GET `/api/categories/{id}` — Single Category
Same shape as single item above.

### GET `/api/subcategories` — All Subcategories
**Auth:** None

### GET `/api/subcategories/by-category?categoryId={uuid}` — Subcategories by Category
**Auth:** None

---

## 8. AUTHORITIES (`/api/authorities`)

### GET `/api/authorities` — List Authorities
**Auth:** None

**Response 200 — Array of `AuthorityProfileDto`:**
```json
[
  {
    "id": "uuid",
    "name": "string",
    "email": "string or null",
    "phone": "string or null",
    "type": "string or null",
    "latitude": 30.0,
    "longitude": 31.0,
    "jurisdictionRadiusKm": 10.0,
    "status": 1,
    "createdAt": "2024-01-01T00:00:00Z",
    "userId": "string or null",
    "specializations": [ ... ],
    "coverageAreas": [
      {
        "id": "uuid",
        "areaName": "string",
        "centerLatitude": 30.0,
        "centerLongitude": 31.0,
        "radiusKm": 12.5
      }
    ]
  }
]
```

---

## 9. ADMIN ENDPOINTS (`/api/admin`)
**Auth:** Bearer (Admin or SuperAdmin role required for all)

### GET `/api/admin/dashboard-summary`
**Response 200:**
```json
{
  "totalUsers": 0,
  "totalAuthorities": 0,
  "linkedAuthorities": 0,
  "unlinkedAuthorities": 0,
  "totalReports": 0,
  "activeReports": 0,
  "reportsToday": 0,
  "resolvedToday": 0,
  "activeSOS": 0,
  "systemHealth": "operational",
  "generatedAt": "2024-01-01T00:00:00Z"
}
```

### GET `/api/admin/users`
**Query params:** `role`, `search`, `linkedStatus` ("linked"|"unlinked"), `page`, `pageSize`

**Response 200:**
```json
{
  "users": [
    {
      "id": "string",
      "userName": "string",
      "email": "string",
      "phoneNumber": "string or null",
      "lockoutEnd": "datetime or null",
      "isLocked": false,
      "roles": ["Citizen"],
      "linkedAuthority": { "id": "uuid", "name": "string" }
    }
  ],
  "totalCount": 0,
  "page": 1,
  "pageSize": 20,
  "totalPages": 1
}
```

### PUT `/api/admin/users/{userId}/role`
**Request:**
```json
{ "role": "Citizen" }
```
> Values: `"Citizen"` | `"Authority"` | `"Admin"`

**Response 200:**
```json
{ "message": "User role changed to Citizen", "userId": "string", "role": "Citizen" }
```

### PUT `/api/admin/users/{userId}/deactivate`
**Request body:** none
**Response 200:** `{ "message": "User account deactivated", "userId": "string" }`

### PUT `/api/admin/users/{userId}/reactivate`
**Request body:** none
**Response 200:** `{ "message": "User account reactivated", "userId": "string" }`

### POST `/api/admin/users/{userId}/flag`
**Request:**
```json
{ "reason": "string (required, max 500)" }
```
**Response 200:** `{ "message": "User flagged", "userId": "string", "reason": "string" }`

### POST `/api/admin/link-authority-user`
**Request:**
```json
{
  "userId": "string (Identity user Id)",
  "authorityId": "uuid"
}
```
**Response 200:**
```json
{
  "message": "User successfully linked to authority and assigned Authority role",
  "userId": "string",
  "authorityId": "uuid",
  "authorityName": "string",
  "role": "Authority"
}
```

### POST `/api/admin/unlink-authority-user`
**Request:**
```json
{ "userId": "string" }
```
**Response 200:** `{ "message": "User unlinked from authority and demoted to Citizen role" }`

### GET `/api/admin/sos/overview`
**Response 200 — `SOSOverviewDto`:**
```json
{
  "activeAlerts": 0,
  "resolvedToday": 0,
  "falseAlarmsToday": 0,
  "avgResponseMinutes": 0.0,
  "alertsByAuthority": [
    { "authorityName": "string", "active": 0, "resolvedToday": 0 }
  ]
}
```

### DELETE `/api/admin/reports/{reportId}`
**Response 200:** `{ "message": "Report deleted", "reportId": "uuid" }`

### POST `/api/admin/reports/{reportId}/flag`
**Request:**
```json
{ "reason": "string" }
```
**Response 200:** `{ "message": "Report flagged for review", "reportId": "uuid", "reason": "string" }`

---

## 10. SUPERADMIN ENDPOINTS (`/api/superadmin`)
**Auth:** Bearer (SuperAdmin role only)

### PUT `/api/superadmin/users/{userId}/promote-to-admin`
**Response 200:**
```json
{ "message": "User promoted to Admin", "userId": "string", "role": "Admin" }
```

### PUT `/api/superadmin/users/{userId}/demote-to-citizen`
**Response 200:**
```json
{ "message": "User demoted to Citizen", "userId": "string", "role": "Citizen" }
```

---

## 11. ANALYTICS

### GET `/api/reports/analytics/authority/{authorityId}`
**Auth:** Bearer (Authority, Admin, SuperAdmin)
**Query params:** `startDate` (ISO8601), `endDate` (ISO8601)

**Response 200 — `AuthorityAnalyticsDto`:**
```json
{
  "authorityId": "string",
  "periodStart": "2024-01-01T00:00:00Z",
  "periodEnd": "2024-01-31T00:00:00Z",
  "totalAssigned": 0,
  "totalResolved": 0,
  "totalPending": 0,
  "avgResponseTimeHours": 0.0,
  "avgResolutionTimeHours": 0.0,
  "resolutionRate": 0.0,
  "overdueCases": 0,
  "slaMissedRate": 0.0,
  "reportsByCategory": { "CategoryName": 5 },
  "reportsByStatus": {
    "UnderReview": 3,
    "Dispatched": 1,
    "Resolved": 4,
    "Rejected": 0
  },
  "dailyTrend": [
    { "date": "2024-01-01T00:00:00Z", "count": 3, "resolvedCount": 1 }
  ]
}
```

### GET `/api/reports/analytics/system`
**Auth:** Bearer (Admin, SuperAdmin)
**Query params:** `startDate`, `endDate`

**Response 200 — `SystemAnalyticsDto`:**
```json
{
  "periodStart": "2024-01-01T00:00:00Z",
  "periodEnd": "2024-01-31T00:00:00Z",
  "totalReports": 0,
  "totalResolved": 0,
  "totalPending": 0,
  "reportsByStatus": { "UnderReview": 0, "Dispatched": 0, "Resolved": 0, "Rejected": 0 },
  "reportsByCategory": { "CategoryName": 5 },
  "reportsByVisibility": { "Public": 10, "Confidential": 2, "Anonymous": 3 },
  "avgResponseTimeHours": 0.0,
  "avgResolutionTimeHours": 0.0,
  "overallResolutionRate": 0.0,
  "dailyTrend": [
    { "date": "2024-01-01T00:00:00Z", "count": 3, "resolvedCount": 1 }
  ],
  "authorityPerformance": {
    "AuthorityName": {
      "authorityName": "string",
      "reportsAssigned": 10,
      "reportsResolved": 7,
      "avgResolutionTimeHours": 4.5,
      "resolutionRate": 0.7
    }
  }
}
```

### GET `/api/reports/statistics`
**Auth:** Bearer (Admin, SuperAdmin)

**Response 200 — `ReportStatisticsDto`:**
```json
{
  "totalReports": 0,
  "publicReports": 0,
  "confidentialReports": 0,
  "anonymousReports": 0,
  "countByStatus": { "UnderReview": 0, "Dispatched": 0, "ReSolved": 0, "Rejected": 0 },
  "averageReportAgeInDays": 0.0,
  "reportsInLast24Hours": 0,
  "reportsWithAttachments": 0,
  "totalAttachments": 0
}
```

---

## 12. SOCIAL LAYER (`/api/social`)

All social endpoints live under `/api/social`. Trust points are auto-updated server-side — no extra call needed.

### Trust Point Rules
| Action | Trust Change | When |
|---|---|---|
| Submit a report | **+2** | On `POST /api/reports` |
| Report resolved | **+10** | When status set to `ReSolved` |
| Report rejected | **-2** | When status set to `Rejected` |
| Delete own report | **-2** | On `DELETE /api/Reports/{id}` |
| Receive a like on report | **+1** | When another user likes your report |
| Unlike a report | **-1** | When a like is toggled off |

---

### POST `/api/social/reports/{reportId}/like` — Toggle Report Like
**Auth:** Bearer (any authenticated)

**Request body:** none

**Response 200 — `LikeResultDto`:**
```json
{
  "reportId": "uuid",
  "totalLikes": 5,
  "isLikedByCalller": true
}
```
> Calling again on the same report **toggles** (unlike). `isLikedByCaller` reflects new state.

---

### GET `/api/social/reports/{reportId}/likes` — Get Like Count
**Auth:** `[AllowAnonymous]` — token optional (shows your like state if provided)

**Response 200 — `LikeResultDto`:**
```json
{
  "reportId": "uuid",
  "totalLikes": 5,
  "isLikedByCalller": false
}
```

---

### POST `/api/social/comments/{commentId}/like` — Toggle Comment Like
**Auth:** Bearer (any authenticated)

**Request body:** none

**Response 200 — `CommentLikeResultDto`:**
```json
{
  "commentId": "uuid",
  "totalLikes": 3,
  "isLikedByCaller": true
}
```

---

### GET `/api/social/reports/{reportId}/comments` — Get Comments
**Auth:** `[AllowAnonymous]` — token optional

> ⚠️ **READ-ONLY — NO request body.** To create a comment use the POST below.

**Response 200 — Array of `ReportCommentDto`:**
```json
[
  {
    "id": "uuid",
    "content": "string",
    "authorId": "string",
    "authorName": "string",
    "authorPhoto": "string or null",
    "createdAt": "2024-01-01T00:00:00Z",
    "isDeleted": false,
    "totalLikes": 2,
    "isLikedByCaller": false,
    "parentCommentId": null,
    "replies": [
      {
        "id": "uuid",
        "content": "string",
        "authorId": "string",
        "authorName": "string",
        "authorPhoto": "string or null",
        "createdAt": "2024-01-01T00:00:00Z",
        "isDeleted": false,
        "totalLikes": 0,
        "isLikedByCaller": false,
        "parentCommentId": "uuid",
        "replies": []
      }
    ]
  }
]
```
> Replies are nested 1 level deep. Max reply depth = 1 (no nested replies).

---

### POST `/api/social/reports/{reportId}/comments` — Create Comment or Reply
**Auth:** Bearer (any authenticated)
**Content-Type:** `application/json`

**Request body:**
```json
{
  "content": "string (required)",
  "parentCommentId": "uuid or null"
}
```
> Leave `parentCommentId` as `null` (or omit it) for a top-level comment.
> Set `parentCommentId` to an existing comment's ID to create a reply.
> Max 1 level of nesting — you cannot reply to a reply.

**Response 201 — `ReportCommentDto`** (same shape as item in GET list above)

---

### DELETE `/api/social/comments/{commentId}` — Delete Comment
**Auth:** Bearer (comment author, Authority, Admin, SuperAdmin)

**Request body:** none

**Response 204:** No Content

> Soft-delete — comment content is replaced with placeholder, structure preserved for threading.

---

### GET `/api/social/users/{userId}/trust` — Get User Trust Profile
**Auth:** Bearer (any authenticated)

**Response 200 — `UserTrustDto`:**
```json
{
  "userId": "string",
  "displayName": "string",
  "trustPoints": 42,
  "badge": "Trusted",
  "totalReports": 10,
  "resolvedReports": 7,
  "phoneNumber": "string or null",
  "email": "string or null"
}
```
> `phoneNumber` and `email` only shown to Authority/Admin callers.
> `badge` values: `"Newcomer"` | `"Contributor"` | `"Trusted"` | `"Guardian"`

---

### GET `/api/social/me/trust` — Get My Own Trust Profile
**Auth:** Bearer (any authenticated)

**Response 200 — `UserTrustDto`** (full profile, all fields visible to self)

---

## 13. SIGNALR HUB — `/hub/sos`

**Connection:**
```
URL: ws://[server]:5193/hub/sos
Token: passed as query string ?access_token=<JWT>
  OR via header (depends on SignalR client config)
```

### Client → Server (invoke these)
```
JoinCommunityGroup(communityId: string)   // communityId is UUID string
LeaveCommunityGroup(communityId: string)
```

### Server → Client (listen for these)

| Event | Arguments | Description |
|-------|-----------|-------------|
| `ReceiveSOSTriggered` | `(sosAlert: SOSAlertToReturnDto)` | New SOS in a community you joined |
| `ReceiveLocationUpdate` | `(sosAlertId: string, locationUpdate: SOSLocationDto)` | Live location ping from SOS initiator |
| `ReceiveSOSResolved` | `(sosAlertId: string, resolvedBy: string)` | SOS was resolved by authority/admin |
| `ReceiveSOSCancelled` | `(sosAlertId: string, cancelledBy: string)` | SOS was cancelled by initiator |
| `ReceiveSOSMarkedAsFalseAlarm` | `(sosAlertId: string, markedBy: string)` | SOS marked false alarm |
| `ReceiveSeverityChanged` | `(sosAlertId: string, newSeverity: string)` | Severity level changed |

**`SOSLocationDto` shape (in SignalR payload):**
```json
{
  "latitude": 30.0,
  "longitude": 31.0,
  "accuracyMeters": 10.0,
  "altitudeMeters": null,
  "recordedAtUtc": "2024-01-01T00:00:00Z",
  "locationName": "string or null"
}
```

---

## 14. CRITICAL GOTCHAS

| # | Issue | Fix |
|---|-------|-----|
| 1 | `ReportStatus` serialized as `"ReSolved"` (capital S) | Handle both `"ReSolved"` and `"Resolved"` — compare case-insensitively |
| 2 | Signup uses a **different JWT scheme** (`"Signup"`) | Steps 1–5 use `signupToken`, NOT the main token. Different claims. |
| 3 | `AuthResult.user.token` and `AuthResult.accessToken` are the **same value** | Use either; prefer `accessToken` as it's more explicit |
| 4 | `GET /api/community` returns **minimal data** (id + name only) | Always fetch `GET /api/community/{id}` for full details |
| 5 | `POST /api/communitymember/{id}` **adds a user by their email** — not a self-join | You pass another user's email, not your own |
| 6 | `PUT /api/profile/update-profile` is `[FromForm]` — **multipart only** | Do NOT send as JSON. Use `multipart/form-data` |
| 7 | `report.status` uses exact string `"UnderReview"` (no space) | Despite the enum attribute `[EnumMember(Value = "Under Review")]`, JSON serialization uses `"UnderReview"` |
| 8 | `authorityPerformance` in SystemAnalyticsDto is `Dictionary<string, AuthorityPerformanceDto>` | Keys are authority names (strings), not IDs |
| 9 | `reporter` in report responses is `null` for Confidential/Anonymous reports viewed by Citizens | Always null-check before accessing reporter fields |
| 10 | `SOSAlertToReturnDto` is a **record** with positional parameters | JSON fields are camelCased: `id`, `status`, `severity`, `message`, `initiatorUserId`, `communityId`, `createdAtUtc`, `expiresAtUtc`, `resolvedAtUtc`, `recentLocations`, `totalLocationUpdates` |
| 11 | `UserDetailsDto.usrId` — field name is `usrId` not `userId` | Note the lowercase `r`: `"usrId"` |
| 12 | `countByStatus` in statistics uses `"ReSolved"` key | `{ "ReSolved": 5 }` not `"Resolved"` |
| 13 | `DELETE /api/Reports/{id}` is for **Citizen self-delete only** — Authority role gets **403** | Use `DELETE /api/admin/reports/{id}` for admin-level force deletion |
| 14 | `GET /api/social/reports/{id}/comments` has **no request body** — it is read-only | To create a comment use `POST /api/social/reports/{id}/comments` with a JSON body |
| 15 | Anonymous report `reporter.name` is `"مجهول الهوية"` for Authority callers | All other reporter fields are `null`. Admin always sees full identity. |
| 16 | `reporter.nationalId`, `reporter.idCardUrl`, `reporter.idCardBackUrl` are visible to **Authority AND Admin** for Public/Confidential reports | Previously these were Admin-only — this was changed |
| 17 | `POST /api/reports` requires an **authenticated user** even for `Anonymous` visibility | The identity is stored in DB but masked at read time. Pure-guest submission is not supported |
| 18 | `GET /api/community/all` is **scoped by role** — Authority only sees communities within their jurisdiction | Admin sees all. Citizen/unauthenticated gets 403 |
| 19 | `GET /api/reports/nearby` radius is in **kilometers** (`radiusKm` param) — the API converts to meters for the spatial query | The old bug (dividing degrees by 111000) is fixed — nearby now returns correct results |
| 20 | Trust points are **clamped at 0** — cannot go negative | Rejection/deletion won't deduct points if balance < 2 |
