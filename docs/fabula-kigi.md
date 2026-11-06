# KanaYu — Kigi: Ścieżka lampionów

Scenariusz produkcyjny v1 · 30 października 2026

**Cel:** opowieść, którą można wdrażać etapami w obecnej aplikacji Flutter. Pierwszy rozdział korzysta z istniejących 10 znaków, trzech aktywnych słów i nagrody `first-lantern`. Dokument zawiera również dalszą fabułę, aby zamawiane grafiki tworzyły jeden świat.

**Status:** przygotowany scenariusz, nie zaimplementowana funkcja. Kigi, Yuu, szkoła, strumień, mostek, pierwszy lampion i zapowiedź ogrodu już występują w projekcie. Tytuł całej opowieści, notes poprzedniej opiekunki, pozostali mieszkańcy, ich historie oraz dalsze zadania są nowymi propozycjami rozwijającymi te podstawy. Nie zmieniają wyglądu przekazanego grafikowi; opisy nowych postaci określają rolę i rekwizyty, a ich finalna forma należy do tego samego kierunku artystycznego.

Materiały towarzyszące:

- [Lista grafik i instrukcja przekazania plików](grafiki-kigi.md).
- [Scenariusz pierwszego rozdziału w JSON](story/first-light.v1.json).
- [Manifest zamawianych zasobów w JSON](story/art-manifest.v1.json).
- [Kontrakt podłączenia treści do aplikacji](story/README.md).

## 1. Opowieść w jednym akapicie

W małej leśnej wiosce Kigi trwa przygotowanie Wieczoru Lampionów: spotkania, podczas którego mieszkańcy opowiadają historie miejsc ważnych dla ich społeczności. Yuu, liściasty opiekun szkoły, po raz pierwszy organizuje całą trasę. Ma stary notes swojej poprzedniczki, ale notes jest zbiorem drobnych wspomnień, a nie instrukcją organizacji święta. Osoba grająca dołącza jako nowa osoba w szkole i pomaga poznawać znaki, odczytywać przygotowane przez Yuu etykiety, odwiedzać sąsiadów i zapisywać nowe historie. Każdy rozdział kończy się trwałą zmianą w wiosce. W finale okazuje się, że ostatnią stronę notesu pozostawiono pustą celowo: opowieść Kigi ma również pomieścić kogoś, kto właśnie do niej dołączył.

## 2. Świat i ton

Kigi jest zamieszkane, zadbane i bezpieczne od pierwszego wejścia. Przygotowujemy nowe wydarzenie; nie naprawiamy świata zniszczonego nieobecnością użytkownika. Lampiony są zwykłymi przedmiotami o emocjonalnym znaczeniu. Nie pobierają energii z poprawnych odpowiedzi i nie gasną po błędach.

Wieczór Lampionów jest fikcyjnym zwyczajem tej wioski, a nie opisem konkretnego japońskiego święta. Nie ma daty w kalendarzu ani odliczania. Nadchodzi wtedy, kiedy użytkownik dojdzie do finału. Pora dnia w scenach wynika z rozdziału, nie z zegara telefonu.

Dialogi po polsku są krótkie i naturalne. Mieszkańcy mają własne małe sprawy: znaleźć dobre miejsce na spotkanie, przygotować zaproszenia, zachować czyjąś historię. Nie wygłaszają wykładów o algorytmie nauki. Japońskie zadania pozostają wyraźnie oddzielone od polskiego dialogu.

Pojedynczy znak hiragany przedstawiamy jako zapis dźwięku. Nie dopisujemy mu fikcyjnego znaczenia typu „あ oznacza światło”. Fabularne etykiety to materiały ćwiczeniowe przygotowane w szkole, nie rzekome autentyczne japońskie szyldy z przypadkowych sylab.

## 3. Bohaterowie

