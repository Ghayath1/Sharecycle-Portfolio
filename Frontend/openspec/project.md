# Project Context

## Purpose
ShareCycle is a Flutter-based bike and car sharing mobile application that enables users to locate, book, and manage shared vehicles. The app provides real-time location tracking, mapping integration, media upload for vehicle documentation, and cross-platform support for iOS, Android, web, and desktop platforms.

## Tech Stack
- **Framework**: Flutter 3.0+ with Dart SDK
- **State Management**: Provider for reactive state management
- **Routing**: go_router for declarative routing
- **Maps & Location**: Google Maps Flutter, Geolocator, Geocoding for location services
- **Media**: Image Picker for photo uploads, WebView Flutter for web content
- **Storage**: Shared Preferences for local data persistence
- **Networking**: HTTP client for API communications
- **Configuration**: Flutter Dotenv for environment variable management
- **Internationalization**: Intl package for localization support
- **Platform Support**: Cross-platform (Android, iOS, Web, Linux, macOS, Windows)
- **Development Tools**: Flutter lints for code quality

## Project Conventions

### Code Style
- Follows standard Flutter linting rules via `package:flutter_lints`
- Uses standard Dart formatting conventions
- No custom linting rules disabled or added - maintains Flutter best practices
- Consistent naming: camelCase for variables/methods, PascalCase for classes

### Architecture Patterns
- **Clean Architecture**: Separation of concerns with dedicated directories
  - `lib/navigation/` - Routing and navigation logic
  - `lib/ui/` - UI components and screens
  - `lib/viewmodel/` - State management and business logic
  - `lib/theme/` - Theming and styling
  - `lib/utils/` - Utility functions and helpers
- **Provider Pattern**: Centralized state management using Provider package
- **Environment-based Configuration**: Separate .env files for different environments
- **Modular Structure**: Feature-based organization within the lib directory

### Testing Strategy
- Widget testing setup with `flutter_test` package
- Follows Flutter testing best practices for UI component testing
- Test files located in `test/` directory
- Integration with Flutter's testing framework for unit and widget tests

### Git Workflow
- **OpenSpec Integration**: Uses OpenSpec for spec-driven development and change management
- **Three-stage Workflow**:
  - Stage 1: Creating Changes (proposals and specifications)
  - Stage 2: Implementation (following approved proposals)
  - Stage 3: Archiving (moving completed changes to archive)
- **Change Management**: All changes require proposals with clear requirements and scenarios
- **Validation**: Uses `openspec validate --strict` for comprehensive change validation
- **Branching**: Standard Git workflow with feature branches and pull requests

## Domain Context
This is a vehicle sharing platform (bike/car sharing application) that requires:
- Real-time location tracking and mapping capabilities
- User authentication and profile management
- Vehicle booking and reservation system
- Media upload for vehicle documentation
- Cross-platform mobile and web deployment
- Integration with mapping services (Google Maps)
- Environment-specific configuration management

## Important Constraints
- **Platform Requirements**: Must support iOS 11+, Android API 21+, and modern web browsers
- **Performance**: Smooth map interactions and location updates required
- **Security**: Secure API communications and user data handling
- **Offline Capability**: Basic functionality should work offline where possible
- **Accessibility**: Follow Flutter accessibility guidelines for inclusive design
- **Localization**: Support for multiple languages using Flutter's internationalization

## External Dependencies
- **Google Maps Platform**: Requires API keys for maps and location services
- **Backend API**: HTTP-based API for data synchronization (base URL configurable via environment)
- **Environment Variables**:
  - `API_BASE_URL` - Backend API endpoint
  - `MAPS_API_KEY` - Google Maps API key (if required)
  - `ENV_FILE` - Environment configuration file selection
- **Development Tools**: OpenSpec CLI for specification and change management
