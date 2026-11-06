# Pakiet fabularny Kigi v1

Przygotowano 2026-10-30. To dane i kontrakt do implementacji, nie funkcja już działająca w aplikacji. Pliki pozostają w `docs/story/`, aby prototyp nie ładował nieobsługiwanego scenariusza. Obecny `Catalog.load()` czyta tylko `assets/content/hiragana.json`.

## Pliki i odpowiedzialność

- [`../fabula-kigi.md`](../fabula-kigi.md): świat, dialogi, pełny łuk kampanii, sceny i zasady postępu.
- [`../grafiki-kigi.md`](../grafiki-kigi.md): brief produkcyjny dla grafika.
- [`first-light.v1.json`](first-light.v1.json): pierwszy rozdział w postaci uporządkowanych kroków; język `pl-PL`.
- [`art-manifest.v1.json`](art-manifest.v1.json): zamawiane zasoby z ID, ścieżkami i etapem dostawy. `status: requested` oznacza, że pliku jeszcze nie dostarczono. To nie inwentaryzacja istniejących grafik.

Dialogi rozdziału 1 w JSON są wersją do przyszłego wyświetlania; dokument fabuły wyjaśnia inscenizację. Przy redakcji zmienić obie reprezentacje, zwiększając `revision`. ID scen i nagród pozostają stabilne.

## Format scenariusza

`schema` określa wersję tego lokalnego kontraktu. `chapter_id`, `step.id`, `line.id`, `action.id` i `reward.id` są stabilnymi identyfikatorami, nie tekstami do pokazywania. `next` wskazuje kolejny krok; `null` oznacza koniec. `assets` zawiera ID z manifestu, nie dowolne ścieżki. `kind` rozróżnia:

| Rodzaj kroku | Odpowiedzialność odtwarzacza |
|---|---|
| `dialogue` | Wyświetlić wiersze `lines` po kolei. `speaker`, `pose`, `text` sterują mówcą, reakcją i treścią. Jeden wiersz to jeden ekran dialogu; bez automatycznego przewijania |
| `learning_block` | Wyświetlić zadania `tasks` po kolei przez wspólny komponent nauki; treści znaków i poprawne odpowiedzi pobrać z katalogu |
| `checkpoint` | Krótki dialog i możliwość zapisania wyjścia na polanę |
| `word_task` | Jedna próba `word_reading`; `after_feedback` wyświetlić dopiero po zapisaniu odpowiedzi i pokazaniu rozwiązania |
| `reward` | Sprawdzić warunek ukończenia, zapisać zakończenie i nagrodę, następnie pozwolić obejrzeć prezentację |
| `ending` | Pokazać pamiątkę i następny dostępny kierunek; nie otwierać brakującego rozdziału |

`actions` opisują przyciski. `effect: advance` prowadzi do `next`; `effect: exit_to_village` zapisuje bieżący punkt i wychodzi; `effect: show_reward` odtwarza prezentację już zapisanej nagrody; `effect: open_notebook` kończy scenę i otwiera istniejący notes nauki. Pole `resume_step` ustala krok po powrocie, aby przerwa na `c01.pause` nie odtwarzała wcześniejszej piątki. Gdy brak `actions`, standardowy przycisk „Dalej” prowadzi do `next` po zakończeniu kroku.

W zadaniach `kind: exposure` nie ma oceny, `kind: reading` korzysta z `kana_reading`. `content_item_id` jest odwołaniem do bieżącego katalogu. `tasks[].id` jest stałym ID kroku zadania, potrzebnym do wznowienia; sam `content_item_id` nie wystarcza, ponieważ znak występuje w poznawaniu i czytaniu.

`feedback` zawiera teksty wspólne. `{reading}` pochodzi z `Kana.reading`; komunikat dla słów używa odrębnego szablonu. Nie wstawiamy odpowiedzi do tekstu przed próbą. `after_feedback` nie zastępuje ani nie poprzedza zapisu pierwszej próby.

Wiersze `lines` wyświetlamy przed zadaniami danego kroku. `after_presentation` w kroku nagrody pojawia się po animacji lub jej pominięciu. `after_feedback_scene_id`, jeśli występuje, przełącza wyłącznie krótką scenkę po odpowiedzi; następne zadanie wraca do własnego `scene_id`.

Trzy efekty po słowach mają zamknięty zakres: `close_future_notebook_pages` zamienia otwarty notes na zamknięty; `highlight_school_lantern_hook` wskazuje uchwyt na mapie; `show_ready_lantern` pokazuje niezapalony lampion w tym samym miejscu. Nie zmieniają stanu nagrody ani wyniku nauki. Z ograniczeniem ruchu pokazujemy po prostu końcowy stan scenki.

## Zgodność z obecnym projektem

