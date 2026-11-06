# Prototyp 0.2 — zakres, decyzje i postęp prac

Aktualna wersja aplikacji: **0.2.0+3** · zasady: `grading-rules/0.2`, `mastery-rules/0.2` · treści: `hira-prototype-2`.

## Zaimplementowane

Ilustrowany fragment wioski, jeden animowany mieszkaniec, wejście do szkoły, dwa bloki po pięć znaków, odczyt trzech słów zapisywanych kaną (いいえ, ここ, いい), ćwiczenia po błędach, lampion za ukończenie lekcji, notes postępu, opcjonalne pisanie oraz eksport lokalnego dziennika.

Wioska jest sceną z ilustracji i elementów Fluttera. Nie jest swobodnie eksplorowanym światem ani pełnym systemem budowania osady. Mieszkaniec wykorzystuje rzeczywisty runtime Rive 0.14.11. Systemowe ograniczenie animacji zatrzymuje mieszkańca i pokazuje pełne wzorce kresek.

## Oprawa Kigi i muzyka (0.2)

Polana ma nową ilustrację, błękitne niebo, leśną zieleń, jasne panele i brzoskwiniowe przyciski. Lekcja używa drewnianej tabliczki oraz listków jako wskaźnika postępu. Kana pozostaje prawdziwym tekstem Klee One lub ścieżkami KanjiVG; nie jest częścią bitmapy. Interfejs używa Nunito.

Yuu jest teraz własnym liściastym mieszkańcem: `assets/rive/yuu_kigi.riv`. Ma zapętlone kołysanie i mruganie, sterowane maszyną stanów Rive. Dotknięcie otwiera rozmowę o lekcji. Reakcje na odpowiedzi i osobne animacje powitania pozostają do dalszego rozwoju.

Muzyka `YuSoundtrack.mp4` została przekształcona do lokalnego `assets/audio/yuu-forest.m4a` (AAC, około 2:54). Oryginał został zachowany. Utwór zapętla się przy głośności 22%; startuje po wejściu do szkoły lub naciśnięciu nutki, nigdy sam przy otwarciu strony. Nutka na polanie i w lekcji przełącza muzykę. Wybór jest zapisywany lokalnie jako `preference_changed` i nie wpływa na FSRS. Wymowa pauzuje tło, po jej zakończeniu muzyka wraca. Przejście aplikacji w tło zatrzymuje oba kanały; powrót wznawia tylko wcześniej aktywną, niewyciszoną muzykę.

## Ocena i zapis

