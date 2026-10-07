const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String formatStamp(DateTime d, {bool withYear = true}) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  final y = (withYear && d.year != DateTime.now().year) ? ', ${d.year}' : '';
  return '${_months[d.month - 1]} ${d.day}$y · $h:$m $ap';
}
