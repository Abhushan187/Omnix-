class HabitLog {
  int? id;
  String? remoteId;
  int? habitId;
  String? habitRemoteId;
  DateTime? date;
  int? completed;

  HabitLog({this.habitId, this.habitRemoteId, this.date, this.completed});
  HabitLog.withId({this.id, this.remoteId, this.habitId,
      this.habitRemoteId, this.date, this.completed});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (remoteId != null) map['remote_id'] = remoteId;
    if (habitId != null) map['habit_id'] = habitId;
    if (habitRemoteId != null) map['habit_remote_id'] = habitRemoteId;
    map['date'] = date?.toIso8601String();
    map['completed'] = completed ?? 0;
    return map;
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog.withId(
      id: map['id'],
      remoteId: map['remote_id'],
      habitId: map['habit_id'],
      habitRemoteId: map['habit_remote_id'],
      date: DateTime.parse(map['date']),
      completed: map['completed'],
    );
  }

  factory HabitLog.fromSupabase(Map<String, dynamic> map) {
    return HabitLog.withId(
      remoteId: map['id'],
      habitRemoteId: map['habit_id'],
      date: DateTime.parse(map['date']),
      completed: map['completed'],
    );
  }
}