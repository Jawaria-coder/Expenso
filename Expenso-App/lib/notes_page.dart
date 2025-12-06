import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class NotesPage extends StatefulWidget {
  @override
  _NotesPage createState() => _NotesPage();
}

class _NotesPage extends State<NotesPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = false;

  final Color bgWhite = const Color(0xFFFFFFFF);
  final Color lightWhite = const Color(0xFFFFFFFF);
  final Color newPurple = const Color(0xFF9B59B6);

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _fetchNotes();
  }

  Future<void> _initSpeech() async {
    final micStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();

    if (micStatus.isGranted && speechStatus.isGranted) {
      _speech = stt.SpeechToText();
      _speechAvailable = await _speech!.initialize(
        onStatus: (status) {
          print("Main mic status: $status");
          if (status == 'done' && _isListening) {
            _startListening(); // Restart automatically
          }
        },
        onError: (error) => print("Main mic error: $error"),
      );
    } else {
      print('Microphone permission denied');
      _speechAvailable = false;
    }
  }

  void _startListening() async {
    if (_speech != null && _speechAvailable) {
      setState(() => _isListening = true);
      _speech!.listen(
        onResult: (result) {
          setState(() {
            _contentController.text = result.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.dictation,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Speech recognition is not available.")),
      );
    }
  }

  void _stopListening() {
    _speech?.stop();
    setState(() => _isListening = false);
  }

  Future<void> _fetchNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _notes = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Future<void> _addNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Both title and content are required.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('notes').add({
        'userId': user.uid,
        'title': title,
        'content': content,
        'timestamp': Timestamp.now(),
      });

      _titleController.clear();
      _contentController.clear();
      await _fetchNotes();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Note added!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNote(String id, String newTitle, String newContent) async {
    if (newTitle.isEmpty || newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Both title and content are required.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('notes').doc(id).update({
        'title': newTitle,
        'content': newContent,
        'timestamp': Timestamp.now(),
      });

      await _fetchNotes();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Note updated!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNote(String id) async {
    await FirebaseFirestore.instance.collection('notes').doc(id).delete();
    await _fetchNotes();
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd – kk:mm').format(dt);
  }

  void _showEditNoteModal(Map<String, dynamic> note) {
    final editTitleController = TextEditingController(text: note['title']);
    final editContentController = TextEditingController(text: note['content']);
    final stt.SpeechToText localSpeech = stt.SpeechToText();
    bool isListening = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> startListening() async {
              try {
                bool available = await localSpeech.initialize(
                  onStatus: (status) {
                    print("Edit mic status: $status");
                    if (status == 'done' && isListening) {
                      startListening(); // Restart
                    }
                  },
                  onError: (error) => print("Edit mic error: $error"),
                );
                if (available) {
                  setModalState(() => isListening = true);
                  localSpeech.listen(
                    onResult: (result) {
                      setModalState(() {
                        editContentController.text = result.recognizedWords;
                      });
                    },
                    listenMode: stt.ListenMode.dictation,
                  );
                }
              } catch (e) {
                print("Edit mic exception: $e");
              }
            }

            void stopListening() {
              localSpeech.stop();
              setModalState(() => isListening = false);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Edit Note",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: newPurple,
                      )),
                  SizedBox(height: 12),
                  TextField(
                    controller: editTitleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      filled: true,
                      fillColor: lightWhite,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      TextField(
                        controller: editContentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: "Content",
                          filled: true,
                          fillColor: lightWhite,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          color: newPurple,
                        ),
                        onPressed: isListening ? stopListening : startListening,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final newTitle = editTitleController.text.trim();
                      final newContent = editContentController.text.trim();
                      _updateNote(note['id'], newTitle, newContent);
                      Navigator.of(context).pop();
                    },
                    child: Text("Save Changes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: newPurple,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : newPurple,
        ),
        title: Text('Notes', style: TextStyle(color: isDark ? Colors.white : newPurple)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New Note",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: newPurple,
                )),
            SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),
            Stack(
              alignment: Alignment.topRight,
              children: [
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: "Content",
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: newPurple,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addNote,
              child: Text("Save Note"),
              style: ElevatedButton.styleFrom(
                backgroundColor: newPurple,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 24),
            if (_notes.isNotEmpty)
              Text("Your Notes",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: newPurple,
                  )),
            SizedBox(height: 12),
            ..._notes.map((note) {
              final dt = (note['timestamp'] as Timestamp).toDate();
              return GestureDetector(
                onTap: () => _showEditNoteModal(note),
                child: Card(
                  color: colorScheme.surface,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(note['title'],
                        style: TextStyle(fontWeight: FontWeight.bold, color: newPurple)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note['content']),
                        SizedBox(height: 4),
                        Text(_formatDateTime(dt),
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteNote(note['id']),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
