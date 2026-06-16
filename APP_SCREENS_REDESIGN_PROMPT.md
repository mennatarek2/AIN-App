# 🎨 AIN Flutter Citizen App - Complete UI/UX Redesign Prompt

> **Objective**: Redesign all app screens to perfectly align with backend API contracts and ensure consistent, intuitive UI/UX across all features.

> **Status**: Analysis-based - Compare each section with current implementation

---

## 📊 EXECUTIVE SUMMARY

| Category | Count | Status |
|----------|-------|--------|
| Total Screens | 31 | ✅ Mostly implemented |
| API Endpoints | 35+ | ✅ ~32 implemented |
| Missing UI Screens | 6 | ⚠️ Needs implementation |
| Design Inconsistencies | 12+ | ⚠️ Needs standardization |
| Data Model Issues | 5 | ⚠️ Needs refinement |

**Key Gaps**: Password management UI (3 screens), SOS community history, trust profile details, social features enhancements

---

# 🔐 SECTION 1: AUTHENTICATION FLOWS

## Current Status
✅ **Implemented**: 12 screens + 8 API endpoints  
⚠️ **Issues**: Password management flows missing, inconsistent error messages

---

### Screen 1.1: Login Screen (`/login`)
**Endpoint**: `POST /api/account/login`

#### Current Implementation
- ✅ Email + Password fields
- ✅ "Sign up" + "Forgot password" links
- ✅ Loading state on button
- ⚠️ Error handling inconsistent

#### Redesign Requirements
```
LOGIN SCREEN LAYOUT:
┌─────────────────────────────┐
│   [AIN Logo]                │
│   تسجيل الدخول              │ (Arabic: "Login")
│                             │
│   ┌─────────────────────┐   │
│   │ 📧 البريد الإلكتروني │   │ (Email field)
│   │ user@example.com    │   │
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │ 🔒 كلمة المرور       │   │ (Password field)
│   │ ••••••••••          │   │
│   │            [👁️ Show]│   │ (Toggle visibility)
│   └─────────────────────┘   │
│                             │
│   [هل نسيت كلمة المرور؟]     │ (Forgot password link)
│   (Forgot password?)         │
│                             │
│   ┌─────────────────────┐   │
│   │  تسجيل الدخول        │   │ (Primary button)
│   └─────────────────────┘   │
│                             │
│   ليس لديك حساب؟            │ (No account?)
│   [إنشاء حساب الآن]          │ (Sign up link)
│                             │
└─────────────────────────────┘

VALIDATION:
- Email field: Show error icon if invalid format
- Password field: Show error if empty or < 6 chars
- Button: Disabled until both fields valid

ERROR HANDLING:
- 401 Unauthorized → "بيانات تسجيل الدخول غير صحيحة"
  (Invalid login credentials)
- 423 Locked → "الحساب مقفل. تواصل مع الإدارة"
  (Account locked. Contact support)
- Network Error → "تعذر الاتصال بالخادم"
  (Unable to connect to server)

AFTER SUCCESSFUL LOGIN:
- Store JWT token in SecureStorage
- Clear password field
- Navigate to /home
- Show success toast: "أهلا وسهلا" (Welcome)
```

#### API Contract
```json
POST /api/account/login
Content-Type: application/json
Auth: None

REQUEST:
{
  "email": "user@example.com",
  "password": "password123"
}

RESPONSE 200:
{
  "isSuccess": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expiresAt": "2026-06-15T10:30:00Z",
  "user": {
    "id": "uuid",
    "displayName": "أحمد محمد",
    "email": "user@example.com",
    "profilePhotoUrl": "https://..."
  }
}

RESPONSE 401:
{
  "statusCode": 401,
  "message": "Unauthorized"
}
```

#### Components Needed
- `LoginForm` (StatefulWidget) - Form validation + submission
- `EmailInputField` - Custom text input with validation
- `PasswordInputField` - Toggle obscure text
- `PrimaryButton` - Loading state indicator
- `OrDivider` - Separator for links
- `LinkText` - Styled text link

---

### Screen 1.2: Signup Flow (5 Steps) - `/signup/**`

#### Current Implementation
✅ 5-step wizard with progress indicator  
⚠️ OTP timer sometimes inconsistent  
⚠️ Image upload feedback unclear

---

#### Step 1: Basic Information (`/signup/step1`)
**Endpoint**: `POST /api/account/signup-stepOne`

```
STEP 1: البيانات الأساسية (Basic Information)
┌─────────────────────────────┐
│ ◉ ◯ ◯ ◯ ◯  Progress: 20%  │ (Progress indicator)
│                             │
│ البيانات الأساسية            │ (Header)
│                             │
│ ┌─────────────────────┐     │
│ │ اسم العرض           │     │ (Display Name)
│ │ أحمد محمد            │     │
│ └─────────────────────┘     │
│ ⓘ اسم يظهر في البيانات      │ (Helper text)
│                             │
│ ┌─────────────────────┐     │
│ │ رقم الهاتف           │     │ (Phone)
│ │ +20 100 1234567     │     │
│ └─────────────────────┘     │
│ ✓ صيغة صحيحة (01XXXXXXXX)  │ (Validation - green)
│                             │
│ ┌─────────────────────┐     │
│ │ الرقم القومي         │     │ (SSN/National ID)
│ │ 30001011234567      │     │
│ └─────────────────────┘     │
│ ✓ 14 رقم صحيح              │ (Validation - green)
│                             │
│ ┌─────────────────────┐     │
│ │ كلمة المرور          │     │ (Password)
│ │ ••••••••••           │     │
│ └─────────────────────┘     │
│ ⓘ 8 أحرف على الأقل,        │ (Requirements)
│   حرف كبير + رقم            │
│                             │
│ ┌─────────────────────┐     │
│ │ تأكيد كلمة المرور    │     │ (Confirm Password)
│ │ ••••••••••           │     │
│ └─────────────────────┘     │
│                             │
│ [      ← الرجوع  |  التالي →      ] │ (Navigation)
└─────────────────────────────┘

VALIDATION RULES:
- Display Name: 3-50 characters, Arabic/English
- Phone: Exactly 11 digits, starting with 01 (Egyptian format)
- SSN: Exactly 14 digits
- Password: Min 8 chars, uppercase + lowercase + number
- All fields required

INLINE VALIDATION:
- Show ✓ in green when valid
- Show ✗ in red when invalid
- Show requirement status (red/orange/green) for password

ERROR ON SUBMIT:
- Any validation error → Show inline error, don't submit
- API error → Show error toast with retry option
```

#### API Contract
```json
POST /api/account/signup-stepOne
Content-Type: application/json
Auth: None

REQUEST:
{
  "displayName": "أحمد محمد",
  "phoneNumber": "+201001234567",
  "nationalId": "30001011234567",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!"
}

RESPONSE 200:
{
  "isSuccess": true,
  "message": "Please verify your email",
  "signupToken": "eyJhbGc..." ← SAVE THIS
}

ERROR 400:
{
  "errors": {
    "password": ["Password must contain uppercase letter"]
  }
}
```

---

#### Step 2: OTP Verification (`/signup/step2`)
**Endpoint**: `POST /api/account/verify-otp` + `POST /api/account/resend-otp`

```
STEP 2: التحقق من رقم الهاتف (Phone Verification)
┌─────────────────────────────┐
│ ◯ ◉ ◯ ◯ ◯  Progress: 40%  │
│                             │
│ تحقق من رقم هاتفك           │ (Header)
│                             │
│ أرسلنا كود التحقق إلى      │ (Instruction)
│ +20 100 1234567             │
│                             │
│ ┌─ ─ ┬─ ─ ┬─ ─ ┬─ ─ ┬─ ─ ┬─ ─ ┐
│ │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ OTP Cell
│ └─ ─ ┴─ ─ ┴─ ─ ┴─ ─ ┴─ ─ ┴─ ─ ┘
│   ^Focused cell with cursor
│                             │
│ ┌─────────────────────┐     │
│ │ إعادة الإرسال في 00:45 │   │ (Countdown timer)
│ └─────────────────────┘     │
│                             │
│ [إعادة الإرسال]             │ (Disabled until 0:00)
│ (Resend)                    │
│                             │
│ [تحقق]                      │ (Submit button - auto-triggers at 6 digits)
│                             │
│ ← رجوع                      │ (Back)
└─────────────────────────────┘

OTP INPUT BEHAVIOR:
- Use Pinput widget (6 cells)
- Auto-submit when 6th digit entered
- Cursor visual feedback
- Haptic feedback on each digit
- Disabled until timer expires

TIMER LOGIC:
- Start at 60 seconds
- Update every second
- Format: "00:MM" or "00:SS"
- Resend button disabled (grayed out) until 0:00
- On resend click: Reset timer to 60s, call resend API

ERROR HANDLING:
- Invalid code → "الكود غير صحيح" (Red inline message)
- Show "هل لم تستقبل الكود؟ [إعادة الإرسال]"
  (Didn't receive code? Resend)
- Max retries: 5 → Show "حاول لاحقاً" (Try later)
```

