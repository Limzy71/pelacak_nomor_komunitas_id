import 'dart:io';

void main() {
  final dir = Directory('d:/phonerep-caller/mobile/lib/screens');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('GoogleFonts.outfit')) {
      content = content.replaceAllMapped(RegExp(r'GoogleFonts\.outfit\((.*?)\)', dotAll: true), (match) {
        final inner = match.group(1)!;
        if (inner.contains('bold') || inner.contains('w600') || inner.contains('w700') || inner.contains('fontSize: 18') || inner.contains('fontSize: 2')) {
          return 'GoogleFonts.sora($inner)';
        } else {
          return 'GoogleFonts.plusJakartaSans($inner)';
        }
      });
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
