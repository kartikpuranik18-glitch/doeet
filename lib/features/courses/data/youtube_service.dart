// lib/features/courses/data/youtube_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'course_model.dart';

/// YouTube Data API v3 integration
/// Replace [_apiKey] with your key from Google Cloud Console
class YouTubeService {
  static const String _configuredApiKey =
      String.fromEnvironment('YOUTUBE_API_KEY');
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  YouTubeService({String? apiKey}) : _apiKey = apiKey ?? _configuredApiKey;

  final String _apiKey;

  // ── Extract playlist ID from any YouTube URL ──────
  static String? extractPlaylistId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    // ?list=PLxxxxxx
    if (uri.queryParameters.containsKey('list')) {
      return uri.queryParameters['list'];
    }
    // Direct playlist URL: /playlist?list=PL...
    if (url.contains('playlist?list=')) {
      final idx = url.indexOf('list=') + 5;
      final end = url.indexOf('&', idx);
      return end == -1 ? url.substring(idx) : url.substring(idx, end);
    }
    return null;
  }

  // ── Fetch playlist details ────────────────────────
  Future<CourseModel?> fetchPlaylist(String playlistIdOrUrl) async {
    if (_apiKey.isEmpty) {
      throw StateError(
          'YouTube import is not configured. Set YOUTUBE_API_KEY or use a backend proxy.');
    }
    final playlistId =
        extractPlaylistId(playlistIdOrUrl) ?? playlistIdOrUrl.trim();
    if (playlistId.isEmpty) {
      throw FormatException('Enter a valid YouTube playlist URL or ID.');
    }

    // 1. Get playlist metadata
    final metaUri = Uri.parse(
        '$_baseUrl/playlists?part=snippet,contentDetails&id=$playlistId&key=$_apiKey');
    final metaRes = await http.get(metaUri);
    if (metaRes.statusCode != 200) throw Exception('Failed to fetch playlist');

    final metaJson = json.decode(metaRes.body) as Map<String, dynamic>;
    final items = metaJson['items'] as List?;
    if (items == null || items.isEmpty) {
      throw Exception('Playlist not found. Check the URL.');
    }

    final snippet = items[0]['snippet'] as Map<String, dynamic>;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
    final thumb = (thumbnails['maxres'] ?? thumbnails['high'] ??
            thumbnails['medium'] ?? thumbnails['default'])
        as Map<String, dynamic>;

    // 2. Fetch all videos in the playlist
    final videos = await _fetchPlaylistVideos(playlistId);

    final totalDuration =
        videos.fold(0, (sum, v) => sum + v.durationSeconds);

    return CourseModel(
      id: playlistId,
      playlistId: playlistId,
      title: snippet['title'] as String? ?? 'Untitled',
      description: snippet['description'] as String? ?? '',
      thumbnailUrl: thumb['url'] as String? ?? '',
      channelName: snippet['channelTitle'] as String? ?? '',
      videoCount: videos.length,
      totalDurationSeconds: totalDuration,
      addedAt: DateTime.now(),
      videos: videos,
    );
  }

  // ── Fetch all videos (handles pagination) ─────────
  Future<List<VideoItemModel>> _fetchPlaylistVideos(
      String playlistId) async {
    final videos = <VideoItemModel>[];
    String? nextPageToken;
    int position = 0;

    do {
      final pageParam =
          nextPageToken != null ? '&pageToken=$nextPageToken' : '';
      final uri = Uri.parse(
          '$_baseUrl/playlistItems?part=snippet,contentDetails&maxResults=50&playlistId=$playlistId&key=$_apiKey$pageParam');
      final res = await http.get(uri);
      if (res.statusCode != 200) break;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = json['items'] as List? ?? [];
      nextPageToken = json['nextPageToken'] as String?;

      // Collect video IDs for duration lookup
      final videoIds = <String>[];
      for (final item in items) {
        final videoId =
            item['contentDetails']?['videoId'] as String? ?? '';
        if (videoId.isNotEmpty) videoIds.add(videoId);
      }

      // Get durations
      final durations = await _fetchDurations(videoIds);

      for (final item in items) {
        final snippet = item['snippet'] as Map<String, dynamic>;
        final videoId =
            item['contentDetails']?['videoId'] as String? ?? '';
        if (videoId.isEmpty) continue;

        final thumbnails =
            snippet['thumbnails'] as Map<String, dynamic>? ?? {};
        final thumb = (thumbnails['high'] ??
                thumbnails['medium'] ??
                thumbnails['default']) as Map<String, dynamic>?;

        videos.add(VideoItemModel(
          videoId: videoId,
          title: snippet['title'] as String? ?? 'Untitled Video',
          thumbnailUrl: thumb?['url'] as String? ?? '',
          durationSeconds: durations[videoId] ?? 0,
          position: position++,
        ));
      }
    } while (nextPageToken != null);

    return videos;
  }

  // ── Fetch video durations in bulk ─────────────────
  Future<Map<String, int>> _fetchDurations(List<String> videoIds) async {
    if (videoIds.isEmpty) return {};
    final ids = videoIds.join(',');
    final uri = Uri.parse(
        '$_baseUrl/videos?part=contentDetails&id=$ids&key=$_apiKey');
    final res = await http.get(uri);
    if (res.statusCode != 200) return {};

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final items = json['items'] as List? ?? [];
    final durations = <String, int>{};

    for (final item in items) {
      final id = item['id'] as String;
      final iso = item['contentDetails']?['duration'] as String? ?? '';
      durations[id] = _parseIso8601Duration(iso);
    }
    return durations;
  }

  // ── Parse ISO 8601 duration (PT1H2M3S) ───────────
  static int _parseIso8601Duration(String iso) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(iso);
    if (match == null) return 0;
    final h = int.tryParse(match.group(1) ?? '0') ?? 0;
    final m = int.tryParse(match.group(2) ?? '0') ?? 0;
    final s = int.tryParse(match.group(3) ?? '0') ?? 0;
    return h * 3600 + m * 60 + s;
  }

  // ── Search YouTube (for discover section) ─────────
  Future<List<Map<String, dynamic>>> searchPlaylists(String query) async {
    if (_apiKey.isEmpty) {
      throw StateError(
          'YouTube search is not configured. Set YOUTUBE_API_KEY or use a backend proxy.');
    }
    final uri = Uri.parse(
        '$_baseUrl/search?part=snippet&type=playlist&q=${Uri.encodeComponent(query)}&maxResults=10&key=$_apiKey');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(json['items'] ?? []);
  }
}
