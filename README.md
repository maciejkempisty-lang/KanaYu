# KanaYu — prototyp Kigi

Flutter + Rive, lokalny dziennik SQLite/Drift i FSRS. Wioska prowadzi do lekcji **あいうえお・かきくけこ**. Całość działa bez konta i bez backendu.

## Uruchomienie

Na tym Macu otwórz **`Uruchom KanaYu.command`**. Skrypt otwiera zbudowaną aplikację macOS, a gdy jej brakuje — najpierw ją buduje. Aby przebudować po zmianach:

```sh
./scripts/flutter.sh run -d macos
```

Podgląd w przeglądarce:

```sh
./scripts/preview.sh
```

Następnie otwórz <http://127.0.0.1:4175>. Podgląd używa własnej bazy przeglądarkowej; nie współdzieli danych z aplikacją natywną. Jeśli port zajmuje działający podgląd, wystarczy go otworzyć. `Ctrl+C` kończy serwer.

Na tym komputerze SDK **Flutter 3.47.8 / Dart 3.13.7** jest w `.tooling/flutter`. Katalog nie należy do źródeł projektu. Po skopiowaniu projektu na inny komputer zainstaluj Flutter i wykonaj `./scripts/flutter.sh pub get`; skrypt korzysta również z Fluttera w `PATH`. Zachowuj `pubspec.lock`.

```sh
./scripts/flutter.sh devices
./scripts/flutter.sh run -d IDENTYFIKATOR_SYMULATORA
./scripts/flutter.sh analyze
./scripts/flutter.sh test
```

## Co można wypróbować

1. Dotknij szkoły, Yuu albo „Zacznij lekcję”. Mieszkaniec jest prawdziwą animacją Rive z aktywną maszyną stanów.
2. Poznaj pięć znaków: animację kresek, podpis i odtwarzany przyciskiem dźwięk. Następnie wpisz ich odczyt w zmienionej kolejności. Powtórz z drugą piątką.
3. Odczytaj trzy słowa zapisywane kaną: いいえ, ここ, いい. Ich wyniki są niezależne od kart znaków.
4. Po błędzie znak wraca kilka zadań później jako ćwiczenie korekcyjne. Wskazówka pojawi się dopiero przy znakach z przejrzanym skojarzeniem; nigdy nie udaje samodzielnego przypomnienia.
5. Ukończ lekcję, aby zapalić lampion przy szkole. Nagroda jest pamiątką ukończenia materiału; nie oznacza utrwalenia.
6. W „Moje znaki” uruchom powtórki czytania i pisania, dodatkowe czytanie lub opcjonalne pisanie z pamięci (tylko poznane znaki). Odpowiedź po podglądzie znaku w tej samej sesji nie zmienia terminu ani statusu. Rysunek zostaje zablokowany przed odsłonięciem wzorca. Ocena pisma jest własna.
7. Nutką na polanie lub w lekcji włącz lub wycisz muzykę. Tło milknie podczas wymowy; wybór zostaje zapisany na urządzeniu.
8. W „Dzienniku” zobacz ostatnie próby i wyeksportuj wszystkie zdarzenia do JSON.

## Struktura

- `lib/audio/` — muzyka, wymowa, obsługa przejścia w tło i wyciszenia.
- `lib/ui/` — wioska, mieszkaniec, lekcja, pisanie i dziennik.
- `lib/domain/learning_store.dart` — reguły ocen, sesje, stan FSRS i statusy wyliczane ze zdarzeń.
- `lib/data/` — wersjonowana treść i zapis SQLite przez Drift.
- `assets/content/hiragana.json` — odpowiedzi, wskazówki, ścieżki kresek i warianty.
- `docs/spec-v0.1.md` — specyfikacja nauki z historią zmian reguł.
- `docs/prototyp.md` — decyzje wdrożenia, ograniczenia oraz **postęp prac i lista zadań**.
- `docs/weryfikacja.md` — wyniki analizy i testów dla kolejnych wersji.
- `docs/assets.md` — pochodzenie, licencje i prompt ilustracji.
- [Fabuła Kigi: Ścieżka lampionów](docs/fabula-kigi.md) — pełna historia, dokładny pierwszy rozdział i kolejne etapy kampanii.
- [Grafiki do wdrożenia](docs/grafiki-kigi.md) — lista P0/P1/P2 i wymagania dla osoby tworzącej grafiki.
- [Pakiet scenariusza](docs/story/README.md) — JSON pierwszego rozdziału, manifest zasobów i kontrakt przyszłej integracji; jeszcze niepodłączone do aplikacji.
- [NPC-e i dialogi do mapy hiragany](docs/story/kigi-hiragana-v1/README.md) — sześć statycznych postaci, mapa odniesienia, podgląd rozmów i dziesięć wyzwań; propozycja do dalszego wdrożenia.

**Prototyp nie jest jeszcze wydaniem sklepowym.** Zawiera własnego liściastego mieszkańca Rive i syntetyczną wymowę. Fizyczne telefony, klawiatury zewnętrzne, ocena treści przez nauczyciela i badanie retencji pozostają osobnymi etapami.
