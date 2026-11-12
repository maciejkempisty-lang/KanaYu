# Duże drzewo przy poczcie — osobny sprite

Plik `kigi-old-tree-transparent.png`, PNG RGBA, 1254 × 1254 px, natywny wynik wbudowanego imagegen (bez powiększania interpolacją). Żądano 2048 × 2048, ale generator zwrócił 1254 × 1254. To rekonstrukcja drzewa według nowej mapy, nie pikselowo identyczne wycięcie. Uzupełniono koronę poza kadrem. Bez skrzynki, skał, podłoża i zabudowy.

Sprawdzono rzeczywisty kanał alfa: 689153 całkowicie przezroczyste piksele i brak pikseli o alfa > 0.1 na skrajnej krawędzi płótna. Zachować PNG i kanał alfa przy imporcie. Pełny prompt zapisano w `prompt.txt`.

Plik jest pojedynczą warstwą. Można go użyć do animacji deformacją siatki albo shaderem wiatru, utrzymując korzenie nieruchomo i ograniczając ruch pnia. Do niezależnego kołysania gałęzi potrzebny jest dodatkowy podział na pień i zachodzące na siebie grupy liści; ten eksport nie jest jeszcze takim zestawem ani gotową animacją.

Przed wstawieniem ruchomego drzewa na mapę trzeba przygotować tło bez namalowanego oryginału; inaczej nieruchome drzewo pozostanie widoczne pod animacją. Grafika nie została automatycznie podłączona do gry.
