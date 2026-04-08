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

  // Stats tab
  List<JournalEntry> _allEntries = [];

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
    final m = _moods.firstWhere((m) => m['value'] == mood,
        orElse: () => _moods[2]);
    return m['color'] as Color;
  }

  String _moodEmoji(int mood) {
    final m = _moods.firstWhere((m) => m['value'] == mood,
        orElse: () => _moods[2]);
    return m['emoji'] as String;
  }

  String _moodLabel(int mood) {
    final m = _moods.firstWhere((m) => m['value'] == mood,
        orElse: () => _moods[2]);
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

  Future<void> _save() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Journal saved!'),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
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

  // ── STREAK CALCULATION ──────────────────────────────
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Journal',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: primary)),
                      Text('Track your feelings',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Diary'),
                  Tab(text: 'Calendar'),
                  Tab(text: 'Statistics'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab views
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // Date label
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

          // Text entry
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

          // Save button
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
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
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _calendarFocused,
            selectedDayPredicate: (day) =>
                _calendarSelected != null &&
                isSameDay(_calendarSelected!, day),
            onDaySelected: (selected, focused) async {
              setState(() {
                _calendarSelected = selected;
                _calendarFocused = focused;
                _calendarEntry = null;
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
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final dayOnly =
                    DateTime(day.year, day.month, day.day);
                final entry = _entryMap[dayOnly];
                if (entry == null) return null;
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _moodColor(entry.mood ?? 3).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${day.day}',
                        style: TextStyle(
                            color:
                                isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              },
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

        // Selected entry display
        if (_calendarSelected != null) ...[
          Text(
            DateFormat('EEEE, MMM d, yyyy').format(_calendarSelected!),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          if (_calendarEntry == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('No entry for this day.',
                  style: TextStyle(color: Colors.grey.shade400)),
            )
          else
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
                      Text(
                          _moodEmoji(_calendarEntry!.mood ?? 3),
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        _moodLabel(_calendarEntry!.mood ?? 3),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _moodColor(
                                _calendarEntry!.mood ?? 3)),
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
                  const SizedBox(height: 10),
                  // Edit button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = _calendarSelected!;
                        _contentController.text =
                            _calendarEntry!.content ?? '';
                        _selectedMood = _calendarEntry!.mood ?? 3;
                        _selectedEntry = _calendarEntry;
                      });
                      _tabController.animateTo(0);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 14, color: primary),
                        const SizedBox(width: 4),
                        Text('Edit entry',
                            style:
                                TextStyle(fontSize: 13, color: primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // ── STATS TAB ───────────────────────────────────────
  Widget _buildStatsTab(bool isDark, Color primary) {
    final streak = _currentStreak;
    final longest = _longestStreak;
    final total = _allEntries.length;

    // Last 7 days for chart
    final last7 = <JournalEntry>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayOnly = DateTime(day.year, day.month, day.day);
      final entry = _allEntries.where((e) {
        final d = DateTime(e.date!.year, e.date!.month, e.date!.day);
        return d == dayOnly;
      }).firstOrNull;
      if (entry != null) last7.add(entry);
    }

    // Mood counts
    final moodCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final e in _allEntries) {
      moodCounts[e.mood ?? 3] = (moodCounts[e.mood ?? 3] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // Streak card
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
              Text('Current Streak',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('🔥', '$streak', 'Current', Colors.orange),
                  _statItem('🏆', '$longest', 'Longest', primary),
                  _statItem('📝', '$total', 'Total', Colors.green),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mood line chart
        if (last7.length >= 2) ...[
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
                Text('Mood Trend (Last 7 Days)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
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
                              if (idx < 1 || idx > 5) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                _moodEmoji(idx),
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= last7.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                DateFormat('d').format(last7[idx].date!),
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
                          spots: last7.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(),
                                (e.value.mood ?? 3).toDouble());
                          }).toList(),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Mood distribution bar chart
        if (total > 0)
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
                Text('Mood Distribution',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
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
                                  style: const TextStyle(fontSize: 16));
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
                      barGroups: moodCounts.entries.map((e) {
                        return BarChartGroupData(
                          x: e.key - 1,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: _moodColor(e.key),
                              width: 32,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
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

  Widget _statItem(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}