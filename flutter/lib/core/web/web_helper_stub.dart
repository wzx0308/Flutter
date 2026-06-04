import 'dart:typed_data';

void initWebFixes() {}

/// Native stub — Blob URL reading is only needed on web.
Future<Uint8List> readBlobUrl(String url) async {
  throw UnsupportedError('readBlobUrl is only supported on web');
}