#### API Contracts
```json
POST /api/account/verify-otp
Header: Authorization: Bearer <signupToken>
Content-Type: application/json

REQUEST:
{
  "otpCode": "123456"
}

RESPONSE 200:
{
  "isSuccess": true,
  "signupToken": "eyJhbGc..." ← UPDATE STORED TOKEN
}

---

POST /api/account/resend-otp
Header: Authorization: Bearer <signupToken>
Content-Type: application/json
Request Body: {} (empty)

RESPONSE 200:
{
  "isSuccess": true,
  "message": "OTP resent to your phone"
}
```

---

#### Step 3: ID Card Upload (`/signup/step3`)
**Endpoint**: `POST /api/account/upload-idCard` (multipart)

```
STEP 3: تحميل الهوية الوطنية (ID Verification)
┌─────────────────────────────┐
│ ◯ ◯ ◉ ◯ ◯  Progress: 60%  │
│                             │
│ صورة الهوية الوطنية        │ (Header)
│                             │
│ اختر صور واضحة للأمام      │ (Instructions)
│ والخلف مع ظهور البيانات    │
│                             │
│ ┌─────────┬─────────┐      │
│ │ الأمامية │ الخلفية │      │ (Tab-like headers)
│ └─────────┴─────────┘      │
│                             │
│ ╔═════════════════════╗     │
│ ║ [📷 Front Image]    ║     │ (Front card preview if selected)
│ ║ أو                  ║     │ (or)
│ ║ ┏━━━━━━━━━━━━━━━━┓ ║     │ (Upload zone)
│ ║ ┃ 📷               ┃ ║     │
│ ║ ┃ صورة أمامية    ┃ ║     │
│ ║ ┗━━━━━━━━━━━━━━━━┛ ║     │
│ ║ [الكاميرا] [المعرض]║     │ (Action buttons)
│ ╚═════════════════════╝     │
│                             │
│ ╔═════════════════════╗     │
│ ║ [📷 Back Image]     ║     │ (Back card preview if selected)
│ ║ أو                  ║     │ (or)
│ ║ ┏━━━━━━━━━━━━━━━━┓ ║     │ (Upload zone)
│ ║ ┃ 📷               ┃ ║     │
│ ║ ┃ صورة خلفية     ┃ ║     │
│ ║ ┗━━━━━━━━━━━━━━━━┛ ║     │
│ ║ [الكاميرا] [المعرض]║     │ (Action buttons)
│ ╚═════════════════════╝     │
│                             │
│ [تحميل الصور ✓] ← Auto-enabled when both selected
│                             │
│ [      ← الرجوع  |  التالي →      ]
└─────────────────────────────┘

IMAGE UPLOAD BEHAVIOR:
- Tap each card zone to pick image
- Show options: "من الكاميرا" (Camera) / "من المعرج" (Gallery)
- Display image preview with remove button (X overlay)
- Show upload progress (percentage)
- Validate: Image must be < 5MB, JPEG/PNG
- Show quality warning if image too small/blurry

VALIDATION:
- Both images required
- Must be actual ID cards (warn if not detected)
- Auto-submit disabled until both images uploaded

ERROR HANDLING:
- File too large → "حجم الملف كبير جداً (الحد الأقصى 5 ميجابايت)"
- Invalid format → "صيغة الملف غير مدعومة"
- Upload failed → Show retry button
```

#### API Contract
```json
POST /api/account/upload-idCard
Header: Authorization: Bearer <signupToken>
Content-Type: multipart/form-data

FORM FIELDS:
- IDCardFront: File (image)
- IDCardBack: File (image)

RESPONSE 200:
{
  "isSuccess": true,
  "message": "ID verified successfully",
  "signupToken": "eyJhbGc..." ← UPDATE TOKEN
}

RESPONSE 422:
{
  "errors": {
    "IDCardFront": ["Image quality too low"]
  }
}
```

---

#### Step 4: Profile Photo (`/signup/step4`)
**Endpoint**: `POST /api/account/upload-profile-photo` (multipart)

```
STEP 4: الصورة الشخصية (Profile Photo)
┌─────────────────────────────┐
│ ◯ ◯ ◯ ◉ ◯  Progress: 80%  │
│                             │
│ أضف صورة شخصية              │ (Header)
│                             │
│      ╔═════════════╗        │
│      ║             ║        │
│      ║      👤    ║        │ (Circle avatar - 160x160)
│      ║   اختر     ║        │
│      ║   صورة     ║        │
│      ║             ║        │
│      ╚═════════════╝        │
│                             │
│   [الكاميرا] [المعرج]       │ (Action buttons)
│   (Camera)   (Gallery)      │
│                             │
│ ⓘ استخدم صورة واضحة        │ (Tip)
│   لوجهك مباشرة               │
│                             │
│ [تحميل الصورة ✓]            │
│                             │
│ [      ← الرجوع  |  التالي →      ]
└─────────────────────────────┘

IMAGE BEHAVIOR:
- Circular preview (ClipOval)
- Drag to scale/position (optional)
- Show upload progress
- Same file size/format validation as Step 3

AFTER UPLOAD:
- Show "تم التحميل بنجاح" (Upload successful)
- Enable Next button
```

#### API Contract
```json
POST /api/account/upload-profile-photo
Header: Authorization: Bearer <signupToken>
Content-Type: multipart/form-data

FORM FIELDS:
- ProfilePhoto: File (image)

RESPONSE 200:
{
  "isSuccess": true,
  "signupToken": "eyJhbGc..."
}
```

---

#### Step 5: Confirmation (`/signup/step5`)
**Endpoint**: `POST /api/account/complete-signup`

```
STEP 5: تأكيد البيانات (Confirmation)
┌─────────────────────────────┐
│ ◯ ◯ ◯ ◯ ◉  Progress: 100% │
│                             │
│ تأكيد بيانات الحساب         │ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │ ✓ البيانات الأساسية  │    │ (Summary card)
│ │   أحمد محمد          │    │
│ │   +20 100 1234567    │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ ✓ التحقق الهاتفي      │    │
│ │   تم التحقق بنجاح     │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ ✓ الهوية الوطنية     │    │
│ │   تم التحميل بنجاح    │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ ✓ الصورة الشخصية     │    │
│ │   تم التحميل بنجاح    │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ ☐ أوافق على شروط      │    │ (Checkbox)
│ │   الاستخدام والخصوصية  │    │
│ │   [اقرأ الشروط]       │    │
│ └──────────────────────┘    │
│                             │
│ ┌────────────────────┐      │
│ │ إنشاء الحساب       │      │ (Primary button)
│ └────────────────────┘      │
│                             │
│ [      ← الرجوع  |          ]
└─────────────────────────────┘

REQUIREMENTS:
- Checkbox must be checked to enable button
- Summary shows all steps completed
- Terms link opens in-app webview

AFTER COMPLETION:
- Call POST /api/account/complete-signup
- Receive FULL JWT (not signup token)
- Store in SecureStorage
- Navigate to /home
- Show success animation
```

#### API Contract
```json
POST /api/account/complete-signup
Header: Authorization: Bearer <signupToken>
Content-Type: application/json
Request Body: {} (empty - all data from previous steps)

RESPONSE 200:
{
  "isSuccess": true,
  "message": "Account created successfully",
  "token": "eyJhbGciOiJIUzI1NiIs...", ← FULL JWT
  "expiresAt": "2026-12-15T10:30:00Z",
  "user": {
    "id": "uuid",
    "displayName": "أحمد محمد",
    "email": "user@example.com"
  }
}
```

---

### Screen 1.3: Forgot Password (`/forgot-password`)
**CURRENTLY MISSING** ❌

**Endpoint**: `POST /api/account/forgot-password`

```
FORGOT PASSWORD SCREEN
┌─────────────────────────────┐
│   [← Back]                  │
│                             │
│   هل نسيت كلمة المرور؟     │ (Header)
│                             │
│   أدخل بريدك الإلكتروني    │ (Instructions)
│   وسنرسل لك رابط استعادة   │
│                             │
│   ┌─────────────────────┐   │
│   │ 📧 البريد الإلكتروني │   │
│   │ user@example.com    │   │
│   └─────────────────────┘   │
│                             │
│   ┌────────────────────┐    │
│   │ إرسال رابط الاستعادة│   │ (Primary button)
│   └────────────────────┘    │
│                             │
│   [العودة لتسجيل الدخول]    │ (Link)
│                             │
└─────────────────────────────┘

RESPONSE STATE:
After successful submit:

┌─────────────────────────────┐
│   [✓ تم!]                   │
│                             │
│   تم إرسال البريد            │ (Success message)
│                             │
│   أرسلنا رابط استعادة كلمة  │
│   المرور إلى:               │
│   user@example.com          │
│                             │
│   يرجى التحقق من بريدك      │
│   خلال 10 دقائق             │
│                             │
│   ┌─────────────────────┐   │
│   │ [✓ تم استقبالك]    │   │ (Checkmark)
│   └─────────────────────┘   │
│                             │
│   [العودة لتسجيل الدخول]    │ (Link)
│   [إعادة المحاولة]          │ (If no email received)
│                             │
└─────────────────────────────┘
```

#### API Contract
```json
POST /api/account/forgot-password
Content-Type: application/json
Auth: None

REQUEST:
{
  "email": "user@example.com"
}

RESPONSE 200: (Even if email not found - security)
{
  "message": "Reset link sent if email exists"
}
```

---

