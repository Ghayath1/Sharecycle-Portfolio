# GetX Routing Migration Design

## Context
- Current routing uses `go_router` package
- Need to migrate to GetX for better state management integration
- Must maintain all existing navigation flows
- Must support deep linking
- Must handle route parameters

## Goals
- Replace GoRouter with GetX navigation
- Maintain all existing routes and parameters
- Improve code maintainability
- Reduce boilerplate
- Support deep linking
- Maintain backward compatibility

## Non-Goals
- Changing business logic
- Modifying screen UIs
- Changing state management (except where required for routing)

## Technical Decisions

### 1. GetX Navigation
- Use `GetMaterialApp` instead of `MaterialApp.router`
- Define routes in `app_pages.dart`
- Use named routes for all navigation
- Handle route parameters through GetX's parameter system

### 2. Route Organization
```dart
// app_pages.dart
static final routes = [
  GetPage(name: Routes.HOME, page: () => HomeScreen()),
  GetPage(
    name: Routes.BOOKING_DETAILS,
    page: () => BookingDetailsScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<BookingController>(() => BookingController());
    }),
  ),
  // ... other routes
];
```

### 3. Parameter Handling
- Use `Get.parameters` for path parameters
- Use `Get.arguments` for complex objects
- Type-safe parameter extraction in controllers

### 4. Navigation
- Replace `context.go()` with `Get.toNamed()`
- Replace `context.push()` with `Get.toNamed()`
- Replace `context.pop()` with `Get.back()`
- Use `Get.offAllNamed()` for login/logout flows

## Migration Strategy
1. Add GetX and set up basic routing
2. Convert routes incrementally:
   - Auth routes first (login, register, etc.)
   - Main app routes
   - Nested routes
   - Parameterized routes
3. Test navigation after each group
4. Clean up old router code

## Risks & Mitigation
- **Risk**: Breaking existing navigation
  - Mitigation: Test all navigation flows
  - Mitigation: Keep old router temporarily during migration

- **Risk**: Memory leaks from improper disposal
  - Mitigation: Use `GetX` controllers with proper lifecycle
  - Mitigation: Test with dev tools

- **Risk**: Deep linking regressions
  - Mitigation: Test deep links on both platforms
  - Mitigation: Add deep link tests

## Testing Plan
- Unit tests for route definitions
- Widget tests for navigation
- Integration tests for critical flows
- Manual testing of all routes
- Deep link testing
- Back navigation testing
