import 'package:flutter/material.dart';
import '../constants/animation_constants.dart';

/// Mixin for Parallax scrolling animations
mixin ParallaxMixin<T extends StatefulWidget> on State<T> {
  ScrollController? _scrollController;

  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  double getParallaxOffset(
    double offset, {
    double factor = AnimationConstants.parallaxFactor,
  }) {
    return offset * factor;
  }

  Widget buildParallaxWidget({
    required Widget child,
    required double scrollOffset,
    double factor = AnimationConstants.parallaxFactor,
  }) {
    return Transform.translate(
      offset: Offset(0, getParallaxOffset(scrollOffset, factor: factor)),
      child: child,
    );
  }
}

/// Mixin for Hover animations
mixin HoverAnimationMixin<T extends StatefulWidget> on State<T> {
  bool _isHovered = false;

  bool get isHovered => _isHovered;

  void setHovered(bool hovered) {
    if (_isHovered != hovered) {
      setState(() {
        _isHovered = hovered;
      });
    }
  }

  Widget buildHoverWidget({
    required Widget child,
    VoidCallback? onTap,
    double scale = AnimationConstants.hoverScale,
    double elevation = AnimationConstants.hoverElevation,
  }) {
    return MouseRegion(
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AnimationConstants.hoverDuration,
          curve: AnimationConstants.defaultCurve,
          transform: Matrix4.identity()..scale(_isHovered ? scale : 1.0),
          child: AnimatedContainer(
            duration: AnimationConstants.hoverDuration,
            curve: AnimationConstants.defaultCurve,
            decoration: BoxDecoration(
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: elevation,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Mixin for Pulse animations
mixin PulseAnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  AnimationController get pulseController => _pulseController;
  Animation<double> get pulseAnimation => _pulseAnimation;

  void initPulseAnimation(TickerProvider vsync) {
    _pulseController = AnimationController(
      duration: AnimationConstants.pulseDuration,
      vsync: vsync,
    );

    _pulseAnimation =
        Tween<double>(begin: 1.0, end: AnimationConstants.pulseScale).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  void startPulse() {
    _pulseController.repeat(reverse: true);
  }

  void stopPulse() {
    _pulseController.stop();
    _pulseController.reset();
  }

  Widget buildPulseWidget({required Widget child, bool autoStart = false}) {
    if (autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => startPulse());
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child!);
      },
      child: child,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

/// Mixin for Stagger animations
mixin StaggerAnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController _staggerController;
  late List<Animation<double>> _staggerAnimations;

  AnimationController get staggerController => _staggerController;
  List<Animation<double>> get staggerAnimations => _staggerAnimations;

  void initStaggerAnimation({
    required TickerProvider vsync,
    required int itemCount,
    Duration delay = AnimationConstants.staggerDelay,
  }) {
    _staggerController = AnimationController(
      duration: Duration(
        milliseconds:
            AnimationConstants.normalDuration.inMilliseconds +
            (itemCount * delay.inMilliseconds),
      ),
      vsync: vsync,
    );

    _staggerAnimations = List.generate(
      itemCount,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            (index * delay.inMilliseconds) /
                (AnimationConstants.normalDuration.inMilliseconds +
                    (itemCount * delay.inMilliseconds)),
            1.0,
            curve: AnimationConstants.defaultCurve,
          ),
        ),
      ),
    );
  }

  void startStaggerAnimation() {
    _staggerController.forward();
  }

  Widget buildStaggerWidget({
    required int index,
    required Widget child,
    Duration delay = AnimationConstants.staggerDelay,
  }) {
    if (index >= _staggerAnimations.length) return child;

    return AnimatedBuilder(
      animation: _staggerAnimations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _staggerAnimations[index].value)),
          child: Opacity(
            opacity: _staggerAnimations[index].value,
            child: child!,
          ),
        );
      },
      child: child,
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }
}

/// Mixin for Floating animations
mixin FloatingAnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  AnimationController get floatingController => _floatingController;
  Animation<double> get floatingAnimation => _floatingAnimation;

  void initFloatingAnimation({
    required TickerProvider vsync,
    Duration duration = AnimationConstants.floatingDuration,
    double amplitude = AnimationConstants.floatingAmplitude,
  }) {
    _floatingController = AnimationController(duration: duration, vsync: vsync);

    _floatingAnimation = Tween<double>(begin: -amplitude, end: amplitude)
        .animate(
          CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
        );
  }

  void startFloating() {
    _floatingController.repeat(reverse: true);
  }

  void stopFloating() {
    _floatingController.stop();
  }

  Widget buildFloatingWidget({required Widget child, bool autoStart = true}) {
    if (autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => startFloating());
    }

    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: child!,
        );
      },
      child: child,
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }
}

/// Mixin for Glow animations
mixin GlowAnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  AnimationController get glowController => _glowController;
  Animation<double> get glowAnimation => _glowAnimation;

  void initGlowAnimation({
    required TickerProvider vsync,
    Duration duration = AnimationConstants.glowDuration,
    double intensity = AnimationConstants.glowIntensity,
  }) {
    _glowController = AnimationController(duration: duration, vsync: vsync);

    _glowAnimation = Tween<double>(begin: 0.0, end: intensity).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void startGlow() {
    _glowController.repeat(reverse: true);
  }

  void stopGlow() {
    _glowController.stop();
  }

  Widget buildGlowWidget({
    required Widget child,
    required Color glowColor,
    double blurRadius = 20.0,
    bool autoStart = false,
  }) {
    if (autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => startGlow());
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(_glowAnimation.value),
                blurRadius: blurRadius,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: child!,
        );
      },
      child: child,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
}

/// Mixin for Counting animations
mixin CountingAnimationMixin<T extends StatefulWidget> on State<T> {
  late AnimationController _countingController;
  late Animation<double> _countingAnimation;

  AnimationController get countingController => _countingController;
  Animation<double> get countingAnimation => _countingAnimation;

  void initCountingAnimation({
    required TickerProvider vsync,
    Duration duration = AnimationConstants.countingDuration,
    Duration delay = AnimationConstants.countingDelay,
  }) {
    _countingController = AnimationController(duration: duration, vsync: vsync);

    _countingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _countingController,
        curve: AnimationConstants.luxuryCurve,
      ),
    );

    Future.delayed(delay, () {
      if (mounted) {
        _countingController.forward();
      }
    });
  }

  Widget buildCountingWidget({
    required int targetValue,
    required Widget Function(int value) builder,
    String? suffix,
  }) {
    return AnimatedBuilder(
      animation: _countingAnimation,
      builder: (context, child) {
        final currentValue = (_countingAnimation.value * targetValue).round();
        return builder(currentValue);
      },
    );
  }

  @override
  void dispose() {
    _countingController.dispose();
    super.dispose();
  }
}

/// Mixin for Micro-interactions
mixin MicroInteractionMixin<T extends StatefulWidget> on State<T> {
  bool _isPressed = false;

  bool get isPressed => _isPressed;

  void setPressed(bool pressed) {
    if (_isPressed != pressed) {
      setState(() {
        _isPressed = pressed;
      });
    }
  }

  Widget buildMicroInteractionWidget({
    required Widget child,
    VoidCallback? onTap,
    double scale = AnimationConstants.microInteractionScale,
  }) {
    return GestureDetector(
      onTapDown: (_) => setPressed(true),
      onTapUp: (_) => setPressed(false),
      onTapCancel: () => setPressed(false),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimationConstants.microInteractionDuration,
        curve: AnimationConstants.defaultCurve,
        transform: Matrix4.identity()..scale(_isPressed ? scale : 1.0),
        child: child,
      ),
    );
  }
}
