# Szkoła v6 — jedna sala i oryginalne wejście

Mockup: `kigi-school-interior-menu-v6.png`, 1300 × 2100 px. Nowe wnętrze wygenerowano wbudowanym imagegen, a oryginalne wejście i teren nałożono deterministycznie po generowaniu. Nowa koncepcja zastępuje układ wielu sal.

Jedna wspólna sala na parterze: duża tablica pierwszej lekcji, tablica czytania, tablica sprawdzania po przerwie, stanowisko pisania, notesy i dziennik. Bez wewnętrznych korytarzy, klas, schodów ani drugiej kondygnacji. Jest to widok po umownym usunięciu dachu; przednia ściana zasłania część wnętrza. Przy dalszym dopracowaniu projekcji pilnować, aby podłoga była odczytywana jako znajdująca się ZA ścianą wejściową, nie na jej górze.

## Oryginalny fragment bez zmian

Źródło: `../art-delivery/kigi-map-detail-v2/map-master-2560x3840.png`. Pobrano prostokąt (300,1000,1300,1500). Zachowany obszar w jego lokalnych współrzędnych: y >= int(700 - 0.36*x). W finalnym obrazie przesunięto go wyłącznie o (0,600). Bez skalowania, obrotu, filtrów lub ponownego generowania. Obejmuje oryginalne drzwi, zasłonę, okna frontu, lampiony, ganek, schody, nawierzchnię i dolny fragment terenu. Programowe porównanie finalnego PNG potwierdziło 1344590 identycznych pikseli źródłowych.

Wycięty oryginał, przezroczysta nakładka oraz robocze wnętrze są zachowane w `school-v6/`. Wygenerowane obrazy robocze nie są końcowym źródłem wejścia. Finalnym plikiem jest kompozycja v6 w katalogu nadrzędnym. To mockup, nie zasób wdrożony do gry; etykiety pozostają poglądowe.