| Istniejące miejsce | Co można wykorzystać | Czego jeszcze brakuje |
|---|---|---|
| `lib/data/catalog.dart` | Wyszukiwanie 10 znaków i trzech aktywnych słów po ID, odczyty i dopuszczalne odpowiedzi | Osobnego loadera scenariusza i walidacji brakującego ID |
| `lib/ui/lesson.dart` | Poznawanie, odczyt, korekty, słowa, opcjonalne pisanie | Przepływu sterowanego danymi, dialogów między blokami i przywracania kroku po wyjściu |
| `lib/domain/learning_store.dart` | `expose`, `answer`, `reveal`, `completeLesson`, terminy i statusy | Jawnych metod zapisu postępu fabuły i idempotencji ukończenia; obecne `_commit` jest prywatne |
| `lib/data/journal.dart` | Lokalny przyrostowy zapis zdarzeń JSON w SQLite | Zdarzeń fabularnych i odtwarzania ich stanu |
| `lib/ui/village.dart` | Polana, wejście do szkoły, notes, obecny lampion | Kompozytora warstw mapy, wspólnego przekształcenia punktów i obsługi kolejnych rozdziałów |
| `lib/ui/resident.dart` | Wczytanie lokalnego Rive, ograniczanie ruchu | Nowych reakcji, nazw maszyny i PNG jako statycznego fallbacku |
| `lib/audio/app_audio.dart` | Muzyka i wyciszanie tła podczas wymowy | Nic nowego obowiązkowego dla P0; dialogi są tekstowe, nie wymagają lektora |

Obecny `lanternUnlocked` sprawdza dowolne `lesson_completed`, a `completeLesson()` zapisuje `lesson_id: first-ten` i `reward_id: first-lantern`. Przy rozbudowie trzeba zawęzić odczyt nagrody do jej ID i zachować kompatybilność ze starymi wpisami. Nie wolno uzależnić już zdobytego lampionu od nowych dialogów.

## Reguły wykonania pierwszego rozdziału

1. Zachować dokładnie **23 bazowe jednostki nauki**: 10 ekspozycji, 10 samodzielnych odczytów znaków i trzy odczyty słów. Dialogi i dotknięcia przedmiotów nie są jednostkami nauki.
2. Kolejność odczytów w każdej piątce pozostaje `[2, 0, 4, 1, 3]`. Dialog `c01.pause` pojawia się między blokami. Nie dodawać drugiej całej lekcji po zakończeniu minigry.
3. Pierwsze przejście jest `task_source: lesson`, bo wprowadza materiał. Dobrowolna późniejsza gra używa `minigame`; zaplanowane powtórki `scheduled_review`. Sam podgląd historii nie wywołuje `answer` ani `expose` dla materiału językowego.
4. Obecne zasady FSRS i `mastery-rules/0.2` pozostają nadrzędne. Story nie zapisuje własnych ocen Good/Again. Wsparcie, ekspozycje i korekty przechodzą przez istniejący mechanizm.
5. Znak po błędzie wraca jako `corrective` kilka zadań później zgodnie z obecnym podejściem; korekta nie tworzy nowej oceny FSRS. Zapisać też kolejkę takich korekt. Korekta nie dodaje obowiązkowego „trafienia za wszelką cenę”.
6. `word_task` zawsze używa `word_reading`. Dla obecnego API oceny nie przekazywać ID wybranej opcji jako tekstowego odczytu; przyszłe zadania słuchowe wymagają osobnej obsługi poprawności wyboru.
7. Naciśnięcie „Nie wiem jeszcze” i obejrzenie rozwiązania pozwala przejść dalej. Brak progu procentowego. Pisanie nie jest częścią warunku `first-lantern`.
8. `skip_dialogue` pomija pozostałe kwestie w bieżącej scence. Na checkpoint nadal pozwala wyjść; na nagrodzie pomija tylko prezentację. „Sama nauka” korzysta z tych samych kroków i kończy ten sam rozdział.

## Zapis, przerwanie i jednokrotne nagrody

Do implementacji przewidzieć nowe zdarzenia `story_started`, `story_progress`, `story_scene_seen`, `story_choice`, `story_chapter_completed`, `story_reward_presented`. Minimalne wspólne pola: `story_id`, `story_version`, `chapter_id`, `run_id`, istniejące `event_id`, czas i sesja. Postęp zawiera `step_id`, `task_id`, `phase` (`prompt`, `feedback`, `dialogue`), indeks kwestii, kolejkę korekt i ID zapisanej próby, jeśli istnieje.

W obrębie publicznej metody domenowej zapisywać odpowiedź i przesunięcie postępu w jednej transakcji albo odtwarzać krok po jednoznacznym `run_id + task_id + attempt_id`. Obecne zdarzenie odpowiedzi nie ma pól przebiegu fabuły — adapter musi je dopiero dodać. Nie tworzyć ponownie próby, jeśli zapis się powiódł, a aplikacja zamknęła się przed pokazaniem informacji zwrotnej.

