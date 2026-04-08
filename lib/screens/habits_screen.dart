import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/habit_model.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({Key? key}) : super(key: key);

  @override
  _HabitsScreenState createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  Map<int, bool> _todayStatus = {};
  Map<int, int> _streaks = {};
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Personal', 'Work', 'Study', 'Health'];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await DatabaseHelper.instance.getHabitList();
    final Map<int, bool> status = {};
    final Map<int, int> streaks = {};
    for (final h in habits) {
      final log = await DatabaseHelper.instance.getLogForDate(h.id!, DateTime.now());
      status[h.id!] = log?.completed == 1;
      streaks[h.id!] = await DatabaseHelper.instance.getStreakForHabit(h);
    }
    if (mounted) {
      setState(() {
        _habits = habits;
        _todayStatus = status;
        _streaks = streaks;
      });
    }
  }

  List<Habit> get _filteredHabits => _habits
      .where((h) => _selectedCategory == 'All' || h.category == _selectedCategory)
      .toList();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHabitScreen()),
        ).then((_) => _loadHabits()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text('Habits',
                style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.bold, color: primary)),
            Text('Build your streaks',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 20),

            // Category filter
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected ? primary : Colors.grey.shade400),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade500)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (_filteredHabits.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(Icons.loop_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No habits yet.\nTap + to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              )
            else
              ..._filteredHabits.map((habit) => _buildHabitCard(habit)),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final primary = Theme.of(context).colorScheme.primary;
    final bool isDoneToday = _todayStatus[habit.id] ?? false;
    final int streak = _streaks[habit.id] ?? 0;
    final List<String> allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
      ).then((_) => _loadHabits()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(habit.category ?? 'Personal',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: primary,
                                      fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.local_fire_department_rounded,
                                size: 14,
                                color: streak > 0
                                    ? Colors.orange
                                    : Colors.grey.shade400),
                            const SizedBox(width: 2),
                            Text('$streak day streak',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: streak > 0
                                        ? Colors.orange
                                        : Colors.grey.shade400,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Today check button
                  if (habit.isScheduledFor(DateTime.now()))
                    GestureDetector(
                      onTap: () async {
                        await DatabaseHelper.instance
                            .toggleHabitLog(habit.id!, DateTime.now());
                        _loadHabits();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDoneToday ? primary : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 20,
                            color: isDoneToday
                                ? Colors.white
                                : Colors.grey.shade400),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: allDays.map((day) {
                  final isActive = habit.daysList.contains(day);
                  return Container(
                    width: 34,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isActive
                          ? primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isActive ? primary : Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(day[0],
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? primary
                                  : Colors.grey.shade400)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}