# KanaYu — lista grafik do Ścieżki Lampionów

Brief wykonawczy v1 · 30 października 2026

Ten dokument można przekazać osobie tworzącej grafiki razem z [fabułą](fabula-kigi.md). Określa przedmioty, stany i sposób eksportu potrzebne do implementacji. **Nie jest zmianą zaakceptowanego kierunku artystycznego.** Istniejące obrazy z projektu służą do sprawdzenia układu świata; finalną kreskę, kolory i proporcje należy utrzymać zgodnie z wcześniej przekazanym projektem.

**P0 = pierwsze wdrożenie:** 19 plików graficznych używanych przez aplikację: sześć warstw wioski, trzy pliki lampionu, trzy rekwizyty, sześć statycznych póz Yuu i jeden plik Rive. Oprócz nich potrzebne są pliki źródłowe, opis rozmieszczenia i podglądy kontrolne. Nie zamawiamy teraz osobnej ilustracji do każdego ekranu lekcji.

**P1 = dalsza kampania:** dodatkowe miejsca, Mina, Toma i święto. **P2 = później:** ogród katakany, rozbudowane efekty i dodatkowe kosmetyczne warianty. Liczba 19 dotyczy wyłącznie P0, bez dokumentacji i źródeł roboczych.

## 1. Wspólne zasady wszystkich materiałów

- Gra jest oglądana przede wszystkim na telefonie w pionie. Mapa ma proporcje **3:4**; otoczenie może być kadrowane w obrębie osobnego okna sceny, nie musi wypełniać całego ekranu telefonu.
- Bez wrysowanego tekstu, kana, rōmaji, numerów, logotypów i podpisów przycisków. Dotyczy to również szyldu szkoły, stron notesu i kartek. Cały tekst dodaje Flutter.
- Obiekty zmieniające stan i postacie są osobnymi zasobami z prawdziwą przezroczystością. Nie mogą być jednocześnie namalowane w tle.
- Źródło warstw sceny: **2400 × 3200 px** lub równoważny wektor. Eksport do aplikacji: **1200 × 1600 px**, sRGB, PNG. Nie wgrywamy źródeł 2400 × 3200 do runtime bez potrzeby.
- Wszystkie sześć warstw mapy zachowuje pełne, identyczne płótno 1200 × 1600. Nie przycinać każdej warstwy do zawartości. Dzięki temu nakładają się bez odgadywania przesunięć.
- Osobne rekwizyty i pozy postaci mają rozmiary z tabel poniżej. Każdy wariant tego samego obiektu zachowuje identyczne płótno, pozycję i skalę.
- Krawędzie przezroczystych obrazów muszą wyglądać poprawnie na jasnym i ciemnym tle: bez białej obwódki, szachownicy i ciemnego prostokąta.
- Animacja nie zastępuje statycznego stanu. Przy ograniczeniu ruchu lub błędzie odczytu Rive aplikacja pokazuje PNG.
- PNG to podstawowy kontrakt pierwszej dostawy. SVG może być dodatkowym źródłem, lecz obecna aplikacja nie ma ogólnego renderera dowolnych ilustracji SVG; nie przekazujemy wyłącznie SVG jako plików gotowych do użycia.

## 2. P0 — warstwy wioski

Docelowy katalog: `assets/art/story/kigi/layers/`. Pliki nie istnieją jeszcze; są nazwami zamawianych materiałów.

| ID | Plik | Zawartość | Wymagany stan / przezroczystość |
|---|---|---|---|
| `env.kigi.sky` | `kigi-sky-day.png` | Niebo, odległe wzgórza i daleki las; najdalszy plan | Pełne tło, nieprzezroczyste; dzień |
| `env.kigi.ground` | `kigi-ground.png` | Polana, ścieżka, brzegi, woda strumienia, kamienie i rośliny w środkowym planie | Przezroczystość poza zawartością; bez budynków, mostku i Yuu |
| `env.kigi.cottages` | `kigi-cottages.png` | Małe domki w tle, w tym przyszła pracownia Tomy | Przezroczyste tło; bez aktywnych lampek i postaci |
| `env.kigi.school` | `kigi-school.png` | Cała szkoła, ganek, stopnie, drzwi, pusty szyld, stały uchwyt na lampion | Przezroczyste tło; **bez samego lampionu, jego poświaty i tekstu na szyldzie** |
| `env.kigi.bridge` | `kigi-bridge.png` | Cały istniejący drewniany mostek i jego poręcz | Przezroczyste tło; mostek od początku sprawny, bez wariantu zniszczonego |
| `env.kigi.foreground` | `kigi-foreground.png` | Pień i korona dużego drzewa oraz wybrane rośliny przy krawędziach | Przezroczyste tło; środek i główne punkty dotyku pozostają czytelne |

