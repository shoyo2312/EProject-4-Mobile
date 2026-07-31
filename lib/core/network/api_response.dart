class ApiError {
  const ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: json['code'] as String? ?? 'unknown',
        message: json['message'] as String? ?? 'Unknown error',
      );

  final String code;
  final String message;
}

class ApiResponse<T> {
  const ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] == null ? null : fromJsonT(json['data']),
      error: json['error'] == null
          ? null
          : ApiError.fromJson(json['error'] as Map<String, dynamic>),
    );
  }

  final bool success;
  final T? data;
  final ApiError? error;
}
