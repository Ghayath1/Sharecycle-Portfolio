## Why
Users need a way to communicate with each other regarding their bike sharing transactions. This is essential for coordinating pickup/drop-off details, asking questions about the bike, and resolving any issues that may arise during the rental period.

## What Changes
- Add real-time chat functionality between bike owners and renters
- Implement WebSocket connection for instant messaging
- Add chat button to order cards in the orders screen
- Create a chat screen UI for message exchange
- Store chat history for future reference

## Impact
- **Affected specs**: messaging, orders
- **Affected code**:
  - `lib/ui/screens/orders_screen.dart` - Add chat button handler
  - New files:
    - `lib/ui/screens/chat_screen.dart`
    - `lib/services/chat_service.dart`
    - `lib/models/chat_message.dart`
    - `lib/models/chat_room.dart`
