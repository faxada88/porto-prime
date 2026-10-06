{{flutter_js}}
{{flutter_build_config}}

window.addEventListener('error', function(event) {
  console.error('Porto Prime startup error:', event.error || event.message);
});

window.addEventListener('unhandledrejection', function(event) {
  console.error('Porto Prime unhandled promise:', event.reason);
});

_flutter.loader.load({
  config: {
    canvasKitVariant: 'full',
    canvasKitForceCpuOnly: true
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      canvasKitVariant: 'full',
      canvasKitForceCpuOnly: true
    });
    await appRunner.runApp();
  }
});
