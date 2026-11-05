import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/create/data/music_remote_datasource.dart';
import 'package:tiktok_mobile/features/create/data/music_track.dart';

class MusicRepository {
  MusicRepository(this._remoteDatasource);

  final MusicRemoteDatasource _remoteDatasource;

  /// [query] empty for the most popular tracks. A [ServerException] with code
  /// `MUSIC_UNAVAILABLE` means the catalogue cannot be read right now.
  Future<List<MusicTrack>> search({String query = '', int page = 0}) async {
    try {
      return await _remoteDatasource.search(query: query, page: page);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
