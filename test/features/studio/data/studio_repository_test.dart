import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/data/studio_remote_datasource.dart';
import 'package:tiktok_mobile/features/studio/data/studio_repository.dart';

class MockStudioRemoteDatasource extends Mock implements StudioRemoteDatasource {}

void main() {
  late MockStudioRemoteDatasource remote;
  late StudioRepository repository;

  setUp(() {
    remote = MockStudioRemoteDatasource();
    repository = StudioRepository(remote);
  });

  DioException badResponse(int status, String code) {
    final request = RequestOptions(path: '/x');
    return DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: status,
        data: {'success': false, 'code': code, 'message': code},
      ),
    );
  }

  test('a refused pin surfaces as a ServerException with its code', () async {
    when(() => remote.setPinned('1', true))
        .thenThrow(badResponse(409, 'PIN_LIMIT_REACHED'));

    await expectLater(
      repository.setPinned('1', true),
      throwsA(isA<ServerException>()
          .having((e) => e.code, 'code', 'PIN_LIMIT_REACHED')),
    );
  });

  test('a lost connection becomes a NetworkException', () async {
    when(() => remote.getOverview(7)).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    ));

    await expectLater(
      repository.getOverview(7),
      throwsA(isA<NetworkException>()),
    );
  });

  test('a success passes straight through', () async {
    const overview = CreatorOverview(
      current: CreatorTotals(views: 3),
      previous: CreatorTotals(),
    );
    when(() => remote.getOverview(28)).thenAnswer((_) async => overview);

    expect(await repository.getOverview(28), overview);
  });
}