### Screen 1.4: Reset Password (`/reset-password`)
**CURRENTLY MISSING** ❌

**Endpoint**: `POST /api/account/reset-password`

Accessed via deep link: `ain://reset-password?token=XXX`

```
RESET PASSWORD SCREEN
┌─────────────────────────────┐
│   إعادة تعيين كلمة المرور   │ (Header)
│                             │
│   ┌─────────────────────┐   │
│   │ 🔒 كلمة المرور الجديدة│   │
│   │ ••••••••••          │   │
│   │            [👁️ Show]│   │
│   └─────────────────────┘   │
│   ⓘ 8 أحرف على الأقل,      │
│     حرف + رقم               │
│                             │
│   ┌─────────────────────┐   │
│   │ 🔒 تأكيد كلمة المرور │   │
│   │ ••••••••••          │   │
│   │            [👁️ Show]│   │
│   └─────────────────────┘   │
│                             │
│   ┌────────────────────┐    │
│   │ تعيين كلمة المرور  │    │ (Primary button)
│   └────────────────────┘    │
│                             │
└─────────────────────────────┘

VALIDATION:
- Same as signup password rules
- Must match (password confirmation)

ERROR:
- Invalid token → "الرابط منتهي الصلاحية"
- Token expired → "انتهت صلاحية الرابط، اطلب آخر جديد"
```

#### API Contract
```json
POST /api/account/reset-password
Content-Type: application/json
Auth: None

REQUEST:
{
  "email": "user@example.com",
  "resetToken": "xxxxx",
  "newPassword": "NewPass123!",
  "confirmPassword": "NewPass123!"
}

RESPONSE 200:
{
  "isSuccess": true,
  "message": "Password reset successfully"
}
```

---

### Screen 1.5: Change Password (`/change-password`)
**CURRENTLY MISSING** ❌

**Endpoint**: `POST /api/account/change-password`

Located in: Settings → Change Password

```
CHANGE PASSWORD SCREEN
┌─────────────────────────────┐
│   [← Back]                  │
│   تغيير كلمة المرور         │ (Header)
│                             │
│   ┌─────────────────────┐   │
│   │ 🔒 كلمة المرور الحالية│   │
│   │ ••••••••••          │   │
│   │            [👁️ Show]│   │
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │ 🔒 كلمة المرور الجديدة│   │
│   │ ••••••••••          │   │
│   │            [👁️ Show]│   │
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │ 🔒 تأكيد كلمة المرور │   │
│   │ ••••••••••          │   │
│   │            [👁️ Show]│   │
│   └─────────────────────┘   │
│                             │
│   ┌────────────────────┐    │
│   │ تحديث كلمة المرور  │    │ (Primary button)
│   └────────────────────┘    │
│                             │
└─────────────────────────────┘

ON SUCCESS:
- Show success toast: "تم تحديث كلمة المرور بنجاح"
- Auto-logout after 3s
- Redirect to /login
```

#### API Contract
```json
POST /api/account/change-password
Header: Authorization: Bearer <token>
Content-Type: application/json

REQUEST:
{
  "oldPassword": "CurrentPass123!",
  "newPassword": "NewPass123!",
  "confirmPassword": "NewPass123!"
}

RESPONSE 200:
{
  "isSuccess": true,
  "message": "Password changed successfully"
}

RESPONSE 401:
{
  "statusCode": 401,
  "message": "Current password is incorrect"
}
```

---

# 🏠 SECTION 2: HOME & REPORTS

## Current Status
✅ **Implemented**: Home, Add Report, Map, Public Feed  
⚠️ **Issues**: Report detail incomplete, comments UI minimal

---

### Screen 2.1: Home Page (`/home`)
**Endpoints**: Multiple (`/api/reports/public`, `/api/categories`, etc.)

```
HOME PAGE - TABBED VIEW
┌─────────────────────────────┐
│ ← [AIN Logo] [🔔 Notifications]│ (Header)
│                             │
│ ┌───────┬───────┬───────┐   │
│ │ 🔥 الأحدث │📍 الخريطة │ ➕ إضافة  │ (Tab bar)
│ └───────┴───────┴───────┘   │
│                             │
│ ┌──────────────────────┐    │
│ │ [🔍 Search/Filter]  │    │ (Search + category filter)
│ │ ☐ All  ☐ Safety  ☐ │    │ (Quick category chips)
│ │ ☐ Roads ☐ Health... │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 📌 انقطاع الكهرباء   │    │ (Report card)
│ │ منطقة الزمالك        │    │
│ │ أمس في 2:30 م       │    │
│ │ ❤️ 23  💬 5  👁️ 142 │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 📌 حفر في الطريق    │    │ (Another report card)
│ │ شارع الرحاب          │    │
│ │ منذ 3 ساعات          │    │
│ │ ❤️ 45  💬 12  👁️ 256 │    │
│ └──────────────────────┘    │
│                             │
│ [↻ Pull to refresh]         │
│                             │
└─────────────────────────────┘

TAB FEATURES:
1. "الأحدث" (Latest) - Public report feed
2. "الخريطة" (Map) - Map view with pins
3. "➕ إضافة" (Add) - New report form

FEED FEATURES:
- Pull-to-refresh functionality
- Infinite scroll pagination
- Category filter chips (swipeable)
- Search by title/description
- Sort: Latest, Most Liked, Most Viewed

REPORT CARD DESIGN:
- Category icon + title
- Attachments
- Location (address)
- Time ago
- Like, comment, view counts
- Status badge (if applicable)
- Tap to view details
```

#### API Contract
```json
GET /api/reports/public?page=1&pageSize=20&categoryId=&search=&status=
Content-Type: application/json
Auth: AllowAnonymous

RESPONSE 200:
{
  "data": [
    {
      "id": "uuid",
      "title": "انقطاع الكهرباء",
      "description": "انقطاع متكرر...",
      "status": "UnderReview",
      "visibility": "Public",
      "categoryName": "Utilities",
      "subCategoryName": "Electricity",
      "latitude": 30.048,
      "longitude": 31.2357,
      "locationAddress": "Zamalek, Cairo",
      "createdAt": "2026-06-14T14:30:00Z",
      "attachments": [
        {
          "id": "uuid",
          "fileName": "photo.jpg",
          "filePath": "https://...",
          "contentType": "image/jpeg"
        }
      ],
      "likes": 23,
      "commentsCount": 5,
      "viewsCount": 142
    }
  ],
  "pageNumber": 1,
  "pageSize": 20,
  "totalCount": 1523,
  "hasNextPage": true
}
```

---

### Screen 2.2: Map View (`/map`)
**Endpoint**: `GET /api/reports/map-data`

```
MAP VIEW
┌─────────────────────────────┐
│ ← [AIN] [🔔]                │ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │                      │    │
│ │   [Google Map View]  │    │ (Clustered markers)
│ │   - Red pins for urgent
│ │   - Yellow pins for normal
│ │   - Blue pins for your reports
│ │   - Clustered markers (e.g., "23")
│ │                      │    │
│ ├──────────────────────┤    │
│ │ [🔍 Filter] [📍 My Location]│ (Bottom controls)
│ │ ☐ Safety ☐ Roads ☐ Health │
│ │ ☐ UnderReview ☐ Resolved  │
│ │ ☐ Rejected                │
│ └──────────────────────┘    │
│                             │
│ LEGEND (Collapsible):       │
│ 🔴 Urgent (Under Review)    │
│ 🟡 Normal (Normal)          │
│ 🟢 Resolved                 │
│ 🔵 My Reports               │
│                             │
└─────────────────────────────┘

TAP ON MARKER:
- Show info window with:
  - Report title
  - Category
  - Status badge
  - Like count
  - [View] button

FILTER BEHAVIOR:
- Filter by category
- Filter by status
- Apply live (re-query API)
- Show "X reports found"
```

#### API Contract
```json
GET /api/reports/map-data?categoryId=&status=&authorityId=
Header: Authorization: Bearer <token>
Content-Type: application/json

RESPONSE 200:
{
  "data": [
    {
      "id": "uuid",
      "latitude": 30.048,
      "longitude": 31.2357,
      "title": "انقطاع الكهرباء",
      "categoryName": "Utilities",
      "status": "UnderReview",
      "severity": "Standard",
      "locationName": "Zamalek, Cairo"
    }
  ]
}
```

---

### Screen 2.3: Add Report - Step 1 (`/report/new`)
**Endpoint**: `POST /api/reports` (multipart)

