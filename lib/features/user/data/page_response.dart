/// Generic wrapper for Spring Data's `Page<T>` envelope used by the
/// followers/following/blocked/muted list endpoints (see user-service API
/// doc section 2) — not a Spring "flat array" response.
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    return PageResponse(
      content: (json['content'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      number: json['number'] as int,
      last: json['last'] as bool,
    );
  }

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final bool last;
}
