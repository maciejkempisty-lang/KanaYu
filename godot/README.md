# Kigi — eksploracja w Godot

Działający prototyp 2.5D, Godot **4.7.2 stable**, renderer Compatibility. Uruchom projekt przez F5 lub `../Uruchom Kigi Godot.command`. F6 uruchamia wybraną scenę. Aby otworzyć podzielony widok przez F6, wybierz `scenes/debug_workspace.tscn`. Z terminala repozytorium użyj `./scripts/godot.sh`. `GODOT_BIN` pozwala wskazać inne położenie silnika.

Na komputerze widok debugowania otwiera się na pełnym ekranie. Po lewej jest edytor aktywnej sceny, po prawej działająca gra z wyborem **Telefon** lub **Tablet**. Zapis odświeża scenę po prawej. Jeśli Godot osadza grę w swoim oknie, wyłącz **Embed Game on Play**, aby pełny ekran działał w osobnym oknie. F11 przełącza tryb pełnoekranowy i okienkowy.

Eksploracja, szkoła, lekcje, powtórki, pisanie i zapis postępów działają natywnie w Godot. Uruchomienie gry nie wymaga Fluttera, przeglądarki, serwera, Pythona ani sieci. Dotychczasowy kod Flutter zachowano jako archiwum i źródło testów zgodności migracji. Nowe założenie nadrzędne: bohater rzeczywiście chodzi, kamera śledzi go po dużej mapie. Stare dokumenty o wybieraniu miejsc bez awatara nie opisują tego trybu.

## Sterowanie i trasa

WASD/strzałki lub przeciąganie drążka (dotyk, także mysz); E/przycisk otwiera pobliskie miejsce. F3 nakłada roboczy podgląd korytarzy ruchu: turkusowe pasy, żółte środki i punkty oznaczone `trasa.punkt` (od zera), czerwone przeszkody. Start u stóp dolnych schodów. Wejdź po schodach, minij pocztę i idź na północny wschód wzdłuż strumienia, po czym skręć w lewo przez most; potem na zachód i w górę do szkoły. Od szkoły prawą ścieżką i schodami do pracowni; dalej można dojść do bramki ogrodu. Dolne schody prowadzą do wejścia; boczne schody przy drzewie kończą się pod koroną (bez przeprawy przez wodę).

## Skala i strojenie

Jedna jednostka świata to piksel mapy 1024 × 1536. Skrzynka ma około 73 px wysokości, widoczny bohater około 70 px. Po korekcie użytkownika zoom **1,8** daje około 126 px / 844 = **14,9% wysokości telefonu**, widoczny świat 217 × 469 jednostek. Tablet 768 × 1024 pokazuje około 427 × 569 jednostek przy tej samej wielkości obiektów. Kadr jest o około 19% szerszy i wyższy niż przy poprzednim zoomie 2,15. Bez mgły wojny. Zmiana kadru odsłania świat.

Inspektor głównego węzła `Kigi`: `camera_zoom`, `camera_follow_speed`, `movement_speed`, `journal_path`, `show_walkable`. `hero_visual.gd` zawiera niezależny wygląd i wysokość bohatera. Mobilne okna używają logicznego rozmiaru odniesienia 390 × 844 i rozszerzania na szersze proporcje, aby gęstość pikseli telefonu nie pomniejszała postaci i przycisków. Sprzęt mobilny wymaga jeszcze weryfikacji.

Camera2D ma wygładzanie i granice 0..1024/1536. Interfejs należy do CanvasLayer. Przesunięcie kadru jest celem kamery, nie offsetem wychodzącym poza granice. Przy szerokim oknie zoom ma dodatkowe minimum, które uniemożliwia pokazanie pustego obszaru.

## Ruch i zasłanianie

`terrain.gd` opisuje ręcznie wyznaczone korytarze na namalowanych drogach, schodach, moście i polanie. Ruch sprawdza pięć punktów obrysu stóp i dzieli krok na odcinki do 2 px; po blokadzie próbuje ślizgu w osiach. Obszary poza korytarzami są niedostępne, a ławki i skrzynka mają dodatkowe wykluczenia. To konserwatywna maska prototypowa, nie automatyczne kolizje z PNG ani otwarty teren w każdym zielonym miejscu.

