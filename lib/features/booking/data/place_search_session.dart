import '../../../core/format/uuid.dart';
import '../../../core/location/geo_point.dart';
import 'booking_models.dart';
import 'booking_repository.dart';

/// One place search: a single session token shared by every autocomplete call and the
/// final details call (Google bills them as one session), then discarded.
class PlaceSearchSession {
  PlaceSearchSession(this._repo, {String Function()? newToken})
    : _newToken = newToken ?? uuidV4;

  static const minChars = 2;

  final BookingRepository _repo;
  final String Function() _newToken;
  String? _token;

  /// The active token, or null before the first search / after [select] or [discard].
  String? get token => _token;

  Future<List<PlacePrediction>> search(String input, {GeoPoint? near}) {
    final query = input.trim();
    if (query.length < minChars) return Future.value(const []);
    return _repo.autocomplete(
      input: query,
      sessionToken: _token ??= _newToken(),
      near: near,
    );
  }

  /// Resolves the chosen prediction and ends the session.
  Future<Place> select(PlacePrediction prediction) async {
    final token = _token ??= _newToken();
    try {
      return await _repo.placeDetails(
        placeId: prediction.placeId,
        sessionToken: token,
      );
    } finally {
      _token = null;
    }
  }

  void discard() => _token = null;
}
