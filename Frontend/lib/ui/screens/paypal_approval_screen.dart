import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/payment_models.dart';
import 'package:sharecycleapp/viewmodel/payment_view_model.dart';

/// WebView zur PayPal-Zahlungsfreigabe
class PayPalApprovalScreen extends StatefulWidget {
  final String approvalUrl;

  const PayPalApprovalScreen({
    super.key,
    required this.approvalUrl,
  });

  @override
  State<PayPalApprovalScreen> createState() => _PayPalApprovalScreenState();
}

class _PayPalApprovalScreenState extends State<PayPalApprovalScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🎯 PayPal WebView - Start: $url');
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (String url) {
            debugPrint('🎯 PayPal WebView - Fertig: $url');
            setState(() {
              _isLoading = false;
            });

            // Fallback-Erkennung für Redirects
            if (_isRedirectBackToApp(url)) {
              debugPrint('🎯 PayPal WebView - Fallback-Redirect erkannt');
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('🎯 PayPal WebView - Fehler: ${error.description}');
            debugPrint('🎯 PayPal WebView - URL: ${error.url}');
            setState(() {
              _isLoading = false;
              _error = 'PayPal-Seite konnte nicht geladen werden: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🎯 PayPal WebView - Navigation: ${request.url}');

            final uri = Uri.parse(request.url);
            final isOurApp = uri.host.contains('localhost') ||
                uri.host.contains('192.168.') ||
                uri.host.contains('10.0.') ||
                uri.host.contains('sharecycle') ||
                uri.host.endsWith('.local') ||
                request.url.contains('/payment-success') ||
                request.url.contains('/payment-error') ||
                request.url.contains('/payment-cancel') ||
                request.url.contains('success=1') ||
                request.url.contains('success=true') ||
                request.url.contains('cancel=1') ||
                request.url.contains('cancel=true') ||
                request.url.contains('error=');

            final isPayPalSuccessRedirect = uri.queryParameters.containsKey('token') &&
                uri.queryParameters.containsKey('PayerID') &&
                (request.url.contains('/checkout/success') ||
                    request.url.contains('/success') ||
                    request.url.contains('success'));

            final hasExplicitSuccess = uri.queryParameters['success'] == '1' ||
                uri.queryParameters['success'] == 'true' ||
                request.url.contains('success=1') ||
                request.url.contains('success=true');

            final hasOrderWithToken = uri.queryParameters.containsKey('token') &&
                (uri.queryParameters.containsKey('orderId') ||
                    uri.queryParameters.containsKey('paymentId'));

            final hasPayPalSuccessReturn =
                uri.queryParameters['return']?.contains('success') == true ||
                    uri.queryParameters['action']?.contains('success') == true;

            final hasNoErrors = !uri.queryParameters.containsKey('error') &&
                !uri.queryParameters.containsKey('cancel') &&
                !request.url.contains('error=') &&
                !request.url.contains('cancel=1');

            final isSuccessRedirect =
                (hasExplicitSuccess || hasOrderWithToken || hasPayPalSuccessReturn) && hasNoErrors;

            final shouldBlockNavigation =
                isOurApp || isPayPalSuccessRedirect || isSuccessRedirect;

            if (shouldBlockNavigation) {
              debugPrint('🎯 PayPal WebView - Navigation geblockt (Redirect erkannt)');
              if (isPayPalSuccessRedirect || isSuccessRedirect) {
                debugPrint('🎯 PayPal WebView - ✅ Erfolg erkannt → Autorisierung starten');
                final params = PayPalRedirectParams.fromUrl(request.url);
                context.read<PaymentViewModel>().handlePayPalRedirect(params);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.prevent;
            }

            debugPrint('🎯 PayPal WebView - PayPal-Navigation erlaubt');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approvalUrl));

    debugPrint('🎯 PayPal WebView - Initiale URL: ${widget.approvalUrl}');
  }

  bool _isRedirectBackToApp(String url) {
    debugPrint('🎯 PayPal WebView - Prüfe URL: $url');
    final uri = Uri.parse(url);

    final isOurApp = uri.host.contains('localhost') ||
        uri.host.contains('192.168.') ||
        uri.host.contains('10.0.') ||
        uri.host.contains('sharecycle') ||
        uri.host.endsWith('.local') ||
        url.contains('/payment-success') ||
        url.contains('/payment-error') ||
        url.contains('/payment-cancel');

    final isPayPalSuccessRedirect = uri.queryParameters.containsKey('token') &&
        uri.queryParameters.containsKey('PayerID') &&
        (url.contains('/checkout/success') || url.contains('/success') || url.contains('success'));

    if (!isOurApp && !isPayPalSuccessRedirect) return false;

    final hasExplicitSuccess = uri.queryParameters['success'] == '1' ||
        uri.queryParameters['success'] == 'true' ||
        url.contains('success=1') ||
        url.contains('success=true');

    final hasOrderWithToken = uri.queryParameters.containsKey('token') &&
        (uri.queryParameters.containsKey('orderId') ||
            uri.queryParameters.containsKey('paymentId'));

    final hasPayPalSuccessReturn =
        uri.queryParameters['return']?.contains('success') == true ||
            uri.queryParameters['action']?.contains('success') == true;

    final hasNoErrors = !uri.queryParameters.containsKey('error') &&
        !uri.queryParameters.containsKey('cancel') &&
        !url.contains('error=') &&
        !url.contains('cancel=1');

    final isSuccessRedirect =
        (hasExplicitSuccess || hasOrderWithToken || hasPayPalSuccessReturn) && hasNoErrors;

    final hasSuccessParam = uri.queryParameters.containsKey('success') ||
        url.contains('/payment-success') ||
        url.contains('success=1') ||
        url.contains('success=true');

    final hasErrorParam = url.contains('/payment-error') ||
        url.contains('error=') ||
        uri.queryParameters['return']?.contains('error') == true;

    final hasCancelParam = url.contains('/payment-cancel') ||
        url.contains('cancel=1') ||
        url.contains('cancel=true') ||
        uri.queryParameters['return']?.contains('cancel') == true;

    final isRedirect = (isOurApp || isPayPalSuccessRedirect) &&
        (hasSuccessParam || hasErrorParam || hasCancelParam || isSuccessRedirect);

    return isRedirect;
  }

  @override
  Widget build(BuildContext context) {
    final paymentViewModel = context.watch<PaymentViewModel>();

    // Navigation basierend auf dem Payment-Status
    if (paymentViewModel.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/payment-success');
      });
    } else if (paymentViewModel.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/payment-error', extra: {
          'type': 'auth_failed',
          'message': paymentViewModel.errorMessage ?? 'Zahlungsautorisierung fehlgeschlagen'
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PayPal-Zahlung',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            // Bestätigung vorm Abbruch
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Zahlung abbrechen'),
                content: const Text('Möchtest du die Zahlung wirklich abbrechen?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Zahlung fortsetzen'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/payment-error', extra: {
                        'type': 'cancelled',
                        'message': 'Zahlung vom Benutzer abgebrochen'
                      });
                    },
                    child: const Text('Zahlung abbrechen'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // WebView
            WebViewWidget(controller: _controller),

            // Lade-Overlay
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: orange),
                      SizedBox(height: 16),
                      Text(
                        'PayPal wird geladen…',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Autorisierungs-Overlay
            if (paymentViewModel.state == PaymentState.authorizing)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: orange),
                      SizedBox(height: 16),
                      Text(
                        'Zahlung wird abgeschlossen…',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Fehler-Overlay
            if (_error != null)
              Container(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Zahlungsfehler',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: orange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _isLoading = true;
                              });
                              _controller.loadRequest(Uri.parse(widget.approvalUrl));
                            },
                            child: const Text(
                              'Erneut versuchen',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: orange),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              context.go('/payment-error', extra: {
                                'type': 'error',
                                'message': _error
                              });
                            },
                            child: Text(
                              'Zahlung abbrechen',
                              style: TextStyle(color: orange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
