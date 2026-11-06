# Weryfikacja

Wyniki sprawdzeń dla kolejnych wersji prototypu. Najnowsze na górze.

## 0.2.0+3 — 2026-10-29

- Analiza statyczna bez uwag.
- 28 testów zaliczonych: zachowane 23 testy z 0.1.1, cztery testy koordynacji muzyki/wymowy i jeden test odczytu na ekranie 320 × 568 przy tekście powiększonym do 150%. Po dopracowaniu przewijania ponownie zaliczono pięć testów widgetów lekcji.
- Zbudowano web release (JavaScript), macOS debug i iOS simulator debug.
- Sprawdzono w przeglądarce: polanę, załadowanie nowego Yuu w Rive, wejście do szkoły, animację kresek, przejście do odczytu, poprawną odpowiedź, przyciski muzyki i wymowy oraz zachowanie wyciszenia po odświeżeniu i ponownym wejściu do lekcji. Konsola nie zgłaszała błędów odtwarzaczy.
- Sprawdzono renderowanie polany i własnego mieszkańca Rive w dedykowanym symulatorze iPhone 17 Pro. Końcowy zrzut przedstawia także wejście do szkoły: `screenshots/kigi-ios-welcome.png`. Podgląd web: `screenshots/kigi-web-village.png`, `screenshots/kigi-web-reading.png`.
- Sprawdzono plik audio: jedna ścieżka AAC stereo, 44,1 kHz, 173,923 s; oryginalny MP4 zachowany.

Testy dźwięku używają kontrolowanego backendu i sprawdzają: brak odtwarzania przed interakcją, pauzę tła podczas wymowy, przywrócenie po zakończeniu, wyciszenie w trakcie wymowy, przejście aplikacji w tło i powrót, obsługę nieudanego odczytu oraz zwolnienie odtwarzaczy. Nie są oceną brzmienia, głośności na prawdziwym telefonie ani płynności połączenia końca i początku utworu.

Przy testowaniu układu znaleziono i poprawiono przepełnienie podpisów porównania pisma na wąskim ekranie. Każde nowe zadanie przewija lekcję do początku. Przycisk główny na wysokim ekranie jest przy dole panelu; na małym ekranie i z klawiaturą treść można przewinąć.

Build web zgłasza ostrzeżenia opcjonalnego sprawdzenia zgodności Dart/Wasm w `share_plus` i `sqlite3` oraz o nieużywanej rodzinie CupertinoIcons. Dostarczony build korzysta z JavaScript, lokalnego CanvasKit i modułów WASM Rive/SQLite; kompilacja zakończyła się powodzeniem. Ostrzeżenia nie są dowodem obsługi docelowego trybu `--wasm`.

Nadal do sprawdzenia: fizyczne telefony iOS/Android, klawiatury firm trzecich, subiektywne brzmienie i zapętlenie dostarczonej muzyki. Nie wykonano nowego builda Androida.

## 0.1.1+2 — 2026-10-28

Środowisko: macOS, Flutter 3.47.8 / Dart 3.13.7 z `.tooling/flutter`.

| Sprawdzenie | Polecenie | Wynik |
|---|---|---|
| Analiza statyczna | `./scripts/flutter.sh analyze` | Brak uwag |
| Testy | `./scripts/flutter.sh test` | 23 / 23 zaliczone |
| Formatowanie | `dart format lib test` | Zastosowane |

Nowe testy regresji:
- zdarzenia zachowują wskazówki i kreski po wyczyszczeniu list w lekcji; odpowiedź ze wskazówką nie liczy się później jako samodzielna;
- odpowiedź po ekspozycji w tej samej sesji nie aktualizuje istniejącej karty ani utrwalenia (3 sesje z podglądem nie dają statusu „utrwalony”), a znak znika z „Znaków na dzisiaj”;
- pierwsza próba w lekcji po poznaniu znaku nadal tworzy kartę;
- błąd po podglądzie nadal oznacza „Do odświeżenia”;
- karty pisania mają własną kolejkę powtórek;
- pomiar czeka na sesję bez wcześniejszego kontaktu, a spóźniony pomiar po kontakcie ma `measurement_clean = false`;
- `session_end` zawiera `last_activity_at`; wycofane słowa pozostają czytelne w katalogu;
- przycisk wskazówki nie pojawia się bez skojarzenia w treści.

Błąd z kopiowaniem danych zdarzeń potwierdzono przed poprawką tymczasowym testem: po `support.clear()` i `drawing.clear()` wpisy w pamięci miały puste `support_used` i kreski, a eksport nie zawierał kresek. Zapis w SQLite był poprawny.

Nie sprawdzono:
- działania na fizycznym iPhonie i telefonie z Androidem (klawiatury, dźwięk, Rive);
- wyglądu nowych przycisków w notesie poza testami widgetów (brak zrzutów ekranu dla tej wersji);
- brzmienia nowych nagrań syntezy (いいえ, ここ, いい).

## 0.1.0+1 — 2026-10-28

Analiza statyczna bez uwag, 16 / 16 testów zaliczonych (stan z przeglądu kodu). Wcześniejszy plik z wynikami tej wersji nie istniał, mimo odwołania w `prototyp.md`.
