## Why
Users occasionally forget their passwords and need a secure way to reset them. Currently, there's no self-service password recovery mechanism, which leads to increased support requests and a poor user experience.

## What Changes
- Add Forgot Password screen with email input
- Add Reset Password screen for OTP and new password entry
- Implement API integration with the backend
- Add navigation between authentication screens
- Add input validation and error handling
- Include success/error feedback to users

## Impact
- **Affected specs**: Authentication flow
- **Affected code**:
  - New screens: `forgot_password_screen.dart`, `reset_password_screen.dart`
  - Updated: `login_screen.dart`
  - New services: `auth_service.dart` (if not exists)
  - Navigation updates
- **Security considerations**:
  - Rate limiting on password reset requests
  - Secure handling of OTP and tokens
  - Password strength requirements

## Dependencies
- Backend API endpoints must be available and properly documented
- Email service for OTP delivery must be configured