Kolejność rysowania: niebo → teren → domki → szkoła → mostek → poświata i lampion → pierwszy plan → Yuu → interfejs. Układ ma być zaprojektowany tak, aby pierwszy plan nie zasłaniał Yuu ani uchwytu przy szkole. Jeśli kompozycja wymaga innej kolejności, podać ją w pliku rozmieszczenia; nie scalać obiektów.

**Istotna korekta względem obecnej bitmapy:** aktualne `assets/art/kigi-village.png` ma lampion namalowany przy drzwiach. Do finalnych warstw potrzebne jest czyste miejsce po tym lampionie. Nałożenie drugiego zasobu na istniejący obraz może dać dwa lampiony lub pozostawić widoczny stary kształt.

### Rozmieszczenie i kadrowanie

Zachować rozpoznawalne relacje: szkoła po prawej, duże drzewo po lewej, strumień i mostek po lewej na dole, otwarte miejsce na Yuu w dolnej części. Pozycje są wspólne dla wariantów dziennych i wieczornych.

Punkt startowy do kompozycji w układzie znormalizowanym 0–1, liczonym od lewego górnego rogu:

| Element | Orientacyjne miejsce | Uwagi |
|---|---|---|
| Wejście do szkoły | `x=0.65, y=0.52` | Główny punkt wejścia do lekcji |
| Uchwyt lampionu | `x=0.83, y=0.47` | Dokładny punkt zaczepienia podaje grafik po zatwierdzeniu kompozycji |
| Środek mostku | `x=0.24, y=0.63` | Widoczny także przed odblokowaniem jego wątku |
| Podstawa Yuu | `x=0.25, y=0.91` | Postać nie jest częścią żadnej warstwy |
| Spokojny obszar na dole | `y=0.75–1.00` | Może być częściowo przysłonięty UI; bez jedynych egzemplarzy istotnych rekwizytów |

To wskazówki produkcyjne, nie pomiary istniejącej ilustracji. Plik `kigi-layout.json` dostarczany z grafikami ma zawierać faktyczne: wymiary płótna, kolejność warstw, `school_entry`, `lantern_hook`, `bridge_center`, `yuu_feet`, prostokąty klikalnych obszarów i dozwolony zakres kadrowania. Punkty trzeba zatwierdzić na wspólnym podglądzie.

W implementacji wszystkie warstwy i punkty korzystają z **tego samego przekształcenia skali i kadrowania**. Nie rozstawiamy przycisków wyłącznie procentami całego ekranu. Przy skrajnych proporcjach bezpieczniejszy jest cały widok mapy z dopasowanym tłem niż ucięcie szkoły.

## 3. P0 — lampion i rekwizyty

Docelowy katalog: `assets/art/story/kigi/props/`, poświata w `assets/art/story/kigi/fx/`.

| ID | Plik | Rozmiar eksportu | Co dokładnie narysować |
|---|---|---|---|
| `prop.lantern.off` | `lantern-off.png` | 512 × 768 | Papierowy lampion z zawieszeniem, bez światła, na przezroczystym tle |
| `prop.lantern.on` | `lantern-on.png` | 512 × 768 | Ten sam kształt, zawieszenie i położenie; ciepło rozświetlone wnętrze, bez wielkiej zewnętrznej poświaty |
| `fx.lantern.glow` | `lantern-glow.png` | 1024 × 1024 | Sam miękki bursztynowy blask na przezroczystości, bez lampionu i twardej granicy |
| `prop.notebook.closed` | `notebook-closed.png` | 768 × 768 | Notes z liściowym motywem, bez liter; niewielki obrót dopuszczalny |
| `prop.notebook.open` | `notebook-open.png` | 1536 × 1024 | Otwarty notes oglądany niemal na wprost, dwie jasne puste strony; płaskie miejsce na tekst i pamiątki |
| `prop.lesson.tag` | `lesson-tag.png` | 768 × 512 | Jedna prosta papierowa etykieta, pusta w środku; spokojne krawędzie, bez faktury przecinającej znak |

Punkt zaczepienia obu lampionów: **(0.5, 0.05)** ich lokalnego płótna. Środek poświaty: **(0.5, 0.5)**; aplikacja ustawia go na środku korpusu, osobno od punktu zawieszenia. Grafik powinien przekazać dokładny środek korpusu w metadanych. Zawieszenie musi mieścić się w eksporcie; nie domalowujemy przypadkowego sznurka w kodzie.

