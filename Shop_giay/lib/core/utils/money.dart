String formatVnd(num value) {
  final s = value.toStringAsFixed(0);
  final chars = s.split('').reversed.toList();
  final out = <String>[];
  for (int i = 0; i < chars.length; i++) {
    out.add(chars[i]);
    if ((i + 1) % 3 == 0 && i != chars.length - 1) out.add('.');
  }
  return '${out.reversed.join()} ₫';
}
