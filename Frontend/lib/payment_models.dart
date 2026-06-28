// Zahlungsdaten-Modelle für die PayPal-Integration

import 'package:flutter/foundation.dart';

/// Antwort von POST /api/payment/orders
/// Enthält die PayPal-Approval-URL und Auftragsdetails
class PaymentOrderResponse {
  final String? approvalUrl;
  final String? orderId;
  final String? status;
  final String? paypalOrderId;
  final DateTime? createdAt;
  final String? message;

  const PaymentOrderResponse({
    this.approvalUrl,
    this.orderId,
    this.status,
    this.paypalOrderId,
    this.createdAt,
    this.message,
  });

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    return PaymentOrderResponse(
      approvalUrl: json['approvalUrl']?.toString(),
      orderId: json['orderId']?.toString() ?? json['id']?.toString(),
      status: json['status']?.toString(),
      paypalOrderId: json['paypalOrderId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (approvalUrl != null) 'approvalUrl': approvalUrl,
      if (orderId != null) 'orderId': orderId,
      if (status != null) 'status': status,
      if (paypalOrderId != null) 'paypalOrderId': paypalOrderId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (message != null) 'message': message,
    };
  }

  bool get hasApprovalUrl => approvalUrl != null && approvalUrl!.isNotEmpty;

  @override
  String toString() =>
      'PaymentOrderResponse(status: $status, hasApprovalUrl: $hasApprovalUrl)';
}

/// Request für POST /api/payment/orders/{paypalOrderId}/authorize
class PaymentAuthorizationRequest {
  final String paypalOrderId;
  final String? authorizationId;

  const PaymentAuthorizationRequest({
    required this.paypalOrderId,
    this.authorizationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'paypalOrderId': paypalOrderId,
      if (authorizationId != null) 'authorizationId': authorizationId,
    };
  }

  @override
  String toString() =>
      'PaymentAuthorizationRequest(paypalOrderId: $paypalOrderId)';
}

/// Parameter, die vom PayPal-Redirect zurückgegeben werden
class PayPalRedirectParams {
  final String? paypalOrderId;
  final bool? success;
  final String? error;
  final String? cancelReason;

  const PayPalRedirectParams({
    this.paypalOrderId,
    this.success,
    this.error,
    this.cancelReason,
  });

  factory PayPalRedirectParams.fromUrl(String url) {
    debugPrint('🔗 PayPalRedirectParams - URL wird geparst: $url');
    try {
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      debugPrint('🔗 PayPalRedirectParams - Alle Query-Parameter: $params');
      debugPrint('🔗 PayPalRedirectParams - Pfad: ${uri.path}');
      debugPrint('🔗 PayPalRedirectParams - Host: ${uri.host}');

      // PayPal leitet typischerweise mit Parametern weiter wie:
      // success=1, orderId=PAYPAL_ORDER_ID, error=FEHLER
      // oder: token=PAYPAL_ORDER_ID, PayerID=PAYER_ID
      // oder: paymentId=PAYPAL_ORDER_ID, paymentToken=TOKEN
      // oder: success=true&token=ORDER_ID (Erfolg zurück zur App)
      // oder: /checkout/success?token=ORDER_ID&PayerID=PAYER_ID (PayPal-Erfolg)
      final paypalOrderId =
          params['orderId'] ?? params['token'] ?? params['paymentId'];

      final success = params['success'] == '1' ||
          params['success'] == 'true' ||
          params['return']?.contains('success') == true ||
          params['action']?.contains('success') == true ||
          (paypalOrderId != null && params['token'] != null) ||
          (params['success'] != null && paypalOrderId != null) ||
          (params['token'] != null && params['PayerID'] != null) || // 🎯 PayPal-Erfolgsformat
          (url.contains('/checkout/success') && params['token'] != null); // 🎯 PayPal-Checkout-Erfolg

      final error = params['error'] ?? params['error_description'];
      // ⚠️ Hinweis: Der Textwert 'cancelled' lassen wir bewusst auf Englisch,
      // da die Logik an anderer Stelle ggf. genau diesen String erwartet.
      final cancelReason = params['cancelReason'] ??
          (params['return']?.contains('cancel') == true ? 'cancelled' : null);

      debugPrint('🔗 PayPalRedirectParams - Extrahierte Werte:');
      debugPrint('   • paypalOrderId: $paypalOrderId');
      debugPrint('   • success: $success');
      debugPrint('   • error: $error');
      debugPrint('   • cancelReason: $cancelReason');

      final result = PayPalRedirectParams(
        paypalOrderId: paypalOrderId,
        success: success,
        error: error,
        cancelReason: cancelReason,
      );

      debugPrint('🔗 PayPalRedirectParams - Ergebnis: $result');
      return result;
    } catch (e) {
      debugPrint('🔗 PayPalRedirectParams - Fehler beim Parsen der URL: $e');
      return const PayPalRedirectParams();
    }
  }

  bool get isSuccess =>
      success == true &&
      paypalOrderId != null &&
      paypalOrderId!.isNotEmpty &&
      error == null &&
      cancelReason == null;

  bool get isCancelled =>
      success == false ||
      cancelReason != null ||
      (error != null && error!.contains('cancel'));

  bool get hasError => error != null && error!.isNotEmpty;

  @override
  String toString() =>
      'PayPalRedirectParams(success: $success, paypalOrderId: $paypalOrderId, error: $error)';
}
