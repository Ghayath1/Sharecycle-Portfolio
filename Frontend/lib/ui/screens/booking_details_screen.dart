import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/screens/bike_list_screen.dart';
import 'package:sharecycleapp/viewmodel/payment_view_model.dart';
import 'package:intl/intl.dart';
import 'dart:developer';

class BookingDetailsScreen extends StatelessWidget {
  final Bicycle bike;
  final DateTime from;
  final DateTime to;

  const BookingDetailsScreen({
    super.key,
    required this.bike,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    final days = to.difference(from).inDays + 1;
    final total = (bike.price ?? 0) * days;
    final dateFmt = DateFormat('yyyy-MM-dd');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        centerTitle: true,
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              Card(
                color: Colors.white,
                elevation: 2,
                shadowColor: orange.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image / placeholder
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 88,
                          width: 88,
                          child: (bike.imageUrl != null && bike.imageUrl!.trim().isNotEmpty)
                              ? Image.network(
                                  bike.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.pedal_bike, color: orange),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.pedal_bike, color: orange),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bike.name ?? 'Bike',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: orange),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    bike.city ?? 'Unknown location',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: orange.withOpacity(0.25)),
                              ),
                              child: Text(
                                '${bike.price ?? 0} € / day',
                                style: const TextStyle(color: orange, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Details
              Text('Booking details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: orange.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: orange),
                      title: const Text('From'),
                      subtitle: Text(dateFmt.format(from.toLocal())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.calendar_month, color: orange),
                      title: const Text('To'),
                      subtitle: Text(dateFmt.format(to.toLocal())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.timelapse, color: orange),
                      title: const Text('Number of days'),
                      subtitle: Text('$days'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.attach_money, color: orange),
                      title: const Text('Price per day'),
                      subtitle: Text('${bike.price ?? 0} €'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Total price highlight
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: orange.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Total', style: theme.textTheme.titleMedium),
                    ),
                    Text(
                      '${total} €',
                      style: theme.textTheme.titleMedium?.copyWith(color: orange, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: orange, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final idNum = int.tryParse(bike.id ?? '');
                        if (idNum == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ungültiger Fahrrad id')),
                          );
                          return;
                        }

                        final paymentViewModel = context.read<PaymentViewModel>();
                        try {
                          final success = await paymentViewModel.createPaymentOrder(
                            bicycleId: idNum,
                            dateFrom: from,
                            dateTo: to,
                          );
                          if (success && paymentViewModel.approvalUrl != null) {
                            context.go('/payment-approval', extra: paymentViewModel.approvalUrl);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(paymentViewModel.errorMessage ?? 'Failed to create payment order'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          log('Error creating payment order: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Proceed to Payment'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
