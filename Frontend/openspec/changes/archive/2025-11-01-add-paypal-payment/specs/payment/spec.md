## ADDED Requirements

### Requirement: PayPal Payment Integration
The system SHALL integrate with PayPal to enable secure payment processing for bicycle rentals.

#### Scenario: User initiates payment for bicycle rental
- **GIVEN** user selects a bicycle and chooses rental dates in the booking dialog
- **WHEN** user taps the "Buchen" (Book) button
- **THEN** the app calls POST /api/payment/orders with bicycleId, dateFrom, dateTo
- **AND** displays loading indicator during API call

#### Scenario: Backend creates PayPal order successfully
- **GIVEN** the payment order API call is successful
- **WHEN** backend returns response with PayPal approvalUrl
- **THEN** app extracts the approvalUrl from response
- **AND** redirects user to PayPal approval page using WebView

#### Scenario: User approves payment on PayPal
- **GIVEN** user is redirected to PayPal WebView
- **WHEN** user completes payment approval on PayPal
- **THEN** PayPal redirects back to app with success parameters
- **AND** app extracts paypalOrderID from redirect parameters

#### Scenario: App authorizes payment after PayPal approval
- **GIVEN** user returns from PayPal with approved payment
- **WHEN** app receives paypalOrderID
- **THEN** app calls POST /api/payment/orders/{paypalOrderID}/authorize
- **AND** shows success message if authorization succeeds

#### Scenario: Payment process fails at any stage
- **GIVEN** any step in payment process fails
- **WHEN** error occurs (API error, PayPal rejection, network issue)
- **THEN** app shows user-friendly error message
- **AND** provides option to retry or cancel booking
- **AND** does not charge user's payment method

### Requirement: PayPal WebView Integration
The system SHALL use WebView to display PayPal payment approval interface.

#### Scenario: WebView loads PayPal approval page
- **GIVEN** backend provides approvalUrl
- **WHEN** user needs to approve payment
- **THEN** app opens WebView with the approvalUrl
- **AND** shows loading indicator while page loads

#### Scenario: WebView handles PayPal redirect back to app
- **GIVEN** user completes payment on PayPal
- **WHEN** PayPal redirects back with return parameters
- **THEN** WebView detects the redirect
- **AND** extracts paypalOrderID and success status (paypalOrderID, will be in the response of the POST /api/payment/orders)
- **AND** navigates to appropriate success or error screen

### Requirement: Payment Error Handling
The system SHALL handle various payment failure scenarios gracefully.

#### Scenario: API returns error during order creation
- **GIVEN** POST /api/payment/orders fails
- **WHEN** backend returns error response
- **THEN** app shows error message to user
- **AND** provides option to retry booking
- **AND** logs error for debugging

#### Scenario: PayPal payment is cancelled by user
- **GIVEN** user is on PayPal approval page
- **WHEN** user cancels payment on PayPal
- **THEN** PayPal redirects back with cancellation status
- **AND** app shows cancellation message
- **AND** returns user to bike selection screen

#### Scenario: PayPal payment fails due to insufficient funds
- **GIVEN** user attempts payment on PayPal
- **WHEN** payment fails due to insufficient funds
- **THEN** PayPal shows error message to user
- **AND** redirects back to app with failure status
- **AND** app shows appropriate error message

#### Scenario: Network connectivity issues during payment
- **GIVEN** user is in payment flow
- **WHEN** network connection is lost
- **THEN** app shows network error message
- **AND** provides retry option
- **AND** preserves booking state for retry

### Requirement: Payment Authorization Flow
The system SHALL complete payment authorization after PayPal approval.

#### Scenario: Successful payment authorization
- **GIVEN** user returns from successful PayPal approval
- **WHEN** app calls authorization endpoint
- **THEN** backend updates payment status to AUTHORIZED
- **AND** app shows booking confirmation
- **AND** provides booking details and next steps

#### Scenario: Authorization fails after PayPal approval
- **GIVEN** PayPal approval was successful
- **WHEN** authorization API call fails
- **THEN** app shows authorization error message
- **AND** provides option to retry authorization
- **AND** explains that payment was approved but needs final confirmation
