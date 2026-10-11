import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class LecturePlayerScreen extends StatefulWidget {
  const LecturePlayerScreen({super.key});

  @override
  State<LecturePlayerScreen> createState() => _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends State<LecturePlayerScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> lectures = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchLectures();
  }

  Future<void> fetchLectures() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await supabase
          .from('lectures')
          .select('id, title, subject, video_url')
          .order('id', ascending: true);

      if (!mounted) return;

      setState(() {
        lectures = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  void openLecture(Map<String, dynamic> lecture) {
    final String videoUrl = (lecture['video_url'] ?? '').toString().trim();

    final Uri? uri = Uri.tryParse(videoUrl);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Is lecture ka video URL check karein.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LectureVideoScreen(
          title: (lecture['title'] ?? 'Lecture').toString(),
          subject: (lecture['subject'] ?? '').toString(),
          videoUrl: videoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lectures'),
        actions: [
          IconButton(
            onPressed: fetchLectures,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh lectures',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Lectures load nahi ho sake.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchLectures,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : lectures.isEmpty
                  ? const Center(
                      child: Text(
                        'Abhi koi lecture available nahi hai.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchLectures,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lectures.length,
                        itemBuilder: (context, index) {
                          final lecture = lectures[index];

                          final title = (lecture['title'] ?? 'Untitled Lecture')
                              .toString();

                          final subject =
                              (lecture['subject'] ?? 'General').toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: const CircleAvatar(
                                radius: 26,
                                child: Icon(Icons.play_arrow, size: 30),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Subject: $subject'),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                              ),
                              onTap: () => openLecture(lecture),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class LectureVideoScreen extends StatefulWidget {
  final String title;
  final String subject;
  final String videoUrl;

  const LectureVideoScreen({
    super.key,
    required this.title,
    required this.subject,
    required this.videoUrl,
  });

  @override
  State<LectureVideoScreen> createState() => _LectureVideoScreenState();
}

class _LectureVideoScreenState extends State<LectureVideoScreen> {
  VideoPlayerController? controller;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  Future<void> initializeVideo() async {
    try {
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      controller = videoController;

      await videoController.initialize();

      if (!mounted) {
        await videoController.dispose();
        return;
      }

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> togglePlayback() async {
    final videoController = controller;

    if (videoController == null || !videoController.value.isInitialized) {
      return;
    }

    if (videoController.value.isPlaying) {
      await videoController.pause();
    } else {
      await videoController.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoController = controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subject,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Video play nahi ho saka.\n$errorMessage',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : videoController != null &&
                                videoController.value.isInitialized
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: VideoPlayer(videoController),
                              )
                            : const Center(
                                child: Text(
                                  'Video available nahi hai.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
              ),
            ),
            const SizedBox(height: 12),
            if (errorMessage == null && !isLoading)
              Center(
                child: ElevatedButton.icon(
                  onPressed: togglePlayback,
                  icon: Icon(
                    videoController?.value.isPlaying == true
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    videoController?.value.isPlaying == true
                        ? 'Pause Video'
                        : 'Play Video',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Lecture Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Title: ${widget.title}'),
            const SizedBox(height: 6),
            Text('Subject: ${widget.subject}'),
          ],
        ),
      ),
    );
  }
}