```
ADD REPORT - STEP 1: تفاصيل التقرير (Report Details)
┌─────────────────────────────┐
│ ◉ ◯ ◯  Progress: 33%      │ (Progress indicator)
│                             │
│ تفاصيل التقرير             │ (Header)
│                             │
│ ┌─────────────────────┐     │
│ │ 📝 العنوان          │     │
│ │ [مثال: انقطاع الكهرباء]   │ (Title field - max 200 chars)
│ │                     │     │
│ └─────────────────────┘     │
│ 0/200 characters           │ (Counter)
│                             │
│ ┌─────────────────────┐     │
│ │ 📝 الوصف            │     │
│ │ [اشرح المشكلة بالتفصيل]   │ (Long description)
│ │                     │     │
│ │ [مثال: انقطاع متكرر...]  │
│ └─────────────────────┘     │
│ 0/1000 characters          │ (Counter)
│                             │
│ ┌─────────────────────┐     │
│ │ 📂 الفئة             │     │ (Category dropdown)
│ │ [اختر من القائمة]   │     │
│ │ ▼ Safety            │     │
│ │   ☐ Accident        │     │ (Expanded subcategories)
│ │   ☐ Violence        │     │
│ │   ☐ Crime           │     │
│ └─────────────────────┘     │
│                             │
│ ┌─────────────────────┐     │
│ │ 👁️ الرؤية            │     │ (Visibility radio)
│ │ ◉ عام (Public)     │     │
│ │ ○ سري (Confidential)│     │
│ │ ○ مجهول (Anonymous)│     │
│ │                     │     │
│ │ ⓘ بيانات المبلغ:    │     │ (Info per visibility)
│ │   - عام: الاسم+صورة │
│ │   - سري: مخفية      │
│ │   - مجهول: مخفية    │
│ └─────────────────────┘     │
│                             │
│ [      ← الرجوع  |  التالي →      ]
└─────────────────────────────┘

VALIDATION:
- Title: Required, max 200 chars
- Description: Required, max 1000 chars
- Category: Required
- Visibility: Default to "Public"

VISIBILITY GUIDE:
- Public: Name + profile photo shown to all
- Confidential: Name + info shown to authorities only
- Anonymous: No reporter info visible
```

---

### Screen 2.4: Add Report - Step 2 (`/report/location`)
**Endpoint**: Uses map to pick location

```
ADD REPORT - STEP 2: تحديد الموقع (Select Location)
┌─────────────────────────────┐
│ ◯ ◉ ◯  Progress: 66%      │
│                             │
│ أين تقع المشكلة؟            │ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │                      │    │
│ │   [Google Map]       │    │
│ │   With drag marker   │    │
│ │   Center shows pin   │    │
│ │                      │    │
│ │   📍 (Center)        │    │
│ │                      │    │
│ ├──────────────────────┤    │
│ │ [📍 موقعي الحالي]     │    │ (Get current location)
│ │ [🔍 بحث]              │    │ (Search address)
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ الموقع المختار:      │    │
│ │ Zamalek, Cairo       │    │ (Selected address)
│ │ 30.048°, 31.2357°   │    │ (Coords)
│ │                      │    │
│ │ ⓘ يمكن سحب الدبوس   │    │ (Tip)
│ │   لتعديل الموقع      │    │
│ └──────────────────────┘    │
│                             │
│ [      ← الرجوع  |  التالي →      ]
└─────────────────────────────┘

MAP INTERACTIONS:
- Tap to place marker
- Drag marker to adjust
- Buttons:
  - Current Location (uses geolocator)
  - Search (reverse geocoding)
- Show address below map
- Auto-fill from geolocation on load
```

---

### Screen 2.5: Add Report - Step 3 (`/report/attachments`)
**Endpoint**: Prepare multipart upload

```
ADD REPORT - STEP 3: إضافة الوسائط (Attachments)
┌─────────────────────────────┐
│ ◯ ◯ ◉  Progress: 100%     │
│                             │
│ أضف صور أو فيديو (اختياري) │ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │ [الكاميرا] [المعرج]   │    │ (Upload buttons)
│ │ (Camera)   (Gallery)  │    │
│ └──────────────────────┘    │
│                             │
│ الملفات المرفوعة:           │ (Uploaded list)
│ ┌──────────────────────┐    │
│ │ 📷 photo1.jpg (3 MB) │ X  │ (Image with delete)
│ │ ├─ Processing...     │    │ (Progress)
│ │ ├─ [100% ✓]          │    │ (Completion)
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 📷 photo2.jpg (2 MB) │ X  │
│ │ [✓ تم التحميل]       │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 🎥 video1.mp4 (15MB)│ X  │
│ │ [85% ⏳]             │    │ (Still uploading)
│ └──────────────────────┘    │
│                             │
│ ⓘ الحد الأقصى 10 ملفات    │ (Info)
│   صور فقط أو فيديو        │
│   الحد الأقصى 50 MB لكل ملف│
│                             │
│ ┌────────────────────┐      │
│ │ ✓ إرسال التقرير    │      │ (Submit button)
│ └────────────────────┘      │ (Enabled only if step 1 & 2 valid)
│                             │
│ [      ← الرجوع  |          ]
└─────────────────────────────┘

UPLOAD BEHAVIOR:
- Max 10 files
- Max 50 MB per file
- Show upload progress per file
- Allow multiple selections from gallery
- Video thumbnails shown
- Swipeable list if many files

ON FINAL SUBMIT:
- Combine all data from steps 1-3
- Send as multipart/form-data:
  - Title, Description, SubCategoryId, Visibility
  - Latitude, Longitude
  - Attachments[] (array of files)
- Show uploading spinner
- Navigate to success screen
```

#### Final API Contract
```json
POST /api/reports
Header: Authorization: Bearer <token> (optional - AllowAnonymous)
Content-Type: multipart/form-data

FORM FIELDS:
- Title: "انقطاع الكهرباء"
- Description: "انقطاع متكرر منذ الصباح"
- SubCategoryId: "uuid"
- Visibility: "Public"
- Latitude: 30.048
- Longitude: 31.2357
- Attachments[0]: File (image1.jpg)
- Attachments[1]: File (image2.jpg)

RESPONSE 201:
{
  "id": "new-report-uuid",
  "message": "Report submitted successfully",
  "trackingNumber": "AIN-20260614-00123"
}
```

---

### Screen 2.6: Report Success (`/report/success`)
**No API call**

```
REPORT SUCCESS SCREEN
┌─────────────────────────────┐
│                             │
│      [Lottie Animation]     │
│      ✓ Large checkmark      │
│                             │
│      تم بنجاح!              │ (Success message)
│                             │
│      شكراً لإبلاغك          │ (Thank you message)
│                             │
│      تم استقبال تقريرك      │
│      وسيتم مراجعته قريباً   │
│                             │
│      رقم التتبع: AIN-XXXX-XX│ (Tracking number)
│                             │
│      تم إضافة 2 نقاط        │ (Trust points awarded)
│      للحساب الخاص بك!       │
│                             │
│ ┌────────────────────┐      │
│ │ العودة للرئيسية    │      │ (Primary button)
│ └────────────────────┘      │
│                             │
│ [عرض التقرير]               │ (Secondary link)
│                             │
└─────────────────────────────┘

ON CLOSE:
- Navigate to /home (feed tab)
- Refresh feed to show new report
- Update user trust points
```

---

### Screen 2.7: Report Detail (`/report/:id`)
**Endpoint**: `GET /api/reports/{id}` + social endpoints

```
REPORT DETAIL PAGE
┌─────────────────────────────┐
│ [← Back]  [Share] [...]     │ (Header with actions)
│                             │
│ ┌──────────────────────┐    │
│ │ [📷 Carousel]        │    │ (Image carousel)
│ │ ← Attachment 1/3 →   │    │
│ │                      │    │
│ │ [🔍 Fullscreen]      │    │ (Fullscreen button)
│ └──────────────────────┘    │
│                             │
│ 📌 انقطاع الكهرباء         │ (Title)
│ منطقة الزمالك, القاهرة     │ (Location)
│ أمس الساعة 2:30 PM         │ (Time)
│                             │
│ [Category Badge]            │ (Category chip)
│ [Status Badge]              │ (Status: UnderReview)
│                             │
│ ┌──────────────────────┐    │
│ │ 👤 المُبلِّغ         │    │ (Reporter - visibility based)
│ │                      │    │
│ │ [📷 Profile Photo]   │    │
│ │ أحمد محمد            │    │ (Name - if public)
│ │ 📍 Zamalek, Cairo    │    │ (Location - if public)
│ │ ⭐⭐⭐ Trusted (87 pts)│ (Trust badge - if public)
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ الوصف:               │    │
│ │                      │    │
│ │ انقطاع متكرر منذ     │    │
│ │ الصباح في شارع...   │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ ❤️ 23  💬 5  👁️ 142  │    │ (Engagement metrics)
│ │ [❤️ Like] [💬 Comment]    │ (Action buttons)
│ └──────────────────────┘    │
│                             │
│ COMMENTS SECTION:           │
│ ┌──────────────────────┐    │
│ │ التعليقات (5)         │    │ (Comment count)
│ │                      │    │
│ │ [👤 محمد علي]        │    │ (Comment author)
│ │ شارك تجربتي الشيء...  │    │ (Comment text)
│ │ منذ ساعة              │    │ (Time)
│ │ ❤️ 3  💬 Reply       │    │ (Comment actions)
│ │ ─────────────────    │    │
│ │   [👤 نور]           │    │ (Nested reply)
│ │   أنا أيضاً واجهت...   │    │
│ │   منذ 30 دقيقة       │    │
│ │   ❤️ 1  💬 Reply    │    │
│ │                      │    │
│ │ ┌──────────────────┐ │    │
│ │ │ [View more...]   │ │    │ (Load more link)
│ │ └──────────────────┘ │    │
│ └──────────────────────┘    │
│                             │
│ INPUT SECTION:              │ (Bottom input - sticky)
│ ┌──────────────────────┐    │
│ │ [👤 You] 💬 أضف تعليق ...│ (Comment input)
│ │                  [Send]   │
│ └──────────────────────┘    │
│                             │
└─────────────────────────────┘

REPORTER INFO VISIBILITY RULES:
┌────────────────┬─────────────┬──────────────┐
│ Report Type    │ Show Name?  │ Show ID Docs?│
├────────────────┼─────────────┼──────────────┤
│ Public         │ YES         │ NO           │
│ Confidential    │ NO (403)    │ NO           │
│ Anonymous      │ NO (403)    │ NO           │
└────────────────┴─────────────┴──────────────┘

ACTION BUTTONS (Bottom):
- [❤️ Like] - Toggle like, update count
- [💬 Comment] - Focus input field
- [Share] - Share via apps
- [...] - Delete (if owner), Report (if flagged)

OWNER ACTIONS (if current user = reporter):
- Edit visibility
- Delete report
- View analytics
```

