// lib/models/home/home_widget_model.dart

class HomeWidget {
  final String widgetType;
  final int priority;
  final Map<String, dynamic> data;

  const HomeWidget({
    required this.widgetType,
    required this.priority,
    required this.data,
  });

  factory HomeWidget.fromJson(Map<String, dynamic> json) {
    return HomeWidget(
      widgetType: json['widget_type'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }
}
