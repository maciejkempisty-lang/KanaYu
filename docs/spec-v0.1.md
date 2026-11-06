# KanaYu — specyfikacja oceny odpowiedzi v0.1

| | |
|---|---|
| Status | Robocza. Dotyczy prototypu (10 znaków) i pilotażu pełnej hiragany. |
| Data | 2026-10-28, ostatnia zmiana 2026-10-28 |
| Wersja zasad oceniania | `grading-rules/0.2` |
| Wersja kryteriów postępu | `mastery-rules/0.2` |

Historia zmian jest na końcu dokumentu.

Ten dokument ustala, skąd aplikacja wie, że użytkownik coś pamięta. Minigry, miasteczko i nagrody korzystają z tych zasad, ale nie są tu opisane.

**Poza zakresem v0.1:** automatyczne rozpoznawanie pisma, zdalna telemetria, synchronizacja między urządzeniami, katakana, połączenia typu きゃ.

Wszystkie progi i reguły w tym dokumencie są **decyzjami produktowymi do sprawdzenia w pilotażu**, a nie ustalonymi naukowo granicami.

---

## 1. Pojęcia

| Pojęcie | Znaczenie |
|---|---|
| Element treści | Konkretny znak lub słowo z wersjonowanej bazy treści, np. `kana.hira.ka`, `word.kao`. |
| Umiejętność | Co dokładnie sprawdzamy dla elementu (sekcja 2). |
| Karta | Para *(element treści, umiejętność)* mająca własny stan FSRS. |
| Zadanie | Jedno polecenie pokazane użytkownikowi. |
| Próba | Odpowiedź użytkownika na zadanie. Zadanie ma jedną **pierwszą próbę**; wszystko po pokazaniu rozwiązania to ćwiczenie korekcyjne. |
| Wsparcie | Wszystko, co ułatwia odpowiedź: podpis rōmaji, obrazek-skojarzenie, animacja kresek, pierwsza kreska, odsłonięcie rozwiązania. Wskazówką do odczytu jest tylko skojarzenie (`mnemonic`) z treści; opis kształtu znaku nie jest wskazówką. |
| Ekspozycja | Pokazanie elementu bez wymagania odpowiedzi (np. poznawanie znaku). |
| Sesja | Ciągły okres korzystania z aplikacji. Nowa sesja zaczyna się po zamknięciu aplikacji lub po 30 min bezczynności. |

---

## 2. Umiejętności

| ID | Bodziec → odpowiedź | Karta FSRS w v0.1 | Uwagi |
|---|---|---|---|
| `kana_reading` | znak → odczyt | **tak** | Główna umiejętność kursu. |
| `kana_listening` | dźwięk → znak | nie | W v0.1 odpowiedź tylko przez wybór lub siatkę, czyli rozpoznawanie. Wyniki trafiają do dziennika. |
| `kana_writing` | dźwięk lub odczyt → znak napisany z pamięci | **tak**, jeśli użytkownik włączył pisanie | Ocena własna; status opisany jako samoocena (sekcja 7). |
| `word_reading` | słowo → odczyt | nie | Zastosowanie znaków. Nie zalicza kart znaków, z których słowo się składa. |
| `word_spelling` | nagranie słowa → zapis | nie | Sprawdza pisownię konkretnego słowa, nie znajomość kany. Błąd nie obniża oceny znaku. |

Rozpoznawanie (wybór, siatka) i samodzielne przypominanie to różne dowody. Wynik rozpoznawania nigdy nie zalicza karty przypominania.

---

## 3. Wymiary próby

Próbę opisują **niezależne pola**. Jedna próba może być jednocześnie rysowaniem, samooceną i powtórką po 7 dniach.

| Pole | Wartości |
|---|---|
| `response_mode` | `choice` (2–6 opcji), `grid` (cała znana tabela), `text`, `drawing`, `spoken` |
| `grading_mode` | `automatic`, `self`, `reviewer` |
| `task_source` | `lesson`, `scheduled_review`, `minigame`, `measurement`, `corrective` |
| `support_used` | lista wsparć z czasem użycia: `romaji_label`, `mnemonic`, `stroke_animation`, `first_stroke`, `audio_replay`, `reveal` |
| `first_attempt_result` | `correct`, `incorrect`, `dont_know` |

Pochodne:
- **rozpoznawanie:** `response_mode ∈ {choice, grid}`;
- **przypominanie:** `response_mode ∈ {text, drawing, spoken}`.

