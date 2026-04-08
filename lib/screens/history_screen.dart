import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/task_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Task>> _taskList;
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _updateTaskList();
  }

  _updateTaskList() {
    setState(() {
      _taskList = DatabaseHelper.instance.getTaskList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _taskList,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Task> tasks = snapshot.data as List<Task>;
          final List<Task> completedTasks =
              tasks.where((Task task) => task.status == 1).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 80.0),
            itemCount: 1 + completedTasks.length,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _buildTask(completedTasks[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTask(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        children: [
          ListTile(
            title: Text(
              task.title ?? '',
              style: const TextStyle(
                fontSize: 18.0,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            subtitle: Text(
              '${_dateFormatter.format(task.date!)} · ${task.priority}',
              style: const TextStyle(
                fontSize: 15.0,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () {
                task.status = 0;
                DatabaseHelper.instance.updateTask(task);
                Fluttertoast.showToast(
                  msg: 'Task reassigned',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                );
                _updateTaskList();
              },
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}