| Postać | Rola w historii | Charakter i mały problem | Funkcja w grze / grafika |
|---|---|---|---|
| Osoba grająca | Nowa osoba w szkole; współtworzy trasę i nową stronę notesu | Na początku zna niewiele znaków, ale może od razu uczestniczyć w życiu wioski | Perspektywa gracza bez widocznego awatara; bez konieczności rysowania płci, ubiorów i personalizacji |
| Yuu | Liściasty opiekun szkoły i przewodnik | Troskliwy i trochę skrupulatny. Chce dobrze przygotować pierwsze święto pod swoją opieką; uczy się, że nie musi odtwarzać wszystkiego dokładnie po poprzedniczce | Jedyna wymagana postać rozdziału 1. Wita, wskazuje, czeka, wspiera i cieszy się spokojnie |
| Mina — nowa propozycja | Osoba roznosząca pocztę | Energiczna, zna wszystkich, lecz zakłada, że wszyscy pamiętają drogi tak dobrze jak ona | Od rozdziału 2. Proponowana sylwetka małego leśnego ptaka z torbą; bez wymogu latania i animacji podróży |
| Toma — nowa propozycja | Rzemieślnik przygotowujący lampiony | Uważny i spokojny. Przechowuje różne stare modele i nie chce wybierać jednego „najlepszego” | Od rozdziału 3. Proponowana sylwetka żółwia z fartuchem; pracuje przy stole, nie nosi wszystkich przedmiotów w każdej pozie |
| Poprzednia opiekunka | Autorka notesu | Jej uwagi mówią o gościnności, nie o idealnym wykonaniu zadań | Obecna wyłącznie w krótkich cytatach po polsku. Bez portretu, retrospekcji i nowego zestawu animacji |

Mina i Toma to imiona fabularne, nie materiał językowy. W pierwszej dostawie nie są potrzebni. Po drugiej stronie strumienia nie wprowadzamy jeszcze kolejnego bohatera: ogród zostaje zapowiedzią następnej opowieści.

## 4. Miejsca i główne rekwizyty

Całość jest zbiorem dotykanych scen 2D. Gracz wybiera miejsce na mapie lub przycisk aktywności. Nie potrzebujemy swobodnego chodzenia, kolizji, izometrycznej siatki ani animacji postaci w wielu kierunkach.

- **Polana i szkoła:** punkt powrotu, start lekcji, pierwszy lampion. Znany układ świata pozostaje rozpoznawalny przez całą kampanię.
- **Drzewo z pocztą:** to samo duże drzewo przy polanie, później z osobną skrzynką i uchwytem na listy.
- **Pracownia Tomy:** jeden z domków widocznych w tle. Zbliżenie stołu wystarcza za osobną scenę.
- **Mostek:** od początku istnieje i jest cały. W rozdziale 4 zyskuje oznaczenie oraz lampion, a nie naprawę po katastrofie.
- **Polana spotkań:** nowe miejsce w pobliżu strumienia; kilka poduszek, stół i girlanda zmieniają je w miejsce finału.
- **Ogród za strumieniem:** widok w oddali i przyszły kierunek katakany. Nie jest dostępną lokacją w pierwszym pakiecie.
- **Notes ścieżki:** zamknięty i otwarty; strony, tekst, ilustracje pamiątek i znaczniki są nakładane osobno przez aplikację. To notes fabularny, wizualnie powiązany z istniejącym ekranem „Moje znaki”, lecz nie zastępuje wyników nauki.
- **Papierowa etykieta:** jeden neutralny nośnik wszystkich ćwiczonych znaków. Jej kolor i ornament nie kodują poprawnej odpowiedzi.

## 5. Zasady fabuły i postępu