`audio_replay` w zadaniach słuchowych jest częścią bodźca, nie wsparciem.

---

## 4. Przebieg zadania

### Odczyt znaku (`text`)
1. Pokaż znak. Podpis rōmaji tylko w fazie poznawania; jego wycofanie nie usuwa możliwości wpisania rōmaji jako odpowiedzi.
2. Użytkownik wpisuje odczyt albo wybiera „Nie wiem”.
3. Ocena pierwszej próby (automatyczna, sekcja 6).
4. Przy błędzie: pokaż poprawną odpowiedź i istotną różnicę (np. mylony znak obok).
5. Opcjonalne przepisanie odpowiedzi jako ćwiczenie korekcyjne.

Pole tekstowe: wyłączona autokorekta i podpowiedzi. Działanie tych ustawień trzeba sprawdzić na urządzeniach z iOS i z Androidem, również z klawiaturami firm trzecich.

### Pisanie z pamięci (`drawing`, `self`)
1. Pokaż bodziec (dźwięk lub odczyt).
2. Użytkownik pisze znak i **zatwierdza próbę**. Po zatwierdzeniu nie można jej zmienić.
3. Pokaż wzorzec: nałożony na próbę, obok niej oraz animację kolejności kresek obok odtworzenia kresek użytkownika.
4. Pokaż informacyjnie liczbę kresek i ich kolejność w porównaniu z dopuszczalnymi wariantami. **W v0.1 to nie zmienia oceny.**
5. Użytkownik ocenia: „Poprawnie” / „Błąd lub nie pamiętam”.

Oryginalna próba (ścieżki kresek) zostaje zapisana.

### Odczyt na głos (`spoken`, `self`)
1. Pokaż znak lub słowo; użytkownik czyta na głos.
2. Odtwórz nagranie wzorcowe.
3. Użytkownik ocenia: „Poprawnie” / „Błąd”.

W v0.1 głos użytkownika nie jest nagrywany ani zapisywany.

---

## 5. Mapowanie na FSRS

Dotyczy kart przypominania (`kana_reading`, `kana_writing`).

| Zdarzenie | Wpływ na FSRS |
|---|---|
| Ekspozycja, demonstracja, animacja | Brak. Zapis ekspozycji. |
| Wybór z listy lub siatki | Brak. Zapis wyniku rozpoznawania. |
| Jakiekolwiek wsparcie przed pierwszą odpowiedzią | `Again` |
| Poprawna pierwsza odpowiedź bez wsparcia | `Good` |
| Błędna odpowiedź albo „Nie wiem” | `Again`, zapisane przed pokazaniem rozwiązania |
| Przepisanie odsłoniętej odpowiedzi | Brak. Ćwiczenie korekcyjne. |
| Powrót znaku w tej samej sesji po błędzie | Brak w v0.1. Zapis w dzienniku; w pilotażu porównujemy przeliczenie z i bez tych prób. |
| Samoocena „Poprawnie” | `Good`, z oznaczeniem `grading_mode = self` |
| Samoocena „Błąd lub nie pamiętam” | `Again`, z oznaczeniem `grading_mode = self` |
| Odpowiedź po ekspozycji tego elementu w tej samej sesji, gdy karta już istnieje | Brak (`reason = recent_exposure`). Zapis w dzienniku z `exposed_in_session = true`. |
| Próba pomiarowa (`measurement`) | Aktualizuje, bo też jest ćwiczeniem. Protokół jest jednakowy dla wszystkich (sekcja 9). |

Zasady ogólne:
- **Najwyżej jedna aktualizacja FSRS na kartę na sesję**: pierwsza oceniana próba przypominania w danej sesji, niezależnie od tego, czy pochodzi z powtórki, czy z minigry. Kolejne próby trafiają tylko do dziennika.
- Próby w różnych sesjach tego samego dnia mogą aktualizować FSRS. Pakiet FSRS dla Darta ma osobną aktualizację dla odstępu krótszego niż doba; trzeba to potwierdzić testem integracyjnym.
- Karta powstaje przy pierwszej ocenianej próbie przypominania, nie przy ekspozycji. Pierwsza próba w lekcji, tuż po poznaniu znaku, tworzy kartę (krok nauki FSRS). Każda późniejsza odpowiedź po pokazaniu elementu w tej samej sesji (ponowna lekcja, podgląd w notesie) nie aktualizuje FSRS.
- W v0.1 nie używamy ocen `Hard` ani `Easy`. Czas odpowiedzi jest tylko zapisywany.
- Konfiguracja: domyślne parametry biblioteki, docelowa retencja 0,90, bez optymalizacji parametrów w pilotażu. Dopiero po pilotażu sprawdzamy kalibrację: czy przewidywana retencja zgadza się z rzeczywistą.
- **Stan FSRS jest wyliczany z dziennika.** Zmiana zasad lub algorytmu oznacza przeliczenie, a nie migrację stanu.

