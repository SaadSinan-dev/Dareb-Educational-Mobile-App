import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/lessons/domain/lesson.dart';
import 'package:tamkeen2/core/errors/failure_message.dart';

import 'package:tamkeen2/core/widgets/request_retry.dart';

class BackendVideoPlayer extends StatefulWidget {
  const BackendVideoPlayer({
    super.key,
    required this.lesson,
    required this.resolveSource,
    required this.onCompleted,
  });
  final RemoteLesson lesson;
  final Future<Uri> Function() resolveSource;
  final Future<void> Function() onCompleted;
  @override
  State<BackendVideoPlayer> createState() => _BackendVideoPlayerState();
}

class _BackendVideoPlayerState extends State<BackendVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  bool _loading = true, _completed = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    final old = _controller;
    _controller = null;
    await old?.dispose();
    if (!mounted) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    VideoPlayerController? player;
    try {
      final uri = await widget.resolveSource();
      player = VideoPlayerController.networkUrl(uri);
      await player.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) {
        await player.dispose();
        return;
      }
      _controller = player;
      player.addListener(_changed);
      setState(() => _loading = false);
    } catch (error) {
      await player?.dispose();
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = failureMessage(error);
        });
      }
    }
  }

  void _changed() {
    final value = _controller?.value;
    if (!mounted || value == null) return;
    if (value.hasError) {
      setState(() => _error = AppCopy.playbackFailed);
      return;
    }
    if (!_completed && value.isCompleted) {
      _completed = true;
      unawaited(widget.onCompleted());
    }
    setState(() {});
  }

  @override
  void dispose() {
    ++_generation;
    _controller?.removeListener(_changed);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _controller;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: player?.value.isInitialized == true
                ? player!.value.aspectRatio
                : 16 / 9,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : player != null && _error == null
                ? VideoPlayer(player)
                : Image.asset(
                    'assets/images/lesson_poster.png',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (_error != null) RemoteRetry(message: _error!, retry: _initialize),
        if (player != null && _error == null) ...[
          VideoProgressIndicator(
            player,
            allowScrubbing: true,
            colors: VideoProgressColors(playedColor: context.colors.primary),
          ),
          IconButton(
            tooltip: context.tr(
              player.value.isPlaying ? AppCopy.pauseAction : AppCopy.playAction,
            ),
            onPressed: () {
              player.value.isPlaying ? player.pause() : player.play();
            },
            icon: Icon(
              player.value.isPlaying
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              size: 48,
              color: context.colors.secondary,
            ),
          ),
        ],
      ],
    );
  }
}