W notesie co najmniej 70% powierzchni każdej strony pozostaje spokojnym, jasnym polem. W etykiecie środkowe 65% szerokości i 65% wysokości pozostaje wolne od ornamentów. Gracz widzi tam prawdziwy tekst lub wzorzec kresek, nie zdjęcie znaku.

## 4. P0 — Yuu

**Wygląd:** zachować Yuu zgodnego z przekazanym kierunkiem — liściastego opiekuna szkoły. Prototypowy model Rive może służyć do sprawdzenia ruchu i skali, ale nie wymusza upraszczania finalnego projektu.

Sześć plików PNG, każdy **1024 × 1024**, przezroczyste tło, wspólna skala i podstawa postaci **(0.5, 0.92)**. Żaden gest nie wychodzi poza płótno. Nie dodawać tekstu do postaci ani dymków do tych plików.

| ID | Plik w `assets/art/story/yuu/` | Poza | Zastosowanie |
|---|---|---|---|
| `char.yuu.neutral` | `yuu-neutral.png` | Spokojny, otwarty wyraz twarzy | Mapa, oczekiwanie, tryb bez animacji |
| `char.yuu.greet` | `yuu-greet.png` | Małe powitanie dłonią lub listkiem | Pierwsze wejście i powrót |
| `char.yuu.point` | `yuu-point.png` | Wskazuje w prawo i lekko w górę | Etykieta, szkoła, lampion |
| `char.yuu.think` | `yuu-think.png` | Zaciekawienie, namysł | Otwieranie notesu, pusta strona |
| `char.yuu.encourage` | `yuu-encourage.png` | Życzliwy, spokojny gest „sprawdźmy razem” | Błąd, „Nie wiem”, ponowna próba |
| `char.yuu.celebrate` | `yuu-celebrate.png` | Uśmiech i niewielki gest radości | Zakończenie części i pierwszy lampion |

Siódmy plik: **`assets/rive/story/yuu-story.riv`**, ID `char.yuu.rive`, przezroczysty artboard **`YuuStory`**, współrzędne 1024 × 1024 i ta sama podstawa postaci.

Proponowany kontrakt animacji do wykonania i późniejszego sprawdzenia z runtime projektu:

| Nazwa animacji | Długość / pętla | Treść |
|---|---|---|
| `Idle` | 4–6 s, pętla | Delikatny oddech/kołysanie i mrugnięcie; bez przemieszczania po scenie |
| `Greet` | 0.8–1.2 s, raz | Krótkie powitanie |
| `Point` | 0.8–1.2 s, raz | Wskazanie i powrót |
| `Think` | 1.2–2 s, raz | Spokojny namysł |
| `Encourage` | 0.8–1.2 s, raz | Łagodny gest wsparcia |
| `Celebrate` | 1–1.8 s, raz | Mała radość bez skakania przez cały ekran |

Domyślna maszyna stanów **`YuuStory`**: stan `Idle`, wejścia typu trigger `greet`, `point`, `think`, `encourage`, `celebrate`; każde przejście wraca do `Idle`. Reakcje na odpowiedź uruchamiane są dopiero po zapisaniu próby. Ostateczne nazwy należy zachować dokładnie albo dostarczyć uzgodnioną mapę nazw przed integracją.

Przekazać także edytowalne źródło: oddzielne oczy/powieki, usta, tułów, kończyny/listki i elementy potrzebne do tych gestów. Nie wystarczy nagranie MP4/GIF animacji. Nie są potrzebne chodzenie, bieg, atak, smutek po błędzie, obrót 360° ani animacja ust do każdego zdania.

## 5. P1 — materiały dla dalszych rozdziałów

Poniższe pozycje są zakresem następnej dostawy. Nie blokują wdrożenia rozdziału 1. ID i planowane ścieżki są również w [manifeście](story/art-manifest.v1.json).

