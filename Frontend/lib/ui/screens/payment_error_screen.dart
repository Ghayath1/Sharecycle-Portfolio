import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/viewmodel/payment_view_model.dart';

/// Bildschirm, wenn die Zahlung fehlschlägt oder abgebrochen wurde
class PaymentErrorScreen extends StatelessWidget {
  final String? errorType;
  final String? errorMessage;

  const PaymentErrorScreen({
    super.key,
    this.errorType,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Fehlertyp/-nachricht ggf. aus den Routenparametern lesen
    final routeError = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final type = errorType ?? routeError?['type'] ?? 'unknown';
    final message = errorMessage ?? routeError?['message'] ?? 'Ein unbekannter Fehler ist aufgetreten.';

    debugPrint('❌ PaymentErrorScreen - Typ: $type, Nachricht: $message');
    debugPrint('❌ PaymentErrorScreen - Route extra: $routeError');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Fehler-Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getErrorIcon(type),
                  color: Colors.red[600],
                  size: 80,
                ),
              ),

              const SizedBox(height: 32),

              // Titel
              Text(
                _getErrorTitle(type),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Nachricht
              Text(
                _getErrorMessage(type, message),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Hilfe-Karte
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: orange, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Was ist passiert?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getHelpText(type),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Aktionen
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Zahlung zurücksetzen und erneut versuchen
                        context.read<PaymentViewModel>().reset();
                        context.go('/bikes');
                      },
                      child: Text(
                        _getRetryButtonText(type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (type != 'cancelled') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Hilfe/Support
                          context.read<PaymentViewModel>().reset();
                          context.go('/police'); // deine Hilfeseite
                        },
                        child: Text(
                          'Hilfe erhalten',
                          style: TextStyle(
                            color: orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon(String type) {
    switch (type) {
      case 'cancelled':
        return Icons.cancel;
      case 'network':
        return Icons.wifi_off;
      case 'timeout':
        return Icons.timer_off;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle(String type) {
    switch (type) {
      case 'cancelled':
        return 'Zahlung abgebrochen';
      case 'network':
        return 'Verbindungsfehler';
      case 'timeout':
        return 'Zeitüberschreitung';
      case 'auth_failed':
        return 'Zahlung fehlgeschlagen';
      default:
        return 'Zahlungsfehler';
    }
  }

  String _getErrorMessage(String type, String originalMessage) {
    switch (type) {
      case 'cancelled':
        return 'Du hast den Zahlungsvorgang abgebrochen. Es wurden keine Kosten berechnet.';
      case 'network':
        return 'Verbindung zu den Zahlungsdiensten nicht möglich. Bitte Internetverbindung prüfen und erneut versuchen.';
      case 'timeout':
        return 'Die Zahlungsanfrage hat zu lange gedauert. Bitte erneut versuchen.';
      case 'auth_failed':
        return 'Deine Zahlung konnte nicht autorisiert werden. Bitte Zahlungsdaten prüfen und erneut versuchen.';
      default:
        return originalMessage.isNotEmpty
            ? originalMessage
            : 'Bei der Zahlung ist ein Fehler aufgetreten. Bitte erneut versuchen.';
    }
  }

  String _getHelpText(String type) {
    switch (type) {
      case 'cancelled':
        return 'Du kannst jederzeit zur Fahrradauswahl zurückkehren und die Buchung erneut starten. Es wurden keine Zahlungsdaten gespeichert.';
      case 'network':
        return 'Bitte stelle eine stabile Internetverbindung sicher. Du kannst die Zahlung erneut versuchen, sobald die Verbindung wiederhergestellt ist.';
      case 'timeout':
        return 'Das passiert oft, wenn der Zahlungsdienst ausgelastet ist. Bitte einen Moment warten und erneut versuchen.';
      case 'auth_failed':
        return 'Prüfe, ob dein PayPal-Konto gedeckt ist und deine Zahlungsmethode gültig ist.';
      default:
        return 'Wenn das Problem weiterhin besteht, kontaktiere bitte den Support oder versuche eine andere Zahlungsmethode.';
    }
  }

  String _getRetryButtonText(String type) {
    switch (type) {
      case 'cancelled':
        return 'Erneut versuchen';
      case 'network':
        return 'Zahlung erneut versuchen';
      case 'timeout':
        return 'Erneut versuchen';
      case 'auth_failed':
        return 'Zahlung erneut versuchen';
      default:
        return 'Erneut versuchen';
    }
  }
}
