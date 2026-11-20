# Generatore delle pose

Script usati per creare le animazioni in `assets/contenuti/anim/` e le schede in `tecniche.json`.

- `proto.js`: motore del prototipo (posizioni, braccia, passi) ed esportatore JSON.
- `tech.js`: posizioni, parate, pugni, percosse, calci e kumite aggiunti.
- `kata.js`: costruttore generico di kata (Heian 3-5, Tekki 1-3).
- `kata2.js`, `kata3.js`: kata superiori descritti con una riga per movimento (formato spiegato in cima a kata2.js).
- `contenuti/*.py`: testi delle schede e regole di gara.
- `build.py` e `build_kata.py`: scrivono le schede nella cartella contenuti.
- `render.js`: foglio di anteprime con Playwright (`node render.js out.png anim.json:t1,t2`).

Uso: `python3 build.py ../../assets/contenuti && python3 build_kata.py ../../assets/contenuti`
