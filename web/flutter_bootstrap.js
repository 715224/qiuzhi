{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  // 本地网页版不注册 Service Worker，避免浏览器长期缓存旧构建。
  serviceWorkerSettings: null,
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    document.getElementById('qiuzhi-loading')?.remove();
  }
});
