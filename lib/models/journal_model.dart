class JournalEntry {
  int? id;
  DateTime? date;
  String? content;
  int? mood;

  JournalEntry({this.date, this.content, this.mood});
  JournalEntry.withId({this.id, this.date, this.content, this.mood});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    map['date'] = DateTime(date!.year, date!.month, date!.day).toIso8601String();
    map['content'] = content ?? '';
    map['mood'] = mood ?? 3;
    return map;
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry.withId(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      content: map['content'] as String? ?? '',
      mood: map['mood'] as int? ?? 3,
    );
  }
}