# FCM Quick Start Guide

## Backend Setup (5 minutes)

### 1. Get Firebase Credentials
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. **Project Settings** → **Service Accounts** → **Generate New Private Key**
4. Download the JSON file

### 2. Add Credentials to Project
```bash
# Copy the downloaded file to:
src/main/resources/firebase-service-account.json
```

### 3. Build and Run
```bash
mvn clean install
mvn spring-boot:run
```

✅ **Backend is ready!** FCM notifications will now be sent when users receive messages.

---

## Flutter App Setup (10 minutes)

### 1. Add Dependencies
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
```

### 2. Configure Firebase
1. Add your Flutter app to Firebase project
2. Download `google-services.json` (Android) → place in `android/app/`
3. Download `GoogleService-Info.plist` (iOS) → place in `ios/Runner/`

### 3. Initialize Firebase
```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Request permissions
  await FirebaseMessaging.instance.requestPermission();
  
  runApp(MyApp());
}
```

### 4. Register Token After Login
```dart
// After successful login
final fcmToken = await FirebaseMessaging.instance.getToken();

// Send to backend
await http.post(
  Uri.parse('$baseUrl/api/fcm/token'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authToken',
  },
  body: jsonEncode({'fcmToken': fcmToken}),
);
```

### 5. Handle Notifications
```dart
// Setup notification handlers
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Handle foreground notification
  print('New message: ${message.notification?.title}');
});

FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Handle notification tap - navigate to chat
  String senderId = message.data['senderId'];
  // Navigate to chat screen
});
```

✅ **Done!** Users will now receive notifications even when the app is closed.

---

## Test It

1. **Login** with two different users on two devices
2. **Send a message** from User A to User B
3. **Close the app** on User B's device
4. User B should receive a **push notification**
5. **Tap the notification** → App opens to chat screen

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/fcm/token` | Register FCM token |
| DELETE | `/api/fcm/token` | Remove FCM token (logout) |
| GET | `/api/fcm/token/status` | Check token status |

---

## Architecture

```
User A sends message
    ↓
Backend receives via WebSocket
    ↓
Backend saves to database
    ↓
Backend sends TWO notifications:
    1. WebSocket → User B (if online)
    2. FCM Push → User B (always, even if offline)
    ↓
User B receives notification on device
```

---

## Troubleshooting

**Notifications not working?**
1. Check if `firebase-service-account.json` exists in `src/main/resources/`
2. Verify FCM token is registered: `GET /api/fcm/token/status`
3. Check backend logs for FCM errors
4. Ensure notification permissions are granted in Flutter app

**Need more details?** See `FCM_SETUP_GUIDE.md` for comprehensive documentation.
