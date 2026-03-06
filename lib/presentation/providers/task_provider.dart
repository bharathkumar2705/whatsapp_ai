import 'package:flutter/material.dart';
import '../../domain/entities/task_entity.dart';

class TaskProvider extends ChangeNotifier {
  final List<TaskEntity> _tasks = [];
  
  List<TaskEntity> get tasks => _tasks;
  List<TaskEntity> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<TaskEntity> get completedTasks => _tasks.where((t) => t.isCompleted).toList();

  void addTask(TaskEntity task) {
    _tasks.add(task);
    notifyListeners();
  }

  void toggleTask(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
      notifyListeners();
    }
  }

  void removeTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void clearTasks() {
    _tasks.clear();
    notifyListeners();
  }
}
