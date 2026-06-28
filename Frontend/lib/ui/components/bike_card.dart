import 'package:flutter/material.dart';
import 'package:sharecycleapp/theme/color.dart';

class BikeCard extends StatelessWidget {
  final String image;               // asset *or* network URL
  final String title;
  final String location;
  final String date;
  final String price;
  final VoidCallback onDelete;

  /// Optional headers for protected images (falls du welche brauchst)
  final Map<String, String>? networkHeaders;

  const BikeCard({
    super.key,
    required this.image,
    required this.title,
    required this.location,
    required this.date,
    required this.price,
    required this.onDelete,
    this.networkHeaders,
  });

  bool get _isNetwork =>
      image.startsWith('http://') || image.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final imgWidget = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: _isNetwork
          ? Image.network(
              image,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
              headers: networkHeaders,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : Image.asset(
              image,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
    );

    return Container(
      width: 160,
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
          Stack(
            children: [
              imgWidget,
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: orange),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 13, color: orange),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: onDelete,
              child: const Text(
                "löschen",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 90,
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(Icons.pedal_bike, size: 36, color: Colors.black26),
        ),
      );
}