Przednie fragmenty poręczy, korony i wejścia szkoły są poligonami z teksturą oryginalnej mapy. Każdy ma osobną strefę stóp, w której zasłania bohatera. Nie używamy globalnego sortowania Y między różnymi tarasami. Maski są ręcznie obrysowanymi przybliżeniami, wymagającymi zastąpienia prawdziwymi warstwami alfa.

## Lekcje — natywna szkoła

Podejdź do szkoły i naciśnij E / „Wejdź do szkoły”. Po krótkim wygaszeniu obrazu otwiera się osobna scena jednej sali według mockupu v6. Bohater chodzi między sześcioma stanowiskami; E/przycisk uruchamia istniejące ćwiczenia. Przycisk „Aktywności” daje także dostęp do ich listy. Drzwi/E lub Esc wracają przed wejście w wiosce. Wioska i jej dziennik pozostają w pamięci, bez ponownego tworzenia stanu. Nie ma przejścia do Fluttera ani przeglądarki.

- Pierwsza lekcja: 10 ekspozycji i 10 odczytów w dwóch piątkach, kolejność `[2,0,4,1,3]`; potem trzy aktywne słowa: いいえ, ここ, いい. Wycofane słowa pozostają rozpoznawalne w historycznych wpisach.
- Ekspozycja pokazuje animowane kreski KanjiVG, odczyt, opis kształtu i lokalną wymowę. Odpowiedź/znaczenie słowa nie są ujawniane przed próbą. Wskazówki tylko dla istniejących przejrzanych `mnemonic` (obecnie brak).
- Po błędzie/„Nie wiem” zadanie czytania wraca po dwóch zadaniach, jako `corrective`, bez drugiej oceny FSRS. Korekta nie zapętla się. Nie ma progu poprawności; lampion oznacza ukończenie materiału.
- Samodzielna poprawna odpowiedź → Good, błąd/brak odpowiedzi/pomoc → Again; maksimum jedna aktualizacja karty na sesję. Wcześniejsza ekspozycja istniejącej karty wyklucza nową ocenę w tej sesji. Pierwsza próba nowej karty po wprowadzeniu nadal ją tworzy.
- FSRS-6: dokładny port przypiętej biblioteki Dart fsrs 2.0.1, oryginalne parametry, retencja 0,9, bez fuzzingu, kroki 60/600 s, ponowna nauka 600 s. Porównany z oryginałem na 480 kolejnych ocenach Good/Again/Hard/Easy w różnych odstępach.
- Statusy: trzy samodzielne poprawne próby w różnych sesjach i końcowy odstęp 7 dni; błąd po utrwaleniu → „Do odświeżenia”; odzyskanie wymaga poprawnej próby w innej sesji po co najmniej dobie. Pisanie ma osobny status i kolejkę.
- Pisanie: dotyk/mysz, zapis znormalizowanych kresek z czasami; trwałe zatwierdzenie przed pokazaniem wzorca; nakładka, odtworzenie i samoocena. Brak automatycznego rozpoznawania pisma.
- Powtórki czytania/pisania na dziś, dodatkowe ćwiczenia tylko poznanych znaków, pomiary po 7/30 dniach bez wcześniejszego kontaktu w sesji. Sesja wygasa po 30 minutach bezczynności.

`school.gd` odpowiada za interfejs, `lesson_model.gd` za przebieg, `store.gd` za dowody i statusy, `fsrs.gd` za harmonogram. Zasoby treści, wymowy i font japoński skopiowano z istniejącego repozytorium. Przerwana lekcja zaczyna się od początku, a zapisane próby zostają — tak jak w dotychczasowej wersji. Nie dodano nowych treści edukacyjnych ani scenariusza fabularnego.

## Zapis i migracja

Źródłem prawdy pozostaje dziennik zdarzeń `kanayu-journal/1`, nie licznik ukończenia. Godot zapisuje `user://learning-journal.json` (na tym Macu pod `~/Library/Application Support/Godot/app_userdata/Kigi · Ścieżki wioski/`). Plik zawiera otoczkę z sumą SHA-256; eksport użytkownika zachowuje dotychczasowy format JSON.

Każda operacja zapisuje pełny nowy dziennik do pliku tymczasowego, opróżnia bufor, ponownie weryfikuje treść, tworzy kopię `.bak`, a następnie atomowo podmienia plik główny. Dopiero po sukcesie zmienia stan w pamięci i odsłania odpowiedź. Nieudany zapis pozostawia zadanie do ponowienia. Uszkodzony plik przywracany jest z poprawnej kopii z komunikatem. Gdy oba pliki są nieczytelne, nauka nie nadpisuje danych; jawny import zabezpiecza uszkodzony plik przed przywróceniem. Wykrycie zapisu przez inne okno wymaga restartu zamiast nadpisania nowszych danych.

