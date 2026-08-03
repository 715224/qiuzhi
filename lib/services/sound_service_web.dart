// sound_service_web.dart — Web 端实现
// 使用 dart:html AudioElement 播放音效，无需额外 Flutter 插件。

import 'dart:async';
import 'dart:html' as html;

class SoundService {
  static final SoundService instance = SoundService._();

  html.AudioElement? _rollAudio;
  bool _initialized = false;

  SoundService._();

  void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    try {
      _rollAudio = html.AudioElement('assets/sounds/draw_roll.wav');
      _rollAudio!.loop = true;
      _rollAudio!.volume = 0.4;
    } catch (_) {
      // 浏览器可能阻止音频创建，忽略不中断流程。
    }
  }

  /// 播放抽取滚动音效（循环播放，直到调用 stopDrawRoll）。
  void playDrawRoll() {
    _ensureInit();
    try {
      _rollAudio?.currentTime = 0;
      _rollAudio?.play()?.catchError((_) {});
    } catch (_) {}
  }

  /// 停止抽取滚动音效。
  void stopDrawRoll() {
    try {
      _rollAudio?.pause();
      _rollAudio?.currentTime = 0;
    } catch (_) {}
  }

  /// 播放揭晓音效（一次性）。
  void playReveal() {
    try {
      final audio = html.AudioElement('assets/sounds/draw_reveal.wav');
      audio.volume = 0.5;
      audio.play()?.catchError((_) {});
    } catch (_) {}
  }
}
