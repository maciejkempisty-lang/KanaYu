# Dymki interakcji w szkole — koncepcja v1

Mockup: `kigi-school-proximity-popups-v1.png`. Trzy warianty na jednym obrazie: ręcznie formowany pergamin, kartka z indygową obwódką, mała wisząca etykieta. Użyto wbudowanego imagegen; pełny prompt w pliku obok. Tło inspirowane szkołą v6, bohater wzorowany na aktualnej grafice Godot.

## Teksty proponowane do runtime

| Stanowisko | Wypowiedź bohatera | Akcja |
|---|---|---|
| Duża tablica | Na tej tablicy poznam pierwsze znaki. | Rozpocznij lekcję |
| Tablica czytania | Tutaj poćwiczę czytanie. | Ćwicz czytanie |
| Stół pisania | Tu mogę poćwiczyć pisanie. | Ćwicz pisanie |
| Tablica sprawdzania | Sprawdzę, co pamiętam po przerwie. | Sprawdź pamięć |
| Regał z notesami | Tutaj są moje poznane znaki. | Otwórz notes |
| Biurko dziennika | Tu znajdę zapis swoich prób. | Otwórz dziennik |
| Wyjście | Wrócę do wioski. | Wyjdź |

Wersja obrazowa jest poglądowa: tekst, przyciski, liczniki i ogon dymku powinny być rysowane przez Godot, bez wypalania ich w tle. Dymek należy pozycjonować w przestrzeni ekranu nad bohaterem, z ograniczeniem do bezpiecznych krawędzi ekranu. Ogon wskazuje bohatera, natomiast otwarty przycisk uruchamia funkcję stanowiska. Po odejściu lub zamknięciu dymek znika. Brak zadań do powtórki powinien zmieniać tekst na neutralny komunikat i nie pokazywać nieaktywnego przycisku jako aktywnego.

Rekomendowany wariant wizualny: pierwszy, z miękką formą pergaminu; trzeci jest dobry na mały ekran, jeśli tekst będzie krótszy. Przetestować czytelność przy polskim dużym tekście i przy prawej/lewej krawędzi kadru.