Menu szkoły → Dziennik → Import/Eksport. Import sprawdza schemat, reguły, identyfikatory treści i parametry FSRS, łączy wpisy po `event_id`, odrzuca konflikty i nie dubluje powtórnego importu. Odświeża karty, statusy i lampion przez odtworzenie zdarzeń. Nie wykonuje niejawnej synchronizacji z dawną aplikacją.

**Migracja na tym Macu wykonana 2026-11-07:** odczytano bez modyfikacji istniejącą bazę `pl.kanayu.kanayu/Data/Documents/kanayu.sqlite`; zaimportowano 57 historycznych zdarzeń, zachowując 10 poznanych znaków, 12 kart i pierwszy lampion. Nowa sesja/migracja dopisuje własne wpisy. Osobiste wpisy nie trafiają do repozytorium ani do testowych fixture'ów.

Na innym komputerze można zaimportować wcześniejszy eksport JSON. Jeśli dostępna jest tylko baza SQLite, jednorazowy pomocniczy skrypt `scripts/export_legacy_journal.py SOURCE.sqlite OUTPUT.json` czyta ją w trybie read-only, bez uruchamiania Fluttera. Sama gra tego narzędzia nie potrzebuje.

Poczta i pracownia nadal emitują `location_entered(location_id)` i pokazują wejścia do przyszłych scen, bez nowej treści nauczania.

## Zasoby i ograniczenia

Mapa: kopia `docs/concepts/kigi-terraces-scroll-map-v1.png`; kierunek graficzny zachowany. Bohater: nowy komplet `hero/Kigi-spritesheet` (16 atlasów: 8 idle + 8 walk), skopiowany do `assets/hero/v2`. Każdy atlas ma 25 klatek 256 × 256; kolejność, regiony, długości klatek i czas pętli 2,333 s są czytane z dostarczonego JSON. Jawne przypisanie źródeł znajduje się w `assets/hero/v2/sources.json`. Wszystkie kierunki zweryfikowano wizualnie w dwóch fazach cyklu oraz testami źródeł atlasów.

Poprzednie arkusze `n/ne/nw/s` miały błędną orientację grafiki. Nie są już używane. Nowy zestaw ma właściwe N, NE, NW, S; nie ma zastępstwa idle ani proceduralnego kołysania. Stała kalibracja rozmiaru i punktu stóp dla każdej animacji (`metrics.json`) zachowuje wysokość około 70 jednostek bez przycinania poszczególnych klatek. `tests/calibrate_hero.gd` odczytuje alfa i odtwarza te dane; PNG pozostają niezmienione. Rzeczywiste przesunięcie po kolizjach wybiera chód, a zatrzymanie, przeszkoda i szkoła przywracają idle z ostatnim kierunkiem. Tempo można stroić przez `walk_speed_scale` w `hero_visual.gd`. Brak nowych generowanych grafik. Nunito i licencja z istniejących zasobów repozytorium.

Powiększona bitmapa jest celowo prototypem, nie finalną jakością. Potrzebne są segmenty mapy w większej rozdzielczości, oddzielne korony/budynki/poręcze. Nie ma jeszcze eksportów sklepowych ani trwałego zapisu pozycji bohatera. Lekcje i ich postęp są natywne i trwałe. Muzyka tła starej aplikacji nie została podłączona; lokalna wymowa działa w Godot.

## Weryfikacja 2026-11-07

`./scripts/godot.sh --headless --script tests/exploration.gd`

`./scripts/godot.sh --script tests/exploration.gd -- --capture`

Testy: wszystkie segmenty tras z rzeczywistym obrysem stóp; przejście poczta–most–szkoła–pracownia tym samym kontrolerem; próbki skał, wody, budynku i ławki; brak tunelowania; proporcja bohatera; dotyk, puszczenie drążka i utrata fokusu; granice kamery dla 390 × 844, 768 × 1024 oraz 1024 × 768. Wynik PASS.

