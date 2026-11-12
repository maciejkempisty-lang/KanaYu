# Kigi — tarasowa mapa do przewijania

2026-11-07. Koncepcja graficzna wygenerowana wbudowanym imagegen na podstawie środkowego wariantu zatwierdzonego przez użytkownika. Plik: kigi-terraces-scroll-map-v1.png. Pełny prompt: kigi-terraces-scroll-map-v1-prompt.txt.

Nowe założenie użytkownika: gracz porusza się po mapie, kamera pokazuje fragment świata i podąża za nim. Całość nie jest dopasowywana do ekranu telefonu ani tabletu. Bohater ma w świecie wielkość czerwonej skrzynki pod drzewem. Około 1/4 ekranu interpretujemy jako 1/4 wysokości ekranu telefonu; tablet zachowuje zbliżoną skalę świata i może pokazywać większy obszar.

Dolny obszar: wejście, drzewo, poczta, polana spotkań. Środkowy: szkoła, most i strumień. Górny: pracownia i bramka ogrodu. Zachowana podwyższona kamera i malowane, przestrzenne bryły.

To scalona ilustracja koncepcyjna, bez bohatera, nie gotowy poziom gry. Docelowo potrzebne są tła poszczególnych obszarów w większej rozdzielczości z nakładającymi się marginesami, osobne elementy zasłaniające postać, ruchome rekwizyty, obszary ruchu i kolizje. Przy zbliżeniu do zadanej skali nie należy rozciągać tej bitmapy jako finalnego ostrego tła. Skala kamery musi być sprawdzona na rzeczywistym ekranie; wzór: wysokość widocznego świata ≈ 4 wysokości bohatera. Nie zmieniono kodu gry ani wcześniejszych manifestów zasobów.