1. Ukończenie zadania oznacza udzielenie pierwszej odpowiedzi lub wybranie „Nie wiem jeszcze”, a następnie obejrzenie informacji zwrotnej. Nie wymagamy bezbłędnej serii.
2. Lampion i inne nagrody otrzymuje się za ukończenie rozdziału, nie za deklarację opanowania materiału. Stan utrwalenia nadal wyznacza istniejący system nauki.
3. Błąd nie cofa sceny, nie obraża postaci i nie odbiera nagrody. Yuu proponuje ponowne spotkanie ze znakiem.
4. Rozdział można przerwać i wznowić. Nie ma limitu czasu, energii, żyć, utraty serii ani dziennego obowiązku.
5. Pominięcie dialogu pomija wyłącznie dialog. Nauka pozostaje dostępna także w trybie „Sama nauka”, z tymi samymi nagrodami za ukończony materiał.
6. Pisanie jest dodatkowe. Nie blokuje kolejnych rozdziałów i nie daje przewagi koniecznej do finału.
7. Czytanie słowa nie zalicza automatycznie znaków, z których słowo się składa. Rozpoznawanie z wyboru nie jest dowodem samodzielnego odczytu.
8. Grafika, podświetlenie, reakcja postaci, polskie znaczenie i wymowa wzorcowa nie zdradzają rozwiązania przed pierwszą odpowiedzią. Znaczenie słowa pokazujemy po odpowiedzi.
9. Powrót do wcześniej obejrzanej scenki jest bezpłatny i nie nalicza kolejnej nagrody ani prób nauki. Dopiero jawne rozpoczęcie ćwiczeń tworzy próby.
10. Wszystkie trwałe efekty są zapisywane lokalnie. Wioska pozostaje taka sama także po dłuższej przerwie.

## 6. Rozdział 1 — Pierwsze światło

**Zakres do pierwszego wdrożenia:** Yuu, obecna polana, szkoła, notes, 10 znaków, trzy słowa i jeden lampion. Fabuła obudowuje istniejącą lekcję. Nie wymaga nowych znaków, nowych nagrań wymowy ani nowych bohaterów.

**Cel gracza:** pomóc Yuu przygotować pierwszy przystanek Ścieżki Lampionów przy szkole.

**Cel nauki:** poznać あいうえお i かきくけこ; spróbować odczytać je samodzielnie; odczytać いいえ, ここ i いい. Ukończenie nie oznacza utrwalenia.

### Scena 1. Ktoś na polanie — `c01.arrival`

Obraz: polana w zwykłym dziennym świetle. Yuu stoi przy ścieżce. Lampion przy drzwiach jest niezapalony. Nie ma dramatycznej mgły, ruin ani pustej wioski.

Yuu, gest powitania:

> „Witaj w Kigi. Jestem Yuu, opiekuję się tutejszą szkołą.”

> „Przygotowujemy Wieczór Lampionów. Każde światło na ścieżce będzie przypominało małą historię naszej wioski.”

Przycisk: **„Pokaż mi”**. Drugie wyjście: **„Rozejrzę się później”** — zamyka rozmowę, zachowuje miejsce i nie przyznaje nagrody.

### Scena 2. Notes bez instrukcji — `c01.notebook`

Yuu otwiera notes. Na pierwszej stronie aplikacja pokazuje prosty rysunek szkoły, a obok pusty kontur lampionu. To mapa pamiątek, nie tabela ocen.

> „Poprzednia opiekunka zostawiła ten notes. Są w nim miejsca, wspomnienia i trochę wolnego miejsca na nowe.”

> „Zacznijmy przy szkole. Przygotowałem dziesięć znaków do naszej pierwszej lekcji.”

Przycisk: **„Wejdź do szkoły”**. Przejście do spokojnej oprawy ćwiczeń; pełna ilustracja polany nie musi być widoczna pod klawiaturą.

### Scena 3. Pierwsze pięć dźwięków — `c01.vowels.learn`

Yuu wskazuje pustą papierową etykietę:

> „Na tych kartach są znaki hiragany. Każdy zapisuje dźwięk. Najpierw je poznamy, potem spróbujesz je odczytać.”

Pięć ekranów poznawania: **あ → い → う → え → お**. Znak, rōmaji, przycisk wymowy i animacja kresek pochodzą z katalogu. Dekoracyjna etykieta jest identyczna dla wszystkich znaków.

Przycisk każdego ekranu: **„Dalej”**. Obejrzenie znaku jest ekspozycją, nie ocenianą odpowiedzią.

### Scena 4. Etykiety do notesu — `c01.vowels.read`

> „Spróbuj odczytać znak na każdej karcie. Jeśli nie pamiętasz, sprawdzimy go razem.”

Pięć prób odczytu w kolejności **う → あ → お → い → え**, zgodnej z bieżącym prototypem. Na karcie wyłącznie znak; pole odpowiedzi w rōmaji i przycisk „Nie wiem jeszcze”. Po zatwierdzeniu można pokazać odczyt, odsłuch i neutralną reakcję Yuu.