Zrzuty renderowane przez uruchomiony Godot/OpenGL na Macu: `captures/tree-390.png`, `school-390.png`, `bridge-390.png`, `workshop-390.png`, `canopy-390.png` i odpowiedniki `-768.png`. Zrzuty przedstawiają ustawione punkty kontrolne; ciągłość drogi jest sprawdzana osobno przez symulację ruchu, a nie wnioskowana ze zrzutów. Obejrzano kadry poczty, szkoły, mostu, pracowni i schodów pod koroną. Po pierwszym przeglądzie poprawiono pozycję przy poczcie i maskę poręczy.

Historia etapu przed migracją lekcji: Flutter — analiza bez problemów, wszystkie 28 testów przeszły, build web udany. Adres szkoły otwarty w przeglądarce: potwierdzono powitanie Yuu i przycisk wejścia. Nie przeprowadzono fizycznego testu telefonu/tabletu, oceny komfortu dotyku ani pełnego wizualnego audytu każdego punktu obwodu kolizji.

### Weryfikacja natywnej nauki

- `./scripts/godot.sh --headless --script tests/learning.gd` — PASS: 480 ocen zgodnych liczbowo z oryginałem; zasady oceniania, statusy, sesje, pomiary, korekty, pisanie, ukończenie lekcji nawet z samymi błędami, zapis/odtworzenie, migracja, idempotencja, błędy zapisu, uszkodzenie i konkurencyjne okna.
- `./scripts/godot.sh --script tests/school_ui.gd` — PASS: rzeczywisty renderer Godot, szkoła otwiera się w grze, ruch zatrzymany podczas nauki, pełna lekcja z błędem i korektą, nagroda, pisanie i powrót do wioski. Test używa osobnego tymczasowego dziennika, nigdy rzeczywistych postępów użytkownika.
- `./scripts/godot.sh --headless --script tests/exploration.gd` — PASS po zmianie zoomu.
- Zrzuty: `captures/school-menu-390.png`, `lesson-exposure-390.png`, `lesson-reading-390.png`, `lesson-feedback-390.png`, `lesson-complete-390.png`, `school-menu-768.png`, `lesson-writing-768.png`, `lesson-writing-compare-768.png`, `tree-zoom-390.png`.
- `test/godot_reference_test.dart` generuje syntetyczne wyniki z oryginalnej domeny Flutter i fsrs 2.0.1. Fixture jest dołączony; uruchamianie testów Godot nie wymaga Fluttera.
- Nie testowano jeszcze klawiatury ekranowej i eksportów na fizycznych telefonach/tabletach. Testy renderera obejmują okna 390 × 844 i 768 × 1024 na Macu.

### Wizualny edytor ścieżek

Otwórz **`\` w grze**, plik **`Edytor sciezek Kigi.command`** (duże okno 1100 × 850), albo scenę `scenes/path_editor.tscn` w Godot i uruchom F6. Na komputerze skrót `\` otwiera osobne, skalowalne okno 1200 × 900, niezależne od telefonicznego podglądu gry w Godot. Zamknięcie przywraca grę; niezapisane zmiany wymagają zapisania lub odrzucenia. Na urządzeniu mobilnym edytor pozostaje w oknie gry. To natywny edytor w działającej scenie Godot; nie wymaga ręcznej zmiany współrzędnych w kodzie.

1. Wybierz ścieżkę z listy lub kliknij jej punkt na mapie.
2. Przeciągnij punkt. Wspólne skrzyżowanie kilku tras przesuwa się razem, zachowując połączenie.
3. Pole **Szerokość** ustawia pełną szerokość pasa (nie promień), od 16 do 240 jednostek mapy.
4. Puste tło albo prawy/środkowy przycisk myszy przesuwa mapę; kółko i przyciski −/+ zmieniają zoom. **Cała mapa** dopasowuje mapę wyłącznie w edytorze — kamera gry pozostaje 1,8.
5. Dwuklik na linii dodaje punkt. **Usuń punkt** / Delete usuwa wybrany, zachowując minimum dwa punkty na trasę. **Cofnij/Ponów** oraz Ctrl/Cmd+Z / Shift+Ctrl/Cmd+Z działają również dla szerokości i wspólnych skrzyżowań.
6. **Sprawdź przejścia** kontroluje środki ścieżek, ich połączenia i bliskość wejść do miejsc. To kontrola geometrii; zgodność z namalowanymi skałami, wodą i schodami nadal wymaga obejrzenia mapy oraz przejścia postacią.
7. **Zapisz** / Ctrl/Cmd+S zapisuje zmiany. **Zapisz i wróć** wraca do gry z nowymi kolizjami. Zamknięcie niezapisanego projektu pyta o odrzucenie zmian. Gdy po edycji postać znalazłaby się poza drogą, wraca na najbliższy dozwolony fragment.
8. **Animacje** otwiera porównanie wszystkich ośmiu kierunków: idle obok walk, na nowych atlasach.

Gra i edytor korzystają ze wspólnego `assets/world/paths.json` (`kigi-paths/1`). To źródło danych, które można zachować w repozytorium. Edycja nie zmienia tła ani postępów nauki. Dane obejmują nazwy tras, listy punktów, promienie i przeszkody. Czerwone prostokąty są podglądem istniejących przeszkód; ta wersja narzędzia edytuje punkty i szerokości, nie prostokąty.

Przed zapisem dane przechodzą walidację, zapis do pliku tymczasowego i ponowny odczyt. Poprzedni poprawny plik otrzymuje kopię `.bak`. Edytor wykrywa zmianę pliku przez inne okno i odmawia nadpisania. W wersji eksportowanej, gdzie zasoby projektu są tylko do odczytu, zapis trafia do `user://paths.json`; lokalna kopia ma pierwszeństwo przy wczytywaniu. W projekcie uruchamianym na tym Macu zapis trafia do pliku źródłowego. Po edycji w osobnym oknie działająca gra wczytuje zapis po odzyskaniu fokusu; `\` stosuje zapis od razu.

