import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../models/journal_model.dart';
import '../helpers/database_helper.dart';

class SyncService {
  static final _client = Supabase.instance.client;

  static String? get _userId => _client.auth.currentUser?.id;
  static bool get isOnline => _userId != null;

  // ─── TASKS ───────────────────────────────────────────
  static Future<void> pushTask(Task task, {bool isDelete = false}) async {
    if (!isOnline) return;
    try {
      if (isDelete) {
        if (task.remoteId != null) {
          await _client.from('tasks').delete().eq('id', task.remoteId!);
        }
        return;
      }
      final data = {
        'user_id': _userId,
        'title': task.title,
        'date': task.date?.toIso8601String(),
        'priority': task.priority,
        'status': task.status,
        'category': task.category ?? 'Personal',
      };
      if (task.remoteId != null) {
        await _client.from('tasks').update(data).eq('id', task.remoteId!);
      } else {
        final response = await _client
            .from('tasks')
            .insert(data)
            .select('id')
            .single();
        final remoteId = response['id'] as String;
        await DatabaseHelper.instance.updateTaskRemoteId(task.id!, remoteId);
      }
    } catch (e) {
      print('pushTask error: $e');
    }
  }

  static Future<void> pullTasks() async {
    if (!isOnline) return;
    try {
      final response =
          await _client.from('tasks').select().eq('user_id', _userId!);
      final remoteTasks =
          (response as List).map((m) => Task.fromSupabase(m)).toList();
      await DatabaseHelper.instance.replaceAllTasks(remoteTasks);
    } catch (e) {
      print('pullTasks error: $e');
    }
  }

  // Deletes ALL tasks for this user from Supabase
  static Future<void> deleteAllTasksRemote() async {
    if (!isOnline) return;
    try {
      await _client.from('tasks').delete().eq('user_id', _userId!);
    } catch (e) {
      print('deleteAllTasksRemote error: $e');
    }
  }

  // ─── HABITS ──────────────────────────────────────────
  static Future<String?> pushHabit(Habit habit,
      {bool isDelete = false}) async {
    if (!isOnline) return null;
    try {
      if (isDelete) {
        if (habit.remoteId != null) {
          await _client
              .from('habit_logs')
              .delete()
              .eq('habit_id', habit.remoteId!);
          await _client.from('habits').delete().eq('id', habit.remoteId!);
        }
        return null;
      }
      final data = {
        'user_id': _userId,
        'name': habit.name,
        'category': habit.category ?? 'Personal',
        'days': habit.days,
        'start_date': habit.startDate?.toIso8601String(),
        'end_date': habit.endDate?.toIso8601String(),
      };
      if (habit.remoteId != null) {
        await _client.from('habits').update(data).eq('id', habit.remoteId!);
        return habit.remoteId;
      } else {
        final response = await _client
            .from('habits')
            .insert(data)
            .select('id')
            .single();
        final remoteId = response['id'] as String;
        await DatabaseHelper.instance.updateHabitRemoteId(habit.id!, remoteId);
        return remoteId;
      }
    } catch (e) {
      print('pushHabit error: $e');
      return null;
    }
  }

  static Future<void> pullHabits() async {
    if (!isOnline) return;
    try {
      final habitsResponse =
          await _client.from('habits').select().eq('user_id', _userId!);
      final remoteHabits =
          (habitsResponse as List).map((m) => Habit.fromSupabase(m)).toList();

      final logsResponse =
          await _client.from('habit_logs').select().eq('user_id', _userId!);
      final remoteLogs =
          (logsResponse as List).map((m) => HabitLog.fromSupabase(m)).toList();

      await DatabaseHelper.instance.replaceAllHabits(remoteHabits, remoteLogs);
    } catch (e) {
      print('pullHabits error: $e');
    }
  }

  static Future<void> pushHabitLog(HabitLog log, String habitRemoteId) async {
    if (!isOnline) return;
    try {
      final data = {
        'user_id': _userId,
        'habit_id': habitRemoteId,
        'date': log.date?.toIso8601String(),
        'completed': log.completed,
      };
      if (log.remoteId != null) {
        await _client.from('habit_logs').update(data).eq('id', log.remoteId!);
      } else {
        final response = await _client
            .from('habit_logs')
            .insert(data)
            .select('id')
            .single();
        final remoteId = response['id'] as String;
        await DatabaseHelper.instance
            .updateHabitLogRemoteId(log.id!, remoteId);
      }
    } catch (e) {
      print('pushHabitLog error: $e');
    }
  }

  // Deletes ALL habits + logs for this user from Supabase
  static Future<void> deleteAllHabitsRemote() async {
    if (!isOnline) return;
    try {
      await _client.from('habit_logs').delete().eq('user_id', _userId!);
      await _client.from('habits').delete().eq('user_id', _userId!);
    } catch (e) {
      print('deleteAllHabitsRemote error: $e');
    }
  }

  // ─── JOURNAL ─────────────────────────────────────────
  static Future<void> pushJournalEntry(JournalEntry entry,
      {bool isDelete = false}) async {
    if (!isOnline) return;
    try {
      if (isDelete) {
        if (entry.remoteId != null) {
          await _client
              .from('journal_entries')
              .delete()
              .eq('id', entry.remoteId!);
        }
        return;
      }
      final data = {
        'user_id': _userId,
        'date': DateTime(entry.date!.year, entry.date!.month, entry.date!.day)
            .toIso8601String(),
        'content': entry.content ?? '',
        'mood': entry.mood ?? 3,
      };
      if (entry.remoteId != null) {
        await _client
            .from('journal_entries')
            .update(data)
            .eq('id', entry.remoteId!);
      } else {
        final response = await _client
            .from('journal_entries')
            .insert(data)
            .select('id')
            .single();
        final remoteId = response['id'] as String;
        if (entry.id != null) {
          await DatabaseHelper.instance
              .updateJournalRemoteId(entry.id!, remoteId);
        }
      }
    } catch (e) {
      print('pushJournalEntry error: $e');
    }
  }

  static Future<void> pullJournal() async {
    if (!isOnline) return;
    try {
      final response = await _client
          .from('journal_entries')
          .select()
          .eq('user_id', _userId!);
      final remoteEntries =
          (response as List).map((m) => JournalEntry.fromSupabase(m)).toList();
      await DatabaseHelper.instance.replaceAllJournal(remoteEntries);
    } catch (e) {
      print('pullJournal error: $e');
    }
  }

  // Deletes ALL journal entries for this user from Supabase
  static Future<void> deleteAllJournalRemote() async {
    if (!isOnline) return;
    try {
      await _client.from('journal_entries').delete().eq('user_id', _userId!);
    } catch (e) {
      print('deleteAllJournalRemote error: $e');
    }
  }

  // ─── FULL SYNC ───────────────────────────────────────
  static Future<void> pullAll() async {
    if (!isOnline) return;
    await Future.wait([
      pullTasks(),
      pullHabits(),
      pullJournal(),
    ]);
  }
}