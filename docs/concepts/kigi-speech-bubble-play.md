# Pusty dymek bohatera z ikoną startu

Plik: `../../godot/assets/ui/kigi-speech-bubble-play.png`. PNG 1536 × 1024 z prawdziwą przezroczystością. Wbudowany imagegen; prompt obok. W próbce sprawdzono alfa: narożniki są przezroczyste, środek pergaminu nieprzezroczysty.

Puste miejsce na tekst: orientacyjnie x=0.14–0.75, y=0.25–0.69 lokalnego obrazu; dopasować po obejrzeniu na urządzeniu. Ikona startu jest już częścią obrazu, orientacyjny środek x=0.81, y=0.67. Godot powinien nałożyć na nią przezroczysty obszar dotyku o wygodnym rozmiarze. Ogon dymku wskazuje głowę bohatera. Obiekt UI należy trzymać na CanvasLayer, śledząc pozycję ekranową bohatera i ograniczając do granic widoku. Tekst pozostaje dynamiczny; nie wypalać go w PNG.

Treści i mapowanie akcji: `kigi-school-proximity-popups-v1.md`. Zasób graficzny zapisano w projekcie, ale nie podłączono do sceny. Przy brakujących powtórkach nie pokazywać ikony jako dostępnego startu bez działającej akcji; potrzebny jest stan nieaktywny albo krótki komunikat bez przycisku.
