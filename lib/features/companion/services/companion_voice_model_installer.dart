import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads + unpacks the neural TTS voice (Piper, via sherpa_onnx) into
/// `<app-docs>/tts/`. Everything stays on-device after that.
///
/// The model ships as a `.tar.bz2` (top-level folder → stripped). The single
/// `.onnx` is renamed to `model.onnx`; `tokens.txt` + `espeak-ng-data/` keep
/// their names — matching what [CompanionVoiceService] expects.
class CompanionVoiceModelInstaller {
  static final CompanionVoiceModelInstaller _instance =
      CompanionVoiceModelInstaller._internal();
  factory CompanionVoiceModelInstaller() => _instance;
  CompanionVoiceModelInstaller._internal();

  /// Piper `en_US-ryan-medium` (~63 MB). For a female voice, swap to
  /// `vits-piper-en_US-amy-medium.tar.bz2`.
  static const String _modelUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-ryan-medium.tar.bz2';

  Directory? _dir;
  Future<void>? _inFlight;
  ValueChanged<double>? _onProgress; // latest listener (so a UI can attach late)

  Future<Directory> _ttsDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory('${docs.path}/tts');
    if (!d.existsSync()) d.createSync(recursive: true);
    _dir = d;
    return d;
  }

  Future<String> get modelPath async => '${(await _ttsDir()).path}/model.onnx';
  Future<String> get tokensPath async => '${(await _ttsDir()).path}/tokens.txt';
  Future<String> get espeakPath async =>
      '${(await _ttsDir()).path}/espeak-ng-data';

  Future<bool> isInstalled() async {
    final d = await _ttsDir();
    return File('${d.path}/.ready').existsSync();
  }

  /// Idempotent. Concurrent/repeat calls share one in-flight download.
  /// [onProgress] reports 0.0 → 1.0 (download is ~0–0.9, unpack ~0.9–1.0).
  Future<void> ensureInstalled({ValueChanged<double>? onProgress}) {
    if (onProgress != null) _onProgress = onProgress;
    return _inFlight ??= _run().whenComplete(() {
      _inFlight = null;
      _onProgress = null;
    });
  }

  Future<void> _run() async {
    if (await isInstalled()) {
      _onProgress?.call(1.0);
      return;
    }
    final d = await _ttsDir();
    final client = http.Client();
    try {
      debugPrint('⬇️ Companion voice: downloading model…');
      final resp = await client.send(http.Request('GET', Uri.parse(_modelUrl)));
      if (resp.statusCode != 200) {
        debugPrint('⚠️ voice model download failed: HTTP ${resp.statusCode}');
        return;
      }
      final total = resp.contentLength ?? 0;
      final builder = BytesBuilder(copy: false);
      var received = 0;
      await for (final chunk in resp.stream) {
        builder.add(chunk);
        received += chunk.length;
        if (total > 0) _onProgress?.call((received / total) * 0.9);
      }
      _onProgress?.call(0.92);

      // Decode (bz2 → tar) + extract off the UI thread so it never janks.
      await compute(_decodeAndExtract, _ExtractArgs(builder.takeBytes(), d.path));

      File('${d.path}/.ready').writeAsStringSync('1');
      _onProgress?.call(1.0);
      debugPrint('✅ Companion voice: model installed at ${d.path}');
    } catch (e) {
      debugPrint('⚠️ Companion voice install error: $e');
    } finally {
      client.close();
    }
  }
}

class _ExtractArgs {
  final Uint8List bytes;
  final String dir;
  const _ExtractArgs(this.bytes, this.dir);
}

/// Runs in a background isolate via [compute].
void _decodeAndExtract(_ExtractArgs a) {
  final tarBytes = BZip2Decoder().decodeBytes(a.bytes);
  final archive = TarDecoder().decodeBytes(tarBytes);
  for (final entry in archive) {
    if (!entry.isFile) continue;
    var rel = entry.name;
    final slash = rel.indexOf('/'); // strip the top-level "<model>/" folder
    if (slash >= 0) rel = rel.substring(slash + 1);
    if (rel.isEmpty) continue;
    if (rel.endsWith('.onnx')) rel = 'model.onnx';
    final out = File('${a.dir}/$rel');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(entry.content);
  }
}
