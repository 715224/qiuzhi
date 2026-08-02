import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qiuzhi/data/github_word_source.dart';

void main() {
  group('GithubWordSource.candidateUris', () {
    test('expands a repository home page', () {
      final urls = GithubWordSource.candidateUris(
        'https://github.com/715224/qiuzhi',
      ).map((uri) => uri.toString()).toList();

      expect(
        urls.first,
        'https://api.github.com/repos/715224/qiuzhi/contents/daily_hotwords/library.json?ref=master',
      );
      expect(
        urls,
        contains(
          'https://api.github.com/repos/715224/qiuzhi/contents/daily_hotwords/words.json?ref=master',
        ),
      );
      expect(
        urls,
        contains(
          'https://cdn.jsdelivr.net/gh/715224/qiuzhi@master/words.example.json',
        ),
      );
      expect(
        urls,
        contains(
          'https://api.github.com/repos/715224/qiuzhi/contents/words.example.json?ref=master',
        ),
      );
      expect(urls.last,
          'https://raw.githubusercontent.com/715224/qiuzhi/master/words.example.json');
    });

    test('converts a GitHub file page to a raw URL', () {
      final urls = GithubWordSource.candidateUris(
        'https://github.com/715224/qiuzhi/blob/master/words.example.json',
      );

      expect(urls.map((uri) => uri.host), [
        'api.github.com',
        'cdn.jsdelivr.net',
        'raw.githubusercontent.com',
      ]);
    });

    test('keeps a raw URL unchanged', () {
      const raw =
          'https://raw.githubusercontent.com/715224/qiuzhi/master/words.example.json';
      final urls = GithubWordSource.candidateUris(raw);
      expect(urls.first.host, 'api.github.com');
      expect(urls.last.toString(), raw);
    });
  });

  test('falls back from missing files to the CDN example file', () async {
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      if (request.url.host == 'cdn.jsdelivr.net' &&
          request.url.path.endsWith('@master/words.example.json')) {
        return http.Response.bytes(
          utf8.encode('[{"id":1001,"word":"大模型","pack":"每日热词"}]'),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('not found', 404);
    });

    final words = await GithubWordSource.fetch(
      'https://github.com/715224/qiuzhi',
      client: client,
    );

    expect(words.single.word, '大模型');
    expect(requested.first.host, 'api.github.com');
    expect(
      requested.last.toString(),
      'https://cdn.jsdelivr.net/gh/715224/qiuzhi@master/words.example.json',
    );
  });

  test('rejects stale CDN data and accepts a source containing current date',
      () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      final date = requestCount == 1 ? '2026-08-01' : '2026-08-02';
      return http.Response.bytes(
        utf8.encode(
          '[{"id":2026080201,"word":"测试热词","pack":"每日热词",'
          '"publishedDate":"$date"}]',
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final words = await GithubWordSource.fetch(
      'https://github.com/715224/qiuzhi',
      client: client,
      requiredPublishedDate: '2026-08-02',
    );

    expect(requestCount, 2);
    expect(words.single.publishedDate, '2026-08-02');
  });
}
