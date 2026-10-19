/// The server's clock as seen from this device, learned from HTTP `Date` response headers.
/// Countdowns driven by server timestamps (offer `expires_at`, pickup deadline) use [now] so a
/// phone whose clock is off still shows the server's remaining time.
class ServerClock {
  ServerClock({DateTime Function()? deviceNow})
    : _deviceNow = deviceNow ?? DateTime.now;

  /// A sample this far from the current offset replaces it (the phone clock was changed).
  static const jumpThreshold = Duration(seconds: 5);

  /// Weight of a new sample in the smoothed offset.
  static const smoothing = 0.25;

  // `Date` has one-second resolution: the true server time is in [header, header + 1s).
  static const _resolutionMidpoint = Duration(milliseconds: 500);

  final DateTime Function() _deviceNow;
  Duration _offset = Duration.zero;
  bool _sampled = false;

  /// Server time minus device time; zero until a valid header was seen.
  Duration get offset => _offset;

  bool get hasSample => _sampled;

  /// Server-adjusted current time.
  DateTime now() => _deviceNow().add(_offset);

  /// Feeds a `Date` header value received now. Absent or unparseable values are ignored.
  void observe(String? dateHeader) {
    final server = parseHttpDate(dateHeader);
    if (server == null) return;
    observeSample(server.add(_resolutionMidpoint), _deviceNow());
  }

  /// Records that the server clock read [server] when the device clock read [device].
  void observeSample(DateTime server, DateTime device) {
    final sample = server.difference(device);
    if (!_sampled || (sample - _offset).abs() > jumpThreshold) {
      _offset = sample;
      _sampled = true;
      return;
    }
    final blended =
        _offset.inMicroseconds +
        ((sample.inMicroseconds - _offset.inMicroseconds) * smoothing).round();
    _offset = Duration(microseconds: blended);
  }
}

const _months = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};

final _imfFixdate = RegExp(
  r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), (\d{2}) ([A-Z][a-z]{2}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
);

/// Parses an RFC 7231 IMF-fixdate (`Sun, 06 Nov 1994 08:49:37 GMT`, what Go's net/http sends)
/// to UTC, or null for anything else.
DateTime? parseHttpDate(String? value) {
  if (value == null) return null;
  final m = _imfFixdate.firstMatch(value.trim());
  if (m == null) return null;
  final month = _months[m.group(3)];
  if (month == null) return null;
  final day = int.parse(m.group(2)!);
  final year = int.parse(m.group(4)!);
  final hour = int.parse(m.group(5)!);
  final minute = int.parse(m.group(6)!);
  final second = int.parse(m.group(7)!);
  if (day < 1 || day > 31 || hour > 23 || minute > 59 || second > 60) {
    return null;
  }
  final date = DateTime.utc(year, month, day, hour, minute, second);
  // Rejects overflow such as 31 Feb, which DateTime would roll into March.
  if (date.month != month || date.day != day) return null;
  return date;
}
