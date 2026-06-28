import 'package:flutter/material.dart';
import 'package:sharecycleapp/services/payment_service.dart';
import 'package:sharecycleapp/payment_models.dart';

/// Zahlungszustände
enum PaymentState {
  idle,              // kein Prozess
  creatingOrder,     // Zahlungsauftrag wird erstellt
  awaitingApproval,  // Warten auf PayPal-Freigabe
  authorizing,       // Zahlung wird autorisiert
  completed,         // Zahlung erfolgreich
  failed,            // Zahlung fehlgeschlagen
  cancelled,         // Zahlung abgebrochen
}

/// ViewModel für den Zahlungsablauf
class PaymentViewModel extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  PaymentState _state = PaymentState.idle;
  String? _errorMessage;
  String? _currentOrderId;
  String? _approvalUrl;
  String? _paypalOrderId;

  // Getter
  PaymentState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get currentOrderId => _currentOrderId;
  String? get approvalUrl => _approvalUrl;
  String? get paypalOrderId => _paypalOrderId;

  bool get isLoading =>
      _state == PaymentState.creatingOrder || _state == PaymentState.authorizing;

  bool get hasError => _state == PaymentState.failed;
  bool get isCompleted => _state == PaymentState.completed;
  bool get isCancelled => _state == PaymentState.cancelled;

  /// Zurücksetzen
  void reset() {
    _state = PaymentState.idle;
    _errorMessage = null;
    _currentOrderId = null;
    _approvalUrl = null;
    _paypalOrderId = null;
    notifyListeners();
  }

  /// Zahlungsauftrag erstellen
  Future<bool> createPaymentOrder({
    required int bicycleId,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    _setState(PaymentState.creatingOrder);

    try {
      final response = await _paymentService.createPaymentOrder(
        bicycleId: bicycleId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      if (response.hasApprovalUrl) {
        _currentOrderId = response.orderId;
        _approvalUrl = response.approvalUrl;
        _paypalOrderId = response.paypalOrderId;
        _setState(PaymentState.awaitingApproval);
        return true;
      } else {
        _setError('Keine Freigabe-URL vom Zahlungsdienst erhalten.');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Zahlung nach PayPal-Freigabe autorisieren
  Future<bool> authorizePayment(String paypalOrderId) async {
    _setState(PaymentState.authorizing);

    try {
      await _paymentService.authorizePayment(paypalOrderId);
      _setState(PaymentState.completed);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void cancelPayment() {
    _setState(PaymentState.cancelled);
  }

  void setPaymentError(String error) {
    _setError(error);
  }

  void _setState(PaymentState newState) {
    _state = newState;
    if (newState != PaymentState.failed) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String error) {
    _state = PaymentState.failed;
    _errorMessage = error;
    notifyListeners();
  }

  /// PayPal-Redirect verarbeiten
  void handlePayPalRedirect(PayPalRedirectParams params) {
    if (params.isSuccess && params.paypalOrderId != null) {
      _paypalOrderId = params.paypalOrderId;
      _setState(PaymentState.authorizing);
      _authorizePaymentAfterRedirect(params.paypalOrderId!);
    } else if (params.isCancelled) {
      _setState(PaymentState.cancelled);
    } else if (params.hasError) {
      _setError(params.error ?? 'Fehler beim PayPal-Redirect');
    } else {
      _setError('Unbekanntes Redirect-Ergebnis');
    }
  }

  Future<void> _authorizePaymentAfterRedirect(String paypalOrderId) async {
    try {
      await _paymentService.authorizePayment(paypalOrderId);
      _setState(PaymentState.completed);
    } catch (e) {
      _setError(e.toString());
    }
  }
}
