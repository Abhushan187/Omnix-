import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../models/journal_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _db;

  DatabaseHelper._instance();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/omnix2.db';
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  void _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT, date TEXT, priority TEXT,
        status INTEGER, category TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, category TEXT, days TEXT,
        start_date TEXT, end_date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE habit_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER, date TEXT, completed INTEGER,
        FOREIGN KEY (habit_id) REFERENCES habits(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, icon_code INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE journal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE, content TEXT, mood INTEGER
      )
    ''');
  }

  void _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journal_entries(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT UNIQUE, content TEXT, mood INTEGER
        )
      ''');
    }
  }

  // ─── TASKS ───────────────────────────────────────────
  Future<List<Task>> getTaskList() async {
    Database db = await this.db;
    final maps = await db.query('tasks');
    final tasks = maps.map((m) => Task.fromMap(m)).toList();
    tasks.sort((a, b) => a.date!.compareTo(b.date!));
    return tasks;
  }

  Future<List<Task>> getTodayTasks() async {
    final all = await getTaskList();
    final today = DateTime.now();
    return all.where((t) {
      final d = t.date!;
      return t.status == 0 &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();
  }

  Future<int> insertTask(Task task) async {
    Database db = await this.db;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    Database db = await this.db;
    return await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(int id) async {
    Database db = await this.db;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllTasks() async {
    Database db = await this.db;
    return await db.delete('tasks');
  }

  // ─── HABITS ──────────────────────────────────────────
  Future<List<Habit>> getHabitList() async {
    Database db = await this.db;
    final maps = await db.query('habits');
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  Future<List<Habit>> getTodayHabits() async {
    final all = await getHabitList();
    final today = DateTime.now();
    return all.where((h) => h.isScheduledFor(today)).toList();
  }

  Future<int> insertHabit(Habit habit) async {
    Database db = await this.db;
    return await db.insert('habits', habit.toMap());
  }

  Future<int> updateHabit(Habit habit) async {
    Database db = await this.db;
    return await db.update('habits', habit.toMap(),
        where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabit(int id) async {
    Database db = await this.db;
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetHabitLogs(int habitId) async {
    Database db = await this.db;
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [habitId]);
  }

  Future<int> deleteAllHabits() async {
    Database db = await this.db;
    await db.delete('habit_logs');
    return await db.delete('habits');
  }

  // ─── HABIT LOGS ──────────────────────────────────────
  Future<List<HabitLog>> getLogsForHabit(int habitId) async {
    Database db = await this.db;
    final maps = await db.query('habit_logs',
        where: 'habit_id = ?', whereArgs: [habitId]);
    return maps.map((m) => HabitLog.fromMap(m)).toList();
  }

  Future<HabitLog?> getLogForDate(int habitId, DateTime date) async {
    Database db = await this.db;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    final maps = await db.query('habit_logs',
        where: 'habit_id = ? AND date = ?', whereArgs: [habitId, dateStr]);
    if (maps.isEmpty) return null;
    return HabitLog.fromMap(maps.first);
  }

  Future<void> toggleHabitLog(int habitId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final existing = await getLogForDate(habitId, dateOnly);
    Database db = await this.db;
    if (existing == null) {
      await db.insert('habit_logs',
          HabitLog(habitId: habitId, date: dateOnly, completed: 1).toMap());
    } else {
      final newVal = existing.completed == 1 ? 0 : 1;
      await db.update('habit_logs', {'completed': newVal},
          where: 'id = ?', whereArgs: [existing.id]);
    }
  }

  Future<int> getStreakForHabit(Habit habit) async {
    final logs = await getLogsForHabit(habit.id!);
    final completedDates = logs
        .where((l) => l.completed == 1)
        .map((l) => DateTime(l.date!.year, l.date!.month, l.date!.day))
        .toSet();
    int streak = 0;
    DateTime check = DateTime.now();
    int safetyLimit = 0;
    while (safetyLimit < 365) {
      safetyLimit++;
      final day = DateTime(check.year, check.month, check.day);
      if (!habit.isScheduledFor(day)) {
        check = check.subtract(const Duration(days: 1));
        continue;
      }
      if (completedDates.contains(day)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── JOURNAL ─────────────────────────────────────────
  Future<JournalEntry?> getJournalForDate(DateTime date) async {
    Database db = await this.db;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    final maps = await db.query('journal_entries',
        where: 'date = ?', whereArgs: [dateStr]);
    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }

  Future<List<JournalEntry>> getJournalEntriesForMonth(int year, int month) async {
    Database db = await this.db;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query('journal_entries',
        where: 'date >= ? AND date < ?', whereArgs: [start, end]);
    return maps.map((m) => JournalEntry.fromMap(m)).toList();
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    Database db = await this.db;
    final dateStr =
        DateTime(entry.date!.year, entry.date!.month, entry.date!.day)
            .toIso8601String();
    final existing = await db.query('journal_entries',
        where: 'date = ?', whereArgs: [dateStr]);
    if (existing.isEmpty) {
      await db.insert('journal_entries', entry.toMap());
    } else {
      await db.update('journal_entries', entry.toMap(),
          where: 'date = ?', whereArgs: [dateStr]);
    }
  }

  Future<int> deleteAllJournalEntries() async {
    Database db = await this.db;
    return await db.delete('journal_entries');
  }

  // ─── CUSTOM CATEGORIES ───────────────────────────────
  Future<List<Map<String, dynamic>>> getCustomCategories() async {
    Database db = await this.db;
    return await db.query('custom_categories');
  }

  Future<int> insertCustomCategory(String name, int iconCode) async {
    Database db = await this.db;
    return await db
        .insert('custom_categories', {'name': name, 'icon_code': iconCode});
  }

  Future<int> deleteCustomCategory(int id) async {
    Database db = await this.db;
    return await db
        .delete('custom_categories', where: 'id = ?', whereArgs: [id]);
  }
}