#### API Contracts
```json
GET /api/reports/{id}
Content-Type: application/json
Auth: AllowAnonymous (Bearer if available)

RESPONSE 200:
{
  "id": "uuid",
  "title": "انقطاع الكهرباء",
  "description": "انقطاع متكرر...",
  "status": "UnderReview",
  "visibility": "Public",
  "latitude": 30.048,
  "longitude": 31.2357,
  "locationAddress": "Zamalek, Cairo",
  "categoryName": "Utilities",
  "subCategoryName": "Electricity",
  "createdAt": "2026-06-13T14:30:00Z",
  "attachments": [
    {
      "id": "uuid",
      "fileName": "photo.jpg",
      "filePath": "https://...",
      "contentType": "image/jpeg"
    }
  ],
  "reporter": {
    "id": "uuid",
    "name": "أحمد محمد",
    "profilePhotoUrl": "https://...",
    "nationalId": null,     ← null for citizens
    "idCardUrl": null,      ← null for citizens
    "idCardBackUrl": null   ← null for citizens
  },
  "likes": 23,
  "commentsCount": 5
}

---

GET /api/social/reports/{reportId}/comments
Content-Type: application/json
Auth: AllowAnonymous

RESPONSE 200:
{
  "data": [
    {
      "id": "comment-uuid",
      "content": "شارك تجربتي الشيء...",
      "authorId": "user-uuid",
      "authorName": "محمد علي",
      "authorProfilePhoto": "https://...",
      "createdAt": "2026-06-13T16:45:00Z",
      "likes": 3,
      "replies": [
        {
          "id": "reply-uuid",
          "content": "أنا أيضاً واجهت...",
          "authorName": "نور",
          ...
        }
      ]
    }
  ]
}

---

POST /api/social/reports/{reportId}/comments
Header: Authorization: Bearer <token>
Content-Type: application/json

REQUEST:
{
  "content": "أنا أيضاً أواجه نفس المشكلة",
  "parentCommentId": null  ← null for top-level, uuid for reply
}

RESPONSE 201:
{
  "id": "new-comment-uuid",
  "message": "Comment created"
}

---

POST /api/social/reports/{reportId}/like
Header: Authorization: Bearer <token>
Content-Type: application/json
Request Body: {} (empty - toggles like)

RESPONSE 200:
{
  "reportId": "uuid",
  "totalLikes": 24,
  "isLikedByCaller": true
}

---

PUT /api/reports/{id}/visibility
Header: Authorization: Bearer <token>
Content-Type: application/json

REQUEST:
{
  "visibility": "Confidential"  ← "Public" | "Confidential" | "Anonymous"
}

RESPONSE 200:
{
  "message": "Visibility updated"
}

---

DELETE /api/reports/{id}
Header: Authorization: Bearer <token>
Auth: Citizen/Admin/SuperAdmin (Authority=403)

RESPONSE 204: (No Content - success)

ERROR 403:
{
  "statusCode": 403,
  "message": "Only the report creator can delete it"
}
```

---

# 👤 SECTION 3: PROFILE & SETTINGS

## Current Status
✅ **Implemented**: Basic profile, edit, settings  
⚠️ **Issues**: Trust profile incomplete, leaderboard missing, change password not implemented

---

### Screen 3.1: Profile Page (`/profile`)
**Endpoint**: `GET /api/profile/my-profile`

```
PROFILE PAGE
┌─────────────────────────────┐
│ [Menu] [AIN] [Settings]     │ (Header)
│                             │
│ ╔═════════════════════╗     │
│ ║                     ║     │
│ ║    [👤 Avatar]      ║     │ (Profile section)
│ ║                     ║     │
│ ║  أحمد محمد           ║     │ (Display name)
│ ║  user@example.com   ║     │ (Email)
│ ║                     ║     │
│ ║  ⭐⭐⭐ Trusted      ║     │ (Trust badge)
│ ║  87 نقطة             ║     │ (Points)
│ ║                     ║     │
│ ║ [📝 تعديل الملف]     ║     │ (Edit profile link)
│ ╚═════════════════════╝     │
│                             │
│ ┌──────────────────────┐    │
│ │ 🏆 الإحصائيات        │    │ (Statistics section)
│ │                      │    │
│ │ تقارير مرسلة: 12     │    │
│ │ ❤️ تم تلقيه: 45      │    │
│ │ 💬 تعليقات: 23       │    │
│ │ 👁️ آخر تقرير: 156   │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 📊 البيانات           │    │ (Badge info)
│ │                      │    │
│ │ 🏷️ Trusted Badge    │    │
│ │ نقاط: 87             │    │
│ │ التالي: Guardian (100)│   │
│ │ التقدم: ████░░░░ 87% │    │
│ │                      │    │
│ │ [عرض التفاصيل]       │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ ⚙️ الإعدادات          │    │ (Settings options)
│ │                      │    │
│ │ [→ تغيير كلمة المرور]│    │
│ │ [→ الإشعارات]         │    │
│ │ [→ اللغة]             │    │
│ │ [→ عن التطبيق]       │    │
│ │ [→ تسجيل الخروج]      │    │
│ └──────────────────────┘    │
│                             │
└─────────────────────────────┘

PROFILE SECTIONS:
1. Avatar + Name + Email + Badge
2. Quick statistics
3. Badge progress to next level
4. Settings options

TRUST BADGE HIERARCHY:
- 🆕 Newcomer (0-20 pts)
- 👤 Contributor (21-60 pts)
- ⭐ Trusted (61-100 pts)
- 👑 Guardian (100+ pts)
```

#### API Contract
```json
GET /api/profile/my-profile
Header: Authorization: Bearer <token>
Content-Type: application/json

RESPONSE 200:
{
  "id": "uuid",
  "displayName": "أحمد محمد",
  "email": "user@example.com",
  "phoneNumber": "+201001234567",
  "profilePhotoUrl": "https://...",
  "trustPoints": 87,
  "badge": "Trusted",
  "reportsSubmitted": 12,
  "likesReceived": 45,
  "commentsCount": 23,
  "lastReportViews": 156
}
```

---

### Screen 3.2: Edit Profile (`/profile/edit`)
**Endpoint**: `PUT /api/profile/update-profile`

```
EDIT PROFILE PAGE
┌─────────────────────────────┐
│ [← Back] تعديل الملف الشخصي │ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │ ╔════════════════╗   │    │
│ │ ║                ║   │    │
│ │ ║  [👤 Avatar]   ║   │    │ (Profile photo - tap to edit)
│ │ ║                ║   │    │
│ │ ║   📷 تحميل     ║   │    │
│ │ ║                ║   │    │
│ │ ╚════════════════╝   │    │
│ │ [تغيير الصورة]       │    │
│ └──────────────────────┘    │
│                             │
│ ┌─────────────────────┐     │
│ │ اسم العرض          │     │
│ │ أحمد محمد           │     │
│ └─────────────────────┘     │
│                             │
│ ┌─────────────────────┐     │
│ │ رقم الهاتف          │     │
│ │ +20 100 1234567     │     │
│ └─────────────────────┘     │
│                             │
│ ┌────────────────────┐      │
│ │ حفظ التعديلات       │      │ (Primary button)
│ └────────────────────┘      │
│                             │
│ [← الرجوع]                  │
└─────────────────────────────┘

EDITABLE FIELDS:
- Display Name (required)
- Phone Number (optional)
- Profile Photo (optional)

ON SAVE:
- Validate inputs
- Show loading
- Upload photo if changed (multipart)
- Update fields via API
- Show success toast
- Refresh profile data
- Navigate back to /profile
```

#### API Contract
```json
PUT /api/profile/update-profile
Header: Authorization: Bearer <token>
Content-Type: multipart/form-data

FORM FIELDS:
- DisplayName: "أحمد محمد" (optional)
- PhoneNumber: "+201001234567" (optional)
- ProfilePhoto: File (optional)

RESPONSE 200:
{
  "isSuccess": true,
  "message": "Profile updated",
  "user": {
    "displayName": "أحمد محمد",
    "phoneNumber": "+201001234567",
    "profilePhotoUrl": "https://..."
  }
}
```

---

### Screen 3.3: Change Password (`/change-password`)
**MISSING** ❌

Already described in Section 1.5 above (same screen, different access point)

---

### Screen 3.4: Trust & Badges (`/profile/trust`)
**Endpoint**: `GET /api/social/me/trust` (if implemented)