Podgląd F3 nadal działa w grze. Pokazuje pasy przed uwzględnieniem obrysu stóp: 5 px marginesu w poziomie i 3 px w pionie.

Testy po zmianie:
- `tests/directions.gd`: PASS — wszystkie osiem kierunków chodu, idle po zatrzymaniu oraz konkretne źródła atlasów.
- `tests/exploration.gd`: PASS — nowe atlasy i kolizje wczytywane z JSON, istniejące trasy, kamera, sterowanie.
- `tests/path_editor.gd -- --capture`: PASS — przeciąganie rzeczywistymi zdarzeniami myszy, transformacja zoomu, wspólne skrzyżowania, szerokość, cofanie/ponawianie, dodanie/usunięcie punktu, zapis i restart, kopia, błędny zapis, konflikt dwóch okien, `\` i zatrzymanie postaci podczas edycji. Testy zapisują wyłącznie tymczasowe pliki.

Zrzuty renderera: `captures/path-editor.png`, `captures/directions-v2.png`, `captures/directions-v2-later.png`. Po dodaniu nowego zestawu zweryfikowano wszystkie kierunki na tych zrzutach. Zasłanianie, bitmapa mapy i fizyczne urządzenia nadal mają ograniczenia opisane powyżej.

### Mapa detail v2

Gra i edytor korzystają z `assets/map-v2/map-master-2560x3840.png`, dostarczonego w `docs/art-delivery/kigi-map-detail-v2-godot.zip`. Jedna współdzielona tekstura (około 37,5 MiB RGBA) służy jako tło, podgląd edytora i źródło masek zasłaniania, bez ładowania dodatkowej kopii kafli. Skala tła 0,4 zachowuje świat 1024 × 1536 i zapisane ścieżki. UV masek są przeliczone przez 2,5; filtrowanie Linear. Zoom pozostaje 1,8. Grafika nadal jest scalona, maski pierwszego planu pozostają ręcznymi wielokątami, a obszary ruchu można dopracować w edytorze.

### Edytor masek zasłaniania

Po otwarciu edytora ścieżek (`\`) wybierz **Maski**. Lista zawiera poręcz mostu, koronę drzewa i fragment szkoły. **Obrys maski** (złoty) wyznacza wycinany fragment mapy; **obszar aktywacji** (niebieski) określa położenie stóp bohatera, przy którym fragment zasłania postać. Oba są edytowalnymi wielokątami. Przeciągaj punkty, dodawaj je dwuklikiem na krawędzi (również zamykającej), usuwaj Delete (minimum 3), cofaj Ctrl/Cmd+Z. Kółko przybliża, prawy przycisk przesuwa mapę.

**Podgląd bohatera** pozwala ustawiać postać kliknięciem lub przeciąganiem lewym przyciskiem; pokazuje wszystkie maski według niezapisanych obrysów. To podgląd zasłaniania, bez ograniczeń kolizji, dzięki czemu można sprawdzić obie strony granicy. **Zapisz i wróć** wraca do edytora ścieżek. Po zamknięciu jego okna gra wczytuje maski. Szkic ścieżek pozostaje zachowany podczas edycji masek.

Dane: `assets/world/masks.json` (w eksporcie `user://masks.json`). Zapis atomowy z kopią `.bak`, kontrolą konfliktu między oknami i walidacją przecinających się krawędzi. Niezapisane zmiany wymagają potwierdzenia odrzucenia. Grafika jest nadal scalona: obrys wycina również tło pomiędzy elementami, dlatego poręcze i liście wymagają dokładnych obrysów lub docelowych osobnych grafik z przezroczystością.