| ID / pakiet | Co przygotować | Stany i eksport | Pierwsze użycie |
|---|---|---|---|
| `prop.postbox` | Skrzynka pocztowa przy istniejącym drzewie | Zamknięta i otwarta, 768 × 1024, PNG alpha, wspólny pivot | Rozdział 2 |
| `prop.envelope` | Koperta bez adresu | Otwarta i zamknięta, 768 × 512, PNG alpha | Rozdział 2 |
| `prop.stamps` | Dwa kosmetyczne stemple | Liść i kółko, osobne PNG 256 × 256; bez liter i kana | Rozdział 2 |
| `char.mina` | Mina z torbą | Pozy neutralna, powitanie, przekazanie listu, namysł, radość; po 1024 × 1024 PNG alpha; jedna wspólna baza | Rozdział 2 |
| `scene.workshop` | Widok stołu w pracowni | Tło 1200 × 1600 bez ruchomych narzędzi, postaci, napisów i lampionów | Rozdział 3 |
| `prop.workshop.kit` | Materiały na stole | Papier, szkielet lampionu i gotowy lampion, osobne PNG 768 × 768 | Rozdział 3 |
| `prop.lantern.ornaments` | Dwie ozdoby na wspólny lampion | Liście i łagodne fale, osobne maski PNG 512 × 768 w układzie lampionu | Rozdział 3 |
| `char.toma` | Toma z fartuchem | Neutralna, powitanie, praca przy stole, namysł, radość; po 1024 × 1024 PNG alpha | Rozdział 3 |
| `prop.bridge.marker` | Stały znak orientacyjny przy moście | Kamień z prostym motywem i pustą płytką, PNG 512 × 512; napis nakładany w UI | Rozdział 4 |
| `prop.bridge.hook` | Uchwyt na lampion | PNG alpha 512 × 768; lampion ponownie używa P0, nie jest wrysowany w uchwyt | Rozdział 4 |
| `scene.gathering` | Polana spotkań | Dzień i wieczór, identyczna kompozycja, po 1200 × 1600; bez postaci i ruchomych dekoracji | Rozdział 5 / 7 |
| `prop.gathering.kit` | Wyposażenie polany | Poduszki, stół i girlanda jako trzy nakładki na wspólnym płótnie 1200 × 1600 | Rozdziały 5–6 |
| `env.kigi.sky.evening` | Wieczorne niebo | Zamiennik warstwy nieba P0, 1200 × 1600; pozostałe warstwy korzystają z uzgodnionego filtra barwnego | Rozdział 7 |
| `fx.kigi.evening` | Lokalny blask okien na mapie | PNG alpha 1200 × 1600, bez poświat zdobywanych lampionów | Rozdział 7 |
| `ui.memory.frames` | Ramka pamiątki i zakładka | PNG alpha, odpowiednio 768 × 768 i 256 × 512; same ilustracje pamiątek pochodzą z już dostarczonych miejsc | Notes kampanii |

Mina i Toma mogą wejść w P1 jako statyczne postacie. Osobne Rive dla nich jest ulepszeniem P2, a nie warunkiem pojawienia się rozdziałów. Dla każdej postaci zachować wspólny pivot i skalę we wszystkich pozach.

Wieczór na mapie wymaga jednego uzgodnionego podglądu: nowe niebo + filtr istniejących warstw + osobne światła. Jeśli filtr źle działa z wybranym stylem, rozliczyć oddzielnie dodatkowe warianty warstw. Nie udawać, że nowe niebo samo zmieni słoneczne cienie na nocne oświetlenie.

## 6. P2 — nie zamawiać do pierwszego wdrożenia

- `concept.garden`: koncepcja ogrodu katakany, 1200 × 1600; bez udawania gotowej, interaktywnej mapy.
- `fx.ambient`: opcjonalne listki, delikatny ruch wody i świetliki. Brak wpływu na ocenę, możliwość pełnego wyłączenia.
- Rozbudowane animacje Miny i Tomy oraz dodatkowe motywy dekoracyjne lampionów.
- Osobne widoki innych pór roku dopiero po określeniu ich funkcji.

## 7. Co przygotuje aplikacja bez osobnego zamówienia graficznego

- Kana, rōmaji, dialogi, tytuły, liczby, polskie znaczenia i statusy nauki.
- Przyciski, pola odpowiedzi, obszary dotyku, paski postępu, dymki i panele z poprawnie skalującym się tekstem.
- Znaki i animacje kresek z katalogu oraz KanjiVG; grafik nie odrysowuje ich dla każdego zadania.
- Przejście lampionu między stanem zgaszonym i zapalonym oraz pulsowanie osobnej poświaty.
- Podświetlenie aktywnego miejsca, znaczniki wyboru i proste przesunięcie kartki do notesu.
- Ilustracje pamiątek wycięte z dostarczonych obiektów; bez ponownego zamawiania szkoły, mostku i poczty w niemal identycznej formie.
- Ikony standardowych czynności, np. odsłuch, powrót i zamknięcie, z przyjętego zestawu aplikacji.

