import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/create/data/music_remote_datasource.dart';
import 'package:tiktok_mobile/features/create/data/music_repository.dart';
import 'package:tiktok_mobile/features/create/data/music_track.dart';

part 'music_provider.g.dart';

@Riverpod(keepAlive: true)
MusicRepository musicRepository(Ref ref) =>
    MusicRepository(MusicRemoteDatasource(ref.watch(apiClientProvider)));

/// One page of the catalogue for [query] (empty: the most popular). Dropped
/// once the picker stops showing it; the server caches pages anyway.
@riverpod
Future<List<MusicTrack>> musicSearch(Ref ref, String query) =>
    ref.watch(musicRepositoryProvider).search(query: query);
