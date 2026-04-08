class HabitLog {
  int? id;
  int? habitId;
  DateTime? date;
  int? completed; // 0 or 1

  HabitLog({this.habitId, this.date, this.completed});
  HabitLog.withId({this.id, this.habitId, this.date, this.completed});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    map['habit_id'] = habitId;
    map['date'] = date?.toIso8601String();
    map['completed'] = completed ?? 0;
    return map;
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog.withId(
      id: map['id'],
      habitId: map['habit_id'],
      date: DateTime.parse(map['date']),
      completed: map['completed'],
    );
  }
}