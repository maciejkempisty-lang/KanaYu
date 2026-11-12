# Szkoła Yuu — wnętrze jako menu

2026-11-08. Mockup koncepcyjny, bez zmian w aplikacji. Sprawdzono faktyczne menu w `godot/scripts/learning/school.gd`, funkcja `menu()` (wiersze 128–147). Grafika: `kigi-school-interior-menu-v1.png`. Wykonano wbudowanym imagegen; prompt obok w pliku `kigi-school-interior-menu-v1-prompt.txt`.

| Obecna funkcja menu | Odpowiednik we wnętrzu | Krótki podpis mockupu |
|---|---|---|
| Pierwsze światło · lekcja 10 znaków | Centralne wejście do klasy, ławki, tablica i lampion | Pierwsze światło |
| Czytanie na dzisiaj · liczba | Tablica z neutralnymi kartami i pulpit po lewej | Czytanie |
| Pisanie na dzisiaj · liczba | Stół z papierem, pędzlami i tuszem po prawej | Pisanie |
| Sprawdź po przerwie · liczba | Cichy kącik z parawanem i zamkniętym pudełkiem kart u góry po prawej | Sprawdź po przerwie |
| Moje znaki i dodatkowe ćwiczenia | Regał z notesami, otwarty album i poduszka na dole po lewej | Moje znaki |
| Dziennik i przenoszenie postępów | Biurko z dziennikiem, szufladami i dwiema tackami na dole po prawej | Dziennik i postępy |
| Wróć do wioski | Drzwi na ganek, na dole kadru | Wróć do wioski |

## Zachowanie po wejściu

Wybór obiektu uruchamia dokładnie istniejącą funkcję. Czytanie, pisanie i sprawdzanie po przerwie zachowują dotychczasowe warunki dostępności; brak zadań nie usuwa mebla ani nie gasi świata. UI pokazuje neutralny status „Na dziś gotowe” lub właściwy dla danego stanu. Nie obiecywać terminów bez danych systemu.

Regał otwiera istniejący notes z poznanymi znakami i akcjami „Dodatkowe czytanie” oraz „Pisanie z pamięci”. Te akcje można pokazać w zbliżeniu regału jako album i zeszyt ćwiczeń. Biurko otwiera istniejący dziennik: „Eksportuj postępy” i „Importuj postępy KanaYu” pozostają osobnymi akcjami przy tackach; import nadal korzysta z wyboru pliku i walidacji. Nie importować ani eksportować automatycznie po samym wejściu.

Liczba poznanych znaków 0–10 jest dynamicznym statusem notesu. Zdobyty pierwszy lampion można pokazać przy klasie; w mockupie światła mają charakter poglądowy i nie odwzorowują konkretnego zapisu gracza. Komunikaty błędów, odzyskiwania zapisu i importu pozostają czytelne w UI.

## Produkcja i dostępność

To przegląd całego wnętrza służący ocenie kompozycji. Przy kamerze blisko bohatera telefon pokaże tylko fragment pomieszczenia. Wybór obiektu powinien być możliwy po podejściu, a skrót do listy aktywności zapewniać wygodny dostęp bez szukania miejsca. Żadne meble ani podpisy nie mogą blokować przejść.

Podpisy na ilustracji są demonstracją docelowych etykiet, nie tekstem do pozostawienia w finalnym tle. Finalny zestaw wymaga czystego tła bez etykiet, osobnych liczników/UI i warstw zasłaniających postać. Zachować czytelność dotykową i dostęp do tych samych funkcji klawiaturą/czytnikiem.

Nie malować znaków kana, romaji ani rozwiązań na tablicach, papierach i grzbietach notesów w menu. Poznawanie nieznanego materiału pozostaje kontrolowane przez istniejący system lekcji.
