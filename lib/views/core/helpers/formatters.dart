import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

Icon formatFileTypeIcon(String? type) {
  return switch (type) {
    'pdf' => const Icon(MdiIcons.filePdfBox),
    'docx' => const Icon(MdiIcons.fileWordBox),
    'pptx' => const Icon(MdiIcons.filePowerpointBox),
    'xlsx' => const Icon(MdiIcons.fileExcelBox),
    'txt' => const Icon(MdiIcons.textBox),
    'zip' || 'rar' || '7z' => const Icon(MdiIcons.zipBox),
    'mp3' || 'ogg' || 'm4a' => const Icon(MdiIcons.musicBox),
    'mp4' || 'mkv' || 'webm' => const Icon(MdiIcons.movie),
    'jpg' || 'jpeg' || 'png' || 'gif' => const Icon(MdiIcons.image),
    'apk' => const Icon(MdiIcons.android),
    'exe' => const Icon(MdiIcons.microsoftWindows),
    'html' => const Icon(MdiIcons.languageHtml5),
    'css' => const Icon(MdiIcons.languageCss3),
    'js' => const Icon(MdiIcons.languageJavascript),
    _ => const Icon(Icons.insert_drive_file),
  };
}

Color formatFileTypeColor(String? type) {
  return switch (type) {
    'pdf' => Colors.red,
    'docx' => Colors.blue,
    'pptx' => Colors.orange,
    'xlsx' => Colors.green,
    'txt' => Colors.grey,
    'zip' || 'rar' || '7z' => Colors.indigo,
    'mp3' || 'ogg' || 'm4a' => Colors.blue,
    'mp4' || 'mkv' || 'webm' => Colors.red,
    'jpg' || 'jpeg' || 'png' || 'gif' => Colors.blue,
    'apk' => Colors.green,
    'exe' => Colors.grey,
    'html' => Colors.orange,
    'css' => Colors.blue,
    'js' => Colors.yellow,
    _ => Colors.grey,
  };
}