- FSRS: pakiet Dart `fsrs` **2.0.1**, algorytm FSRS-6, domyślne parametry i retencja 0,90. Losowy rozrzut terminów (`enableFuzzing`) jest wyłączony, aby ponowne odczytanie dziennika dawało identyczne terminy. Jest to jawne uściślenie konfiguracji, nie zmiana ocen.
- Każda karta to `(element, umiejętność)`. Czytanie i pisanie są rozdzielone; słowa nie tworzą kart znaków.
- Wsparcie przed odpowiedzią, błąd i „Nie wiem” dają Again. Samodzielna poprawna pierwsza próba daje Good. Najwyżej jedna aktualizacja na kartę i sesję. Korekty są oddzielnymi zdarzeniami.
- Odpowiedź po pokazaniu elementu w tej samej sesji (ponowna lekcja, podgląd w notesie) nie aktualizuje istniejącej karty (`recent_exposure`) i nie liczy się do utrwalenia. Wyjątek: pierwsza próba w lekcji tworzy kartę. Takie znaki nie pojawiają się w „Znakach na dzisiaj” do końca sesji.
- Przycisk wskazówki pojawia się tylko, gdy treść ma skojarzenie (`mnemonic`). Opis kształtu (`shape_note`) jest pokazywany przy poznawaniu znaku i nie jest wskazówką. Obecnie żaden znak nie ma przejrzanego skojarzenia, więc przycisku nie ma.
- Zdarzenia przechowują własną kopię danych. Wcześniej czyszczenie list w lekcji zmieniało wpisy w pamięci (eksport z bieżącego uruchomienia tracił wskazówki i kreski, a status mógł uznać odpowiedź ze wskazówką za samodzielną). Zapis w SQLite był poprawny.
- Odpowiedź i późniejsze odsłonięcie rozwiązania są zapisywane w jednej transakcji, przed pokazaniem informacji zwrotnej. Zdarzenie `solution_revealed` wiąże się z próbą przez `attempt_id`; przy odczycie czas ujawnienia znajduje się w tym osobnym zdarzeniu.
- Pisanie dodaje `response_committed` przed pokazaniem wzorca: zapisuje niezmieniony rysunek nawet wtedy, gdy użytkownik nie dokończy samooceny. Potem powstaje `attempt` z tym samym identyfikatorem. Czas odpowiedzi kończy się przy zatwierdzeniu, a nie po zastanawianiu się nad samooceną.
- Kreski mają kolejność i punkty `[x, y, t_ms]`, współrzędne 0–1. Odtwarzanie pokazuje kolejność ruchów w ujednoliconym tempie. Liczba kresek jest informacją, nie oceną. Warianty pochodzą z treści; drugi wariant き jest opisany, ale ma tylko jedną animację demonstracyjną.
- Sesja kończy się po 30 minutach bezczynności lub zamknięciu procesu. Niedomknięta sesja po wymuszonym wyjściu jest zamykana przy następnym starcie; zapisywany wtedy czas nie udaje dokładnego czasu zabicia aplikacji. `session_end` zawiera `last_activity_at` (dla zamknięcia przy starcie: czas ostatniego zdarzenia tej sesji), od którego liczymy długość sesji. Przejście na chwilę do innej aplikacji nie jest zamknięciem procesu.
- Status „utrwalony” ma próg trzech samodzielnych poprawnych prób w różnych sesjach i końcowej przerwy co najmniej siedmiu dni. Poprawne odpowiedzi po ekspozycji w tej samej sesji nie są liczone; błędy tak. Błąd oznacza „Do odświeżenia”; powrót wymaga poprawnej próby w innej sesji co najmniej dobę później. Status pisania jest opisany jako samoocena.
- Licznik „poznanych” oznacza znaki już wprowadzone, również w przerwanej lekcji. Lampion wymaga ukończenia całej lekcji. Powrót do przerwanej lekcji zaczyna ją od początku; wcześniejsze próby i rozpoznane statusy pozostają. Ponowne przejście lekcji nie wpływa na terminy ani na utrwalenie poznanych znaków.
- Pisanie ma własną kolejkę („Pisanie na dzisiaj”). Swobodne ćwiczenia czytania i pisania obejmują tylko znaki już wprowadzone w lekcji.
- Przygotowano zadania pomiarowe po 7 i 30 dniach od wprowadzenia. Przycisk pojawia się po upływie terminu, zatem pomiar może być spóźniony. Znak pokazany lub ćwiczony w bieżącej sesji czeka z pomiarem do następnej sesji; próba ma pole `measurement_clean`. Po osiągnięciu 30. dnia nie odrabiamy pomiaru z 7. dnia. Do analizy używaj rzeczywistych dat i odstępów z dziennika, nie traktuj etykiety terminu jako dowodu punktualności. To jeszcze nie gotowy system prowadzenia badania.
- Dziennik jest źródłem stanu FSRS i nagrody. Replay obecnej wersji jest deterministyczny. Surowe odpowiedzi pozwalają przygotować ponowną ocenę według nowych zasad; nie ma jeszcze narzędzia do importu, porównywania alternatywnych modeli ani panelu ocen niezależnego recenzenta.

## Dane i uruchomienie

Natywnie Drift używa pliku `kanayu.sqlite` w katalogu dokumentów aplikacji. W przeglądarce korzysta z obsługi SQLite/WASM i trwałego magazynu przeglądarki. Usunięcie danych witryny usuwa jej dziennik. Eksport jest ręczny. Nie ma kont, backendu, synchronizacji ani telemetrii.

Moduły SQLite i Rive do podglądu są dołączone w `web/`. Polecenie budowania w `scripts/preview.sh` używa też lokalnego CanvasKit. Podgląd nie jest skonfigurowany jako instalowalna aplikacja PWA offline; natywna aplikacja ma lokalne zasoby lekcji.

## Granice prototypu

