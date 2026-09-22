import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated CoDriver intro shown once at app start.
///
/// The [child] (normally the auth gate) is built underneath from the very
/// first frame, so Firebase/auth resolution runs while the intro plays.
/// Sequence (~1.8 s, then a 350 ms cross-fade into the app):
///   1. the inner dot pops in,
///   2. the two-tone ring draws on from the upper tip round to the lower tip,
///   3. "CO" slides in, "DRIVER" follows letter by letter,
///   4. the tagline settles in as its tracking tightens.
/// With "Reduce Motion" enabled the final frame is shown briefly instead.
class CodriverSplash extends StatefulWidget {
  final Widget child;

  const CodriverSplash({super.key, required this.child});

  @override
  State<CodriverSplash> createState() => _CodriverSplashState();
}

class _CodriverSplashState extends State<CodriverSplash>
    with SingleTickerProviderStateMixin {
  static const _kIntro = Duration(milliseconds: 1800);
  static const _kHold = Duration(milliseconds: 350);
  static const _kFadeOut = Duration(milliseconds: 350);
  static const _kReducedHold = Duration(milliseconds: 700);
  static const _kFontTimeout = Duration(milliseconds: 700);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: _kIntro,
  );

  bool _fontsReady = false;
  bool _fadingOut = false;
  bool _done = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _prepareFonts();
  }

  Future<void> _prepareFonts() async {
    try {
      await GoogleFonts.pendingFonts([
        _wordmarkStyle(FontWeight.w800),
        _wordmarkStyle(FontWeight.w300),
        _taglineStyle(),
      ]).timeout(_kFontTimeout);
    } catch (_) {
      // Offline or slow network: fall back to the platform font.
    }
    if (!mounted) return;
    setState(() => _fontsReady = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  void _start() {
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _ctrl.value = 1.0;
      Future<void>.delayed(_kReducedHold, _beginFadeOut);
      return;
    }
    _ctrl.forward().whenComplete(() {
      Future<void>.delayed(_kHold, _beginFadeOut);
    });
  }

  void _beginFadeOut() {
    if (!mounted || _fadingOut) return;
    setState(() => _fadingOut = true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static TextStyle _wordmarkStyle(FontWeight weight) => GoogleFonts.montserrat(
    fontWeight: weight,
    fontSize: 44,
    height: 1.0,
    letterSpacing: 0.5,
    color: _CodriverBrand.graphite,
  );

  static TextStyle _taglineStyle() => GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.0,
    color: _CodriverBrand.taglineGrey,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_done)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _fadingOut ? 0.0 : 1.0,
              duration: _kFadeOut,
              curve: Curves.easeOutCubic,
              onEnd: () {
                if (_fadingOut && mounted) setState(() => _done = true);
              },
              child: ColoredBox(
                color: Colors.white,
                child: _fontsReady
                    ? _SplashScene(
                        controller: _ctrl,
                        wordmarkBold: _wordmarkStyle(FontWeight.w800),
                        wordmarkLight: _wordmarkStyle(FontWeight.w300),
                        tagline: _taglineStyle(),
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ),
      ],
    );
  }
}

class _CodriverBrand {
  static const deep = Color(0xFF006047);
  static const green = Color(0xFF00B287);
  static const graphite = Color(0xFF3D3D3D);
  static const taglineGrey = Color(0xFF7A7A7A);
}

class _SplashScene extends StatelessWidget {
  final AnimationController controller;
  final TextStyle wordmarkBold;
  final TextStyle wordmarkLight;
  final TextStyle tagline;

  const _SplashScene({
    required this.controller,
    required this.wordmarkBold,
    required this.wordmarkLight,
    required this.tagline,
  });

  static const _easeOutQuint = Cubic(0.22, 1, 0.36, 1);

