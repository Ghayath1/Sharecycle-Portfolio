# Firebase Cloud Messaging (FCM) Setup Guide

## Overview
This backend now supports push notifications via Firebase Cloud Messaging (FCM). Users will receive notifications even when the Flutter app is closed or in the background.

## Architecture

### SOLID Principles Applied
1. **Single Responsibility Principle**: Each class has one clear purpose
   - `FCMNotificationService`: Handles FCM notifications only
   - `FCMTokenService`: Manages FCM token lifecycle
   - `FirebaseConfig`: Initializes Firebase
   
2. **Open/Closed Principle**: Extensible without modification
   - `NotificationService` interface allows multiple implementations (Email, SMS, etc.)
   
3. **Liskov Substitution Principle**: Interface-based design
   - Any `NotificationService` implementation can be used interchangeably
   
4. **Interface Segregation Principle**: Focused interfaces
   - `NotificationService` provides only notification-related methods
   
5. **Dependency Inversion Principle**: Depend on abstractions
   - `ChatController` depends on `NotificationService` interface, not concrete implementation

## Backend Setup

### Step 1: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Go to **Project Settings** (gear icon) → **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file

### Step 2: Add Firebase Configuration File

1. Rename the downloaded file to `firebase-service-account.json`
2. Place it in: `src/main/resources/firebase-service-account.json`
3. **IMPORTANT**: Add to `.gitignore` to avoid committing credentials:
   ```
   src/main/resources/firebase-service-account.json
   ```

### Step 3: Run Maven Install

```bash
mvn clean install
```

This will download the Firebase Admin SDK dependency.

### Step 4: Database Migration

The `User` entity now has two new fields:
- `fcmToken` (VARCHAR 500)
- `deviceId` (VARCHAR 255)

If using `spring.jpa.hibernate.ddl-auto=update`, these columns will be added automatically.

For production, create a migration script:
```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(500);
ALTER TABLE users ADD COLUMN device_id VARCHAR(255);
```

## API Endpoints

### 1. Register FCM Token
**POST** `/api/fcm/token`

Register or update the FCM device token for the authenticated user.

**Request Body:**
```json
{
  "fcmToken": "your-fcm-device-token-here",
  "deviceId": "optional-device-identifier"
}
```

**Response:**
```json
{
  "data": "FCM token registered successfully",
  "statusCode": 200,
  "message": "Token registered"
}
```

### 2. Remove FCM Token
**DELETE** `/api/fcm/token`

Remove FCM token when user logs out.

**Response:**
```json
{
  "data": "FCM token removed successfully",
  "statusCode": 200,
  "message": "Token removed"
}
```

### 3. Check Token Status
**GET** `/api/fcm/token/status`

Check if the user has an active FCM token registered.

**Response:**
```json
{
  "data": true,
  "statusCode": 200,
  "message": "Token registered"
}
```

## Flutter App Integration

### Step 1: Add Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0
```

### Step 2: Configure Firebase

1. Add your Flutter app to Firebase project
2. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Place them in the appropriate directories

### Step 3: Initialize Firebase

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Request notification permissions (iOS)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  runApp(MyApp());
}
```

### Step 4: Get and Register FCM Token

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  Future<void> registerToken(String authToken) async {
    // Get FCM token
    String? fcmToken = await _messaging.getToken();
    
    if (fcmToken != null) {
      // Send to backend
      final response = await http.post(
        Uri.parse('https://your-backend-url/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'deviceId': 'optional-device-id',
        }),
      );
      
      if (response.statusCode == 200) {
        print('FCM token registered successfully');
      }
    }
  }
  
  Future<void> removeToken(String authToken) async {
    await http.delete(
      Uri.parse('https://your-backend-url/api/fcm/token'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );
  }
}
```

### Step 5: Handle Notifications

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHandler {
  
  void setupNotificationHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Show local notification or update UI
      }
    });
    
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Navigate to chat screen
      _handleNotificationTap(message);
    });
    
    // Handle notification tap when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    // Extract data
    String type = message.data['type'];
    String senderId = message.data['senderId'];
    String chatRoomId = message.data['chatRoomId'];
    
    // Navigate to appropriate screen
    if (type == 'chat_message') {
      // Navigate to chat screen with senderId
      // Navigator.push(...);
    }
  }
}
```

### Step 6: Register Token on Login

```dart
// After successful login
await FCMService().registerToken(authToken);
```

### Step 7: Remove Token on Logout

```dart
// Before logout
await FCMService().removeToken(authToken);
```

## Testing

### Test Push Notification Manually

Use this curl command to test:

```bash
curl -X POST https://your-backend-url/api/fcm/token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "fcmToken": "YOUR_FCM_TOKEN_FROM_FLUTTER_APP"
  }'
```

Then send a test message via WebSocket or directly trigger a notification.

## Notification Flow

1. **User A sends message to User B**
2. **Backend saves message to database**
3. **Backend sends via WebSocket** (if User B is online)
4. **Backend sends FCM notification** (always, even if offline)
5. **User B's device receives notification** (even if app is closed)
6. **User B taps notification** → App opens to chat screen

## Error Handling

The implementation includes:
- Invalid token cleanup (removes expired/invalid tokens)
- Graceful fallback (message sending continues even if FCM fails)
- Logging for debugging
- Non-blocking notification sending

## Security Considerations

1. **Never commit** `firebase-service-account.json` to version control
2. **Use environment variables** in production for sensitive config
3. **Validate tokens** before sending notifications
4. **Rate limiting** should be implemented for notification endpoints
5. **User privacy**: Only send notifications to intended recipients

## Production Deployment

### Environment Variables (Recommended)

Instead of using `firebase-service-account.json`, use environment variables:

```properties
# application.properties
firebase.project.id=${FIREBASE_PROJECT_ID}
firebase.private.key=${FIREBASE_PRIVATE_KEY}
firebase.client.email=${FIREBASE_CLIENT_EMAIL}
```

Update `FirebaseConfig.java` to read from environment variables.

## Troubleshooting

### Issue: Firebase not initializing
- Check if `firebase-service-account.json` exists in `src/main/resources/`
- Verify JSON file is valid
- Check application logs for initialization errors

### Issue: Notifications not received
- Verify FCM token is registered in database
- Check if user has granted notification permissions
- Verify Firebase project configuration
- Check backend logs for FCM errors

### Issue: Invalid token errors
- Token is automatically removed from database
- User needs to re-register token (happens automatically on next login)

## Additional Features (Optional)

### 1. Notification Preferences
Allow users to customize notification settings:
```java
@Entity
public class NotificationPreferences {
    private Long userId;
    private boolean chatNotifications = true;
    private boolean orderNotifications = true;
    private boolean emailNotifications = true;
}
```

### 2. Notification History
Track sent notifications:
```java
@Entity
public class NotificationLog {
    private Long id;
    private Long userId;
    private String type;
    private String title;
    private LocalDateTime sentAt;
    private boolean delivered;
}
```

### 3. Multiple Device Support
Store multiple FCM tokens per user:
```java
@Entity
public class UserDevice {
    private Long id;
    private Long userId;
    private String fcmToken;
    private String deviceId;
    private String deviceName;
    private LocalDateTime lastActive;
}
```

## Support

For issues or questions:
1. Check Firebase Console for errors
2. Review application logs
3. Verify Flutter app configuration
4. Test with Firebase Cloud Messaging test tool

---

**Implementation completed following SOLID principles and production-ready best practices.**
