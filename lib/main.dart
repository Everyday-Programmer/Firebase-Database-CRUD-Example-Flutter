import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crud_example_flutter/firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref("notes");
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  void _fetchNotes() {
    _databaseReference.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          notes = data.entries.map((e) => {
            "id": e.key,
            "title": e.value["title"],
            "content": e.value["content"],
          }).toList();
        });
      }
    });
  }

  void _addNotes() {
    String id = _databaseReference.push().key!;
    _databaseReference.child(id).set({
      "title": _titleController.text,
      "content": _contentController.text,
    });
    _titleController.clear();
    _contentController.clear();
  }

  void _updateNote(String id, String newTitle, String newContent) {
    _databaseReference.child(id).update({
      "title": newTitle,
      "content": newContent,
    });
  }

  void _deleteNote(String id, int index) {
    _databaseReference.child(id).remove();
    setState(() {
      notes.removeAt(index);
    });
  }

  void _showEditDialog(String id, String currentTitle, String currentContent) {
    TextEditingController titleController = TextEditingController(text: currentTitle);
    TextEditingController contentController = TextEditingController(text: currentContent);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Edit Note"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: InputDecoration(labelText: "Title"),),
                TextField(controller: contentController, decoration: InputDecoration(labelText: "Content"),)
              ],
            ),
            actions: [
              TextButton(onPressed: () {
                _updateNote(id, titleController.text, contentController.text);
                Navigator.pop(context);
              }, child: Text("Update"))
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Firebase CRUD Example"),),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(labelText: "Content"),
                ),
                SizedBox(height: 10,),
                ElevatedButton(onPressed: _addNotes, child: Text("Add Note")),
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];

                    return ListTile(
                      title: Text(note["title"]),
                      subtitle: Text(note["content"]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              onPressed: () => _showEditDialog(note["id"], note["title"], note["content"]),
                              icon: Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () => _deleteNote(note["id"], index),
                            icon: Icon(Icons.delete, color: Colors.red,),
                          ),
                        ],
                      ),
                    );
                  }
              )
          )
        ],
      ),
    );
  }
}