Grafik powinien pokazać te elementy na makietach, aby ustalić styl i odstępy, ale nie wypalać całych paneli z tekstem w bitmapach. Podczas odczytu żadna ilustracja nie może zdradzać odpowiedzi. Reakcje i znaczenia pojawiają się dopiero po próbie.

## 8. Pakiet przekazania

```text
kigi-delivery-v1/
  source/                   # edytowalne źródła sceny, rekwizytów i Yuu
  runtime/
    assets/art/story/kigi/layers/
    assets/art/story/kigi/props/
    assets/art/story/kigi/fx/
    assets/art/story/yuu/
    assets/rive/story/yuu-story.riv
  metadata/
    kigi-layout.json         # faktyczne pozycje, pivoty, kolejność, pola dotyku
    animation-names.txt      # artboard, maszyna, wejścia, animacje
    credits.txt             # autor, data, prawa użycia; źródła zewnętrzne, jeśli występują
  previews/
    village-before.png
    village-after.png
    lesson-with-keyboard.png
    yuu-contact-sheet.png
```

Nazwy plików: małe litery ASCII i łączniki; bez spacji, polskich znaków i przyrostków „final-final2”. Wersja paczki w nazwie katalogu; nazwy w runtime stabilne. Podglądy mogą zawierać przykładowy tekst, ale pliki runtime muszą być czyste.

Do metadanych obiektu dodać `asset_id`, `file`, `canvas_px`, `pivot_normalized`, a w razie potrzeby `text_safe_rect_normalized` i `body_center_normalized`. Mapa używa osobnego układu współrzędnych sceny. Plik `.riv` musi być samowystarczalny lub mieć jawnie wymienione wszystkie dodatkowe zasoby; nie może po cichu wymagać obrazów z chmury.

## 9. Odbiór przed integracją

1. Nałożenie sześciu warstw odtwarza zatwierdzoną mapę. Nie ma luk, podwójnych obiektów ani przesunięcia mostku między wariantami.
2. W czystej szkole nie ma lampionu. Wyświetlenie `off`, a potem `on` nie zmienia położenia zawieszenia.
3. Każdy PNG z przezroczystością wygląda dobrze na białym, ciemnozielonym i docelowym tle.
4. Yuu ma tę samą skalę i podstawę w sześciu pozach i Rive. Żaden gest nie jest obcięty.
5. Znak あ i słowo いいえ pozostają czytelne na etykiecie w rzeczywistym rozmiarze telefonu. Bez ornamentu przechodzącego przez kreski.
6. Podglądy na szerokościach 360 i 430 jednostek logicznych pokazują szkołę, Yuu i lampion. Duży tekst oraz klawiatura nie zasłaniają odpowiedzi i przycisków. To kontrola integracji, nie wymóg rysowania osobnej bitmapy dla każdego rozmiaru.
7. Wyłączenie ruchu zostawia pełną, zrozumiałą scenę i czytelną nagrodę. Informacja o wyniku nie opiera się wyłącznie na kolorze.
8. Rive otwiera się w runtime przypiętym w projekcie (`rive: 0.14.11` w chwili spisania briefu); nazwy i reakcje są sprawdzone w aplikacji. Sama poprawność w edytorze nie potwierdza integracji.
9. Pliki są lokalne i opisane w manifeście. Sprawdzamy rozmiar paczki i pamięć na docelowym telefonie; nie utrzymujemy w pamięci wszystkich scen całej kampanii naraz.

## 10. Krótka treść do przesłania grafikowi

> Rozwijamy historię Kigi jako „Ścieżkę Lampionów”. Yuu i gracz przygotowują małe spotkanie mieszkańców, a każda lekcja zostawia pamiątkę w wiosce. Pierwszy rozdział dzieje się wyłącznie na obecnej polanie i przy szkole: Yuu otwiera notes, prowadzi przez pierwsze znaki, a na końcu przy szkole zapala się lampion. Proszę utrzymać przekazany wcześniej kierunek graficzny i przygotować zestaw P0 z tego dokumentu: sześć osobnych warstw wioski, lampion zgaszony i zapalony z osobną poświatą, notes zamknięty i otwarty, pustą etykietę oraz sześć póz i plik Rive Yuu. Wszystko bez wrysowanych tekstów i znaków. Mina, Toma, poczta, pracownia i świąteczna polana to kolejna dostawa; nie są potrzebne do pierwszego uruchomienia.
