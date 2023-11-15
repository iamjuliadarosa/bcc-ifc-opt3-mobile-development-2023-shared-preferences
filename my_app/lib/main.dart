import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

final uuid = Uuid();
List<TaskItem> CompletedTasks = [];
List<TaskItem> DeletedTasks = [];
List<TaskItem> Tasks = [];
String title_chosen = 'Lista de Tarefas';

String generateUniqueId() {
  return uuid.v4();
}

const TelaPrincipal APP = TelaPrincipal();
void main() {
  runApp(APP);
}

class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title_chosen,
      home: Scaffold(
          appBar: AppBar(
            title: const Text("To Do"),
          ),
          body: TaskList()),
    );
  }
}

class TaskList extends StatefulWidget {
  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  final TaskService _taskService = TaskService();
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.getTasks();
    setState(() {
      Tasks = tasks;
    });
  }

  Future<void> _saveTasks() async {
    await _taskService.saveTasks(Tasks);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2), // Duração da mensagem em segundos
      ),
    );
  }

  void _addNewTask(String title, String description) {
    if (description.isNotEmpty && title.isNotEmpty) {
      setState(() {
        final uniqueId = generateUniqueId();
        Tasks.add(TaskItem(uniqueId, title, description, false));
        _showSnackbar('Tarefa adicionada: $title');
      });
    } else {
      if (title.isEmpty) {
        _showSnackbar('O título não pode estar vazio.');
      }
      if (description.isEmpty) {
        _showSnackbar('A descrição não pode estar vazia.');
      }
    }
    _saveTasks();
  }

  void _completeTask(int index) {
    setState(() {
      _showSnackbar('Tarefa completa: ${Tasks[index].title}');
      Tasks[index].completed = !Tasks[index].completed;
      CompletedTasks.add(Tasks[index]);
      Tasks.removeAt(index);
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _showSnackbar('Tarefa removida: ${Tasks[index].title}');
      DeletedTasks.add(Tasks[index]);
      Tasks.removeAt(index);
    });
    _saveTasks();
  }

  int _findTaskbyID(String ID) {
    int foundTask = Tasks.indexWhere((task) => task.id == ID);
    return foundTask;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TaskInput(_addNewTask),
        Expanded(
          child: ListView.builder(
            itemCount: Tasks.length,
            itemBuilder: (context, index) {
              final uniqueId = generateUniqueId();
              return Dismissible(
                key: Key(uniqueId),
                child: TaskItem(Tasks[index].id, Tasks[index].title,
                    Tasks[index].description, Tasks[index].completed),
                onDismissed: (direction) => {
                  if (direction == DismissDirection.endToStart)
                    {
                      // Left-to-right swipe
                      // Marca tarefa como completa
                      _completeTask(index)
                    }
                  else if (direction == DismissDirection.startToEnd)
                    {
                      // Right-to-left swipe
                      // Remove tarefa da lista
                      _deleteTask(index)
                    }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

//Completed Tasks Screen
class CompletedTaskList extends StatefulWidget {
  @override
  _CompletedTaskListState createState() => _CompletedTaskListState();
}

class _CompletedTaskListState extends State<CompletedTaskList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tarefas Completas'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: CompletedTasks.length,
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                      duration: Duration(seconds: 2),
                      curve: Curves.fastOutSlowIn,
                      child: TaskItem(
                          CompletedTasks[index].id,
                          CompletedTasks[index].title,
                          CompletedTasks[index].description,
                          CompletedTasks[index].completed));
                },
              ),
            ),
          ],
        ));
  }
}

// Deleted Tasks Screen
class DeletedTaskList extends StatefulWidget {
  @override
  _DeletedTaskListState createState() => _DeletedTaskListState();
}

class _DeletedTaskListState extends State<DeletedTaskList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tarefas Apagadas'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: CompletedTasks.length,
                itemBuilder: (context, index) {
                  return TaskItem(
                      DeletedTasks[index].id,
                      DeletedTasks[index].title,
                      DeletedTasks[index].description,
                      DeletedTasks[index].completed);
                },
              ),
            ),
          ],
        ));
  }
}

// Active Tasks Screen
class TaskInput extends StatelessWidget {
  final Function(String, String) onTaskAdded;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  TaskInput(this.onTaskAdded);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Tarefa'),
          ),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          ElevatedButton(
            onPressed: () {
              onTaskAdded(titleController.text, descriptionController.text);
              titleController.clear();
              descriptionController.clear();
            },
            child: const Text('Adicionar Tarefa'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return CompletedTaskList();
                        },
                      ),
                    );
                  },
                  child: IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return CompletedTaskList();
                          },
                        ),
                      );
                    },
                  )),
              Text(
                  "< Deslize as tarefas para alterar para completar ou apagar >"),
              ElevatedButton(
                  onPressed: () {},
                  child: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return DeletedTaskList();
                          },
                        ),
                      );
                    },
                  )),
            ],
          )
        ],
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  String id;
  String title;
  String description;
  bool completed;

  TaskItem(this.id, this.title, this.description, this.completed);
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
        json['id'], json['title'], json['description'], json['completed']);
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor:
                completed ? Colors.green[200] : Colors.orange[200]),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class TaskService {
  static const _keyTasks = 'tasks';

  Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => task.toJson()).toList();
    await prefs.setString(_keyTasks, jsonEncode(tasksJson));
  }

  Future<List<TaskItem>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_keyTasks);
    if (tasksJson != null) {
      final List<dynamic> decodedTasks = jsonDecode(tasksJson);
      return decodedTasks.map((json) => TaskItem.fromJson(json)).toList();
    }
    return [];
  }
}