Po przejściu kart notes zyskuje mały ornament liścia. Jest to wskaźnik przejścia części zadania, nie osobna waluta ani trwała nagroda do zbierania.

### Scena 5. Dobra chwila na oddech — `c01.pause`

Yuu odkłada notes:

> „Pierwsza część za nami. Możemy zrobić przerwę albo poznać następne pięć znaków.”

Przyciski: **„Poznaj kolejne pięć”**, **„Wróć na polanę”**. Przy powrocie aplikacja zachowuje krok; główny przycisk na polanie staje się „Kontynuuj: Pierwsze światło”. Nie ma kary za przerwę.

### Scena 6. Drugi plik kart — `c01.k.learn` i `c01.k.read`

> „Teraz poznamy pięć kolejnych dźwięków. Z tych znaków za chwilę złożą się pierwsze słowa.”

Poznawanie: **か → き → く → け → こ**. Następnie odczyt: **く → か → こ → き → け**. Zasady i oprawa pozostają te same. Nie tworzymy nowej mechaniki tylko po to, aby pokazać inne tło.

### Scena 7. Trzy małe wiadomości — `c01.words`

> „Znaki mogą tworzyć całe słowa. Odczytajmy trzy krótkie wiadomości, a potem wybierzemy miejsce na lampion.”

Każde słowo pojawia się na tej samej neutralnej karcie. Kolejność pozostaje zgodna z aktywnym katalogiem:

| Słowo | Odpowiedź z katalogu | Dopiero po próbie: znaczenie i dialog | Drobna akcja fabularna |
|---|---|---|---|
| いいえ | `iie` | „いいえ znaczy «nie».” Yuu: „Nie musimy dziś zrobić wszystkiego. Jeden lampion to dobry początek.” | Yuu zamyka dalsze strony notesu; nie pokazuje ich jako niezaliczonych |
| ここ | `koko` | „ここ znaczy «tutaj».” Yuu: „Tutaj, przy wejściu. To będzie nasz pierwszy przystanek.” | Dopiero teraz wskazuje uchwyt przy szkole |
| いい | `ii` | „いい znaczy «dobry», «w porządku».” Yuu: „To dobre miejsce. Przygotowania pierwszego przystanku są gotowe.” | Lampion czeka na pokazanie nagrody |

Te wypowiedzi są polską narracją po ćwiczeniu, nie pełnymi japońskimi dialogami do oceny. Nie wracamy do wycofanych z lekcji słów いえ, かお i あき.

### Scena 8. Pierwszy lampion — `c01.lantern`

Po zapisaniu zakończenia lekcji gracz wraca na polanę. Yuu wskazuje lampion. Przycisk: **„Zobacz pierwsze światło”**. Dotknięcie uruchamia krótką prezentację: lampion rozświetla się, pojawia się łagodna poświata, Yuu uśmiecha się. Całość około 1–2 sekund, możliwa do pominięcia. Przy ograniczeniu ruchu od razu pokazujemy stan końcowy.

> „Pierwsze światło jest na miejscu. To pamiątka naszej pierwszej lekcji.”

> „Nie trzeba pamiętać wszystkiego od razu. Do znaków będziemy wracać, a lampion zostanie.”

**Trwała zmiana:** `first-lantern` przy szkole; nigdy drugi lampion za ponowienie tego rozdziału. Nagroda jest przyznana po zakończeniu nauki, przed animacją, aby zamknięcie aplikacji nie mogło jej zgubić.

### Scena 9. Pierwsza nowa strona — `c01.ending`

Na stronie notesu pojawia się szkoła z zapalonym lampionem. Tekst pamiątki:

> „Pierwsze światło. Przy szkole zaczęła się nowa ścieżka.”

Yuu:

> „Następnym razem zajrzymy pod duże drzewo. Mina przygotowuje tam pocztę na nasze spotkanie.”

Przyciski: **„Wróć na polanę”** i drugorzędne **„Zobacz moje znaki”**. Zapowiedź Miny jest tekstowa; jej grafika nie jest wymagana w rozdziale 1. Gdy rozdział 2 nie jest jeszcze wydany, UI mówi „Kolejny rozdział w przygotowaniu”. Nie wyświetla aktywnego zadania bez treści.

