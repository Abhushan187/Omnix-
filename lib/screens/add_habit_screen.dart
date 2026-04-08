import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/habit_model.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit;
  const AddHabitScreen({Key? key, this.habit}) : super(key: key);

  @override
  _AddHabitScreenState createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _category = 'Personal';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');

  final List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Personal', 'icon': Icons.person_outline},
    {'label': 'Work', 'icon': Icons.work_outline},
    {'label': 'Study', 'icon': Icons.menu_book_outlined},
    {'label': 'Health', 'icon': Icons.favorite_outline},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _name = widget.habit!.name ?? '';
      _category = widget.habit!.category ?? 'Personal';
      _startDate = widget.habit!.startDate ?? DateTime.now();
      _endDate = widget.habit!.endDate;
      _selectedDays = widget.habit!.daysList;
    }
  }

  _pickDate({bool isStart = true}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      Fluttertoast.showToast(msg: 'Select at least one day');
      return;
    }
    _formKey.currentState!.save();

    // Sort days in week order
    final ordered = _allDays.where((d) => _selectedDays.contains(d)).toList();

    final habit = Habit(
      name: _name,
      category: _category,
      days: ordered.join(','),
      startDate: _startDate,
      endDate: _endDate,
    );

    if (widget.habit == null) {
      await DatabaseHelper.instance.insertHabit(habit);
      Fluttertoast.showToast(msg: 'Habit created!');
    } else {
      habit.id = widget.habit!.id;
      // If start date changed, reset logs
      if (!isSameDay(_startDate, widget.habit!.startDate!)) {
        await DatabaseHelper.instance.resetHabitLogs(habit.id!);
        Fluttertoast.showToast(msg: 'Start date changed — logs reset');
      }
      await DatabaseHelper.instance.updateHabit(habit);
      Fluttertoast.showToast(msg: 'Habit updated!');
    }
    Navigator.pop(context);
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  _delete() async {
    await DatabaseHelper.instance.deleteHabit(widget.habit!.id!);
    Fluttertoast.showToast(msg: 'Habit deleted');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 70),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios, size: 28, color: primary),
              ),
              const SizedBox(height: 20),
              Text(
                widget.habit == null ? 'New Habit' : 'Edit Habit',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      initialValue: _name,
                      style: TextStyle(fontSize: 16, color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Habit Name',
                        labelStyle: TextStyle(color: labelColor),
                        prefixIcon: Icon(Icons.loop_rounded, color: primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Please enter a habit name'
                          : null,
                      onSaved: (v) => _name = v ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Category
                    Text('Category',
                        style: TextStyle(fontSize: 16, color: labelColor)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _categories.map((cat) {
                        final bool isSelected = _category == cat['label'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _category = cat['label']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary
                                  : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(cat['icon'] as IconData,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade600),
                                    size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  cat['label'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Days picker
                    Text('Track on these days',
                        style: TextStyle(fontSize: 16, color: labelColor)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _allDays.map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDays.remove(day);
                              } else {
                                _selectedDays.add(day);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected ? primary : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? primary
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                day[0],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Start date
                    GestureDetector(
                      onTap: () => _pickDate(isStart: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_outline,
                                color: primary, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Start Date',
                                    style: TextStyle(
                                        fontSize: 12, color: labelColor)),
                                Text(
                                  _dateFormatter.format(_startDate),
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: textColor,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (widget.habit != null &&
                                !isSameDay(
                                    _startDate, widget.habit!.startDate!))
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '⚠️ Logs will reset',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade400),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // End date
                    GestureDetector(
                      onTap: () => _pickDate(isStart: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.stop_circle_outlined,
                                color: Colors.grey.shade400, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('End Date (optional)',
                                    style: TextStyle(
                                        fontSize: 12, color: labelColor)),
                                Text(
                                  _endDate != null
                                      ? _dateFormatter.format(_endDate!)
                                      : 'No end date — runs forever',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: _endDate != null
                                          ? textColor
                                          : Colors.grey.shade400,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (_endDate != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _endDate = null),
                                  child: Icon(Icons.close_rounded,
                                      size: 16,
                                      color: Colors.grey.shade400),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          widget.habit == null ? 'Create Habit' : 'Update Habit',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    // Delete button
                    if (widget.habit != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _delete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Delete Habit',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}