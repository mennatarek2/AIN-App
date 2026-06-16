/// Formats a [DateTime] as a human-readable Arabic time-ago string.
abstract final class TimeAgoFormatter {
  static String format(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inDays > 30) return 'منذ أكثر من شهر';
    if (diff.inDays >= 1) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours >= 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes >= 1) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
