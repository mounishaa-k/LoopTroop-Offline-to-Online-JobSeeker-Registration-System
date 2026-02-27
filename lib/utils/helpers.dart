import 'dart:math';
import 'package:intl/intl.dart';

class Helpers {
  static String formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, HH:mm').format(dt);

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return DateFormat('dd MMM yyyy').format(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  static String confidenceLabel(double c) {
    if (c >= 0.8) return 'High';
    if (c >= 0.55) return 'Medium';
    return 'Low';
  }

  static String truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  /// Strips extra whitespace and normalizes line endings.
  static String normalizeText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  /// Simple Levenshtein distance between two lowercase strings.
  static int editDistance(String s1, String s2) {
    final m = s1.length, n = s2.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      d[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          d[i][j] = d[i - 1][j - 1];
        } else {
          d[i][j] = 1 + [d[i - 1][j], d[i][j - 1], d[i - 1][j - 1]].reduce(min);
        }
      }
    }
    return d[m][n];
  }

  /// True if [candidate] fuzzy-matches any item in [keywords] within [maxDist].
  static bool fuzzyMatchesAny(
    String candidate,
    List<String> keywords, {
    int maxDist = 2,
  }) {
    final normalized = candidate.toLowerCase().trim();
    for (final kw in keywords) {
      final k = kw.toLowerCase();
      if (normalized.contains(k) || k.contains(normalized)) {
        return true;
      }
      if (editDistance(normalized, k) <= maxDist) {
        return true;
      }
    }
    return false;
  }

  /// Capitalize first letter of each word.
  static String toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}