---

## 6. Dopuszczalne odpowiedzi

### Zasada
Zbiór dopuszczalnych odpowiedzi należy do **konkretnego zadania i elementu treści** i jest przechowywany w wersjonowanych treściach. Kod nie zawiera globalnych zamian typu は→わ czy おう→おお.

### Normalizacja wpisanego tekstu
Usuwa tylko różnice techniczne:
- wielkość liter;
- spacje na początku, na końcu i wewnątrz odpowiedzi;
- znaki łacińskie pełnej szerokości → ASCII;
- normalizacja Unicode NFC.

Zachowuje różnice istotne dla zadania, w szczególności długość samogłoski.

### Warianty rōmaji dla odczytu znaku

| Znak | Akceptowane |
|---|---|
| し | `shi`, `si` |
| ち | `chi`, `ti` |
| つ | `tsu`, `tu` |
| ふ | `fu`, `hu` |
| じ | `ji`, `zi` |
| ぢ | `ji`, `di` |
| づ | `zu`, `du` |
| を | `o`, `wo` |
| ん | `n`, `nn` |

Pozostałe znaki: jedna forma Hepburna, zgodna z odczytem Kunrei.

### Homofony w zadaniach słuchowych
- じ/ぢ, ず/づ, お/を mają tę samą wymowę standardową. **W v0.1 ぢ, づ i を nie są bodźcami izolowanych zadań słuchowych.** Uczymy ich w kontekście słów.
- Partykuły は (wa), へ (e), を (o) występują tylko w zadaniach ze słowami lub frazami; ich odczyt i pisownia zależą od kontekstu.
- W dyktandzie słów (`word_spelling`) obowiązuje pisownia danego słowa, np. とおい, こうこう, せんせい. Odczyt na głos tego samego słowa akceptuje standardową wymowę, np. „sensē”.

### Pisanie
Każdy znak ma w treściach listę dopuszczalnych wariantów (np. き, さ, そ, り, ふ w wariantach drukowanych i ręcznych), każdy z liczbą i kolejnością kresek. Źródło ścieżek: KanjiVG (CC BY-SA 3.0, wymaga atrybucji, a zmodyfikowane dane podlegają tej samej licencji).

### Przykład wpisu w treściach

```yaml
id: kana.hira.shi
version: 3
char: し
tasks:
  kana_reading:
    accepted: [shi, si]
  kana_listening:
    audio: audio/shi.m4a
    accepted: [し]
  kana_writing:
    variants:
      - id: standard
        strokes: 1
        source: kanjivg:03057
```

---

## 7. Statusy postępu

Trzy osobne informacje, których nie łączymy w jeden wskaźnik:
1. **Ukończenie materiału**: znak został wprowadzony w lekcji.
2. **Potwierdzony wynik**: statusy poniżej.
3. **Bieżąca potrzeba powtórki**: termin z FSRS.

| Status | Kryterium (`mastery-rules/0.1`) |
|---|---|
| Poznany | Ukończona lekcja z tym znakiem. |
| Ćwiczony | Co najmniej jedna oceniana próba przypominania. |
| **Utrwalony w czytaniu** | `kana_reading`: co najmniej 3 poprawne pierwsze próby bez wsparcia, z oceną automatyczną, w oddzielnych sesjach; ostatnia co najmniej 7 dni po poprzedniej ocenianej próbie tej karty. |
| Do odświeżenia | Błąd po uzyskaniu statusu „utrwalony”. Wraca do „utrwalony” po poprawnej samodzielnej próbie w innej sesji, co najmniej dzień później. |
| Utrwalony w pisaniu (samoocena) | `kana_writing`, to samo kryterium co dla czytania, ale z oceną własną. Interfejs pokazuje, że to samoocena. |

