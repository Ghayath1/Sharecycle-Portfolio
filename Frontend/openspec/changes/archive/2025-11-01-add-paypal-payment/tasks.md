## 1. Payment Integration Setup

### 1.1 Add Required Dependencies
- [ ] Add `url_launcher` dependency to pubspec.yaml for external URL handling
- [ ] Verify `webview_flutter` is properly configured for PayPal redirects
- [ ] Run `flutter pub get` to install new dependencies

### 1.2 Create Payment Data Models
- [ ] Create `PaymentOrderResponse` model for API response structure
- [ ] Create `PaymentAuthorizationRequest` model for authorization calls
- [ ] Create `PayPalRedirectParams` model for handling PayPal return parameters
- [ ] Update existing booking models if needed

## 2. Payment Service Implementation

### 2.1 Create Payment Service
- [ ] Create `lib/services/payment_service.dart` for API interactions
- [ ] Implement `createPaymentOrder()` method for POST /api/payment/orders
- [ ] Implement `authorizePayment()` method for POST /api/payment/orders/{id}/authorize
- [ ] Add comprehensive error handling for network and API failures
- [ ] Add proper HTTP headers and authentication tokens

### 2.2 Update API Response Handling
- [ ] Modify response parsing to extract `approvalUrl` from backend response
- [ ] Handle different response formats and error structures
- [ ] Add logging for debugging payment flow issues

## 3. WebView Integration for PayPal

### 3.1 Create PayPal WebView Screen
- [ ] Create `lib/ui/screens/paypal_approval_screen.dart`
- [ ] Implement WebView with PayPal approvalUrl
- [ ] Add loading indicators and error states
- [ ] Handle WebView navigation and redirect detection

### 3.2 Implement PayPal Redirect Handling
- [ ] Detect when PayPal redirects back to app
- [ ] Extract paypalOrderID and success status from redirect
- [ ] Navigate to appropriate success or error screens
- [ ] Handle PayPal cancellation scenarios

## 4. Enhanced Booking Flow

### 4.1 Update Bike List Screen Booking Logic
- [ ] Modify `_book()` method in `bike_list_screen.dart` to handle PayPal responses
- [ ] Update success message handling for payment flow
- [ ] Add navigation to PayPal WebView on successful order creation
- [ ] Preserve booking state during payment process

### 4.2 Add Payment State Management
- [ ] Create payment provider using Provider package
- [ ] Manage payment status (pending, approved, authorized, failed)
- [ ] Handle loading states during payment process
- [ ] Coordinate between booking and payment flows

## 5. Navigation and Routing Updates

### 5.1 Add Payment Flow Routes
- [ ] Add `/payment-approval` route for PayPal WebView
- [ ] Add `/payment-success` route for successful payments
- [ ] Add `/payment-error` route for failed payments
- [ ] Update `app_navigation.dart` with new routes

### 5.2 Create Payment Result Screens
- [ ] Create `payment_success_screen.dart` with booking confirmation
- [ ] Create `payment_error_screen.dart` with retry options
- [ ] Add appropriate success and error messaging
- [ ] Provide navigation back to bike selection

## 6. Error Handling and User Experience

### 6.1 Comprehensive Error Handling
- [ ] Add error boundaries for payment flow failures
- [ ] Implement retry mechanisms for failed API calls
- [ ] Add user-friendly error messages for different failure types
- [ ] Handle network connectivity issues gracefully

### 6.2 Loading States and User Feedback
- [ ] Add loading indicators during API calls
- [ ] Show progress during PayPal approval process
- [ ] Provide clear feedback for each step of payment flow
- [ ] Handle app background/foreground during payment

## 7. Testing and Validation

### 7.1 Unit Tests
- [ ] Test payment service methods with mock responses
- [ ] Test API response parsing and error handling
- [ ] Test WebView navigation and redirect detection
- [ ] Test payment state management logic

### 7.2 Integration Tests
- [ ] Test complete payment flow end-to-end
- [ ] Test error scenarios and recovery
- [ ] Test PayPal redirect handling
- [ ] Test offline and network failure scenarios

### 7.3 Manual Testing
- [ ] Test with PayPal sandbox environment
- [ ] Verify all payment success and failure paths
- [ ] Test on different devices and platforms
- [ ] Verify user experience is smooth and intuitive

## 8. Documentation and Polish

### 8.1 Update Documentation
- [ ] Document payment flow in README or user guide
- [ ] Add API documentation for payment endpoints
- [ ] Document error codes and recovery procedures
- [ ] Update project.md with payment capability details

### 8.2 Code Quality and Polish
- [ ] Add proper comments and documentation
- [ ] Ensure consistent code style and naming
- [ ] Optimize WebView performance and memory usage
- [ ] Add proper error logging and analytics
