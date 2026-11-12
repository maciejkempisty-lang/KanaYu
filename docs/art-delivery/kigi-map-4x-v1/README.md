# Kigi — mapa podzielona na fragmenty, 4×

## Zawartość i jakość

- `map-master-4096x6144.png`: pełny obraz 4096 × 6144.
- `tiles/`: 24 fragmenty w siatce 4 × 6; rdzeń 1024 × 1024, do 4 pikseli wspólnego marginesu z każdej strony.
- `map.tscn`: składana mapa dla Godot 4, w dotychczasowym rozmiarze świata 1024 × 1536.
- `manifest.json`: pozycje, skala, prostokąty i metoda przygotowania.

Ważne: jest to interpolacja Lanczos 4× oryginalnej mapy, nie natywna grafika 6K ani rekonstrukcja nowych detali. Wbudowany generator w trzech próbach nie dostarczył żądanej większej rozdzielczości; pierwsza próba dodatkowo zmieniła proporcje. Wariantów tych nie wykorzystano. Ten pakiet zachowuje dokładnie geometrię oryginału i poprawne łączenie, ale nie rozwiązuje w pełni ostrości przy bardzo dużym zbliżeniu. Finalna oprawa wymaga rzeczywistego super-resolution lub ręcznego dopracowania wspólnego obrazu w większej rozdzielczości.

Wszystkie fragmenty wycięto z jednego obrazu. Po zapisaniu porównano każdy piksel wszystkich 24 PNG z odpowiednim obszarem obrazu źródłowego. Wspólne marginesy zawierają te same piksele; nie są niezależnie wygenerowanymi krawędziami.

## Podłączenie

1. Skopiować `tiles/` i `map.tscn` razem do jednego katalogu projektu Godot. Pełny master i dokumentacja nie muszą trafić do aplikacji.
2. Wstawić instancję `map.tscn` w miejsce dotychczasowego Sprite2D tła, w pozycji (0,0), ze skalą rodzica (1,1).
3. Fragmenty mają już skalę 0.25 i prawidłowe pozycje. Nie zmieniać pozycji bohatera, punktów tras, kolizji ani granic kamery 1024 × 1536.
4. Używać bezstratnej kompresji tekstur, filtrowania Linear i bez powtarzania. Scena ustawia Linear. Marginesy nakładają się, zapobiegając odkrywaniu pustych szczelin przy ułamkowej pozycji kamery. Nie stosować indywidualnej modulacji/przezroczystości fragmentów.
5. Aktualne nakładki Polygon2D zasłaniające postać nadal używają starej bitmapy. Aby zwiększyć także ich rozdzielczość, należy wyciąć odpowiednie obszary z mastera i przeliczyć UV ×4 (z uwzględnieniem przesunięcia wycinka), zachowując punkty polygonu w jednostkach świata. Tego pakiet nie zmienia automatycznie.
6. Sprawdzić na urządzeniu szwy, pamięć i ostrość. Scena nie zawiera streamingu: wszystkie 24 tekstury są ładowane. Sam podział na fragmenty nie zmniejsza zużycia pamięci; nieskompresowane RGBA to około 97 MiB, bez mipmap i dodatkowych kopii.

Pakiet jest dostawą graficzną; istniejąca scena gry nie została podmieniona. Nie przeprowadzono testu wizualnego tej sceny na telefonie/tablecie.
