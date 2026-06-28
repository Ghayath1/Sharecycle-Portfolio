# Chat POC - WebSocket Testing Interface

A proof-of-concept web application to test the WebSocket chat functionality.

## Features

✅ **User Login** - Select any user from the system to login  
✅ **View All Users** - See all available users to chat with  
✅ **Private Chat** - Click on any user to open a chat room  
✅ **Real-time Messaging** - Send and receive messages instantly via WebSocket  
✅ **Switch Users** - Easily switch between different users to test bidirectional chat  
✅ **Message History** - View previous messages when opening a chat  
✅ **Connection Status** - See WebSocket connection status in real-time  

## Setup Instructions

### 1. Configure Backend CORS

Add CORS configuration to your Spring Boot application to allow the POC to connect:

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("http://localhost:3000", "http://127.0.0.1:3000", "null")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }
}
```

Also update your `WebSocketConfig`:

```java
@Override
public void registerStompEndpoints(StompEndpointRegistry registry) {
    registry.addEndpoint("/ws")
            .setAllowedOrigins("http://localhost:3000", "http://127.0.0.1:3000", "null")
            .withSockJS();
}
```

### 2. Start Your Backend

Make sure your Spring Boot application is running on `http://localhost:8080`

### 3. Open the POC

Simply open `index.html` in your browser. You can:

- **Option 1**: Double-click `index.html` to open in your default browser
- **Option 2**: Use a simple HTTP server:
  ```bash
  # Using Python
  python -m http.server 3000
  
  # Using Node.js
  npx http-server -p 3000
  ```
  Then navigate to `http://localhost:3000`

## How to Test

### Test Scenario 1: Basic Chat
1. Open `index.html` in your browser
2. Select **User A** to login
3. Click on **User B** from the users list
4. Send a message: "Hello from User A!"
5. Open a new browser window/tab (or incognito)
6. Login as **User B**
7. Click on **User A** - you should see the message
8. Reply: "Hi User A!"
9. Switch back to the first window - you should see the reply instantly

### Test Scenario 2: Multiple Conversations
1. Login as **User A**
2. Chat with **User B**
3. Click on **User C** and send messages
4. Switch back to **User B** - messages should be preserved
5. All conversations are maintained separately

### Test Scenario 3: Connection Status
1. Login and start chatting
2. Stop your backend server
3. Notice the connection status changes to "Disconnected"
4. Start the backend again
5. Connection should automatically reconnect

### Test Scenario 4: Message History
1. Login as **User A** and send messages to **User B**
2. Logout
3. Login as **User B**
4. Click on **User A** - all previous messages should load

## File Structure

```
chat-poc/
├── index.html          # Login page
├── chat.html           # Main chat interface
├── login.js            # Login page logic
├── chat.js             # Chat functionality & WebSocket
├── styles.css          # All styling
└── README.md           # This file
```

## Configuration

If your backend runs on a different port, update the configuration in both JS files:

**login.js** and **chat.js**:
```javascript
const API_BASE_URL = 'http://localhost:8080';
const WS_URL = 'http://localhost:8080/ws';
```

## Troubleshooting

### "Failed to load users"
- Ensure your backend is running
- Check that the `/users/all` endpoint is accessible
- Verify CORS is properly configured

### "WebSocket Disconnected"
- Check backend console for WebSocket errors
- Verify the `/ws` endpoint is accessible
- Ensure SockJS is properly configured in backend

### Messages not appearing
- Check browser console for errors
- Verify WebSocket connection is established (green dot)
- Ensure both users are subscribed to their message queues

### CORS Errors
- Add proper CORS configuration to backend
- Allow origins: `http://localhost:3000`, `http://127.0.0.1:3000`, `null`
- Allow credentials: `true`

## Browser Support

- Chrome/Edge (recommended)
- Firefox
- Safari

## Dependencies

All dependencies are loaded via CDN:
- SockJS Client 1.x
- STOMP.js 2.3.3

No npm install or build process required!
