{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    // HTML renderer avoids downloading the ~1.5 MB CanvasKit WASM file,
    // giving a much faster first-load experience on web.
    let appRunner = await engineInitializer.initializeEngine({
      renderer: "html",
    });
    await appRunner.runApp();
  }
});
