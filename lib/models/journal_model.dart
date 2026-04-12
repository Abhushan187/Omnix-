class JournalEntry {
  int? id;
  String? remoteId;
  DateTime? date;
  String? content;
  int? mood;

  JournalEntry({this.date, this.content, this.mood});
  JournalEntry.withId({this.id, this.remoteId, this.date,
      this.content, this.mood});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (remoteId != null) map['remote_id'] = remoteId;
    map['date'] = DateTime(date!.year, date!.month, date!.day)
        .toIso8601String();
    map['content'] = content ?? '';
    map['mood'] = mood ?? 3;
    return map;
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry.withId(
      id: map['id'],
      remoteId: map['remote_id'],
      date: DateTime.parse(map['date']),
      content: map['content'] as String? ?? '',
      mood: map['mood'] as int? ?? 3,
    );
  }

  factory JournalEntry.fromSupabase(Map<String, dynamic> map) {
    return JournalEntry.withId(
      remoteId: map['id'],
      date: DateTime.parse(map['date']),
      content: map['content'] as String? ?? '',
      mood: map['mood'] as int? ?? 3,
    );
  }
}