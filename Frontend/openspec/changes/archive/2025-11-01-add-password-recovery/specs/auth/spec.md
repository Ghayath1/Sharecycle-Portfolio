## ADDED Requirements

### Requirement: Password Recovery Flow
Users MUST be able to recover their password using their registered email address.

#### Scenario: Request Password Reset
- **GIVEN** a user is on the login screen
- **WHEN** they tap "Forgot Password?"
- **THEN** they are navigated to the Forgot Password screen
- **WHEN** they enter their email and submit
- **THEN** a password reset OTP is sent to their email
- **AND** they are navigated to the Reset Password screen

#### Scenario: Reset Password with Valid OTP
- **GIVEN** a user has requested a password reset
- **WHEN** they enter a valid OTP and new password
- **AND** the passwords match and meet requirements
- **THEN** their password is updated
- **AND** they are redirected to the login screen with a success message

#### Scenario: Reset Password with Invalid OTP
- **GIVEN** a user has requested a password reset
- **WHEN** they enter an invalid OTP
- **THEN** an error message is displayed
- **AND** they can try again

### Requirement: Security Measures
The system SHALL implement security measures to prevent abuse of the password recovery feature.

#### Scenario: Rate Limiting
- **GIVEN** a user attempts to request multiple password resets
- **WHEN** they exceed the rate limit
- **THEN** further requests are temporarily blocked
- **AND** an appropriate error message is shown

#### Scenario: OTP Expiration
- **GIVEN** a password reset OTP has been issued
- **WHEN** the OTP expires
- **THEN** it can no longer be used to reset the password
- **AND** the user must request a new OTP
