# Messaging Specification

## Purpose
Enable real-time communication between bike owners and renters to facilitate smooth transactions and resolve any issues during the rental period.

## ADDED Requirements

### Requirement: Real-time Chat
Users SHALL be able to exchange messages in real-time with other users they have an active order with.

#### Scenario: Sending a message
- **GIVEN** a user is viewing an order
- **WHEN** they tap the chat button
- **THEN** they are taken to the chat screen
- **WHEN** they type a message and tap send
- **THEN** the message is immediately displayed in the chat
- **AND** the message is delivered to the other participant

#### Scenario: Receiving a message
- **GIVEN** a user has the chat screen open
- **WHEN** they receive a new message
- **THEN** the message is displayed in the chat
- **AND** a notification is shown if the chat is not in focus

### Requirement: Message Persistence
Chat messages SHALL be persisted and available for future reference.

#### Scenario: Viewing chat history
- **GIVEN** a user opens a chat
- **WHEN** they have previous messages with the other user
- **THEN** the message history is displayed in chronological order
- **AND** they can scroll through the entire conversation