```
TRUST & ACHIEVEMENTS PAGE
┌─────────────────────────────┐
│ [← Back] الشارات والإنجازات│ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │ إجمالي النقاط:       │    │ (Total points)
│ │ 87 نقطة              │    │
│ │                      │    │
│ │ الشارة الحالية:      │    │
│ │ ⭐ Trusted          │    │
│ │ اكتساب 87 نقطة       │    │
│ │ التالي: Guardian (13) │   │ (Pts to next badge)
│ └──────────────────────┘    │
│                             │
│ PROGRESS TO NEXT BADGE:     │
│ ████████░ 87/100 (87%)     │
│                             │
│ BADGE UNLOCK HISTORY:       │
│ ┌──────────────────────┐    │
│ │ 🆕 Newcomer         │    │ (Unlocked badges)
│ │ تم الحصول عليها: 2024-01-15 │
│ │ السبب: Created account    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 👤 Contributor      │    │
│ │ تم الحصول عليها: 2024-03-20 │
│ │ السبب: Submitted 5 reports│
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ ⭐ Trusted          │    │
│ │ تم الحصول عليها: 2024-05-10 │
│ │ السبب: Reached 60 points │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 👑 Guardian (Locked)│    │ (Locked badge)
│ │ تحتاج إلى: 13 نقاط أخرى│
│ │ السبب: Reach 100 points │
│ └──────────────────────┘    │
│                             │
│ POINTS BREAKDOWN:           │
│ ┌──────────────────────┐    │
│ │ كيف حصلت على النقاط:  │    │
│ │                      │    │
│ │ 📝 تقرير مرسل: +2    │    │
│ │ ✓ تقرير تم حله: +10  │    │
│ │ ❤️ إعجاب مستقبل: +1  │    │
│ │ 🗑️ تقرير محذوف: -2   │    │
│ │ ✗ تقرير مرفوض: -2    │    │
│ └──────────────────────┘    │
│                             │
│ [مشاهدة التفاصيل]           │ (View detailed history)
│                             │
└─────────────────────────────┘
```

#### API Contract
```json
GET /api/social/me/trust
Header: Authorization: Bearer <token>
Content-Type: application/json

RESPONSE 200:
{
  "userId": "uuid",
  "displayName": "أحمد محمد",
  "trustPoints": 87,
  "badge": "Trusted",
  "nextBadge": "Guardian",
  "pointsToNextBadge": 13,
  "badges": [
    {
      "name": "Newcomer",
      "unlockedAt": "2024-01-15T10:00:00Z",
      "reason": "Account created"
    }
  ],
  "pointsBreakdown": {
    "reportsSubmitted": 24,    ← 12 * 2
    "reportsResolved": 20,     ← 2 * 10
    "likesReceived": 45,
    "reportsDeleted": -2,      ← -1 * 2
    "reportsRejected": -2      ← -1 * 2
  }
}
```

---

### Screen 3.5: Leaderboard (`/profile/leaderboard`)
**MISSING** ❌

```
LEADERBOARD PAGE
┌─────────────────────────────┐
│ [← Back] لوحة الصدارة      │ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │ [This Week] [Month]  │    │ (Time period tabs)
│ │ [All Time]           │    │
│ └──────────────────────┘    │
│                             │
│ YOUR RANK:                  │
│ #42 out of 1,234 users     │
│                             │
│ TOP USERS:                  │
│ ┌──────────────────────┐    │
│ │ 🥇 محمد علي  (156 pts)│   │ (1st place)
│ │ ⭐⭐⭐ Trusted        │    │
│ │ 📊 12 reports, 45 likes   │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 🥈 فاطمة أحمد  (142 pts)│  │ (2nd place)
│ │ ⭐⭐ Contributor    │    │
│ │ 📊 8 reports, 38 likes    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 🥉 أحمد محمد  (87 pts)│   │ (3rd place - CURRENT USER)
│ │ ⭐⭐⭐ Trusted        │    │ (YOU)
│ │ 📊 12 reports, 30 likes   │
│ └──────────────────────┘    │
│                             │
│ ... (more users)            │
│                             │
│ ┌──────────────────────┐    │
│ │ 42. You  (87 pts)    │    │ (Current user highlight)
│ │ ⭐⭐⭐ Trusted         │    │
│ │ 📊 12 reports, 45 likes   │
│ │ [View Profile]            │
│ └──────────────────────┘    │
│                             │
│ ⓘ نقاطك تُحدّث كل ساعة    │ (Info)
│                             │
└─────────────────────────────┘
```

---

### Screen 3.6: Settings (`/settings`)
**No API call**

```
SETTINGS PAGE
┌─────────────────────────────┐
│ [← Back] الإعدادات          │ (Header)
│                             │
│ ACCOUNT SECTION:            │
│ ┌──────────────────────┐    │
│ │ [→ تغيير كلمة المرور]│    │ (Change password)
│ │ [→ البريد الإلكتروني]│    │ (Email)
│ │ [→ رقم الهاتف]       │    │ (Phone)
│ └──────────────────────┘    │
│                             │
│ NOTIFICATIONS:              │
│ ┌──────────────────────┐    │
│ │ ☑️ نشاط في التقارير │    │ (Report activity toggle)
│ │ ☑️ رسائل مباشرة     │    │ (Messages toggle)
│ │ ☑️ أخبار النظام     │    │ (System updates toggle)
│ │ ☑️ تنبيهات الطوارئ  │    │ (Emergency alerts toggle)
│ └──────────────────────┘    │
│                             │
│ APPEARANCE:                 │
│ ┌──────────────────────┐    │
│ │ الوضع: ◉ Dark ○ Light│   │ (Dark/Light mode)
│ │                      │    │
│ │ اللغة: ◉ العربية     │    │ (Language)
│ │        ○ English      │    │
│ └──────────────────────┘    │
│                             │
│ LOCATION:                   │
│ ┌──────────────────────┐    │
│ │ ☑️ مشاركة الموقع    │    │ (Share location toggle)
│ │ ⓘ لتحسين البحث      │    │
│ │   عن التقارير       │    │
│ └──────────────────────┘    │
│                             │
│ ABOUT:                      │
│ ┌──────────────────────┐    │
│ │ [→ عن التطبيق]      │    │ (About app)
│ │ [→ الشروط والأحكام] │    │ (Terms & conditions)
│ │ [→ سياسة الخصوصية]  │    │ (Privacy policy)
│ │ [→ تقييم التطبيق]   │    │ (Rate app)
│ │ [→ الإبلاغ عن خطأ]  │    │ (Report bug)
│ └──────────────────────┘    │
│                             │
│ DANGER ZONE:                │
│ ┌──────────────────────┐    │
│ │ [🚪 تسجيل الخروج]   │    │ (Logout button)
│ │ [🗑️ حذف الحساب]      │    │ (Delete account)
│ └──────────────────────┘    │
│                             │
│ Version: 1.0.0              │ (Version info)
│ Build: 47                   │
│                             │
└─────────────────────────────┘

ACTIONS:
- Change password → Navigate to /change-password
- Logout → Call SignOut API + Clear storage + Go to /login
- Delete account → Confirmation dialog
```

#### Logout API Contract
```json
POST /api/account/signOut
Header: Authorization: Bearer <token>
Content-Type: application/json
Request Body: {} (empty)

RESPONSE 200:
{
  "message": "Logged out successfully"
}

AFTER LOGOUT:
- Clear JWT token from SecureStorage
- Clear all cached data
- Reset app state
- Navigate to /login
- Show "تم تسجيل الخروج" (Logged out) toast
```

---

# 👥 SECTION 4: COMMUNITIES & SOS

## Current Status
✅ **Implemented**: Community CRUD, join, SOS trigger  
⚠️ **Issues**: SOS community history UI missing, member interaction limited

---

### Screen 4.1: Communities List (`/communities`)
**Endpoint**: `GET /api/community`

```
COMMUNITIES PAGE
┌─────────────────────────────┐
│ [Menu] المجتمعات [+ Create]│ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │ [🔍 Search/Filter]  │    │
│ │ ☐ Active  ☐ Nearby  │    │
│ │ ☐ All               │    │
│ └──────────────────────┘    │
│                             │
│ JOINED COMMUNITIES:         │
│ ┌──────────────────────┐    │
│ │ 👥 الزمالك كوميونتي │    │ (Community card)
│ │ 45 أعضاء             │    │
│ │ 3 تنبيهات نشطة      │    │ (Active SOS alerts)
│ │ ┌────────┬────────┐  │    │
│ │ │[👤 Mbr]│[👤 Mbr]│  │    │ (Member avatars)
│ │ └────────┴────────┘  │    │
│ │ [View] [Invite]      │    │ (Actions)
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 👥 مجتمع الحي        │    │
│ │ 32 أعضاء             │    │
│ │ 0 تنبيهات نشطة       │    │
│ │ ┌────────┬────────┐  │    │
│ │ │[👤 Mbr]│[👤 Mbr]│  │    │
│ │ └────────┴────────┘  │    │
│ │ [View] [Leave]       │    │ (Leave option)
│ └──────────────────────┘    │
│                             │
│ ┌────────────────────┐      │
│ │ ➕ إنشاء مجتمع     │      │ (Create button)
│ └────────────────────┘      │
│                             │
│ ┌────────────────────┐      │
│ │ 🔗 الانضمام برمز   │      │ (Join by code)
│ └────────────────────┘      │
│                             │
└─────────────────────────────┘
```

