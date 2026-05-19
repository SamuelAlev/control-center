import 'dart:ui' as ui;

import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Asset path for the dark-mode fluted-glass cloudscape shader.
const String _darkShaderAsset = 'assets/shaders/login_background_dark.frag';

/// Asset path for the light-mode blue-sky shader.
const String _lightShaderAsset = 'assets/shaders/login_background_light.frag';

/// Animated shader background that renders the fluted-glass cloudscape.
///
/// Loads a fragment shader from the given asset path and drives a
/// ticker that updates the `u_time` uniform every frame.
///
/// When [shaderAsset] is omitted the asset is chosen from the ambient
/// [Theme.of] brightness — light theme gets a blue sky, dark theme gets the
/// original ember cloudscape.
///
/// When [animate] is false the shader is rendered once at `u_time = 0` and no
/// ticker runs — a frozen "speed 0" frame for `prefers-reduced-motion` that
/// keeps the shapes but stops the motion.
class ShaderBackground extends StatefulWidget {
  /// Creates a [ShaderBackground].
  const ShaderBackground({
    super.key,
    this.shaderAsset,
    this.child,
    this.animate = true,
  });

  /// Asset path to the fragment shader. When null, the asset is selected from
  /// the current [Brightness] (see [ShaderBackground]).
  final String? shaderAsset;

  /// Child widget drawn on top of the shader.
  final Widget? child;

  /// Whether to animate. When false the shader holds at `u_time = 0` with no
  /// ticker — the frozen "speed 0" path for `prefers-reduced-motion`.
  final bool animate;

  @override
  State<ShaderBackground> createState() => _ShaderBackgroundState();
}

class _ShaderBackgroundState extends State<ShaderBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  Ticker? _ticker;
  // ValueNotifier instead of setState — the ticker fires every frame, and
  // rebuilding the whole subtree (Scaffold, forms, providers) every frame
  // makes the onboarding screen unusable. AnimatedBuilder below scopes the
  // rebuild to just the CustomPaint.
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  bool _loaded = false;
  String? _loadedAsset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final desired = _resolveAsset(context);
    if (desired != _loadedAsset) {
      _loadShader(desired);
    }
  }

  @override
  void didUpdateWidget(covariant ShaderBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final desired = _resolveAsset(context);
    if (desired != _loadedAsset) {
      _loadShader(desired);
    }
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        if (_loaded) {
          _startTicker();
        }
      } else {
        _ticker?.stop();
      }
    }
  }

  String _resolveAsset(BuildContext context) {
    if (widget.shaderAsset != null) {
      return widget.shaderAsset!;
    }
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? _lightShaderAsset
        : _darkShaderAsset;
  }

  Future<void> _loadShader(String asset) async {
    _loadedAsset = asset;
    try {
      final program = await ui.FragmentProgram.fromAsset(asset);
      if (!mounted || _loadedAsset != asset) {
        return;
      }
      final newShader = program.fragmentShader();
      final oldShader = _shader;
      setState(() {
        _program = program;
        _shader = newShader;
        _loaded = true;
      });
      oldShader?.dispose();
      if (widget.animate) {
        _startTicker();
      }
    } catch (e) {
      AppLog.e('ShaderBackground', 'Failed to load shader $asset: $e', e);
      if (mounted && _loadedAsset == asset) {
        setState(() => _loaded = false);
      }
    }
  }

  void _startTicker() {
    if (_ticker != null && _ticker!.isActive) {
      return;
    }
    _ticker ??= createTicker(_onTick);
    _ticker!.start();
  }

  // Throttle to ~30 FPS. The shader animates very slowly (u_time scaled by
  // 0.05–0.08 inside the shader), so 30 FPS is visually indistinguishable
  // from 60 FPS but halves the GPU work — important on Retina displays
  // where the fragment shader runs across millions of pixels.
  static const Duration _frameInterval = Duration(milliseconds: 33);
  Duration _lastTick = Duration.zero;

  void _onTick(Duration elapsed) {
    if (elapsed - _lastTick < _frameInterval) {
      return;
    }
    _lastTick = elapsed;
    _time.value = elapsed.inMicroseconds / 1000000;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On macOS alt+tab fires `inactive`/`hidden` rather than `paused`, so
    // pause on any non-foreground state. Resume goes through `_startTicker`
    // which guards against re-starting an already-active ticker — calling
    // `_ticker.start()` directly here is what produced the "ticker started
    // twice" crash on alt+tab back into the window.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _ticker?.stop();
      case AppLifecycleState.resumed:
        if (_loaded && widget.animate) {
          _startTicker();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    _shader?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _program == null || _shader == null) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: widget.child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return AnimatedBuilder(
                animation: _time,
                builder: (context, _) {
                  _shader!
                    ..setFloat(0, size.width)
                    ..setFloat(1, size.height)
                    ..setFloat(2, _time.value);
                  return CustomPaint(
                    size: size,
                    painter: _ShaderPainter(_shader!),
                  );
                },
              );
            },
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.shader);

  final ui.FragmentShader shader;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _cachedPaint..shader = shader);
  }

  static final Paint _cachedPaint = Paint();

  @override
  bool shouldRepaint(covariant _ShaderPainter old) => true;
}