### Co dzieje się przy pomyłce

| Sytuacja | Tekst | Zachowanie świata |
|---|---|---|
| Poprawna pierwsza odpowiedź | „Tak, ten znak czytamy «{reading}».” | Krótka życzliwa reakcja; bez gwałtownego skakania |
| Błąd | „Ten znak czytamy «{reading}». Przyjrzyjmy mu się jeszcze raz.” | Yuu wskazuje kartę; nic nie gaśnie |
| „Nie wiem jeszcze” | „Sprawdźmy razem: «{reading}».” | Odsłonięcie odpowiedzi i możliwość odsłuchu |
| Powrót znaku po błędzie | „Jeszcze jedno spotkanie z tym znakiem.” | Odrębna korekta, bez dodatkowego zaliczania pamięci |
| Nie udał się zapis | „Nie udało się zapisać tego kroku. Spróbuj ponownie.” | Bez przesunięcia sceny i bez animacji nagrody |
| Powrót po przerwie | „Dobrze znów cię widzieć. Zatrzymaliśmy się tutaj.” | Kontynuacja od zapisanego kroku |

## 7. Dalsza fabuła — pełny łuk pierwszej kampanii

Rozdziały 2–7 wymagają rozbudowy katalogu. Podane grupy znaków są zakresem planowanym, nie listą już dostępnych lekcji. Nowe słowa, konteksty partykuł i nagrania wymagają osobnego opracowania językowego. Nie stosujemy nieweryfikowanych zdań jako materiału ocenianego.

### Rozdział 2. List spod wielkiego drzewa

**Nowy materiał:** さしすせそ, łącznie 15 podstawowych znaków. **Miejsce:** poczta pod drzewem. **Postać:** Mina.

1. Przy drzewie czeka skrzynka i torba Miny. Mina ma przygotowane zaproszenia, ale zauważa, że jej opis drogi zaczyna się od „tam, gdzie zawsze”.
2. Yuu proponuje dopisać do zaproszeń małe piktogramy przystanków. W szkole przygotowuje pięć nowych etykiet do ćwiczeń; poznajemy nową grupę i odczytujemy ją na osobnych kartach.
3. W minigrze „Poczta pod drzewem” odczytanie każdej karty odsłania jeden element zaproszenia. Dopiero po odpowiedzi ilustracja wskazuje miejsce. Gracz dotyka „Włóż do koperty”; nie zgaduje słów z rysunku.
4. Jedno zaproszenie nie ma odbiorcy. Mina wyjaśnia, że co roku zostawia jedno dla osoby, która pierwszy raz pojawi się w Kigi.
5. Gracz wybiera jeden z dwóch dekoracyjnych stempli na swojej kopercie: liść lub kółko. Wybór jest kosmetyczny i nie zmienia wyniku nauki.
6. Skrzynka zostaje otwarta, obok pojawia się uchwyt z gotowymi zaproszeniami. W notesie zostaje pamiątka „Miejsce dla kogoś nowego”.

Dialog otwierający, Mina: „Wiem, gdzie mieszkają wszyscy. Tylko czasem zapominam, że ktoś jeszcze nie zna naszych ścieżek.”

Dialog finałowy, Yuu: „Pierwsze zaproszenie było dla ciebie. Następne zostawimy dla kogoś, kto dopiero nadejdzie.”

**Nagroda:** poczta przy drzewie i pierwsza koperta w notesie. **Łącznik:** Mina prosi o zabranie pustej etykiety do pracowni Tomy.

### Rozdział 3. Pracownia różnych świateł

**Nowy materiał:** たちつてと, następnie なにぬねの; łącznie 25 podstawowych znaków. **Miejsce:** pracownia. **Postać:** Toma.