Poprawna odpowiedź udzielona po ekspozycji tego elementu w tej samej sesji nie jest dowodem przypomnienia: nie liczy się do „utrwalony” i nie przesuwa punktu odniesienia dla 7 dni. Błąd w takiej sytuacji nadal oznacza „Do odświeżenia”.

Siedem dni liczymy od poprzedniej ocenianej próby, nie od ostatniego kontaktu. Interfejs nie twierdzi, że użytkownik przez tydzień nie widział znaku.

Komunikaty są neutralne płciowo i używają form liczby mnogiej zgodnych z ICU (1 znak, 2 znaki, 5 znaków), np. „Udało się samodzielnie odczytać 8 znaków”.

---

## 8. Dziennik zdarzeń

Dziennik tylko przyrasta i jest źródłem prawdy. Stan FSRS i statusy postępu są z niego wyliczane. Ocena osoby sprawdzającej to **nowe zdarzenie** odwołujące się do próby; nie nadpisuje wpisu.

### Typy zdarzeń
`session_start`, `session_end`, `exposure`, `attempt`, `solution_revealed`, `corrective`, `reviewer_grade`.

### Pola zdarzenia `attempt`

| Pole | Opis |
|---|---|
| `event_id` | UUID zdarzenia |
| `attempt_id` | UUID próby (wspólny z `solution_revealed`, `corrective`, `reviewer_grade`) |
| `session_id` | UUID sesji |
| `timestamp` | czas UTC + przesunięcie strefy czasowej |
| `app_version` | wersja aplikacji |
| `content_version` | wersja pakietu treści |
| `content_item_id`, `content_item_version` | element i jego wersja |
| `skill` | umiejętność (sekcja 2) |
| `task_source`, `response_mode`, `grading_mode` | sekcja 3 |
| `prompt_shown` | co było widoczne przy bodźcu (znak, podpis rōmaji, obrazek, audio) |
| `support_used` | lista wsparć z czasem użycia |
| `raw_response` | surowa odpowiedź: tekst, ID wybranej opcji, `dont_know` albo ścieżki kresek `[[x, y, t_ms], …]` w kolejności |
| `normalized_response` | po normalizacji |
| `matched_answer` | która dopuszczalna odpowiedź pasowała, jeśli któraś |
| `first_attempt_result` | `correct` / `incorrect` / `dont_know` |
| `latency_ms` | czas od pokazania bodźca do odpowiedzi; tylko informacyjnie |
| `solution_revealed_at` | czas odsłonięcia rozwiązania |
| `fsrs_decision` | `{applied, rating, reason}`, np. `{false, null, "second_attempt_in_session"}`; `reason` ∈ `first_recall_in_session`, `assisted_recall`, `second_attempt_in_session`, `recent_exposure`, `not_scheduled_recall` |
| `exposed_in_session` | czy element był pokazany wcześniej w tej sesji |
| `ms_since_last_exposure` | czas od ostatniej ekspozycji elementu (dowolnej sesji) lub `null` |
| `measurement_day`, `measurement_clean` | tylko pomiar: dzień pomiaru i czy w tej sesji nie było wcześniej kontaktu z elementem |
| `grading_rules_version` | np. `grading-rules/0.2` |
| `fsrs_config` | nazwa i wersja biblioteki, wersja algorytmu, skrót parametrów, docelowa retencja |

Surowa odpowiedź jest obowiązkowa. Bez niej nie da się ponownie ocenić starych prób po zmianie dopuszczalnych odpowiedzi.

### Przykład

```json
{
  "type": "attempt",
  "event_id": "5f0c…",
  "attempt_id": "a19e…",
  "session_id": "7c2d…",
  "timestamp": "2026-11-04T18:22:07.412Z",
  "tz_offset_min": 60,
  "app_version": "0.1.0+12",
  "content_version": "hira-pilot-3",
  "content_item_id": "kana.hira.shi",
  "content_item_version": 3,
  "skill": "kana_reading",
  "task_source": "scheduled_review",
  "response_mode": "text",
  "grading_mode": "automatic",
  "prompt_shown": ["char"],
  "support_used": [],
  "raw_response": "Si ",
  "normalized_response": "si",
  "matched_answer": "si",
  "first_attempt_result": "correct",
  "latency_ms": 2140,
  "solution_revealed_at": null,
  "fsrs_decision": { "applied": true, "rating": "Good", "reason": "first_recall_in_session" },
  "grading_rules_version": "grading-rules/0.1",
  "fsrs_config": { "library": "fsrs", "library_version": "2.0.1", "params_hash": "…", "desired_retention": 0.9 }
}
```

