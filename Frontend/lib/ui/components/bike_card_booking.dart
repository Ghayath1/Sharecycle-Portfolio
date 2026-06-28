import 'package:flutter/material.dart';
import 'package:sharecycleapp/theme/color.dart';

class BikeCardBooking extends StatelessWidget {
  final String image; // asset or network URL
  final String title;
  final String location;
  final String date;
  final String price;
  final VoidCallback onBook;

  /// Optional headers for protected images (e.g., Authorization)
  final Map<String, String>? networkHeaders;

  const BikeCardBooking({
    super.key,
    required this.image,
    required this.title,
    required this.location,
    required this.date,
    required this.price,
    required this.onBook,
    this.networkHeaders,
  });

  bool get _isNetwork =>
      image.startsWith('http://') || image.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final img = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: _isNetwork
          ? Image.network(
              image,
              height: 85, // 🚨 Slightly reduced from 90
              width: double.infinity,
              fit: BoxFit.cover,
              headers: networkHeaders,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : Image.asset(
              image,
              height: 85, // 🚨 Slightly reduced from 90
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: orange, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image section with fixed height
          SizedBox(
            height: 85,
            child: Stack(
              children: [
                img,
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 90),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content section with flexible layout
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4), //
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), //
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3), //

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: orange), //
                      const SizedBox(width: 4), //
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 13, color: Colors.black54), //
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3), //

                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: orange), //
                      const SizedBox(width: 4), //
                      Expanded(
                        child: Text(
                          date,
                          style: const TextStyle(fontSize: 13, color: Colors.black54), //
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16), //

                  // Button with fixed height
                  SizedBox(
                    height: 32, //
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: EdgeInsets.zero, //
                      ),
                      onPressed: onBook,
                      child: const Text(
                        'Buchen',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14, //
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 85, // 🚨 Match the image height
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.pedal_bike, size: 36, color: Colors.black26),
        ),
      );
}
