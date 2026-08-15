import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';

void main() {
  // The pagination metadata sits inside a nested "page" object and the server
  // never sends `last` — reading either as a flat top-level field throws on
  // every list screen.
  Map<String, dynamic> body({required int number, required int totalPages}) => {
        'content': [
          {'id': 'a'},
        ],
        'page': {
          'size': 20,
          'number': number,
          'totalElements': 42,
          'totalPages': totalPages,
        },
      };

  String pick(Map<String, dynamic> json) => json['id'] as String;

  test('reads the metadata out of the nested page object', () {
    final page = PageResponse.fromJson(body(number: 0, totalPages: 3), pick);

    expect(page.content, ['a']);
    expect(page.size, 20);
    expect(page.number, 0);
    expect(page.totalElements, 42);
    expect(page.totalPages, 3);
  });

  test('derives last from number and totalPages', () {
    expect(PageResponse.fromJson(body(number: 0, totalPages: 3), pick).last, isFalse);
    expect(PageResponse.fromJson(body(number: 2, totalPages: 3), pick).last, isTrue);
    // Empty result set: totalPages 0 must not read as "there is more".
    expect(PageResponse.fromJson(body(number: 0, totalPages: 0), pick).last, isTrue);
  });
}
