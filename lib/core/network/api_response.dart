class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.code,
    this.message,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] == null ? null : fromJsonT(json['data']),
      code: json['code'] as String?,
      message: json['message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  final bool success;
  final T? data;
  final String? code;
  final String? message;
  final DateTime timestamp;
}