Wznowienie po ekspozycji powinno uwzględniać, czy znak z odczytem rzeczywiście pokazano ponownie w nowej sesji. Taki podgląd zapisujemy jako nową ekspozycję. Nie odtwarzamy informacji o „czystej próbie”, jeśli UI przed chwilą pokazało rozwiązanie.

Warunek `all_required_learning_resolved` oznacza: wszystkie 23 jednostki przeszły odpowiednią fazę i pokazano feedback ocenianych zadań, a zaplanowane korekty zostały zakończone bez wymogu poprawnej odpowiedzi. Samo przeklikanie dialogów nie wystarcza.

Na wejściu w `c01.lantern`, po spełnieniu warunku, przyszła metoda domenowa w jednej operacji zapisuje `story_chapter_completed` oraz kompatybilne `lesson_completed` (`first-ten`, `first-lantern`), o ile ta nagroda nie została wcześniej zapisana. Świat od tego momentu pokazuje lampion. Kliknięcie „Zobacz pierwsze światło” jest wyłącznie prezentacją, po której zapisujemy `story_reward_presented`.

Jeśli lampion istniał przed dodaniem historii, należy uznać materiał pierwszego rozdziału za ukończony i pozwolić dobrowolnie obejrzeć scenki. Nie powtarzać obowiązkowo dziesięciu znaków ani odbierać nagrody. Odtwarzanie samych scen nie wyświetla ponownie ocenianych kart. Nowa próba nauki wymaga jawnej decyzji użytkownika.

Podczas pierwszej prezentacji światła widok może chwilowo pokazać przejście `off → on`, ale zapis świata pozostaje już w stanie `on`. Nie zapisujemy przejściowego wygaszenia jako cofnięcia nagrody.

Wyjście zapisuje stan; nie symuluje ukończenia brakujących zadań. Błąd zapisu zatrzymuje przejście i pokazuje ponowienie. Zapis checkpointu nie kończy sam z siebie sesji nauki: nadal obowiązują istniejące reguły sesji i bezczynności.

## Zasoby i integracja

Manifest ma wpisy `assets[]`; każdy zawiera `id`, `phase`, `status`, `files` i `first_chapter`. Jeden wpis może grupować warianty P1, natomiast P0 rozpisuje osobno każdy z 19 plików. `files[].size_px` to rozmiar eksportu, dla Rive rozmiar artboardu; `alpha` oznacza wymagane przezroczyste tło. Manifest nie zawiera atrap bitmap.

Scenariusz P0 odwołuje się wyłącznie do zasobów P0. Tekst wspominający Minę nie wymaga jej modelu. Wszystkie odwołania do znaków muszą istnieć w `hiragana.json`; słowa z `retired: true` są niedozwolone w nowym przebiegu.

Po dostarczeniu plików przenieść zweryfikowane treści do uzgodnionego katalogu runtime i dodać odpowiednie podkatalogi w `pubspec.yaml`. Obecne wpisy `assets/art/` i `assets/rive/` nie powinny być traktowane jako potwierdzenie spakowania nowych, zagnieżdżonych katalogów. Sprawdzić wygenerowany bundle w buildzie aplikacji.

Rive jest kontraktem do przetestowania, nie potwierdzoną zgodnością przyszłego pliku. Najpierw wczytać `YuuStory`, sprawdzić wejścia i porównać wszystkie statyczne pozy. Dopiero potem zastąpić obecne `Resident`. Przy braku zasobów produkcyjnych prototyp zachowuje aktualną oprawę; nie należy aktywować częściowo pustej mapy.

## Kryteria gotowej implementacji

- Nowa osoba przechodzi cały rozdział i otrzymuje jeden lampion także z błędami i odpowiedziami „Nie wiem jeszcze”.
- Przerwanie w dialogu, ekspozycji, przed odpowiedzią, po zapisie odpowiedzi oraz podczas nagrody przywraca właściwy stan bez duplikowania prób.
- Stare `first-lantern` pozostaje odblokowane; ponowne wejście nie przyznaje drugiej nagrody.
- Żaden tekst, odczyt, znaczenie ani ilustracja nie zdradza odpowiedzi przed próbą poza jawnym trybem poznawania lub wsparciem.
- Liczby prób, FSRS i statusy są takie jak dla równoważnego przebiegu bez fabuły.
- Duży tekst, klawiatura, czytnik ekranu i ograniczenie animacji pozwalają ukończyć rozdział.
- Zestaw P0 działa lokalnie bez sieci; brakujący kolejny rozdział wyświetla zapowiedź zamiast martwego przycisku.

Te kryteria są planem weryfikacji przyszłego wdrożenia. Przy przygotowaniu niniejszego pakietu sprawdzamy spójność JSON, odwołań i istniejącego katalogu; nie twierdzimy, że nowy przebieg został uruchomiony na urządzeniu.