Test `tests/mask_editor.gd -- --capture` sprawdza przeciąganie myszą, obszar aktywacji, cofanie, zamkniętą krawędź, zapis/odczyt, konflikt zapisu, niepoprawne wielokąty, podgląd oraz powrót do gry. Zapisuje wyłącznie pliki testowe w katalogu tymczasowym.

**Nowa maska**: naciśnij przycisk i kliknij obiekt na mapie. Powstają dwa początkowe prostokątne obrysy, które dopasujesz punktami. Nowe maski otrzymują wolną nazwę „Maska N”. **Usuń maskę** usuwa całą wybraną maskę wraz z obszarem aktywacji; Cofnij przywraca oba obrysy. Można usunąć i zapisać również wszystkie maski.

**Dodaj punkt**: włącz tryb, następnie klikaj krawędzie wybranego obrysu (złotego lub niebieskiego). Punkt pojawia się na najbliższej krawędzi w zasięgu 18 pikseli ekranu; możesz go potem przeciągnąć. Naciśnij przycisk ponownie, aby wyłączyć tryb. Dwuklik na krawędzi nadal działa. Dodawanie, usuwanie masek i punktów obsługuje cofanie/ponawianie oraz zapis. Test edytora obejmuje także utworzenie maski kliknięciem, dodanie punktów do obu obrysów, usunięcie ostatniej maski i ponowne utworzenie po wczytaniu pustej listy.

### Nowe ścieżki i triggery

