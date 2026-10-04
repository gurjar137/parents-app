class BusStop {
  final String stopName;
  final String morningPickupTime;
  final String afternoonDropTime;
  final bool isCompleted;
  final bool isStudentStop;

  const BusStop({
    required this.stopName,
    required this.morningPickupTime,
    required this.afternoonDropTime,
    this.isCompleted = false,
    this.isStudentStop = false,
  });
}

class TransportModel {
  final String studentId;
  final String busNumber; // e.g. "Bus #14 (DL-1PC-4829)"
  final String routeName; // e.g. "Route 12 - South Delhi & Green Park"
  final String driverName; // e.g. "Ram Singh"
  final String driverPhone; // "+91 98112 34567"
  final String helperName; // "Dinesh Kumar"
  final String currentStatus; // "On Route to School", "Arrived at School", "Departed School"
  final String estimatedArrival; // "7:45 AM"
  final double currentSpeedKmph; // 32.5
  final List<BusStop> routeStops;

  const TransportModel({
    required this.studentId,
    required this.busNumber,
    required this.routeName,
    required this.driverName,
    required this.driverPhone,
    required this.helperName,
    required this.currentStatus,
    required this.estimatedArrival,
    required this.currentSpeedKmph,
    required this.routeStops,
  });
}
