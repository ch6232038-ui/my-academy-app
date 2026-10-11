import 'package:flutter/material.dart';
import 'main.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<dynamic> announcements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    try {
      final response = await supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        announcements = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text("No announcements yet",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final item = announcements[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.campaign_rounded,
                                      color: Color(0xFFE85D5D)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['title'] ?? 'No Title',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF0EFFF),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Text("NEW",
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6A5AE0))),
                                )
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item['description'] ?? '',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  item['created_at'] != null
                                      ? item['created_at']
                                          .toString()
                                          .substring(0, 10)
                                      : '',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
