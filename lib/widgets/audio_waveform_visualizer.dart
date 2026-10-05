import 'dart:math' as math;
import 'package:flutter/material.dart';

class AudioWaveformVisualizer extends StatefulWidget {
  final bool isAnimating;
  final double height;
  final int barCount;
  final Color activeColor;
  final Color inactiveColor;
  final double progress; // 0.0 - 1.0 for playback progress
  final bool isRecordingStyle;

  const AudioWaveformVisualizer({
    super.key,
    required this.isAnimating,
    this.height = 50.0,
    this.barCount = 28,
    required this.activeColor,
    required this.inactiveColor,
    this.progress = 0.0,
    this.isRecordingStyle = false,
  });

  @override
  State<AudioWaveformVisualizer> createState() =>
      _AudioWaveformVisualizerState();
}

class _AudioWaveformVisualizerState extends State<AudioWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Static height ratios for natural waveform curve shape
  final List<double> _baseRatios = [
    0.2,
    0.35,
    0.6,
    0.8,
    0.45,
    0.7,
    0.95,
    0.85,
    0.5,
    0.75,
    0.9,
    0.6,
    0.8,
    1.0,
    0.7,
    0.9,
    0.55,
    0.75,
    0.4,
    0.65,
    0.85,
    0.6,
    0.4,
    0.7,
    0.9,
    0.5,
    0.3,
    0.2
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AudioWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.animateTo(0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final int barRatioIndex = index % _baseRatios.length;
              final double baseRatio = _baseRatios[barRatioIndex];

              double animatedRatio = baseRatio;
              if (widget.isAnimating) {
                // Sine wave harmonic animation multiplier per bar
                final double phase =
                    (index * 0.45) + (_controller.value * 2 * math.pi);
                final double wave = (math.sin(phase) + 1.0) / 2.0; // 0.0 - 1.0
                animatedRatio = baseRatio * (0.3 + 0.7 * wave);
              }

              // Calculate active progress color for playback
              final double barProgressPosition = index / widget.barCount;
              final bool isActiveBar = widget.isRecordingStyle
                  ? widget.isAnimating
                  : barProgressPosition <= widget.progress;

              final Color currentBarColor = isActiveBar
                  ? widget.activeColor
                  : widget.inactiveColor.withValues(alpha: 0.35);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 3.5,
                height: math.max(6.0, widget.height * animatedRatio),
                decoration: BoxDecoration(
                  color: currentBarColor,
                  borderRadius: BorderRadius.circular(4.0),
                  boxShadow: isActiveBar && widget.isAnimating
                      ? [
                          BoxShadow(
                            color: widget.activeColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          )
                        ]
                      : null,
                ),
              );
            }),
          );
        },
      ),
    ),
    );
  }
}
