# Kigi — mapa z nowymi detalami, v2

## Wynik

Mapa 2560 × 3840 px złożona z 12 osobno wygenerowanych fragmentów. To nowe detale materiałów, roślin, kamieni, dachów i wody, a nie interpolacja starej bitmapy. Wbudowany imagegen przerysował każdy wycinek z zachowaniem układu referencji. Surowe wyniki zapisano w `generated/`; ich rzeczywiste rozmiary podaje `manifest.json`. Następnie obrazy zmniejszono do wspólnej gęstości 2.5 piksela na jednostkę świata. Obraz końcowy nie był powiększany.

- `map-master-2560x3840.png`: pełny obraz wynikowy.
- `map-preview.png`: pomniejszony podgląd.
- `tiles/`: 12 finalnych fragmentów do gry (siatka 4 × 3). Rdzeń 640 × 1280 px; wspólne marginesy do 4 px z każdej strony.
- `map.tscn`: scena składająca mapę w Godot 4.
- `detail-school.png`, `detail-bridge.png`, `detail-postbox.png`: zbliżenia w natywnej gęstości wynikowej.
- `comparison-old-left-new-right.png`: ten sam fragment, po lewej stara mapa powiększona, po prawej nowo wygenerowane detale.
- `manifest.json`: pozycje, skala, rozmiary i pochodzenie fragmentów.
- `generation-prompt.txt`: wspólny prompt użyty osobno dla każdego z 12 wycinków; tryb wbudowany imagegen.

## Dopasowanie

Referencje obejmowały rdzenie 256 × 512 jednostek starej mapy oraz 32 jednostki kontekstu po każdej stronie. Sąsiednie generacje mają 64 jednostki wspólnego obrazu. Na granicach całej mapy referencje były przedłużone skrajnymi pikselami; te robocze pasy nie są częścią finalnej mapy.

Składanie wybiera w obszarze wspólnym ścieżkę najmniejszej różnicy barw. Łączenie jest wygładzane tylko w wąskim pasie 8 pikseli, aby nie rozmywać całych obszarów. Po utworzeniu wspólnego obrazu wyeksportowano finalne kafle. Dzięki temu finalne marginesy mają identyczne piksele, niezależnie od różnic między surowymi generacjami.

Sprawdzono wizualnie całość oraz zbliżenia szkoły, mostu i skrzynki. Sprawdzono programowo, że każdy zapisany fragment odpowiada masterowi i złożenie wszystkich rdzeni odtwarza master piksel w piksel. W osobnym projekcie testowym Godot 4.7.2 zaimportował wszystkie 12 tekstur i poprawnie utworzył scenę z granicami 1024 × 1536. To weryfikuje eksport; nie jest obietnicą identycznej geometrii ze starym rysunkiem. Nowa generacja zmienia drobne kształty i faktury. Przed wdrożeniem sprawdzić kolizje i maski zasłaniania, szczególnie poręcz mostu, dach i koronę drzewa.

## Godot

Skopiować `map.tscn` i katalog `tiles/` razem do projektu. Umieścić instancję sceny w (0,0) ze skalą rodzica (1,1). Fragmenty mają już skalę 0.4; mapa zachowuje dotychczasowy obszar świata 1024 × 1536. Nie należy zmieniać rozmiaru świata ani mnożyć współrzędnych tras przez 2.5.

Scena ustawia filtrowanie Linear. Używać bezstratnego importu, bez powtarzania. Nakładające się marginesy zapobiegają szczelinom przy ułamkowej pozycji kamery. Nie ustawiać osobnej przezroczystości poszczególnym kaflom. Całość ładuje wszystkie fragmenty, bez streamingu; pamięć RGBA to około 38 MiB bez dodatkowych kopii i mipmap.

Dotychczasowe Polygon2D wykorzystujące starą bitmapę nie są zgodne wizualnie z nowymi detalami: trzeba pobrać ich teksturę z nowego mastera i przeliczyć UV według gęstości 2.5, z uwzględnieniem pozycji ewentualnego wycinka. Ten pakiet nie zmienia aplikacji ani nie zastępuje jej mapy automatycznie.

Ostrość zależy od końcowej rozdzielczości ekranu i zoomu. Przy 2.5 piksela na jednostkę świata mamy rzeczywisty wzrost szczegółowości względem starej mapy; nie gwarantuje to braku interpolacji przy dowolnie dużym zoomie.
