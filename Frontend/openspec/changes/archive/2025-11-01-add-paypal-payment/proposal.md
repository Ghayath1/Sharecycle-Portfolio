## Why

The ShareCycle app currently has a basic booking system that creates orders via POST /api/payment/orders, but it doesn't integrate with PayPal for actual payment processing. Users need a complete payment flow where they can pay for bicycle rentals through PayPal's secure platform.

## What Changes

- **Enhanced Booking Flow**: Modify existing bike booking to handle PayPal payment integration
- **PayPal WebView Integration**: Add WebView screen for PayPal payment approval
- **Payment Authorization**: Implement authorization flow after PayPal approval
- **Error Handling**: Add comprehensive error handling for payment failures and edge cases
- **Response Processing**: Update API response handling to extract PayPal approvalUrl and order details
- **New Routes**: Add routes for payment flow (/payment-approval, /payment-success, /payment-error)
- **Dependencies**: Add url_launcher for external URL handling (if needed)

## Impact

- **Affected specs**: Payment capability (new), Booking capability (modified), Navigation capability (modified)
- **Affected code**:
  - `lib/ui/screens/bike_list_screen.dart` - Enhanced booking flow
  - `lib/navigation/app_navigation.dart` - New payment routes
  - New payment-related screens in `lib/ui/screens/`
  - `lib/viewmodel/` - Payment state management
- **Breaking changes**: None - enhances existing functionality
- **External dependencies**: PayPal API integration (backend handles PayPal SDK)
