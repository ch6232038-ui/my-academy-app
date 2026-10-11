import 'package:flutter/material.dart';
import 'main.dart';

class AskTeacherScreen extends StatefulWidget {
  const AskTeacherScreen({super.key});

  @override
  State<AskTeacherScreen> createState() => _AskTeacherScreenState();
}

class _AskTeacherScreenState extends State<AskTeacherScreen> {
  final _controller = TextEditingController();
  List<dynamic> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final res = await supabase
          .from('ask_teacher')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        questions = res;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendQuestion() async {
    if (_controller.text.trim().isEmpty) return;
    await supabase.from('ask_teacher').insert({
      'question': _controller.text.trim(),
      'student_email': supabase.auth.currentUser?.email,
    });
    _controller.clear();
    fetchQuestions();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Question Sent! ✅")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ask Teacher")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: "Type your question...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none)),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendQuestion,
                  child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: const Color(0xFF6A5AE0),
                          borderRadius: BorderRadius.circular(14)),
                      child:
                          const Icon(Icons.send_rounded, color: Colors.white)),
                )
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q['question'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            if (q['answer'] != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7FF),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.school_rounded,
                                        size: 16, color: Color(0xFF6A5AE0)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(q['answer'],
                                            style:
                                                const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              )
                            ]
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