1. Toma pokazuje stół z kilkoma formami lampionów. Nie może zdecydować, czy wszystkie na święcie powinny wyglądać jednakowo.
2. W pierwszej części poznajemy grupę T; po jej odczytaniu przygotowujemy papierowy korpus. Przedmioty przesuwają się automatycznie po zakończonym zadaniu. Nie ma testu zręczności.
3. Następuje naturalny punkt przerwy. W drugiej części poznajemy grupę N i kończymy etykiety pracowni.
4. Yuu znajduje w notesie zdanie poprzedniczki: „Ten przy moście był trochę krzywy. I tak wszyscy go pamiętali”. To żartobliwe wspomnienie, nie instrukcja nauki pisma.
5. Toma decyduje, że przygotuje różne lampiony, bo każdy może opowiadać inną historię. Gracz wybiera ornament jednej pamiątki; bryła lampionu pozostaje wspólna technicznie.
6. Przy wejściu pracowni pojawia się gotowy lampion i porządek na stole. Toma prosi, żeby sprawdzić, z którego miejsca przy strumieniu najlepiej widać światło.

Dialog otwierający, Toma: „Ten jest okrągły, tamten wąski. Wszystkie świecą. Jeszcze nie wiem, czy muszą wyglądać tak samo.”

Dialog finałowy: „Zostawmy im trochę własnego charakteru. Dzięki temu każdy znajdzie swój ulubiony.”

**Nagroda:** oświetlona pracownia i pamiątka papierowego lampionu. **Łącznik:** wyprawa na mostek.

### Rozdział 4. Dwie strony strumienia

**Nowy materiał:** はひふへほ, następnie まみむめも; łącznie 35 podstawowych znaków. **Miejsce:** istniejący mostek.

1. Mina przychodzi od strony szkoły, Yuu od strony polany spotkań. Oboje wskazują „prawą stronę mostku”, ale patrzą w przeciwnych kierunkach.
2. Wspólnie wybierają stały punkt orientacyjny: kamień przy początku mostku. Gracz ćwiczy nowe znaki w dwóch blokach, rozdzielonych krótką scenką.
3. Minigra „Przystanki na ścieżce” przedstawia kolejne neutralne karty. Po odczycie aplikacja odsłania mały fragment schematu trasy. Fragmenty układają się automatycznie; ich kolejność nie jest zagadką językową.
4. Opcjonalne „Echo strumienia” ćwiczy dźwięk → wybór znaku, jeśli powstanie obsługa takiego zadania. To dodatkowe rozpoznawanie, nie warunek ukończenia rozdziału.
5. Gracz dotyka stałego uchwytu. Lampion pojawia się przy wejściu na mostek; cała konstrukcja pozostaje bezpieczna i nie zmienia kształtu.
6. Ze środka mostku po raz pierwszy widać polanę spotkań. Ogród w dalszym planie nadal jest tylko spokojną zapowiedzią.

Dialog otwierający, Mina: „Po mojej prawej jest inaczej niż po twojej. Przyda nam się coś, co oboje rozpoznamy.”

Dialog finałowy, Yuu: „Teraz łatwiej opowiedzieć komuś drogę. Zacznij przy kamieniu, potem idź do światła.”

**Nagroda:** oświetlony mostek i czytelny punkt orientacyjny. **Łącznik:** widoczna polana czeka na przygotowanie.

### Rozdział 5. Pusta strona

**Nowy materiał:** やゆよ, らりるれろ, わをん; trzy krótkie bloki, łącznie 46 podstawowych znaków. **Miejsce:** polana spotkań.

1. Bohaterowie przynoszą poduszki, stół i girlandę. Yuu sprawdza notes i znajduje pustą ostatnią stronę. Obawia się, że przeoczył najważniejszy punkt przygotowań.
2. Po pierwszym bloku pojawiają się poduszki, po drugim stół. Gracz wykonuje odczyty i widzi praktyczny postęp, niezależnie od liczby pomyłek.
3. Na odwrocie strony Yuu odnajduje krótki dopisek: „Zostaw miejsce na historię, której jeszcze nie znasz”.
4. Mina przypomina zaproszenie bez adresata, a Toma lampiony o różnych kształtach. Pusta strona nie jest usterką: zostawiono ją dla nowego spotkania.
5. Po trzecim bloku gracz wybiera, jaka pamiątka ma znaleźć się na stronie: szkoła, poczta albo mostek. Nie wpisuje imienia i nie musi tworzyć własnej grafiki. Aplikacja wykorzystuje już posiadane ilustracje.
6. Yuu przyznaje, że chciał urządzić wszystko tak jak poprzedniczka. Teraz może dopisać własny rozdział razem z mieszkańcami.

