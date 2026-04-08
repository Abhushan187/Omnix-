import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../helpers/database_helper.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import 'add_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  const HabitDetailScreen({Key? key, required this.habit}) : super(key: key);

  @override
  _HabitDetailScreenState createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  List<HabitLog> _logs = [];
  DateTime _focusedMonth = DateTime.now();
  int _streak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await DatabaseHelper.instance.getLogsForHabit(widget.habit.id!);
    final streak = await DatabaseHelper.instance.getStreakForHabit(widget.habit);
    if (mounted) {
      setState(() {
        _logs = logs;
        _streak = streak;
        _isLoading = false;
      });
    }
  }

  Set<DateTime> get _completedDays => _logs
      .where((l) => l.completed == 1)
      .map((l) => DateTime(l.date!.year, l.date!.month, l.date!.day))
      .toSet();

  double get _thisMonthCompletion {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    int scheduled = 0;
    int completed = 0;

    for (int i = 0; i < now.day; i++) {
      final day = startOfMonth.add(Duration(days: i));
      if (widget.habit.isScheduledFor(day)) {
        scheduled++;
        if (_completedDays.contains(day)) completed++;
      }
    }
    if (scheduled == 0) return 0;
    return completed / scheduled;
  }

  Future<void> _toggleDay(DateTime day) async {
    final today = DateTime.now();
    final dayOnly = DateTime(day.year, day.month, day.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Block future dates
    if (dayOnly.isAfter(todayOnly)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can't mark future dates")),
      );
      return;
    }

    // Block days not scheduled
    if (!widget.habit.isScheduledFor(dayOnly)) return;

    await DatabaseHelper.instance.toggleHabitLog(widget.habit.id!, dayOnly);
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completionPct = (_thisMonthCompletion * 100).toStringAsFixed(0);

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  // Back + Edit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios, color: primary),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddHabitScreen(habit: widget.habit),
                          ),
                        ).then((_) => Navigator.pop(context)),
                        icon: Icon(Icons.edit_outlined, color: primary, size: 18),
                        label: Text('Edit',
                            style: TextStyle(color: primary, fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name + category
                  Text(widget.habit.name ?? '',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(widget.habit.category ?? 'Personal',
                        style: TextStyle(
                            fontSize: 13,
                            color: primary,
                            fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      _statCard('🔥 Streak', '$_streak days', Colors.orange),
                      const SizedBox(width: 12),
                      _statCard(
                          '📅 This Month', '$completionPct%', primary),
                      const SizedBox(width: 12),
                      _statCard('✅ Total',
                          '${_completedDays.length} days', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Calendar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: widget.habit.startDate ??
                          DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.now(),
                      focusedDay: _focusedMonth,
                      onPageChanged: (focused) =>
                          setState(() => _focusedMonth = focused),
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      onDaySelected: (selected, focused) {
                        setState(() => _focusedMonth = focused);
                        _toggleDay(selected);
                      },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                        leftChevronIcon: Icon(Icons.chevron_left,
                            color: isDark ? Colors.white : Colors.black87),
                        rightChevronIcon: Icon(Icons.chevron_right,
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey,
                            fontSize: 12),
                        weekendStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey,
                            fontSize: 12),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        weekendTextStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        todayDecoration: BoxDecoration(
                            color: primary.withOpacity(0.3),
                            shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(
                            color: primary, shape: BoxShape.circle),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final dayOnly = DateTime(day.year, day.month, day.day);
                          final isScheduled = widget.habit.isScheduledFor(dayOnly);
                          final isCompleted = _completedDays.contains(dayOnly);
                          final isFuture = dayOnly.isAfter(
                              DateTime.now());

                          if (!isScheduled) {
                            return Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade300,
                                    fontSize: 14),
                              ),
                            );
                          }

                          if (isFuture) {
                            return Center(
                              child: Text('${day.day}',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontSize: 14)),
                            );
                          }

                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade400
                                  : Colors.red.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${day.day}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(Colors.green.shade400, 'Completed'),
                      const SizedBox(width: 20),
                      _legendDot(Colors.red.shade300, 'Missed'),
                      const SizedBox(width: 20),
                      _legendDot(Colors.grey.shade300, 'Not scheduled'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}