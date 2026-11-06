import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rive/rive.dart' as rive;
import 'data/catalog.dart';
import 'data/journal.dart';
import 'domain/learning_store.dart';
import 'ui/design.dart';
import 'ui/village.dart';
import 'audio/app_audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await rive.RiveNative.init();
    final store = LearningStore(await Catalog.load(), Journal());
    await store.initialize();
    runApp(KanaYu(store: store));
  } catch (error) {
    runApp(
      MaterialApp(
        theme: appTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: SelectableText(
                'Nie udało się otworzyć KanaYu. Twoje dane nie zostały usunięte.\n\n$error',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KanaYu extends StatefulWidget {
  final LearningStore store;
  const KanaYu({super.key, required this.store});
  @override
  State<KanaYu> createState() => _KanaYuState();
}

class _KanaYuState extends State<KanaYu> with WidgetsBindingObserver {
  late final audio = AppAudio(
    enabled: widget.store.musicEnabled,
    saveEnabled: widget.store.setMusicEnabled,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(audio.setForeground(state == AppLifecycleState.resumed));
    if (state == AppLifecycleState.detached) {
      unawaited(widget.store.endSession('app_closed'));
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KanaYu · Twoja wioska',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: Locale('pl'),
    supportedLocales: const [Locale('pl')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => AudioScope(
      audio: audio,
      child: Listener(
        onPointerDown: (_) => widget.store.touch(),
        child: child!,
      ),
    ),
    home: VillagePage(store: widget.store),
  );
}
