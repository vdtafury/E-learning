# User Data Storage - Complete Guide

## ✅ Where User Data is Now Saved

Your user registration data is now being saved to **Firebase Cloud Services**:

### **1. Authentication Data** → Firebase Authentication
- **Email** and **Password** (encrypted by Firebase)
- **User ID (UID)** (unique identifier)
- **Email verification status**
- **Location**: `https://console.firebase.google.com/authentication`

### **2. User Profile Data** → Firestore Database
- **Name**
- **Email** (reference)
- **Avatar URL**
- **Created At** (timestamp)
- **Location**: `https://console.firebase.google.com/firestore` → Collection: `users`

---

## 📊 Firestore Document Structure

When a user registers, a document is created in the `users` collection:

```
Firestore Database
└── Collection: users
    └── Document: {uid}
        ├── uid: "user123abc..."
        ├── name: "John Doe"
        ├── email: "john@example.com"
        ├── avatarUrl: null (or URL)
        └── createdAt: 2026-04-11T10:30:00Z
```

**Example:**
```
users/
  dv3Ks8mN2pQwXyZ1a/
    uid: "dv3Ks8mN2pQwXyZ1a"
    name: "Alice Johnson"
    email: "alice@example.com"
    avatarUrl: null
    createdAt: Timestamp(seconds: 1712859000, nanoseconds: 0)
```

---

## 🔒 Firebase Security Rules

Set up these rules in Firestore to protect user data:

**Go to Firebase Console → Firestore → Rules**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - only authenticated users can access their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow create: if request.auth.uid == request.resource.data.uid;
    }
  }
}
```

---

## 📋 Updated Code Changes

### **authentication_service.dart** - Now Uses:
- ✅ Firebase Authentication (`firebase_auth`)
- ✅ Firestore Database (`cloud_firestore`)
- ✅ Persistent data storage (not in-memory)
- ✅ Proper error handling
- ✅ Auth state listener

### **Key Features:**

| Feature | Before (In-Memory) | After (Firebase) |
|---------|-------------------|------------------|
| **Data Storage** | RAM only | Cloud Firestore |
| **Persistence** | Lost on app close | Permanent |
| **Security** | NO encryption | Firebase encrypted |
| **Scalability** | Single device | Global cloud |
| **Availability** | Offline only | Always available |
| **Sync** | NO | Automatic |
| **Authentication** | NO verification | Email/password secure |

---

## 🚀 Setup Checklist

### **Step 1: Enable Firestore in Firebase Console**
1. Go to `https://console.firebase.google.com/firestore`
2. Click "Create Database"
3. Select region (e.g., `us-central1`)
4. Choose "Start in test mode" (for development)
5. Create

### **Step 2: Get Dependencies**
```bash
flutter pub get
```

Dependencies added:
- `firebase_core: ^3.6.2` ✓
- `firebase_auth: ^5.4.0` ✓
- `cloud_firestore: ^5.0.0` ✓ (NEW)

### **Step 3: Update firebase_options.dart**
The FlutterFire CLI will auto-generate this with correct credentials:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-firebase-project-id
```

This updates [lib/firebase_options.dart](lib/firebase_options.dart) with all cloud settings.

### **Step 4: Run the App**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📝 How Registration Works Now

```
RegisterScreen (register_screen.dart)
    ↓
    calls: AuthService().registerUser()
    ↓
Firebase Authentication
    ├── Creates user account
    ├── Generates unique UID
    └── Returns credential
    ↓
Firestore Database (users collection)
    └── Stores user profile document
    ↓
AuthService._currentUser
    └── Updates in-app state
    ↓
UI updates + Navigation to Login
```

---

## 🔍 How to View Stored Data

### **In Firebase Console:**
1. Go to `https://console.firebase.google.com/firestore`
2. Select your project
3. Click on `users` collection
4. View all registered user documents

### **In Code:**
```dart
// Get current user
User? currentUser = AuthService().currentUser;
print(currentUser?.name); // "John Doe"

// Get any user by ID
User? user = await AuthService().getUserById("userId123");

// Check if logged in
bool loggedIn = AuthService().isLoggedIn;
```

---

## 🛡️ Security Features Implemented

✅ **Password Encryption** - Firebase handles encryption  
✅ **Email Verification** - When updating email  
✅ **UID-based Access Control** - Only users can access their data  
✅ **Auth State Listener** - Automatic sync across app  
✅ **Error Handling** - Specific Firebase error messages  
✅ **Email Validation** - Built-in Firebase validation  

---

## ⚠️ Important Notes

1. **google-services.json** - Must be in `android/app/google-services.json`
2. **Firestore Test Mode** - For development. Set up proper security rules before production
3. **Email Change** - Requires verification before applying
4. **Offline Support** - Firestore has offline persistence built-in
5. **Data Sync** - Changes sync automatically across all devices

---

## 🐛 Troubleshooting

### "Permission denied" Error
→ Set Firestore rules to test mode or configure proper security rules

### "App check failed"
→ Ensure google-services.json is correct and in the right location

### "No collection 'users' found"
→ Normal! Collections are created automatically when you write the first document

### "User profile not found"
→ May occur if Firestore write didn't complete. Check Firebase console.

---

## 📚 References

- [Firebase Authentication Flutter](https://firebase.flutter.dev/docs/auth/overview)
- [Firestore Documentation](https://firebase.flutter.dev/docs/firestore/overview)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
