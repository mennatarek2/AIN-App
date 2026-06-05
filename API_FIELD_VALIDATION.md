# Add Report API - Field Mapping & Validation

## API Request Format

### Endpoint
```
POST /api/Reports
Content-Type: multipart/form-data
Authorization: Bearer {token}
```

### Required Fields

| Field | Type | Origin in UI | Validation |
|-------|------|--------------|-----------|
| Title | String | Text input "عنوان البلاغ" | Not empty, < 500 chars |
| Description | String | Text input "وصف البلاغ" | Not empty, < 5000 chars |
| SubCategoryId | UUID | Selected subcategory ID | Must match one of the predefined IDs |
| Latitude | Double | Selected map location | Valid coordinate |
| Longitude | Double | Selected map location | Valid coordinate |
| Visibility | String | Dropdown "الظهور" | Must be: Public, Anonymous, or Confidential |
| Image | File | Image picker | Optional, JPG/PNG, < 5MB |

---

## Visibility Mapping

The Arabic UI values are converted to English API values:

| Arabic (UI) | English (API) | Meaning |
|---|---|---|
| عام | Public | Visible to all users |
| مجهول | Anonymous | Visible but without user name |
| سري | Confidential | Only visible to admins |

**Code Location:** `lib/features/home/presentation/pages/add_report_page.dart`
```dart
String _mapVisibilityToApi(String value) {
  switch (value) {
    case 'عام':
      return 'Public';
    case 'مجهول':
      return 'Anonymous';
    case 'سري':
      return 'Confidential';
    default:
      return 'Public';
  }
}
```

---

## Category & Subcategory IDs

### Categories with SubCategoryIds

#### الأمن (Security)
- **ﺳطو** (Robbery): `4364b582-d500-4762-80fb-4ef7501a7ec6`
- **ﺳرﻗﺔ** (Theft): `3087d4ea-352b-4c35-8f1f-e5f508b009fd`

#### السلامة العامة (Public Safety)
- **ﻣواد ﺧطرة** (Hazardous materials): `0d7b168e-d6ea-48b9-b78f-6bdb70a7e1a1`
- **مشاكل المواصلات** (Transportation issues): `59eb1e96-57be-4d3b-a131-520fdc5e69d7`
- **تلف الطرق** (Road damage): `660e8400-e29b-41d4-a716-446655440000`

#### الحوادث المنزلية (Home Accidents)
- **حوادث داخل المنزل** (Home accidents): `b8c89a18-86cc-49f4-bd4d-a6e771625056`
- **إصابات منزلية** (Home injuries): `d445ddd4-f37d-4866-a774-b26d7b481ca7`
- **حرائق** (Fires): `1c556438-f145-4298-97e6-d9af5ad6ab17`

#### المرافق العامة (Public Utilities)
- **انقطاع المياه** (Water outage): `fee18c42-a2a1-4db6-9be0-c3fd83886f6f`
- **انقطاع الكهرباء** (Power outage): `034e5a26-4fd8-4f83-ac4f-c40d4c5f2364`
- **مشاكل الصرف الصحي** (Sewage issues): `8f5d66d4-6a48-4754-a2f0-cce8a48457ef`

#### مشاكل إلكترونية (Electronic Issues)
- **الاختراق** (Hacking): `4379a043-16e7-4206-94fc-4d30097cd84d`
- **التنمر الإلكتروني** (Cyberbullying): `a69a3f06-152b-44a8-a6f7-34e7343dba5a`
- **الاحتيال** (Fraud): `5a19f80f-f265-46cb-b53c-a0890c72ca58`
- **إساءة الاستخدام** (Abuse): `d5f4f7c4-34c7-4fbf-a4ec-56f95ed9f1d4`

#### أخرى (Other)
- No subcategories (uses category name as type)

---

## Form Validation Rules

### Title Validation
- ✓ Must not be empty
- ✓ Must be trimmed (spaces removed)
- ✓ Shown in error: "يرجى تعبئة جميع الحقول المطلوبة"

### Description Validation
- ✓ Must not be empty
- ✓ Must be trimmed
- ✓ Shown in error: "يرجى تعبئة جميع الحقول المطلوبة"

### Category Validation
- ✓ Must be selected from dropdown
- ✓ Must have valid category option
- ✓ Shown in error: "يرجى تعبئة جميع الحقول المطلوبة"

### Subcategory Validation
- ✓ Must be selected if parent category has subcategories
- ✓ Must have valid SubCategoryId
- ✓ Shown in error: "يرجى اختيار التصنيف الفرعي قبل الإرسال" or "تعذر تحديد معرف التصنيف الفرعي"

