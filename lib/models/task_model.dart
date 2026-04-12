class Task {
  int? id;
  String? remoteId;
  String? title;
  DateTime? date;
  String? priority;
  int? status;
  String? category;

  Task({this.title, this.date, this.priority, this.status, this.category});
  Task.withId({this.id, this.remoteId, this.title, this.date,
      this.priority, this.status, this.category});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (remoteId != null) map['remote_id'] = remoteId;
    map['title'] = title;
    map['date'] = date!.toIso8601String();
    map['priority'] = priority;
    map['status'] = status;
    map['category'] = category ?? 'Personal';
    return map;
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task.withId(
      id: map['id'],
      remoteId: map['remote_id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      priority: map['priority'],
      status: map['status'],
      category: map['category'] ?? 'Personal',
    );
  }

  factory Task.fromSupabase(Map<String, dynamic> map) {
    return Task.withId(
      remoteId: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      priority: map['priority'],
      status: map['status'],
      category: map['category'] ?? 'Personal',
    );
  }
}