Nie ma katakany, kanji, automatycznej oceny kształtu/kierunku pisma, rozpoznawania głosu, pełnej gry eksploracyjnej ani synchronizacji. Głos użytkownika nie jest nagrywany. Nie wdrożono jeszcze osobnych zadań rozpoznawania ze słuchu i dyktanda słów — specyfikacja określa ich przyszły format, ale pierwsza lekcja skupia się na czytaniu i opcjonalnym pisaniu.

Skojarzeń do odczytu (`mnemonic`) jeszcze nie ma; wymagają przygotowania i przeglądu. Nagrania Kyoko są roboczą syntezą systemową; nie zastępują kontroli wymowy przez osobę znającą japoński. Źródła kresek i dane treści wymagają przeglądu nauczyciela przed pilotażem.

## Weryfikacja

Wyniki weryfikacji kolejnych zmian znajdują się w [`weryfikacja.md`](weryfikacja.md). Build symulatora i testy widgetów nie potwierdzają wygody na fizycznym telefonie ani zachowania klawiatur iOS/Android firm trzecich.

## Postęp prac

### Zrobione

| Data | Wersja | Zmiana |
|---|---|---|
| 2026-10-28 | 0.1.0+1 | Pierwszy prototyp: wioska, lekcja 10 znaków, 3 słowa, pisanie z samooceną, dziennik SQLite, FSRS, eksport JSON. |
| 2026-10-28 | 0.1.1+2 | Poprawki po przeglądzie kodu: kopie danych w zdarzeniach (błąd eksportu i statusów), reguła `recent_exposure` w ocenianiu i utrwaleniu, czysty pomiar (`measurement_clean`), kolejka powtórek pisania, ćwiczenia tylko z poznanych znaków, wskazówka tylko ze skojarzenia, słowa zapisywane kaną (いいえ, ここ, いい; poprzednie słowa wycofane, ale czytelne w starym dzienniku), `last_activity_at` w `session_end`, indeksy zamiast przeszukiwania dziennika, odmiana liczebników, przypięcie `intl`. Testy: 16 → 23. |
| 2026-10-29 | 0.2.0+3 | Oprawa Kigi: nowa ilustracja polany, własny Yuu w Rive, tabliczka i listki w lekcji, Nunito i Klee One, muzyka z YuSoundtrack, zapamiętywane wyciszenie i priorytet wymowy. Zasady nauki z 0.1.1 zachowane. |

### Do zrobienia

Przed pilotażem pełnej hiragany:
- [ ] Lekcje jako dane w treściach (teraz skład lekcji jest w `LessonPage`). Warunek rozszerzenia do 46 znaków.
- [ ] Skojarzenia (`mnemonic`) do odczytu znaków, z przeglądem nauczyciela.
- [ ] Nagrania lektora zamiast syntezy Kyoko; ustalone prawa.
- [ ] Przegląd treści i kresek przez osobę znającą japoński.
- [ ] Test na fizycznych telefonach: klawiatury firm trzecich, zachowanie `TextInputType.visiblePassword` na iOS.
- [ ] Zasady zbierania danych w pilotażu (zakres, podstawa prawna, przechowywanie).

Technicznie:
- [ ] Typowane, niezmienne klasy zdarzeń zamiast `Map<String, dynamic>` i nazw w napisach.
- [ ] Wydzielenie kontrolera lekcji z `lib/ui/lesson.dart`.
- [ ] Teksty interfejsu w plikach ARB z regułami ICU.
- [ ] Narzędzie do przeliczania dziennika według innych reguł i porównań (np. powrót znaku po błędzie).
- [ ] Panel oceny niezależnej (`reviewer_grade`).

Projekt:
- [x] Osobne repozytorium Git dla KanaYu, z gałęzią `main` (2026-11-06).
- [x] Muzyka z `YuSoundtrack.mp4` podłączona jako tło, ze sterowaniem i pauzą podczas wymowy.
- [x] Własna postać i plik Rive: liściasty Yuu zamiast Little Machine.
- [x] Wdrożona pierwsza wersja Kigi na podstawie palety użytkownika; do jego oceny wizualnej.

Do decyzji:
- [ ] Czy ponowna lekcja ma pomijać ekspozycję poznanych znaków i działać jak powtórka.