Dialog otwierający, Yuu: „Sprawdziłem cały notes. Ostatnia strona jest pusta. Może właśnie tutaj miała być instrukcja?”

Dialog finałowy: „To miejsce nie czekało na instrukcję. Czekało na naszą historię.”

**Nagroda:** przygotowana polana i nowa strona notesu. **Uwaga językowa:** を wymaga właściwego kontekstu; nie pojawia się jako izolowany bodziec w grze słuchowej.

### Rozdział 6. Małe znaki, nowe brzmienia

**Nowy materiał:** がぎぐげご, ざじずぜぞ, だぢづでど, ばびぶべぼ, ぱぴぷぺぽ — 25 form z dakuten/handakuten. To osobny etap po 46 podstawowych znakach, podzielony na pięć małych bloków.

1. Toma przygotowuje ostatnie karty dla szkolnego kącika na święcie. Yuu zauważa, że poznane kształty mogą otrzymać dodatkowe małe znaki i zmienić odczyt.
2. Każdy blok ma poznawanie, samodzielny odczyt i krótką scenkę przygotowania polany. Nowe oznaczenia pojawiają się w poprawnym tekście i wzorcach, nigdy jako luźna ozdoba, którą można przykleić w dowolne miejsce.
3. Gracz pomaga przygotować pięć części girlandy. Jej liście są motywem dekoracyjnym; nie symbolizują fikcyjnych znaczeń kany.
4. Yuu odnajduje swoje pierwsze przygotowane zaproszenie i zauważa drobną niedoskonałość rysunku. Tym razem nie wyrzuca go i nie zaczyna wszystkiego od nowa.
5. Mieszkańcy są gotowi. Przycisk „Rozpocznij Wieczór Lampionów” można nacisnąć później — finał nie ucieknie.

Dialog otwierający, Yuu: „Znasz już te kształty. Teraz zobaczysz, jak mały znak obok potrafi zmienić ich brzmienie.”

Dialog finałowy: „Mamy wszystko, czego potrzeba na dzisiejsze spotkanie. Resztę historii dopiszemy z czasem.”

**Nagroda:** girlanda i gotowość finału. **Ograniczenia:** じ/ぢ oraz ず/づ nie są sztucznie rozróżniane samym dźwiękiem. Nie wprowadzamy tutaj połączeń typu きゃ, małego っ ani reguł długich samogłosek jako rzekomo już przerobionych. Te zagadnienia wymagają osobnych późniejszych lekcji.

### Rozdział 7. Wieczór Lampionów

**Nowy materiał:** brak. **Miejsce:** znana trasa i polana spotkań. **Funkcja:** domknięcie historii, nie egzamin z progiem zaliczenia.

1. Gracz uruchamia finał. Scena przechodzi w łagodny wieczór; zdobyte lampiony są widoczne od razu.
2. Trzy krótkie przystanki przypominają szkołę, pocztę i mostek. W każdym można odczytać jedną znaną kartę lub pominąć dodatkowe ćwiczenie. Pomyłka ani pominięcie nie zatrzymują spotkania.
3. Mina zawiesza niezapisane zaproszenie przy wejściu. Toma ustawia różniące się lampiony. Yuu otwiera nową stronę notesu z pamiątką wybraną przez gracza.
4. Każda postać dodaje jedno zdanie. Mina: „Zostawiliśmy miejsce przy stole”. Toma: „I trochę różnych świateł”. Yuu: „A teraz mamy też nową historię”.
5. Notes pokazuje wpis: „Wieczór Lampionów. W Kigi pojawiło się miejsce na kolejne spotkanie”. Bez twierdzenia „znasz już cały japoński” lub „hiragana opanowana”.
6. Gracz wybiera „Zostań chwilę” albo „Wróć na polanę”. Scenę święta można później odtworzyć bez dodatkowych prób i nagród.
7. W epilogu Yuu spogląda za strumień: „W ogrodzie są jeszcze inne znaki. Zajrzymy tam, kiedy przyjdzie pora”. Katakana pozostaje przyszłą, osobną kampanią.

