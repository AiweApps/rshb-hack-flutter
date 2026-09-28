
import '../../../core/services/api/models/app_error.dart';
import '../../../core/services/api/models/result.dart';
import '../../../core/services/api/repositories/api_repository.dart';
import '../../../core/services/api/service/api_endpoints.dart';
import '../../../core/services/api/service/api_service.dart';
import 'models/music_api_error.dart';
import 'models/track.dart';
import 'music_api_endpoints.dart';
import 'music_api_parser.dart';

class MusicApiRepository extends ApiRepository {
  MusicApiRepository(super.apiService);

  Future<Result<List<Track>>> searchTracks(String query) async {
    final request = ApiServiceRequest(
      endpoint: Search(),
      method: HTTPMethod.get,
      queryParams: {"q": query},
    );
    return handleAPICall(
      apiRequest: request,
      fromJson: (json) => MusicApiParser.getList(
        json,
        keyPath: "data",
        fromJson: Track.fromJson,
      ),
      validateJson: (json) {
        if ((json is Map<String, dynamic>) && json.containsKey("error")) {
          final error = MusicApiError.fromJson(json);
          return ApiError(
            errorCode: error.error.code,
            errorMessage: error.error.message,
          );
        }
        return null;
      },
    );
  }
}