Zdarzenie `session_end` zawiera `reason` i `last_activity_at`. Czas zdarzenia może być późniejszy, np. gdy sesja wygasła po bezczynności, a długość sesji liczymy do `last_activity_at`.

### Przechowywanie
Lokalnie (SQLite przez Drift). Brak zdalnej telemetrii w v0.1. Dane z pilotażu użytkownik przekazuje przez dobrowolny eksport pliku. Zasady zbierania danych (zakres, podstawa prawna, czas przechowywania) trzeba ustalić przed pilotażem.

---

## 9. Protokół pomiaru w pilotażu

- **Punkty pomiaru:** 7. i 30. dzień od **pierwszego wprowadzenia znaku**, jednakowo dla wszystkich uczestników. Raport podaje też liczbę dni od ostatniego kontaktu ze znakiem (z dziennika).
- **Zadanie:** `kana_reading`, `response_mode = text`, bez wsparcia, ocena automatyczna, `task_source = measurement`.
- **Pomiar w sesji bez wcześniejszego kontaktu:** element pokazany lub ćwiczony w bieżącej sesji czeka z pomiarem do następnej. Jeśli mimo to pomiar nastąpi po kontakcie, próba ma `measurement_clean = false` i w analizie traktujemy ją osobno.
- Pomiar sam jest ćwiczeniem (efekt testowania), więc wszyscy mają ten sam harmonogram pomiarów. Badanie pamięci bez dodatkowych powtórek to osobny eksperyment, poza pilotażem.
- **Wiarygodność samooceny:** część zapisanych prób pisania ocenia niezależnie osoba znająca japoński, według tych samych kryteriów co użytkownik. Porównujemy zgodność w obrębie tej samej umiejętności.
- Dodatkowo mierzymy: obciążenie powtórkami (liczba i czas na dzień), tempo wprowadzania znaków, wygodę sposobów odpowiadania.

---

## 10. Otwarte pytania na prototyp

1. Pole rōmaji czy własna klawiatura do odczytu znaku: wygoda, błędy techniczne, dostępność.
2. Czy flagi wyłączające podpowiedzi działają na testowanych urządzeniach i klawiaturach.
3. Powrót znaku po błędzie w tej samej sesji: porównać przeliczenia FSRS z tymi próbami i bez nich na danych z pilotażu.
4. Zgodność samooceny pisania z oceną niezależną.
5. Czy progi „3 próby / 7 dni” dobrze przewidują wynik w 30. dniu.
6. Czy `kana_listening` i `word_reading` potrzebują własnych kart FSRS w kolejnej wersji.
7. Czy informacyjne sprawdzanie liczby i kolejności kresek jest dość wiarygodne, żeby wpływało na ocenę.

---

## Źródła

- Anki Manual — Deck Options (FSRS, znaczenie ocen): https://docs.ankiweb.net/manual/deck-options
- Roediger, Karpicke (2006), *Test-Enhanced Learning*: https://doi.org/10.1111/j.1467-9280.2006.01693.x
- KanjiVG: https://kanjivg.tagaini.net/ — licencja CC BY-SA 3.0: https://creativecommons.org/licenses/by-sa/3.0/
- Irodori — kana (Japan Foundation): https://www.irodori.jpf.go.jp/assets/data/Kana_all.pdf
- Marugoto — tabela rōmaji: https://words.marugotoweb.jp/static_contents/pc/search/romajilist.php
- Wytyczne dotyczące zgody (RODO, art. 8), udostępnione przez UODO: https://uodo.gov.pl/data/filemanager_pl/27.pdf

---

## Historia zmian

| Data | Wersje | Zmiana |
|---|---|---|
| 2026-10-28 | `grading-rules/0.1`, `mastery-rules/0.1` | Pierwsza wersja specyfikacji. |
| 2026-10-28 | `grading-rules/0.2`, `mastery-rules/0.2` | Odpowiedź po ekspozycji w tej samej sesji nie aktualizuje istniejącej karty i nie liczy się do utrwalenia. Pomiar tylko bez wcześniejszego kontaktu w sesji (`measurement_clean`). Nowe pola dziennika: `exposed_in_session`, `ms_since_last_exposure`, `last_activity_at`. Wskazówką jest wyłącznie skojarzenie z treści. |