**Nagroda:** zapisany Wieczór Lampionów w notesie i możliwość oglądania wieczornej polany. Nauka i powtórki nadal są dostępne; fabuła nie wymusza powtarzania całej kampanii.

## 8. Minigry jako wspólne mechaniki

| Mechanika | Działanie gracza | Wariant fabularny | Dane nauki | Kiedy wdrażać |
|---|---|---|---|---|
| Etykiety Yuu | Wpisuje odczyt jednej karty | Przygotowanie pierwszego przystanku, potem etykiet w pracowni | `kana_reading`, `text`, ocena automatyczna | Rozdział 1; bazuje na istniejącym ćwiczeniu |
| Trzy wiadomości / Poczta | Odczytuje słowo, po informacji zwrotnej odkłada kartę | Pierwsze słowa, później zaproszenia | `word_reading`, `text`; bez zaliczania kart znaków | Trzy wiadomości teraz, poczta po rozszerzeniu treści |
| Przystanki na ścieżce | Odczytuje kartę; fragment trasy odsłania się po próbie | Przygotowanie drogi do polany | `kana_reading`, `text` | Rozdział 4; ten sam komponent odpowiedzi |
| Echo strumienia | Słucha i wybiera znak z neutralnych kafelków | Opcjonalna zabawa przy wodzie | `kana_listening`, `choice`; rozpoznawanie, bez FSRS karty czytania | Dopiero po implementacji oceny wyboru i zasad homofonów |
| Pracownia pisania | Pisze z pamięci, zatwierdza, porównuje i samodzielnie ocenia | Osobista kartka w szkolnym kąciku | `kana_writing`, `drawing`, `self` | Opcjonalnie; bazuje na obecnym pisaniu |

Dotykanie koperty, wybór ornamentu, zapalenie lampionu i przewracanie strony nie są zadaniami językowymi. Nie tworzą ocen FSRS. Cała kampania może działać przy trzech wspólnych układach: mapa, dialog, karta ćwiczenia.

## 9. Powroty do Kigi

Po ukończeniu rozdziału główny przycisk prowadzi do następnego dostępnego rozdziału. Dostępne powtórki mają osobny wyraźny przycisk. Użytkownik może zakończyć wizytę bez rozpoczynania nowej treści.

- Gdy są powtórki: „Kilka poznanych znaków czeka na kolejne spotkanie”. Liczbę i poprawną odmianę podaje UI.
- Gdy nie ma powtórek: „Na dziś nic nie czeka. Możesz zajrzeć do notesu albo odpocząć”.
- Po dłuższej przerwie: „Dobrze znów cię widzieć. Twoje światła nadal są na miejscu”.
- Po ponownej prezentacji finału: „Możemy wrócić do tego wieczoru, kiedy zechcesz”. Bez odtwarzania ocenionych prób.

Powtórki mogą być otwierane z Yuu i notesu, ale nie zamieniają się w codzienny obowiązek „utrzymania wioski”. Bohaterowie nigdy nie mówią, że cierpieli podczas nieobecności użytkownika.

## 10. Kolejność produkcji

1. Pierwszy rozdział: zapis wznawiania, dialogi, neutralna etykieta, osobny lampion, reakcje Yuu i pamiątka w notesie.
2. Kolejne grupy podstawowej hiragany, Mina, Toma i trzy rozszerzenia mapy. Każdy rozdział można udostępniać osobno.
3. Formy z dakuten/handakuten i finał; osobno zatwierdzone treści językowe.
4. Opcjonalne rozpoznawanie słuchowe i dalsze zagadnienia zapisu.
5. Katakana i ogród jako następna kampania, z własnym scenariuszem i listą materiałów.

Wszystkie szczegóły interakcji i plików dla pierwszego etapu są opisane w [kontrakcie wdrożenia](story/README.md) oraz [liście grafik](grafiki-kigi.md). Zamówienie pierwszej dostawy obejmuje wyłącznie oznaczenia **P0**.
