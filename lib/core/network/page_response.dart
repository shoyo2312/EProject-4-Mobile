/// Wrapper for the paginated `data` envelope shared by user-service and
/// video-service: `content` plus a nested `page` object with exactly four
/// fields (user-service API doc section 2).
///
/// `first`/`last`/`numberOfElements`/`empty`/`sort`/`pageable` are NOT sent —
/// the server serializes via DTO so Spring Data internals stay off the
/// contract. [last] is derived client-side.
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.size,
    required this.number,
    required this.totalElements,
    required this.totalPages,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final page = json['page'] as Map<String, dynamic>;
    return PageResponse(
      content: (json['content'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      size: page['size'] as int,
      number: page['number'] as int,
      totalElements: page['totalElements'] as int,
      totalPages: page['totalPages'] as int,
    );
  }

  final List<T> content;
  final int size;

  /// Page index, 0-based.
  final int number;
  final int totalElements;
  final int totalPages;

  /// The ONLY valid stop condition for infinite scroll. `content` can be
  /// shorter than [size] on a page that still has successors: the server
  /// silently skips ids whose profile is gone (soft-deleted, or not yet
  /// created via Kafka) instead of failing the whole page.
  bool get last => number + 1 >= totalPages;
}
