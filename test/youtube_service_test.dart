import 'package:doeet/features/courses/data/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YouTubeService.extractPlaylistId', () {
    test('extracts playlist IDs from standard URLs', () {
      expect(
        YouTubeService.extractPlaylistId(
          'https://www.youtube.com/playlist?list=PL123&ref=share',
        ),
        'PL123',
      );
    });

    test('returns null when a URL has no playlist parameter', () {
      expect(
        YouTubeService.extractPlaylistId('https://www.youtube.com/watch?v=abc'),
        isNull,
      );
    });
  });
}