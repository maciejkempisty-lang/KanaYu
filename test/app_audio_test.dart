import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanayu/audio/app_audio.dart';

class FakeAudio implements AudioBackend {
  final completion = StreamController<void>.broadcast(sync: true);
  final calls = <String>[];
  bool musicPlaying = false, closed = false, failVoice = false;
  @override
  Stream<void> get voiceCompleted => completion.stream;
  @override
  Future<void> music(bool playing) async {
    musicPlaying = playing;
    calls.add('music:$playing');
  }

  @override
  Future<void> voice(String asset) async {
    expect(
      musicPlaying,
      false,
      reason: 'Pronunciation must have a quiet background',
    );
    calls.add('voice:$asset');
    if (failVoice) throw StateError('unavailable');
  }

  @override
  Future<void> stopVoice() async {
    calls.add('stop');
  }

  @override
  Future<void> close() async {
    closed = true;
    await completion.close();
  }
}

void main() {
  test(
    'no autoplay before interaction; voice pauses music and completion restores it',
    () async {
      final backend = FakeAudio();
      final audio = AppAudio(backend: () => backend);
      expect(backend.calls, isEmpty);
      await audio.activate();
      expect(backend.musicPlaying, true);
      await audio.playVoice('audio/a.wav');
      expect(backend.musicPlaying, false);
      backend.completion.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(backend.musicPlaying, true);
      audio.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(backend.closed, true);
    },
  );

  test(
    'muting during pronunciation remains muted after completion and resume',
    () async {
      final backend = FakeAudio();
      final saved = <bool>[];
      final audio = AppAudio(
        backend: () => backend,
        saveEnabled: (value) async {
          saved.add(value);
        },
      );
      await audio.activate();
      await audio.playVoice('audio/ka.wav');
      await audio.toggle();
      backend.completion.add(null);
      await audio.setForeground(false);
      await audio.setForeground(true);
      expect(backend.musicPlaying, false);
      expect(saved, [false]);
      expect(audio.enabled, false);
      audio.dispose();
    },
  );

  test(
    'background pauses both channels; resume only restores permitted music',
    () async {
      final backend = FakeAudio();
      final audio = AppAudio(backend: () => backend);
      await audio.activate();
      await audio.playVoice('audio/i.wav');
      await audio.setForeground(false);
      expect(backend.musicPlaying, false);
      expect(backend.calls, contains('stop'));
      expect(audio.speaking, false);
      await audio.setForeground(true);
      expect(backend.musicPlaying, true);
      audio.dispose();
    },
  );

  test(
    'failed pronunciation restores music and reports an error; retry succeeds',
    () async {
      final backend = FakeAudio()..failVoice = true;
      final audio = AppAudio(backend: () => backend);
      await audio.activate();
      await audio.playVoice('missing.wav');
      expect(backend.musicPlaying, true);
      expect(audio.error, isNotNull);
      expect(audio.speaking, false);
      backend.failVoice = false;
      await audio.playVoice('audio/a.wav');
      expect(audio.error, isNull);
      expect(backend.musicPlaying, false);
      audio.dispose();
    },
  );
}