  // Phase timings as fractions of the 1.8 s intro.
  static const _dotIn = Interval(0.00, 0.28, curve: Curves.easeOutBack);
  static const _ringIn = Interval(0.08, 0.50, curve: Curves.easeInOutCubic);
  static const _coIn = Interval(0.34, 0.60, curve: _easeOutQuint);
  static const _driverStart = 0.46;
  static const _driverStep = 0.045;
  static const _driverLen = 0.16;
  static const _taglineIn = Interval(0.70, 0.92, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    final markSize = compact ? 108.0 : 132.0;
    final wordScale = compact ? 0.82 : 1.0;

    return Semantics(
      label: 'CoDriver – Smart Delivery Assistant',
      child: ExcludeSemantics(
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final t = controller.value;
              final dot = _dotIn.transform(t);
              final ring = _ringIn.transform(t);
              final co = _coIn.transform(t);
              final tag = _taglineIn.transform(t);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: markSize,
                    height: markSize,
                    child: CustomPaint(
                      painter: _CodriverMarkPainter(
                        dotScale: dot,
                        ringProgress: ring,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 26 : 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Opacity(
                        opacity: co,
                        child: Transform.translate(
                          offset: Offset(-18 * (1 - co), 0),
                          child: Text(
                            'CO',
                            style: wordmarkBold.copyWith(
                              fontSize: wordmarkBold.fontSize! * wordScale,
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < 'DRIVER'.length; i++)
                        _StaggeredLetter(
                          letter: 'DRIVER'[i],
                          style: wordmarkLight.copyWith(
                            fontSize: wordmarkLight.fontSize! * wordScale,
                          ),
                          progress: Interval(
                            _driverStart + i * _driverStep,
                            _driverStart + i * _driverStep + _driverLen,
                            curve: _easeOutQuint,
                          ).transform(t),
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 12 : 14),
                  Opacity(
                    opacity: tag,
                    child: Text(
                      'SMART DELIVERY ASSISTANT',
                      style: tagline.copyWith(
                        fontSize: tagline.fontSize! * wordScale,
                        // Tracking settles from wide to its final value.
                        letterSpacing: 3.0 + 5.0 * (1 - tag),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StaggeredLetter extends StatelessWidget {
  final String letter;
  final TextStyle style;
  final double progress;

  const _StaggeredLetter({
    required this.letter,
    required this.style,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - progress)),
        child: Text(letter, style: style),
      ),
    );
  }
}

/// Draws the CoDriver "C" mark: a two-tone open ring around a solid dot.
///
/// Proportions follow the brand SVG: ring outer radius R, ring inner radius
/// 0.71 R, dot radius 0.44 R. The ring opens to the right (±36°) and is split
/// at the lower-left diagonal (135°): deep green from the upper tip over the
/// top and left side, bright green along the bottom to the lower tip.
class _CodriverMarkPainter extends CustomPainter {
  final double dotScale;
  final double ringProgress;

  const _CodriverMarkPainter({
    required this.dotScale,
    required this.ringProgress,
  });

  static const _tip = 36.0 * math.pi / 180; // half opening angle
  static const _split = 135.0 * math.pi / 180; // lower-left diagonal

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    // Inner dot.
    if (dotScale > 0) {
      canvas.drawCircle(
        c,
        0.44 * r * dotScale,
        Paint()..color = _CodriverBrand.green,
      );
    }

    if (ringProgress <= 0) return;

    final strokeWidth = r * (1 - 0.71);
    final midRadius = r * (1 + 0.71) / 2;
    final rect = Rect.fromCircle(center: c, radius: midRadius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // The ring is drawn counter-clockwise (negative sweep in Flutter's
    // clockwise-positive angle space) from the upper tip to the lower tip.
    const total = 2 * math.pi - 2 * _tip; // 288°
    // Going counter-clockwise from -36°: the deep segment spans from -36°
    // back to -225° (= 135°), i.e. 189°; the bright one the remaining 99°.
    const deepSweep = 2 * math.pi - (_split + _tip); // 189°
    const brightSweep = total - deepSweep; // 99°

    final drawn = total * ringProgress.clamp(0.0, 1.0);
    final deepDrawn = math.min(drawn, deepSweep);
    final brightDrawn = math.max(0.0, drawn - deepSweep);

    if (deepDrawn > 0) {
      canvas.drawArc(
        rect,
        -_tip,
        -deepDrawn,
        false,
        paint..color = _CodriverBrand.deep,
      );
    }
    if (brightDrawn > 0) {
      canvas.drawArc(
        rect,
        -_tip - deepSweep,
        -math.min(brightDrawn, brightSweep),
        false,
        paint..color = _CodriverBrand.green,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CodriverMarkPainter old) =>
      old.dotScale != dotScale || old.ringProgress != ringProgress;
}