#### API Contract
```json
GET /api/community
Header: Authorization: Bearer <token>
Content-Type: application/json

RESPONSE 200:
{
  "data": [
    {
      "id": "uuid",
      "name": "الزمالك كوميونتي",
      "memberCount": 45,
      "activeSosAlerts": 3,
      "members": [
        {
          "userId": "uuid",
          "displayName": "أحمد",
          "profilePhotoUrl": "https://..."
        }
      ]
    }
  ]
}
```

---

### Screen 4.2: Create Community (`/communities/create`)
**Endpoint**: `POST /api/community`

```
CREATE COMMUNITY PAGE
┌─────────────────────────────┐
│ [← Back] إنشاء مجتمع جديد  │ (Header)
│                             │
│ ┌─────────────────────┐     │
│ │ اسم المجتمع        │     │
│ │ [مثال: الزمالك]     │     │ (Community name)
│ │                     │     │
│ └─────────────────────┘     │
│                             │
│ ┌─────────────────────┐     │
│ │ الوصف (اختياري)     │     │
│ │ [مجتمع الزمالك...]  │     │
│ │                     │     │
│ └─────────────────────┘     │
│                             │
│ ┌─────────────────────┐     │
│ │ موقع المجتمع       │     │
│ │ [Map preview]       │     │ (Optional location)
│ │ تحديد على الخريطة  │     │
│ │ +20 100 1234567     │     │ (Center coordinates)
│ │                     │     │
│ └─────────────────────┘     │
│                             │
│ ┌─────────────────────┐     │
│ │ نطاق الخدمة (كم)   │     │
│ │ [   5.0      ]      │     │ (Radius in KM)
│ │ ⓘ تحديد النطاق      │     │
│ │   الجغرافي للمجتمع  │     │
│ └─────────────────────┘     │
│                             │
│ ┌────────────────────┐      │
│ │ إنشاء المجتمع      │      │ (Primary button)
│ └────────────────────┘      │
│                             │
│ [← الرجوع]                  │
└─────────────────────────────┘

VALIDATION:
- Name: Required, 3-100 chars
- Description: Optional
- Location: Auto-filled from user location
- Radius: Default 5 km, min 1, max 50 km
```

#### API Contract
```json
POST /api/community
Header: Authorization: Bearer <token>
Content-Type: application/json

REQUEST:
{
  "name": "الزمالك كوميونتي",
  "description": "مجتمع سكان منطقة الزمالك"
}

RESPONSE 201:
{
  "id": "new-community-uuid",
  "name": "الزمالك كوميونتي",
  "message": "Community created successfully",
  "inviteCode": "ZAMA-12AB"
}

ON SUCCESS:
- Navigate to /communities/{id}
- Show success toast
```

---

### Screen 4.3: Community Detail (`/communities/:id`)
**Endpoint**: `GET /api/community/{id}`

```
COMMUNITY DETAIL PAGE
┌─────────────────────────────┐
│ [← Back] الزمالك كوميونتي  │ (Header)
│           [...]             │ (More options)
│                             │
│ ┌──────────────────────┐    │
│ │ 👥 المجتمع          │    │ (Community info)
│ │                      │    │
│ │ الأعضاء: 45          │    │
│ │ تنبيهات نشطة: 3      │    │
│ │ تاريخ الإنشاء: 2024-01-15 │
│ │                      │    │
│ │ [📍 الموقع على الخريطة]   │
│ │ رمز الدعوة: ZAMA-12AB│    │
│ │ [📋 نسخ الرمز]      │    │
│ └──────────────────────┘    │
│                             │
│ ┌─────────────────────┐     │
│ │ [➕ إضافة عضو]     │     │ (Add member button)
│ │ [📢 دعوة أصدقاء]   │     │ (Invite friends)
│ └─────────────────────┘     │
│                             │
│ ACTIVE SOS ALERTS: (3)      │
│ ┌──────────────────────┐    │
│ │ 🚨 تنبيه محمد علي   │    │ (SOS trigger)
│ │ منذ 2 دقيقة          │    │ (Time)
│ │ 📍 Zamalek, Cairo    │    │ (Location)
│ │ شدة: 🔴 High        │    │ (Severity)
│ │ [عرض]                │    │ (View button)
│ └──────────────────────┘    │
│                             │
│ MEMBERS: (45)               │
│ ┌──────────────────────┐    │
│ │ 👤 محمد علي         │    │ (Member card)
│ │ ⭐⭐⭐ Trusted      │    │ (Badge)
│ │ آخر تحديث: منذ 5 دقائق   │
│ │ 📍 Zamalek, Cairo    │    │
│ │ [Profile] [Message]  │    │ (Actions)
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 👤 فاطمة أحمد       │    │
│ │ ⭐⭐ Contributor    │    │
│ │ آخر تحديث: منذ 1 ساعة    │
│ │ [Profile]            │    │
│ └──────────────────────┘    │
│                             │
│ [عرض جميع الأعضاء] (45)    │
│                             │
│ ┌────────────────────┐      │
│ │ مغادرة المجتمع     │      │ (Leave button)
│ └────────────────────┘      │
│                             │
└─────────────────────────────┘
```

#### API Contract
```json
GET /api/community/{communityId}
Header: Authorization: Bearer <token>
Content-Type: application/json

RESPONSE 200:
{
  "id": "uuid",
  "name": "الزمالك كوميونتي",
  "memberCount": 45,
  "activeSosAlerts": 3,
  "createdAt": "2024-01-15T10:00:00Z",
  "inviteCode": "ZAMA-12AB",
  "members": [
    {
      "userId": "uuid",
      "displayName": "محمد علي",
      "profilePhotoUrl": "https://...",
      "badge": "Trusted",
      "lastUpdateTime": "2026-06-14T16:50:00Z",
      "latitude": 30.048,
      "longitude": 31.2357
    }
  ],
  "sosAlerts": [
    {
      "id": "uuid",
      "triggeredBy": "محمد علي",
      "triggeredAt": "2026-06-14T16:52:00Z",
      "latitude": 30.048,
      "severity": "High"
    }
  ]
}
```

---

### Screen 4.4: SOS Trigger (`/sos`)
**Endpoint**: `POST /api/sosalerts/trigger`

```
SOS PAGE - EMERGENCY ALERTS
┌─────────────────────────────┐
│ [Menu] SOS [Notifications]  │ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │ اختر مجتمعك:        │    │
│ │ [Dropdown ▼]         │    │ (Community selector)
│ │ الزمالك كوميونتي    │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ شدة التنبيه:         │    │
│ │ ◉ عادي (Standard)   │    │ (Severity radio)
│ │ ○ عالي (High)       │    │
│ │ ○ حرج (Critical)    │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ رسالة (اختياري):     │    │
│ │ [أحتاج إلى مساعدة...]│    │ (Message field)
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ تحديث الموقع تلقائياً:    │
│ │ ☑️ نعم                │    │ (Auto-location toggle)
│ │ ⓘ سيتم إرسال موقعك  │    │
│ │   كل 30 ثانية        │    │
│ └──────────────────────┘    │
│                             │
│ ALERT DURATION:             │
│ ┌──────────────────────┐    │
│ │ مدة التنبيه:         │    │
│ │ ◉ 30 دقيقة           │    │ (Duration radio)
│ │ ○ 1 ساعة             │    │
│ │ ○ 2 ساعة             │    │
│ │ ○ بلا توقيت          │    │
│ └──────────────────────┘    │
│                             │
│ ┌────────────────────┐      │
│ │ 🚨 تفعيل SOS       │      │ (Primary button - RED)
│ └────────────────────┘      │
│                             │
│ [← الرجوع]                  │
│                             │
│ ACTIVE ALERTS (You):        │ (If user has active SOS)
│ ┌──────────────────────┐    │
│ │ 🚨 SOS نشط           │    │
│ │ الزمالك كوميونتي    │    │
│ │ منذ 5 دقائق          │    │
│ │ 📍 Location tracking │    │
│ │ [عرض] [الغاء]        │    │
│ └──────────────────────┘    │
│                             │
└─────────────────────────────┘
```

#### API Contract
```json
POST /api/sosalerts/trigger
Header: Authorization: Bearer <token>
Content-Type: application/json

REQUEST:
{
  "communityId": "uuid",
  "severity": "High",     ← "Standard" | "High" | "Critical"
  "message": "أحتاج إلى مساعدة",
  "durationMinutes": 30,
  "latitude": 30.048,
  "longitude": 31.2357
}

RESPONSE 201:
{
  "id": "new-sos-uuid",
  "status": "Active",
  "severity": "High",
  "triggeredAt": "2026-06-14T16:55:00Z",
  "message": "SOS triggered successfully"
}

ON SUCCESS:
- Show success animation
- Display active SOS card
- Start auto-location updates (if enabled)
- Show countdown timer
```

---

### Screen 4.5: SOS Community History (`/communities/:id/sos-history`)
**MISSING** ❌

**Endpoint**: `GET /api/sosalerts/community/{communityId}`

