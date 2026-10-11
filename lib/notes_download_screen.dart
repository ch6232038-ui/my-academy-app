import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotesDownloadScreen extends StatefulWidget {
  const NotesDownloadScreen({super.key});

  @override
  State<NotesDownloadScreen> createState() => _NotesDownloadScreenState();
}

class _NotesDownloadScreenState extends State<NotesDownloadScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> notes = [];
  final Set<String> downloading = {};
  final Set<String> downloaded = {};

  bool isLoading = true;
  String searchQuery = '';
  String selectedSubject = 'All';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchNotes() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await supabase
          .from('notes')
          .select()
          .order('created_at', ascending: false);

      final loadedNotes = List<Map<String, dynamic>>.from(
        (response as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      if (!mounted) return;

      setState(() {
        notes = loadedNotes;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Notes loading error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Notes load nahi huay. Table aur Supabase settings check karein.';
      });
    }
  }

  List<String> get subjects {
    final list = notes
        .map((note) => note['subject']?.toString() ?? 'General')
        .toSet()
        .toList()
      ..sort();

    return ['All', ...list];
  }

  List<Map<String, dynamic>> get filteredNotes {
    return notes.where((note) {
      final title = (note['title'] ?? 'Note').toString().toLowerCase();

      final subject = (note['subject'] ?? 'General').toString();

      final matchesSubject =
          selectedSubject == 'All' || subject == selectedSubject;

      final matchesSearch = title.contains(searchQuery.toLowerCase());

      return matchesSubject && matchesSearch;
    }).toList();
  }

  String noteUrl(Map<String, dynamic> note) {
    // Table mein file_url ya url column use kar sakte hain.
    return (note['file_url'] ?? note['url'] ?? '').toString().trim();
  }

  String fileName(Map<String, dynamic> note) {
    final title = (note['title'] ?? 'Note').toString();

    final safeName = title
        .replaceAll(RegExp(r'[^\w -]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');

    return '${safeName.isEmpty ? 'Note' : safeName}.pdf';
  }

  Color noteColor(Map<String, dynamic> note) {
    final subject = (note['subject'] ?? '').toString().toLowerCase();

    if (subject.contains('flutter')) return Colors.blue;
    if (subject.contains('database')) return Colors.purple;
    if (subject.contains('web')) return Colors.orange;

    return const Color(0xFF6A5AE0);
  }

  Future<void> downloadNote(Map<String, dynamic> note) async {
    final title = (note['title'] ?? 'Note').toString();
    final url = noteUrl(note);
    final name = fileName(note);

    if (downloading.contains(name)) return;

    if (url.isEmpty || Uri.tryParse(url)?.hasScheme != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Is note ka valid PDF URL nahi mila.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      downloading.add(name);
    });

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }

      final directory = await getApplicationDocumentsDirectory();
      final notesDirectory = Directory(
        '${directory.path}/notes',
      );

      if (!await notesDirectory.exists()) {
        await notesDirectory.create(recursive: true);
      }

      final file = File('${notesDirectory.path}/$name');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (!mounted) return;

      setState(() {
        downloaded.add(name);
        downloading.remove(name);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title download ho gaya hai.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Note download error: $e');

      if (!mounted) return;

      setState(() {
        downloading.remove(name);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Download nahi hua. Internet aur PDF URL check karein.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> openDownloadedNote(
    Map<String, dynamic> note,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/notes/${fileName(note)}',
    );

    if (!await file.exists()) {
      if (!mounted) return;

      setState(() {
        downloaded.remove(fileName(note));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File nahi mili. Dobara download karein.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Note Downloaded'),
        content: Text(
          'File save ho gayi hai:\n${file.path}\n\n'
          'PDF open karne ke liye PDF viewer package connect karein.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredNotes;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: const Text(
          'Notes & Downloads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Notes',
            onPressed: fetchNotes,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Downloaded Notes',
            onPressed: showDownloadedNotes,
            icon: const Icon(Icons.download_done_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final selected = selectedSubject == subject;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(subject),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedSubject = subject;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 55,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: fetchNotes,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Text('No notes found.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final note = filtered[index];
                              return buildNoteCard(note);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget buildNoteCard(Map<String, dynamic> note) {
    final title = (note['title'] ?? 'Note').toString();
    final subject = (note['subject'] ?? 'General').toString();
    final color = noteColor(note);
    final name = fileName(note);
    final isDownloading = downloading.contains(name);
    final isDownloaded = downloaded.contains(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: color,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subject,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  (note['description'] ?? 'PDF Notes').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isDownloaded)
                OutlinedButton.icon(
                  onPressed: () => openDownloadedNote(note),
                  icon: const Icon(Icons.folder_open, size: 17),
                  label: const Text('Open'),
                )
              else
                ElevatedButton.icon(
                  onPressed: isDownloading ? null : () => downloadNote(note),
                  icon: isDownloading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.download_outlined,
                          size: 18,
                        ),
                  label: Text(
                    isDownloading ? 'Downloading' : 'Download',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A5AE0),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void showDownloadedNotes() {
    final list = notes.where((note) {
      return downloaded.contains(fileName(note));
    }).toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Downloaded Notes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No notes downloaded yet.'),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: list.map((note) {
                        return ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          title: Text(
                            (note['title'] ?? 'Note').toString(),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () {
                              Navigator.pop(context);
                              openDownloadedNote(note);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
