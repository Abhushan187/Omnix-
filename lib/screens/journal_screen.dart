import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import '../helpers/database_helper.dart';
import '../models/journal_model.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Diary tab
  DateTime _selectedDay = DateTime.now();
  JournalEntry? _selectedEntry;
  final TextEditingController _contentController = TextEditingController();
  int _selectedMood = 3;
  bool _isLoading = true;
  bool _isSaving = false;

  // Calendar tab
  DateTime _calendarFocused = DateTime.now();
  DateTime? _calendarSelected;
  JournalEntry? _calendarEntry;
  List<JournalEntry> _monthEntries = [];
  bool _isCalendarCollapsed = false;
  bool _isEditingCalendarEntry = false;
  final TextEditingController _calendarContentController =
      TextEditingController();
  int _calendarMood = 3;
  bool _isSavingCalendar = false;

  // Stats tab
  List<JournalEntry> _allEntries = [];
  int _trendDays = 7;
  int _distDays = 30;
  final List<int> _dayOptions = [7, 15, 30, 90];

  final List<Map<String, dynamic>> _moods = [
    {'value': 1, 'emoji': '😢', 'label': 'Very Sad', 'color': Colors.red},
    {'value': 2, 'emoji': '😕', 'label': 'Little Sad', 'color': Colors.amber},
    {'value': 3, 'emoji': '😐', 'label': 'Neutral', 'color': Colors.blue},
    {
      'value': 4,
      'emoji': '🙂',
      'label': 'Happy',
      'color': const Color(0xFF86EFAC)
    },
    {
      'value': 5,
      'emoji': '😄',
      'label': 'Very Happy',
      'color': const Color(0xFF22C55E)
    },
  ];

  Color _moodColor(int mood) {
    final m =
        _moods.firstWhere((m) => m['value'] == mood, orElse: () => _moods[2]);
    return m['color'] as Color;
  }

  String _moodEmoji(int mood) {
    final m =
        _moods.firstWhere((m) => m['value'] == mood, orElse: () => _moods[2]);
    return m['emoji'] as String;
  }

  String _moodLabel(int mood) {
    final m =
        _moods.firstWhere((m) => m['value'] == mood, orElse: () => _moods[2]);
    return m['label'] as String;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadDiaryDay();
    _loadMonth();
    _loadAllEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    _calendarContentController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryDay() async {
    if (mounted) setState(() => _isLoading = true);
    final entry =
        await DatabaseHelper.instance.getJournalForDate(_selectedDay);
    if (mounted) {
      setState(() {
        _selectedEntry = entry;
        _contentController.text = entry?.content ?? '';
        _selectedMood = entry?.mood ?? 3;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonth() async {
    final entries = await DatabaseHelper.instance
        .getJournalEntriesForMonth(
            _calendarFocused.year, _calendarFocused.month);
    if (mounted) setState(() => _monthEntries = entries);
  }

  Future<void> _loadAllEntries() async {
    final db = await DatabaseHelper.instance.db;
    final maps = await db.query('journal_entries', orderBy: 'date ASC');
    if (mounted) {
      setState(() {
        _allEntries = maps.map((m) => JournalEntry.fromMap(m)).toList();
      });
    }
  }

  Future<void> _saveDiary() async {
    setState(() => _isSaving = true);
    final entry = JournalEntry(
      date: _selectedDay,
      content: _contentController.text.trim(),
      mood: _selectedMood,
    );
    if (_selectedEntry != null) entry.id = _selectedEntry!.id;
    await DatabaseHelper.instance.saveJournalEntry(entry);
    await _loadDiaryDay();
    await _loadMonth();
    await _loadAllEntries();
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Journal saved!'),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _saveCalendarEntry() async {
    if (_calendarSelected == null) return;
    setState(() => _isSavingCalendar = true);
    final entry = JournalEntry(
      date: _calendarSelected!,
      content: _calendarContentController.text.trim(),
      mood: _calendarMood,
    );
    if (_calendarEntry != null) entry.id = _calendarEntry!.id;
    await DatabaseHelper.instance.saveJournalEntry(entry);
    await _loadMonth();
    await _loadAllEntries();
    final updated = await DatabaseHelper.instance
        .getJournalForDate(_calendarSelected!);
    if (mounted) {
      setState(() {
        _calendarEntry = updated;
        _isSavingCalendar = false;
        _isEditingCalendarEntry = false;
        _isCalendarCollapsed = false;
      });
    }
  }

  Future<void> _deleteCalendarEntry() async {
    if (_calendarEntry == null || _calendarEntry!.id == null) return;
    final db = await DatabaseHelper.instance.db;
    await db.delete('journal_entries',
        where: 'id = ?', whereArgs: [_calendarEntry!.id]);
    await _loadMonth();
    await _loadAllEntries();
    if (mounted) {
      setState(() {
        _calendarEntry = null;
        _isEditingCalendarEntry = false;
        _isCalendarCollapsed = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Entry deleted'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Map<DateTime, JournalEntry> get _entryMap {
    final map = <DateTime, JournalEntry>{};
    for (final e in _monthEntries) {
      if (e.date != null) {
        map[DateTime(e.date!.year, e.date!.month, e.date!.day)] = e;
      }
    }
    return map;
  }

  int get _currentStreak {
    if (_allEntries.isEmpty) return 0;
    int streak = 0;
    DateTime check = DateTime.now();
    final dates = _allEntries
        .map((e) => DateTime(e.date!.year, e.date!.month, e.date!.day))
        .toSet();
    while (true) {
      final day = DateTime(check.year, check.month, check.day);
      if (dates.contains(day)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int get _longestStreak {
    if (_allEntries.isEmpty) return 0;
    final dates = _allEntries
        .map((e) => DateTime(e.date!.year, e.date!.month, e.date!.day))
        .toList()
      ..sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return longest;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Journal',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: primary)),
                  Text('Track your feelings',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pill tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(26),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Diary'),
                  Tab(text: 'Calendar'),
                  Tab(text: 'Statistics'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiaryTab(isDark, primary),
                  _buildCalendarTab(isDark, primary),
                  _buildStatsTab(isDark, primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DIARY TAB ───────────────────────────────────────
  Widget _buildDiaryTab(bool isDark, Color primary) {
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final today = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isToday
                  ? "Today's Entry"
                  : DateFormat('EEEE, MMM d').format(_selectedDay),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            if (!isToday)
              TextButton(
                onPressed: () {
                  setState(() => _selectedDay = DateTime.now());
                  _loadDiaryDay();
                },
                child: Text('Today',
                    style: TextStyle(color: primary, fontSize: 13)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          // Mood selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.map((m) {
              final isSelected = _selectedMood == m['value'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedMood = m['value'] as int),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (m['color'] as Color).withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? (m['color'] as Color)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(m['emoji'] as String,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        (m['label'] as String).split(' ').last,
                        style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? (m['color'] as Color)
                                : Colors.grey.shade500,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade200),
            ),
            child: TextField(
              controller: _contentController,
              maxLines: 8,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Write about your day, thoughts, feelings...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveDiary,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Entry',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  // ── CALENDAR TAB ────────────────────────────────────
  Widget _buildCalendarTab(bool isDark, Color primary) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isFutureSelected = _calendarSelected != null &&
        DateTime(_calendarSelected!.year, _calendarSelected!.month,
                _calendarSelected!.day)
            .isAfter(todayOnly);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // Calendar — collapses when editing
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isCalendarCollapsed
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Container(
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
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _calendarFocused,
              selectedDayPredicate: (day) =>
                  _calendarSelected != null &&
                  isSameDay(_calendarSelected!, day),
              onDaySelected: (selected, focused) async {
                final selOnly = DateTime(
                    selected.year, selected.month, selected.day);
                if (selOnly.isAfter(todayOnly)) return;
                setState(() {
                  _calendarSelected = selected;
                  _calendarFocused = focused;
                  _calendarEntry = null;
                  _isEditingCalendarEntry = false;
                  _isCalendarCollapsed = false;
                });
                final entry = await DatabaseHelper.instance
                    .getJournalForDate(selected);
                if (mounted) setState(() => _calendarEntry = entry);
              },
              onPageChanged: (focused) {
                setState(() => _calendarFocused = focused);
                _loadMonth();
              },
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
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
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                    fontSize: 12),
                weekendStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
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
                disabledTextStyle:
                    TextStyle(color: Colors.grey.shade300),
              ),
              enabledDayPredicate: (day) {
                final dayOnly =
                    DateTime(day.year, day.month, day.day);
                return !dayOnly.isAfter(todayOnly);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final dayOnly =
                      DateTime(day.year, day.month, day.day);
                  final entry = _entryMap[dayOnly];
                  if (entry == null) return null;
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _moodColor(entry.mood ?? 3)
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${day.day}',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                },
              ),
            ),
          ),
          secondChild: GestureDetector(
            onTap: () => setState(() {
              _isCalendarCollapsed = false;
              _isEditingCalendarEntry = false;
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: primary, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _calendarSelected != null
                        ? DateFormat('EEEE, MMM d, yyyy')
                            .format(_calendarSelected!)
                        : 'Calendar',
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Mood legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _moods
              .map((m) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: (m['color'] as Color)
                                    .withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: m['color'] as Color,
                                    width: 1))),
                        const SizedBox(width: 3),
                        Text(m['emoji'] as String,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),

        // Selected date area
        if (_calendarSelected != null && !isFutureSelected) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d, yyyy')
                    .format(_calendarSelected!),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              // Action buttons: + and delete
              Row(
                children: [
                  if (_calendarEntry != null)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('Delete entry?'),
                            content: const Text(
                                'This will permanently delete this journal entry.'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                              TextButton(
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: Colors.red)),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteCalendarEntry();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            color: Colors.red.shade400, size: 18),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _calendarContentController.text =
                          _calendarEntry?.content ?? '';
                      _calendarMood = _calendarEntry?.mood ?? 3;
                      setState(() {
                        _isEditingCalendarEntry = true;
                        _isCalendarCollapsed = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _calendarEntry == null
                            ? Icons.add_rounded
                            : Icons.edit_outlined,
                        color: primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Entry display or edit form
          if (_isEditingCalendarEntry) ...[
            // Mood selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _moods.map((m) {
                final isSelected = _calendarMood == m['value'];
                return GestureDetector(
                  onTap: () => setState(
                      () => _calendarMood = m['value'] as int),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (m['color'] as Color).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (m['color'] as Color)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(m['emoji'] as String,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 2),
                        Text(
                          (m['label'] as String).split(' ').last,
                          style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? (m['color'] as Color)
                                  : Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200),
              ),
              child: TextField(
                controller: _calendarContentController,
                maxLines: 6,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      'Write about this day, thoughts, feelings...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isEditingCalendarEntry = false;
                      _isCalendarCollapsed = false;
                    }),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isSavingCalendar ? null : _saveCalendarEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSavingCalendar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ] else if (_calendarEntry == null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('No entry for this day. Tap + to add one.',
                  style: TextStyle(color: Colors.grey.shade400)),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
                border: Border(
                  left: BorderSide(
                      color: _moodColor(_calendarEntry!.mood ?? 3),
                      width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_moodEmoji(_calendarEntry!.mood ?? 3),
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        _moodLabel(_calendarEntry!.mood ?? 3),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                _moodColor(_calendarEntry!.mood ?? 3)),
                      ),
                    ],
                  ),
                  if (_calendarEntry!.content != null &&
                      _calendarEntry!.content!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _calendarEntry!.content!,
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                          height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ── STATS TAB ───────────────────────────────────────
  Widget _buildStatsTab(bool isDark, Color primary) {
    final streak = _currentStreak;
    final longest = _longestStreak;
    final total = _allEntries.length;

    final trendEntries = <JournalEntry>[];
    for (int i = _trendDays - 1; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayOnly = DateTime(day.year, day.month, day.day);
      final entry = _allEntries.where((e) {
        final d = DateTime(e.date!.year, e.date!.month, e.date!.day);
        return d == dayOnly;
      }).firstOrNull;
      if (entry != null) trendEntries.add(entry);
    }

    final cutoff =
        DateTime.now().subtract(Duration(days: _distDays));
    final moodCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final e in _allEntries) {
      if (e.date!.isAfter(cutoff)) {
        moodCounts[e.mood ?? 3] =
            (moodCounts[e.mood ?? 3] ?? 0) + 1;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('🔥', '$streak', 'Streak', Colors.orange),
                  _statItem('🏆', '$longest', 'Longest', primary),
                  _statItem('📝', '$total', 'Total', Colors.green),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mood Trend',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : Colors.black87)),
                  _dropdownPill(
                    value: _trendDays,
                    options: _dayOptions,
                    isDark: isDark,
                    primary: primary,
                    onChanged: (val) =>
                        setState(() => _trendDays = val!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (trendEntries.length < 2)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('Not enough data yet.\nKeep journaling!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade400)),
                  ),
                )
              else
                SizedBox(
                  height: 160,
                  child: LineChart(LineChartData(
                    minY: 1,
                    maxY: 5,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 28,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 1 || idx > 5)
                              return const SizedBox.shrink();
                            return Text(_moodEmoji(idx),
                                style: const TextStyle(fontSize: 12));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= trendEntries.length)
                              return const SizedBox.shrink();
                            return Text(
                              DateFormat('d')
                                  .format(trendEntries[idx].date!),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: trendEntries
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(),
                                (e.value.mood ?? 3).toDouble()))
                            .toList(),
                        isCurved: true,
                        color: primary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) =>
                              FlDotCirclePainter(
                            radius: 5,
                            color: _moodColor(spot.y.toInt()),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  )),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mood Distribution',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : Colors.black87)),
                  _dropdownPill(
                    value: _distDays,
                    options: _dayOptions,
                    isDark: isDark,
                    primary: primary,
                    onChanged: (val) =>
                        setState(() => _distDays = val!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (moodCounts.values.every((v) => v == 0))
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No entries in this period.',
                        style:
                            TextStyle(color: Colors.grey.shade400)),
                  ),
                )
              else
                SizedBox(
                  height: 160,
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (moodCounts.values
                                .reduce((a, b) => a > b ? a : b) +
                            2)
                        .toDouble(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt() + 1;
                            return Text(_moodEmoji(idx),
                                style:
                                    const TextStyle(fontSize: 16));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (val, meta) => Text(
                            val.toInt().toString(),
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: moodCounts.entries
                        .map((e) => BarChartGroupData(
                              x: e.key - 1,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.toDouble(),
                                  color: _moodColor(e.key),
                                  width: 32,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                              ],
                            ))
                        .toList(),
                  )),
                ),
            ],
          ),
        ),

        if (total == 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Start journaling to see stats!',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _dropdownPill({
    required int value,
    required List<int> options,
    required bool isDark,
    required Color primary,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: primary, size: 18),
          dropdownColor:
              isDark ? const Color(0xFF1F2937) : Colors.white,
          style: TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w600),
          items: options
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text('$d days'),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _statItem(
      String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}