```
SOS HISTORY PAGE
┌─────────────────────────────┐
│ [← Back] سجل التنبيهات      │ (Header)
│                             │
│ الزمالك كوميونتي            │ (Community name)
│                             │
│ ACTIVE SOS ALERTS: (1)      │
│ ┌──────────────────────┐    │
│ │ 🚨 🔴 تنبيه حرج      │    │ (Active alert)
│ │ محمد علي              │    │ (Triggered by)
│ │ الآن (2 دقائق)        │    │ (Time)
│ │ 📍 Zamalek, Cairo    │    │ (Location)
│ │ الشدة: 🔴 حرج        │    │
│ │ [عرض على الخريطة]    │    │
│ │ [عرض المزيد]         │    │
│ └──────────────────────┘    │
│                             │
│ PAST ALERTS: (12)           │
│ ┌──────────────────────┐    │
│ │ ✓ تنبيه تم حله       │    │ (Resolved - green)
│ │ فاطمة أحمد            │    │
│ │ أمس في 3:30 م        │    │
│ │ شدة: 🟡 عالي         │    │ (Yellow severity)
│ │ تم الحل بعد: 15 دقيقة│    │
│ │ تم الحل بواسطة: سلطة │    │
│ │ [عرض التفاصيل]       │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ X إلغاء             │    │ (Cancelled - gray)
│ │ نور                  │    │
│ │ 2 يوم مضى             │    │
│ │ شدة: 🟢 عادي         │    │ (Green severity)
│ │ [عرض التفاصيل]       │    │
│ └──────────────────────┘    │
│                             │
│ [عرض المزيد] (Load more)    │
│                             │
│ FILTERS:                    │
│ ☐ نشط ☐ تم الحل           │
│ ☐ ملغي ☐ كاذب             │
│                             │
└─────────────────────────────┘
```

#### API Contract
```json
GET /api/sosalerts/community/{communityId}?status=&page=1&pageSize=20
Header: Authorization: Bearer <token>
Content-Type: application/json

RESPONSE 200:
{
  "data": [
    {
      "id": "uuid",
      "status": "Active",              ← "Active" | "Resolved" | "Cancelled" | "FalseAlarm"
      "severity": "Critical",          ← "Standard" | "High" | "Critical"
      "triggeredBy": "محمد علي",
      "triggeredAt": "2026-06-14T16:55:00Z",
      "resolvedAt": null,
      "resolvedBy": null,
      "latitude": 30.048,
      "longitude": 31.2357,
      "message": "أحتاج إلى مساعدة"
    }
  ],
  "pageNumber": 1,
  "pageSize": 20,
  "totalCount": 15,
  "hasNextPage": false
}
```

---

# 🔔 SECTION 5: NOTIFICATIONS & MISC

## Current Status
✅ **Implemented**: Notifications page  
⚠️ **Issues**: Real-time integration, categorization

---

### Screen 5.1: Notifications (`/notifications`)
**Endpoint**: Local + push notifications

```
NOTIFICATIONS PAGE
┌─────────────────────────────┐
│ [Menu] الإشعارات [...]      │ (Header)
│                             │
│ ┌──────────────────────┐    │
│ │ [عرض الكل]           │    │
│ │ [تقارير]             │    │ (Category filter tabs)
│ │ [SOS]                │    │
│ │ [اجتماعي]            │    │
│ │ [نظام]               │    │
│ └──────────────────────┘    │
│                             │
│ TODAY:                      │ (Date header)
│ ┌──────────────────────┐    │
│ │ 🔴 تنبيه SOS جديد   │    │ (SOS notification - red)
│ │ محمد علي في الزمالك │    │
│ │ الآن                 │    │
│ │ [عرض]  [x تجاهل]    │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 💬 تعليق جديد       │    │ (Social notification)
│ │ فاطمة ردت على       │    │
│ │ تقريرك              │    │
│ │ منذ 30 دقيقة         │    │
│ │ [عرض]               │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ ✓ تقرير تم حله      │    │ (Report status)
│ │ تقريرك عن انقطاع     │    │
│ │ الكهرباء تم حله      │    │
│ │ الكسب: +10 نقاط     │    │
│ │ منذ 1 ساعة           │    │
│ │ [عرض]               │    │
│ └──────────────────────┘    │
│                             │
│ YESTERDAY:                  │
│ ┌──────────────────────┐    │
│ │ ❤️ إعجاب جديد       │    │ (Social engagement)
│ │ 5 أشخاص أعجبوا      │    │
│ │ بتقريرك             │    │
│ │ الكسب: +5 نقاط     │    │
│ │ [عرض]               │    │
│ └──────────────────────┘    │
│                             │
│ ┌──────────────────────┐    │
│ │ 📢 انضمام عضو جديد  │    │ (Community notification)
│ │ 2 أشخاص انضموا      │    │
│ │ لمجتمعك الزمالك     │    │
│ │ [عرض]               │    │
│ └──────────────────────┘    │
│                             │
│ [عرض المزيد]  (Load more)   │
│                             │
│ [Mark all as read]          │ (Bulk action)
│ [Clear all]                 │
│                             │
└─────────────────────────────┘

NOTIFICATION TYPES:
- 🚨 SOS (Emergency alerts in your communities)
- 💬 Social (Comments, replies, likes on your content)
- ✓ Status (Your reports status changed)
- 📢 Community (Members joined, invites)
- ℹ️ System (App updates, announcements)

TAP ACTION:
- Report notifications → Go to /report/:id
- SOS notifications → Go to /sos/:id
- Social notifications → Go to /report/:id (comment section)
- Community → Go to /communities/:id
```

---

# 📋 SUMMARY: MISSING SCREENS & GAPS

## ❌ SCREENS NOT IMPLEMENTED

1. **Password Recovery Screen** → `/forgot-password`
2. **Reset Password Screen** → `/reset-password` (deep link)
3. **Change Password Screen** → `/change-password`
4. **SOS Community History** → `/communities/:id/sos-history`
5. **Trust & Badges Detail** → `/profile/trust`
6. **Leaderboard** → `/profile/leaderboard`

---

## ⚠️ SCREEN ISSUES & ENHANCEMENTS NEEDED

| Screen | Current Issue | Required Fix |
|--------|---------------|--------------|
| Report Detail | Minimal comment UI | Add threaded comments, nested replies |
| Report Detail | No reporter visibility rules | Implement role-based masking |
| Profile | Trust points not detailed | Show points breakdown + history |
| Community Detail | Limited member interaction | Show member trust profiles + location map |
| SOS Page | No active SOS display | Show active alert card + countdown |
| Notifications | Basic implementation | Add real-time push + categories |
| Add Report | Multiple steps in UI but state unclear | Confirm multi-step state preservation |

---

## 🔧 DATA MODEL STANDARDIZATION ISSUES

1. **Profile Photo URL** - 12+ field name variants checked
   - **Fix**: Use only `profilePhotoUrl` from API
   
2. **SOS Status/Severity** - Hardcoded array indices
   - **Fix**: Use proper enum mapping
   
3. **User ID** - 5+ field names checked
   - **Fix**: Standardize to `id` or `userId`

4. **Reporter Info Masking** - Not fully implemented
   - **Fix**: Implement full visibility matrix per API spec

---

## ✅ RECOMMENDED IMPLEMENTATION ORDER

### Phase 1: Password Management (HIGH PRIORITY)
1. Create ForgotPasswordScreen
2. Create ResetPasswordScreen
3. Create ChangePasswordScreen
4. Implement API integration

### Phase 2: Enhanced Social Features (MEDIUM)
1. Improve comment thread UI
2. Add comment reply UI
3. Implement comment deletion
4. Show like animations

### Phase 3: Trust & Gamification (MEDIUM)
1. Create TrustProfileScreen
2. Create LeaderboardScreen
3. Show points breakdown
4. Badge unlock animations

### Phase 4: SOS Enhancements (MEDIUM)
1. Create SOS community history screen
2. Implement real-time status updates
3. Add location tracking visualization
4. Show responder list

### Phase 5: UI/UX Polish (LOW)
1. Standardize error handling
2. Consistent loading states
3. Unified empty states
4. Animation consistency

---

## 🎯 ENDPOINT COVERAGE

**Total Backend Endpoints**: 35+  
**Implemented in UI**: 32  
**Missing UI for**: 3 (password management)  
**Rate**: 91% coverage

```
✅ Auth (8/8 endpoints implemented)
✅ Reports (8/8 endpoints)
✅ Categories (3/3 endpoints)
✅ Profile (2/2 endpoints)
⚠️ SOS (6/7 endpoints - no community history UI)
⚠️ Community (5/7 endpoints - limited member interaction)
⚠️ Social (2/5 endpoints - comments/likes minimal)
⚠️ Notifications (partial implementation)
```

---

## 🚀 NEXT STEPS FOR DESIGNER/DEVELOPER

1. **Review** this prompt against current screens
2. **Prioritize** the 6 missing screens by business value
3. **Implement** Phase 1 screens (password management) first
4. **Test** all API integrations match endpoint contracts exactly
5. **Standardize** data models per API specification
6. **Add** real-time updates (SignalR for SOS/Community)
7. **Polish** UI consistency across all screens

---

**Document Generated**: June 14, 2026  
**App Version**: 1.0.0 (In Development)  
**Backend API Version**: v1.0  
**Last Updated**: June 14, 2026
