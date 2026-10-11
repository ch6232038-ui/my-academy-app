import 'package:flutter/material.dart';
import 'main.dart';
import 'announcements_screen.dart';
import 'assignments_screen.dart';
import 'notes_download_screen.dart';
import 'lecture_player_screen.dart';
import 'quiz_screen.dart';
import 'ask_teacher_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email ?? "Student";

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("السلام علیکم 👋",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        userEmail.split('@')[0],
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      await supabase.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  )
                ],
              ),
              const SizedBox(height: 25),

              // Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A5AE0), Color(0xFF8D7DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("آج کیا پڑھنا ہے؟",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("آپ کے 2 نئے لیکچرز اور 1 اسائنمنٹ باقی ہے",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 32),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text("My Academy",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // Grid Menu
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildCard(
                      context,
                      "Announcements",
                      Icons.campaign_rounded,
                      const Color(0xFFFFF0F0),
                      const Color(0xFFE85D5D),
                      const AnnouncementsScreen()),
                  _buildCard(
                      context,
                      "Assignments",
                      Icons.assignment_rounded,
                      const Color(0xFFEFF4FF),
                      const Color(0xFF4A7BFF),
                      const AssignmentsScreen()),
                  _buildCard(
                      context,
                      "Lectures",
                      Icons.play_circle_fill_rounded,
                      const Color(0xFFF0FAF0),
                      const Color(0xFF4CAF50),
                      const LecturePlayerScreen()),
                  _buildCard(
                      context,
                      "Notes",
                      Icons.note_alt_rounded,
                      const Color(0xFFFFF8E6),
                      const Color(0xFFFFB300),
                      const NotesDownloadScreen()),
                  _buildCard(
                      context,
                      "Quizzes",
                      Icons.quiz_rounded,
                      const Color(0xFFF3EFFF),
                      const Color(0xFF8E5CFF),
                      const QuizScreen()),
                  _buildCard(
                      context,
                      "Ask Teacher",
                      Icons.chat_bubble_rounded,
                      const Color(0xFFEFFFFB),
                      const Color(0xFF00C2A2),
                      const AskTeacherScreen()),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon,
      Color bgColor, Color iconColor, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const Spacer(),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text("View all",
                style: TextStyle(color: Colors.grey, fontSize: 12))
          ],
        ),
      ),
    );
  }
}
