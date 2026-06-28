# Migrate to GetX Routing

## Why
Migrate from GoRouter to GetX to simplify navigation management, reduce boilerplate, and better integrate with GetX's state management and dependency injection.

## What Changes
- Replace `go_router` with `get` package
- Convert route definitions to GetX pattern
- Update navigation calls throughout the app
- **BREAKING**: Navigation method signatures will change
- **BREAKING**: Route parameter handling will be updated

## Impact
- **Affected specs**: 
  - Navigation
  - Authentication
  - Deep linking
- **Affected code**:
  - `lib/navigation/app_navigation.dart` (to be replaced)
  - All screen widgets (navigation updates)
  - `main.dart` (app initialization)
