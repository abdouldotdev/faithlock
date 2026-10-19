import 'dart:async';

import 'package:faithlock/features/companion/services/companion_voice_model_installer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Reads the Companion's replies aloud (voice mode).
///
/// Primary engine: **sherpa_onnx** neural TTS (Piper) — natural, on-device, free.
/// The voice model is fetched on first use by [CompanionVoiceModelInstaller]
/// (~63 MB, one time) and cached on-device. Until it finishes, and whenever the
/// neural path is unavailable, it falls back to native **flutter_tts** so voice
/// mode always works.
class CompanionVoiceService {
  static final CompanionVoiceService _instance =
      CompanionVoiceService._internal();
  factory CompanionVoiceService() => _instance;
  CompanionVoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final CompanionVoiceModelInstaller _installer =
      CompanionVoiceModelInstaller();

  sherpa.OfflineTts? _neural;
  bool _neuralFailed = false;
  bool _nativeReady = false;

  /// Kick off the model download early (e.g. when voice mode is on) so the
  /// neural voice is ready by the time the first reply arrives.
  Future<void> prewarm() => _ensureNeural();

  Future<void> _ensureNeural() async {
    if (_neural != null || _neuralFailed) return;
    if (!await _installer.isInstalled()) {
      // Fetch in the background; use the native fallback until it's ready.
      unawaited(_installer.ensureInstalled());
      return;
    }
    try {
      sherpa.initBindings();
      _neural = sherpa.OfflineTts(
        sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            vits: sherpa.OfflineTtsVitsModelConfig(
              model: await _installer.modelPath,
              tokens: await _installer.tokensPath,
              dataDir: await _installer.espeakPath,
            ),
            numThreads: 2,
            debug: false,
          ),
        ),
      );
      debugPrint('✅ Companion TTS: neural (sherpa) ready');
    } catch (e) {
      debugPrint('⚠️ Companion neural TTS init failed → flutter_tts: $e');
      _neuralFailed = true;
    }
  }

  Future<void> _ensureNative() async {
    if (_nativeReady) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _nativeReady = true;
    } catch (e) {
      debugPrint('⚠️ Companion native TTS init failed: $e');
    }
  }

  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await stop();
    await _ensureNeural();

    final neural = _neural;
    if (neural != null) {
      try {
        final audio = neural.generate(text: clean, speed: 1.0);
        final tmp = await getTemporaryDirectory();
        final path = '${tmp.path}/companion_tts.wav';
        sherpa.writeWave(
          filename: path,
          samples: audio.samples,
          sampleRate: audio.sampleRate,
        );
        await _player.setFilePath(path);
        await _player.play();
        return;
      } catch (e) {
        debugPrint('⚠️ Companion neural speak failed → flutter_tts: $e');
      }
    }

    await _ensureNative();
    try {
      await _tts.speak(clean);
    } catch (e) {
      debugPrint('⚠️ Companion native speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
