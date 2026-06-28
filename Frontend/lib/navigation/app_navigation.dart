import 'package:go_router/go_router.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/register_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/bike_list_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/privacy_policy_screen.dart';
import '../ui/screens/police_help_screen.dart';
import '../ui/screens/maps_screen.dart';
import '../ui/screens/add_bike_screen.dart';
import '../ui/screens/my_bikes_screen.dart';
import '../ui/screens/orders_screen.dart';
import '../ui/screens/my_orders_screen.dart';
import '../ui/screens/paypal_approval_screen.dart';
import '../ui/screens/payment_success_screen.dart';
import '../ui/screens/payment_error_screen.dart';
import '../ui/screens/booking_details_screen.dart';
import '../ui/screens/forgot_password_screen.dart';
import '../ui/screens/reset_password_screen.dart';
import '../booking_models.dart';



final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/reset-password', builder: (_, state) => ResetPasswordScreen(email: state.uri.queryParameters['email'] ?? '')),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/bikes', builder: (_, __) => const BikeListScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPolicyScreen()),
    GoRoute(path: '/police', builder: (_, __) => const PoliceHelpScreen()),
    GoRoute(path: '/maps', builder: (ctx, st) => const MapsScreen()),
    GoRoute(path: '/bikes/add',builder: (context, state) => const AddBikeScreen()),
    GoRoute(path: '/my-bikes',builder: (_, __) => const  MyBikeScreen(),),
    GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
    GoRoute(path: '/my-orders', builder: (_, __) => const MyOrdersScreen()),

    GoRoute(
      path: '/booking-details',
      builder: (context, state) {
        final bookingDetails = state.extra as BookingDetails;
        return BookingDetailsScreen(
          bike: bookingDetails.bike,
          from: bookingDetails.from,
          to: bookingDetails.to,
        );
      },
    ),

    // Payment flow routes
    GoRoute(
      path: '/payment-approval',
      builder: (context, state) {
        final approvalUrl = state.extra as String?;
        if (approvalUrl == null) {
          // Fallback to error if no approval URL provided
          return const PaymentErrorScreen(
            errorType: 'error',
            errorMessage: 'Invalid payment session',
          );
        }
        return PayPalApprovalScreen(approvalUrl: approvalUrl);
      },
    ),
    GoRoute(
      path: '/payment-success',
      builder: (_, __) => const PaymentSuccessScreen(),
    ),
    GoRoute(
      path: '/payment-error',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PaymentErrorScreen(
          errorType: extra?['type'] as String?,
          errorMessage: extra?['message'] as String?,
        );
      },
    ),
  ],
);
