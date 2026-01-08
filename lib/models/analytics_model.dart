class DailyAnalytics {
  final DateTime date;
  final int views;
  final int orderClicks;

  DailyAnalytics({
    required this.date,
    required this.views,
    required this.orderClicks,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'views': views,
      'orderClicks': orderClicks,
    };
  }

  factory DailyAnalytics.fromMap(Map<String, dynamic> map) {
    return DailyAnalytics(
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      views: map['views'] ?? 0,
      orderClicks: map['orderClicks'] ?? 0,
    );
  }
}
