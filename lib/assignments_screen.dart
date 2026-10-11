import 'package:flutter/material.dart';
import 'main.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<dynamic> assignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    try {
      final response = await supabase
          .from('assignments')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        assignments = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assignments"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : assignments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text("No assignments yet",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final item = assignments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(item['subject'] ?? 'General',
                                    style: const TextStyle(
                                        color: Color(0xFF4A7BFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 14, color: Colors.red.shade300),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Due: ${item['due_date'] ?? 'No date'}",
                                    style: TextStyle(
                                        color: Colors.red.shade300,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(item['title'] ?? 'No Title',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Text(
                            item['description'] ??
                                'Complete this assignment and submit before due date.',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Assignment Submitted! 🎉")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A5AE0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Submit Now"),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
