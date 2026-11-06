import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Two independent players: pronunciation always has priority over ambience.
abstract class AudioBackend {
  Stream<void> get voiceCompleted;
  Future<void> music(bool playing);
  Future<void> voice(String asset);
  Future<void> stopVoice();
  Future<void> close();
}

class PlayerBackend implements AudioBackend {
  final _music = AudioPlayer();
  final _voice = AudioPlayer();
  bool _loaded = false;
  @override
  Stream<void> get voiceCompleted => _voice.onPlayerComplete;
  @override
  Future<void> music(bool playing) async {
    if (!playing) {
      if (_loaded) await _music.pause();
      return;
    }
    if (!_loaded) {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('audio/yuu-forest.m4a'), volume: .22);
      _loaded = true;
    } else {
      await _music.resume();
    }
  }

  @override
  Future<void> voice(String asset) async {
    await _voice.stop();
    await _voice.play(AssetSource(asset));
  }

  @override
  Future<void> stopVoice() => _voice.stop();
  @override
  Future<void> close() async {
    await _music.dispose();
    await _voice.dispose();
  }
}

class AppAudio extends ChangeNotifier {
  final AudioBackend Function() createBackend;
  final Future<void> Function(bool)? saveEnabled;
  AppAudio({
    this.enabled = true,
    this.saveEnabled,
    AudioBackend Function()? backend,
  }) : createBackend = backend ?? PlayerBackend.new;
  AudioBackend? _backend;
  StreamSubscription<void>? _completion;
  Future<void> _queue = Future.value();
  bool enabled, activated = false, foreground = true, speaking = false;
  bool _closed = false, _playing = false;
  String? error;
  bool get playing => _playing;
  AudioBackend get backend {
    if (_backend == null) {
      _backend = createBackend();
      _completion = _backend!.voiceCompleted.listen((_) {
        speaking = false;
        unawaited(_run(_sync));
      });
    }
    return _backend!;
  }

  Future<void> _run(Future<void> Function() operation) {
    final next = _queue.then((_) async {
      if (_closed) return;
      error = null;
      try {
        await operation();
      } catch (_) {
        error ??=
            'Nie udało się odtworzyć dźwięku. Dotknij, aby spróbować ponownie.';
      }
      if (!_closed) notifyListeners();
    });
    _queue = next;
    return next;
  }

  Future<void> _sync() async {
    final shouldPlay = enabled && activated && foreground && !speaking;
    if (!shouldPlay && _backend == null) return;
    try {
      await backend.music(shouldPlay);
    } catch (_) {
      _playing = false;
      rethrow;
    }
    _playing = shouldPlay;
  }

  /// Called by an explicit interaction, so web autoplay restrictions are respected.
  Future<void> activate() {
    activated = true;
    return _run(_sync);
  }

  Future<void> toggle() {
    if (!activated || error != null) {
      activated = true;
      enabled = true;
    } else {
      enabled = !enabled;
    }
    return _run(() async {
      await _sync();
      try {
        await saveEnabled?.call(enabled);
      } catch (_) {
        // Playback still works, but don't pretend the setting was persisted.
        if (!_closed) {
          error = 'Muzyka działa, ale nie udało się zapisać ustawienia.';
          notifyListeners();
        }
        rethrow;
      }
    });
  }

  Future<void> playVoice(String asset) {
    return _run(() async {
      if (!foreground) return;
      speaking = true;
      try {
        await _sync();
        await backend.voice(asset);
      } catch (_) {
        speaking = false;
        await _sync();
        rethrow;
      }
    });
  }

  Future<void> stopVoice() => _run(() async {
    await _backend?.stopVoice();
    speaking = false;
    await _sync();
  });

  Future<void> setForeground(bool value) {
    foreground = value;
    return _run(() async {
      if (!foreground) {
        await _backend?.stopVoice();
        speaking = false;
      }
      await _sync();
    });
  }

  @override
  void dispose() {
    _closed = true;
    unawaited(_completion?.cancel());
    unawaited(_queue.then((_) => _backend?.close()));
    super.dispose();
  }
}

class AudioScope extends InheritedNotifier<AppAudio> {
  const AudioScope({super.key, required AppAudio audio, required super.child})
    : super(notifier: audio);
  static AppAudio? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AudioScope>()?.notifier;
}

class MusicButton extends StatelessWidget {
  const MusicButton({super.key});
  @override
  Widget build(BuildContext context) {
    final audio = AudioScope.of(context);
    if (audio == null) return const SizedBox.shrink();
    final active = audio.enabled && audio.activated;
    return IconButton.filledTonal(
      tooltip: audio.error ?? (active ? 'Wycisz muzykę' : 'Odtwórz muzykę'),
      onPressed: audio.toggle,
      icon: Icon(
        audio.error != null
            ? Icons.error_outline
            : active
            ? Icons.music_note_rounded
            : Icons.music_off_rounded,
      ),
    );
  }
}