### Location Validation
- ✓ Must be selected on map
- ✓ Must have valid Latitude and Longitude
- ✓ Shown in error: "يرجى اختيار موقع البلاغ على الخريطة"

### Visibility Validation
- ✓ Must be selected from dropdown
- ✓ Must be one of: عام, مجهول, سري
- ✓ Shown in error: "يرجى تعبئة جميع الحقول المطلوبة"

### Image Validation
- ✓ Must be selected (required)
- ✓ Shown in error: "يرجى تعبئة جميع الحقول المطلوبة"
- ℹ️ Image quality reduced to 80%, max width 1440px for optimization

---

## Error Scenarios

### Scenario 1: Missing Token
```
Error Message: "حدث خطأ أثناء إرسال البلاغ: يرجى تسجيل الدخول أولا"
Console Log: [API] Error: Missing auth token
Reason: User not authenticated or token expired
Fix: User needs to log in again
```

### Scenario 2: Missing SubCategoryId
```
Error Message: "حدث خطأ أثناء إرسال البلاغ: يرجى اختيار التصنيف الفرعي"
Console Log: [ReportSync] Cannot sync: missing subCategoryId
Reason: Subcategory not properly selected
Fix: User needs to select from both category and subcategory dropdowns
```

### Scenario 3: Network Error
```
Error Message: "حدث خطأ أثناء إرسال البلاغ: لا يوجد اتصال بالإنترنت"
Console Log: [ReportSync] Device offline - saving report as pending sync
Reason: No internet connection
Fix: User needs internet connection; report will sync when online
```

### Scenario 4: API Server Error
```
Error Message: "حدث خطأ أثناء إرسال البلاغ: فشل الاتصال بالخادم"
Console Log: [API] Response Status: 500
Reason: Server error on backend
Fix: Check server logs; try again later
```

### Scenario 5: Validation Error from API
```
Error Message: "حدث خطأ أثناء إرسال البلاغ: [specific validation error]"
Console Log: [API] Response Status: 400 - [error details]
Reason: API rejected request due to validation
Fix: Check error details in console; verify field values
```

---

## Request Payload Example

### Successful Submission
```
POST /api/Reports
Content-Type: multipart/form-data
Authorization: Bearer eyJhbGc...

Form Fields:
- Title: "حفرة في الطريق الرئيسي"
- Description: "يوجد حفرة كبيرة في منطقة النزهة تهدد سلامة المركبات"
- SubCategoryId: "660e8400-e29b-41d4-a716-446655440000"
- Latitude: "30.0452"
- Longitude: "31.2338"
- Visibility: "Public"
- image: (multipart file: /path/to/image.jpg)
```

### API Response (Success - 200)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "حفرة في الطريق الرئيسي",
  "description": "يوجد حفرة كبيرة...",
  "status": "Pending",
  "submittedAt": "2024-05-11T12:34:56Z",
  "location": {
    "latitude": 30.0452,
    "longitude": 31.2338
  }
}
```

### API Response (Error - 400)
```json
{
  "error": "Invalid SubCategoryId",
  "message": "The provided SubCategoryId does not exist"
}
```

---

## Debugging Field Issues

### If Title/Description Not Sent
- Check: User entered text and it's not empty
- Check: Text was properly trimmed (no leading/trailing spaces)
- Console: Should see in `[API] Submitting report:` log

### If SubCategoryId Not Sent
- Check: User selected both category AND subcategory
- Check: SubCategoryId matches the predefined IDs above
- Console: Will show "[ReportSync] Cannot sync: missing subCategoryId"

### If Location Not Sent
- Check: User clicked on map and selected location
- Check: Latitude and Longitude values are valid coordinates
- Console: Should show coordinates in `[API] Submitting report:` log

### If Image Not Sent
- Check: Form says "يرجى تعبئة جميع الحقول المطلوبة" if missing
- Check: File exists at the path
- Console: Will show "ImagePath: included" or "ImagePath: none"

### If Visibility Not Sent
- Check: User selected value from dropdown
- Check: Selected value is one of: عام, مجهول, سري
- Console: Will show converted value (Public, Anonymous, or Confidential)

---

## Testing Checklist

- [ ] Form validates all required fields before submit
- [ ] Button shows "يرجى تعبئة جميع الحقول المطلوبة" if any field missing
- [ ] SubCategoryId is sent (not just category name)
- [ ] Visibility is converted to English API format
- [ ] Image file is found and included in multipart request
- [ ] Location coordinates are valid and sent correctly
- [ ] Token is included in Authorization header
- [ ] API returns 200 status code for success
- [ ] Report appears in "My Reports" after submission
- [ ] Report sync status updates to "تم الاستلام"

