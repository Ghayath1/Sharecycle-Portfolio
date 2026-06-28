import 'package:sharecycleapp/ui/screens/bike_list_screen.dart';

class BookingDetails {
  final Bicycle bike;
  final DateTime from;
  final DateTime to;

  BookingDetails({
    required this.bike,
    required this.from,
    required this.to,
  });
}