W edytorze (`\`) **Nowa ścieżka** rozpoczyna rysowanie: kliknij początek i drugi punkt, potem kolejne punkty. **Zakończ przedłużanie** wraca do przeciągania punktów. **Dodaj punkt** wstawia punkty na klikniętej linii wybranej ścieżki; **Przedłuż ścieżkę** dopisuje punkty na końcu (lub na początku, jeżeli zaznaczony jest pierwszy punkt). Nazwę zmienisz w polu obok listy, zatwierdzając Enterem lub opuszczając pole. Szerokość, cofanie i zapis działają również dla nowych ścieżek. **Sprawdź przejścia** pomaga wykryć odłączone odnogi; nową ścieżkę należy połączyć z istniejącą siecią.

**Triggery** otwierają edytor trzech obecnych miejsc interakcji: szkoły, poczty i pracowni. Przeciągaj środek koła i zmieniaj jego **średnicę**, a także nazwę wyświetlaną w grze. Zasięg dotyczy pozycji stóp postaci. Przy nakładaniu się kół wygrywa najbliższy środek. Identyfikatory akcji pozostają stałe: szkoła nadal otwiera natywne lekcje po naciśnięciu przycisku/E. Zapisy trafiają do `assets/world/triggers.json` (w eksporcie do `user://triggers.json`) z kopią i kontrolą konfliktów. Po zamknięciu edytora gra wczytuje zmiany. Sam trigger nie zmienia obszaru ruchu — do nowego wejścia musi prowadzić ścieżka.

`tests/world_editor.gd -- --capture` sprawdza rysowanie, wstawianie punktów, szerokość, nazwę, cofanie, zapis ścieżek i kolizje, przesuwanie triggera myszą, zakres, konflikt zapisu, ponowne wczytanie i otwarcie natywnych lekcji przy przesuniętym wejściu. Wszystkie zapisy testowe są tymczasowe.

### Wnętrze szkoły v6

Scena: `scenes/school_interior.tscn`; sterowanie i kamera: `scripts/school_interior.gd`; geometria: `scripts/school_space.gd` i `assets/school/layout.json`. Bitową kopią zaakceptowanego obrazu jest `assets/school/interior-v6.png` (1300 × 2100). Oryginalnego wejścia nie przerysowano. Nie dodano drugiego zestawu podpisów mebli. Aktualne liczby powtórek i przyciski są częścią ekranowego HUD.

Transformacja: `world = source_pixel × 0.4`, bez przesunięcia i obrotu. Granice świata wynoszą 520 × 840 jednostek, UV masek pozostają w pikselach źródłowej grafiki. Gęstość 2,5 px/jednostkę odpowiada mapie wioski. Bohater ma nadal 70 jednostek wysokości i zoom 1,8 (telefon: około 126 px w logicznym widoku 390 × 844). Tablet pokazuje więcej otoczenia; kamera śledzi postać z ograniczeniem do grafiki, a nie dopasowaniem całego mockupu. Parametry kamery i ruchu przechodzą z wioski. Dane JSON przechowują rozmiar źródła, skalę, tło, punkt startu, obrysy wolnej podłogi, przeszkody, stanowiska i regiony aktywacji masek. Można podmienić teksturę bez przenoszenia logiki lekcji do grafiki.

Wnętrze jest jedną salą. Wolna podłoga i obszar tuż za progiem są dostępne; ściany i osiem obrysów mebli/tablic blokują rzeczywisty obrys stóp. Meble i przednia ściana mają osobne maski aktywowane położeniem stóp, bez globalnego sortowania Y. F3 pokazuje geometrię. Spawn leży za zasłoną wejścia, w punkcie źródłowym (660,1040), z kierunkiem północnym. Wyjście wymaga osobnej akcji i krótkiej blokady 0,7 s po wejściu; wygaszenie trwa 0,18 s w każdą stronę. Powrót zachowuje punkt wejścia w wiosce i ustawia postać na południe. Nie ma automatycznego przejścia po wejściu w trigger.

Stanowiska otwierają ten sam `learning/school.gd`: pierwsza lekcja, zaplanowane czytanie, zaplanowane pisanie, pomiary po przerwie, notes i dziennik z importem/eksportem. Tryb `room_mode` wraca z ekranu do zachowanego miejsca w sali. Podczas ćwiczenia drążek i ruch są blokowane. Brak zaplanowanych zadań pokazuje neutralny komunikat; nie uruchamia pustej lekcji. Lista „Aktywności” korzysta z obecnych warunków dostępności. Model, FSRS i dziennik pozostają wspólne z wioską.

Weryfikacja: `tests/school_interior.gd -- --capture` — wielokrotne wejście/wyjście, kierunki i blokada drzwi, przeszukanie wolnej podłogi i przejście kontrolerem do wszystkich stanowisk, blokada ruchu w ćwiczeniu, pełna lekcja i nagroda, puste i niepuste kolejki czytania/pisania/pomiarów, notes/dziennik, zachowanie wyniku po wczytaniu, dotyk syntetyczny, regiony zasłaniania i granice kamery dla 390 × 844, 768 × 1024 oraz 1024 × 768. Zrzuty z renderera Godot: `captures/interior-{entrance,boards,writing}-{390,768}.png`. Zrzuty ustawiają punkty kontrolne, a ciągłe dojście jest testowane osobno. Testy używają tylko tymczasowych dzienników. Testy nauki (480 porównań FSRS), eksploracji, edytora wejść i dotychczasowych ekranów lekcji również przeszły.

Tymczasowe: scalone tło z poglądowymi napisami, ręczne maski i interpretacja podłogi w projekcji cutaway. To integracja mockupu, nie zwiększenie szczegółowości bitmapy ani gotowe warstwy alfa. Docelowo potrzebne są osobne meble i front z przezroczystością oraz tło bez napisów. Proporcje telefonu/tabletu sprawdzono w Godot na Macu; nie przeprowadzono fizycznego testu komfortu sterowania na urządzeniach mobilnych.

### Wspólny edytor scen

Skrót `\` obsługuje teraz autoload `WorldEditor`, a nie tylko skrypt wioski. Wybiera widoczną scenę z grupy `editable_scene`, otwiera osobne duże okno i zatrzymuje przetwarzanie tej sceny na czas edycji. Zamknięcie przywraca poprzedni tryb przetwarzania. Wioska zachowuje dotychczasowe narzędzia ścieżek, masek i triggerów; szkoła otwiera własne tło i dane `assets/school/layout.json`.

W szkole dostępne są: **Podłoga / ruch**, **Przeszkody**, **Maski**, **Aktywacja masek**, **Triggery** oraz **Punkt pojawienia**. Podłoga jest wielokątem, a nie korytarzami o szerokości jak we wiosce. Punkty można przesuwać, dodawać na krawędziach i usuwać. Przeszkody i maski można tworzyć oraz usuwać. Triggery stanowisk zachowują swoje identyfikatory działań; ich środki i promienie są edytowalne. Podgląd bohatera uwzględnia gęstość bitmapy i maski całej sceny. Wszystkie tryby współdzielą historię cofania i jeden zapis układu sceny; zmiany zostają zastosowane po zamknięciu edytora. Jeżeli dotychczasowe miejsce bohatera zostanie zablokowane, zostaje przesunięty na najbliższą wolną podłogę.

Zapis odbywa się atomowo, z kopią `.bak` i odrzuceniem konfliktu między oknami. Układ nie może zapisać punktu pojawienia poza wolną podłogą. W eksporcie lokalne pliki scen mają osobne nazwy `user://scene-<hash ścieżki źródłowej>.json`; gra i edytor używają tego samego mechanizmu odczytu. Edycja szkoły nie zapisuje plików wioski.

**Podłączanie kolejnych scen:** dodaj do korzenia sceny dziecko ze skryptem `scripts/editor/editable_scene.gd`, ustaw `layout_path` i `scene_title`. Plik korzysta ze schematu `kigi-scene-layout/1` (te same pola geometrii co obecny układ szkoły). Scena odczytuje go przez `scene_layout_data.gd.load_layout()`; metodą `reload_scene_layout()` stosuje zapis do swojej grafiki, kolizji i triggerów, a opcjonalnym `reset_editor_input()` zeruje sterowanie. Rejestracja skrótu i okna jest wspólna — nie trzeba dodawać kolejnej obsługi klawisza. Nowe sceny wymagają swoich danych układu i powiązań triggerów, nie otrzymują geometrii wioski automatycznie.

Ta zmiana nie była uruchamiana ani testowana automatycznie — zgodnie z ustaleniem testuje ją użytkownik. Do ręcznego sprawdzenia: otwarcie wioski i szkoły pod `\`, właściwe tło, ruch zablokowany przy otwartym edytorze, zapis/odrzucenie i cofanie, ponowne wejście do sceny, przesunięcie triggera stanowiska, podgląd maski, niezależność danych scen.

### Dymek stanowiska w szkole

`ui/station_bubble.gd` wykorzystuje dostarczony `assets/ui/kigi-speech-bubble-play.png` bez zmiany pliku. Tekst z koncepcji jest etykietą Godot z fontem Nunito; ▶ jest wyłącznie namalowane w PNG. Na ikonę nałożono przezroczysty przycisk minimum 48 × 48, z `accessibility_name`, opisem i widocznym obramowaniem fokusu. Obsługa: dotyk/mysz, E w grze oraz Tab i standardowe zatwierdzenie przycisku klawiaturą. Stan nieaktywny przy braku zaplanowanych zadań ma neutralny tekst, przygaszoną/przekreśloną ikonę i wyłączony start również przez E.

Dymek zastępuje poprzedni przycisk stanowiska w dolnym prawym rogu. Obejmuje pierwszą lekcję, czytanie, pisanie, sprawdzanie po przerwie, notes, dziennik i wyjście. Lista Aktywności pozostaje w nagłówku. Dymek znika po odejściu, podczas przejścia i przy otwartym ćwiczeniu. Nie uruchamia aktywności samoczynnie. Dostępność nadal wynika z istniejącego dziennika, harmonogramu i blokady drzwi.

Dymek jest w HUD, z pozycją głowy przeliczaną przez transformację kamery. Korpus mieści się w szerokości widoku; dolny pas grafiki z ogonem jest dopasowywany do głowy, a tekst i namalowany przycisk zachowują pozycje w korpusie. Kamera rezerwuje miejsce nad bohaterem i wskazanym obiektem bez zmiany skali obiektów. `popup_font_size` (16–28) w scenie szkoły pozwala sprawdzić większą czcionkę; etykieta zawija tekst i zwiększa wysokość korpusu w razie potrzeby.

Zgodnie z ostatnią dyspozycją użytkownika nie uruchomiono gry ani testów tej implementacji i nie wykonano zrzutów. Do ręcznej oceny pozostają kompozycja dymka i ogona, kolizja z meblami przy wygładzaniu kamery, krawędzie telefonu/tabletu, większa czcionka i odczyt przez czytnik ekranu.
