import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/viewmodel/payment_view_model.dart';

/// Bildschirm nach erfolgreicher Zahlung
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // Erfolgs-Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 80,
                  ),
                ),

                const SizedBox(height: 32),

                // Titel
                const Text(
                  'Zahlung erfolgreich!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Nachricht
                Text(
                  'Deine Fahrradmiete wurde erfolgreich gebucht. '
                  'Du erhältst in Kürze eine Bestätigungs-E-Mail.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Buchungsdetails
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
                          Icon(Icons.receipt, color: orange, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Buchungsdetails',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Status', 'Bestätigt', Colors.green),
                      _buildDetailRow('Zahlung', 'Autorisiert', Colors.green),
                      const SizedBox(height: 8),
                      Text(
                        'Du kannst deine Buchung unter „Bestellungen“ einsehen.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

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
                          // Status zurücksetzen und zu „Meine Bestellungen“
                          context.read<PaymentViewModel>().reset();
                          context.go('/my-orders');
                        },
                        child: const Text(
                          'Meine Buchungen ansehen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

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
                          // Status zurücksetzen und zur Fahrradliste
                          context.read<PaymentViewModel>().reset();
                          context.go('/bikes');
                        },
                        child: Text(
                          'Weiteres Fahrrad buchen',
                          style: TextStyle(
                            color: orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
