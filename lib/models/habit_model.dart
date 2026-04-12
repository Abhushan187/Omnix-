class Habit {
  int? id;
  String? remoteId;
  String? name;
  String? category;
  String? days;
  DateTime? startDate;
  DateTime? endDate;

  Habit({this.name, this.category, this.days, this.startDate, this.endDate});
  Habit.withId({this.id, this.remoteId, this.name, this.category,
      this.days, this.startDate, this.endDate});

  List<String> get daysList =>
      days?.split(',').map((d) => d.trim()).toList() ?? [];

  bool isScheduledFor(DateTime date) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[date.weekday - 1];
    return daysList.contains(dayName);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (remoteId != null) map['remote_id'] = remoteId;
    map['name'] = name;
    map['category'] = category ?? 'Personal';
    map['days'] = days ?? 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';
    map['start_date'] = startDate?.toIso8601String();
    map['end_date'] = endDate?.toIso8601String();
    return map;
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit.withId(
      id: map['id'],
      remoteId: map['remote_id'],
      name: map['name'],
      category: map['category'] ?? 'Personal',
      days: map['days'],
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'])
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'])
          : null,
    );
  }

  factory Habit.fromSupabase(Map<String, dynamic> map) {
    return Habit.withId(
      remoteId: map['id'],
      name: map['name'],
      category: map['category'] ?? 'Personal',
      days: map['days'],
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'])
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'])
          : null,
    );
  }
}