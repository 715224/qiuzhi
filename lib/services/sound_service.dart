// sound_service.dart — 条件导入入口
// Web 端使用 dart:html AudioElement 播放音效，
// 非 Web 端使用空实现（不崩溃，后续可接入原生音频包）。

export 'sound_service_stub.dart'
    if (dart.library.html) 'sound_service_web.dart';
