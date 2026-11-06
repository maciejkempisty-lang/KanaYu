# Grafika, dźwięk i źródła

## Kigi — aktualne zasoby (2026-10-29)

- `assets/art/kigi-village.png`: 1086 × 1448, nowa ilustracja polany i japońskiej szkoły. Wygenerowana wbudowanym imagegen, bez klucza API; obraz został obejrzany i skopiowany do projektu. Pełny prompt: [`concepts/kigi-assets-prompts.txt`](concepts/kigi-assets-prompts.txt). Oryginał wygenerowanego pliku jest zachowany poza projektem.
- `assets/rive/yuu_kigi.riv`: własny rysunek wektorowy liściastego Yuu (około 3,8 KB), przezroczyste tło, animacja `Breeze`, domyślna maszyna stanów `Yuu`. Kołysanie i mruganie; bez użycia geometrii Little Machine. Odtwarzanie: `python3 scripts/make_kigi_resident.py` po pobraniu przypiętych zależności. Skrypt używa schematu lokalnego runtime Rive 0.1.11, więc przy aktualizacji runtime wymaga ponownej walidacji.
- Tabliczka, lampion i listki: wektorowe dekoracje w `lib/ui/kigi_art.dart`; znaki i tekst interfejsu nie są wypalone w ilustracji.
- `assets/audio/yuu-forest.m4a`: utwór użytkownika z `YuSoundtrack.mp4`, AAC stereo 44,1 kHz, około 158 kb/s, 173,923 s, około 3,4 MB. Przygotowany przez `afconvert ... -f m4af -d aac -b 160000`; oryginał niezmieniony. Informacja o pochodzeniu: dostarczony przez autora projektu, bez niezależnej weryfikacji licencji.
- [Nunito](https://github.com/google/fonts/tree/main/ofl/nunito) i [Klee One](https://github.com/google/fonts/tree/main/ofl/kleeone): oficjalne pliki z Google Fonts, SIL OFL; fonty i kopie licencji w `assets/fonts/`. Nunito służy do interfejsu, Klee One do znaków. Zen Maru pozostaje fontem zapasowym.

## Poprzednia wioska (zasób zachowany)

Plik: `assets/art/village.png` (1086 × 1448). Wygenerowany narzędziem imagegen dostępnym w Codex, 2026-10-28. Nie wymaga API ani generowania obrazów podczas działania aplikacji.

Prompt:

> Use case: illustration-story. Asset type: production background illustration for a mobile Japanese kana learning app named KanaYu. Create a richly art-directed cozy Japanese village courtyard illustration, no UI, no text, no characters. Portrait composition 3:4, high-quality hand-painted 2D game environment, slight overhead view, soft clean stylized shapes and subtle paper texture, sophisticated warm cream, sage green, terracotta, amber palette. Main small wooden Japanese tea school in center upper half with broad terracotta tiled roof and warmly lit doorway; smaller workshop upper left, small hut upper right. A gently curved sandy path from foreground to school, small stream crossing bottom third with wooden bridge, mossy stones, grass and rounded trees, lanterns hanging near door. Leave an open sandy clearing in lower middle for an animated friendly animal character to be overlaid by code. Warm late afternoon light, inviting, calm, polished premium illustrated game aesthetic. Buildings must be clearly separated and tappable. Entire view fills canvas edge to edge. No writing of any kind, no glyphs, no people, no animals, no UI panels, no watermarks. Save asset for app background.

## Poprzedni mieszkaniec Rive (nieużywany w interfejsie)

Plik: `assets/rive/yuu_machine.riv`. Źródło: `little_machine.riv` z przykładu do przypiętego pakietu `rive` **0.14.11**, [repozytorium Rive Flutter](https://github.com/rive-app/rive-flutter/tree/master/example/assets), licencja repozytorium MIT, © 2020 Rive. Kopia licencji: `assets/rive/LICENSE`.

Zmiana: ustawienie przezroczystości dwóch przystanków gradientu tła artboardu. Geometria postaci, klatki i maszyna stanów są zachowane. Skrypt `scripts/prepare_resident.py` odtwarza zmianę po sprawdzeniu SHA-256 oryginału. Mieszkaniec jest zasobem demonstracyjnym; nie jest autorską maskotką KanaYu. Wcześniejszy test z Coyote nie należy do dostarczonych zasobów aplikacji.

## Kreski

Źródło: [KanjiVG](https://kanjivg.tagaini.net/), © 2009–2011 Ulrich Apel i współtwórcy, [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/). Oryginalne pliki SVG wraz z nagłówkami licencyjnymi pozostają w `assets/strokes/`. Ścieżki przeniesione do `assets/content/hiragana.json`, ich kolejność i informacje o wariantach są udostępniane na tej samej licencji. Zmiana formatu: SVG → ciągi ścieżek w JSON; współrzędne wzorców pozostają w układzie 109 × 109. Własne polskie opisy są dodane w osobnych polach.

## Typografia i ikona

[Zen Maru Gothic](https://github.com/google/fonts/tree/main/ofl/zenmarugothic), SIL Open Font License 1.1. Font i licencja w `assets/fonts/`. Ikona jest prostym typograficznym znakiem ゆ na zielonym tle, renderowanym przez `scripts/make_icons.py`.

## Dźwięk

16 plików WAV w `assets/audio/`: 10 odczytów znaków, 3 słowa używane w lekcji (いいえ, ここ, いい; dodane 2026-10-28) i 3 słowa wycofane z lekcji (いえ, かお, あき), zachowane dla starych wpisów dziennika. Wytworzone lokalnie przez macOS `say -v Kyoko -r 110`, następnie `afconvert` do PCM WAV. To robocza synteza japońska, nie nagrania lektora. Przed publikacją zastąpić zweryfikowanymi nagraniami, z ustalonymi prawami dystrybucji.

## Runtime podglądu

`web/sqlite3.wasm` pochodzi z [wydania sqlite3.dart 2.9.4](https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-2.9.4). Worker jest kompilowany z `web/drift_worker.dart` przy użyciu Drift 2.31.0. Pliki `web/rive/` pochodzą z oficjalnego pakietu `@rive-app/flutter-native-wasm@44.0.0`; wersja odpowiada `rive_native 0.1.11`. Biblioteki Flutter pozostają objęte swoimi licencjami; nie stosujemy licencji grafiki do kodu bibliotek.
