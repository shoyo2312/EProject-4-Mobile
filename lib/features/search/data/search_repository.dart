import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/search/data/search_remote_datasource.dart';

class SearchRepository {
  SearchRepository(this._remoteDatasource);

  final SearchRemoteDatasource _remoteDatasource;

  Future<SearchIdPage> searchVideos({
    String? query,
    String? hashtag,
    int page = 0,
    int size = 24,
  }) async {
    try {
      return await _remoteDatasource.searchVideos(
        query: query,
        hashtag: hashtag,
        page: page,
        size: size,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
