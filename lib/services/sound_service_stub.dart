// sound_service_stub.dart — 非 Web 平台的空实现
// 在移动端/桌面端不会播放声音，但不会崩溃。

class SoundService {
  static final SoundService instance = SoundService._();

  SoundService._();

  /// 播放抽取滚动音效（非 Web 端无操作）。
  void playDrawRoll() {}

  /// 停止抽取滚动音效。
  void stopDrawRoll() {}

  /// 播放揭晓音效（非 Web 端无操作）。
  void playReveal() {}
}
