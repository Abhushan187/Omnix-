import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/task_model.dart';

class AddTaskScreen extends StatefulWidget {
  final Function? updateTaskList;
  final Task? task;

  const AddTaskScreen({Key? key, this.updateTaskList, this.task})
      : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _priority = 'Low';
  String _category = 'Personal';
  DateTime _date = DateTime.now();
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');
  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<Map<String, dynamic>> _categories = [
    {'label': 'Personal', 'icon': Icons.person_outline},
    {'label': 'Work', 'icon': Icons.work_outline},
    {'label': 'Study', 'icon': Icons.menu_book_outlined},
    {'label': 'Health', 'icon': Icons.favorite_outline},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _title = widget.task!.title ?? '';
      _date = widget.task!.date ?? DateTime.now();
      _priority = widget.task!.priority ?? 'Low';
      _category = widget.task!.category ?? 'Personal';
    }
  }

  _handleDatePicker() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && date != _date) {
      setState(() => _date = date);
    }
  }

  _delete() {
    DatabaseHelper.instance.deleteTask(widget.task!.id!);
    Fluttertoast.showToast(
      msg: 'Task Deleted',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
    widget.updateTaskList!();
    Navigator.pop(context);
  }

  _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Task task = Task(
        title: _title,
        date: _date,
        priority: _priority,
        category: _category,
        status: widget.task?.status ?? 0,
      );

      if (widget.task == null) {
        DatabaseHelper.instance.insertTask(task);
        Fluttertoast.showToast(
          msg: 'New Task Added',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        task.id = widget.task!.id;
        DatabaseHelper.instance.updateTask(task);
        Fluttertoast.showToast(
          msg: 'Task Updated',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
      widget.updateTaskList!();
      Navigator.pop(context);
    }
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 70.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back_ios, size: 28.0, color: primary),
                ),
                const SizedBox(height: 20.0),
                Text(
                  widget.task == null ? 'Add Task' : 'Update Task',
                  style: TextStyle(
                    fontSize: 36.0,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 24.0),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        style: TextStyle(fontSize: 16.0, color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(fontSize: 16.0, color: labelColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                        ),
                        validator: (input) => (input?.trim().isEmpty ?? true)
                            ? 'Please enter a task title'
                            : null,
                        onSaved: (input) => _title = input ?? '',
                        initialValue: _title,
                      ),
                      const SizedBox(height: 16),

                      // Date
                      TextFormField(
                        readOnly: true,
                        style: TextStyle(fontSize: 16.0, color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Date',
                          labelStyle: TextStyle(fontSize: 16.0, color: labelColor),
                          prefixIcon: Icon(Icons.calendar_today_outlined, color: primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                        ),
                        onTap: _handleDatePicker,
                        controller: TextEditingController(
                            text: _dateFormatter.format(_date)),
                      ),
                      const SizedBox(height: 16),

                      // Priority
                      DropdownButtonFormField<String>(
                        dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                        items: _priorities.map((String priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(
                              priority,
                              style: TextStyle(color: textColor, fontSize: 16.0),
                            ),
                          );
                        }).toList(),
                        style: TextStyle(fontSize: 16.0, color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          labelStyle: TextStyle(fontSize: 16.0, color: labelColor),
                          prefixIcon: Icon(Icons.flag_outlined, color: primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                        ),
                        validator: (input) =>
                            input == null ? 'Please select a priority' : null,
                        onChanged: (value) =>
                            setState(() => _priority = value as String),
                        value: _priority,
                      ),
                      const SizedBox(height: 24),

                      // Category picker
                      Text(
                        'Category',
                        style: TextStyle(fontSize: 16.0, color: labelColor),
                      ),
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
                                border: Border.all(
                                  color: isSelected
                                      ? primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    cat['icon'] as IconData,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade600),
                                    size: 22,
                                  ),
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
                      const SizedBox(height: 32),

                      // Add/Update button
                      SizedBox(
                        height: 56.0,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          child: Text(
                            widget.task == null ? 'Add Task' : 'Update Task',
                            style: const TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      // Delete button
                      if (widget.task != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: SizedBox(
                            height: 56.0,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _delete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                              child: const Text(
                                'Delete Task',
                                style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600),
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
      ),
    );
  }
}