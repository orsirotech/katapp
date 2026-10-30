# KatApp

App per imparare il karate Shotokan, in italiano. Le tecniche sono disegnate "a matita" da un manichino 3D procedurale: ogni animazione è una sequenza di pose in JSON, disegnata dall'app con `CustomPainter`.

## Struttura

| Cartella | Contenuto |
| --- | --- |
| `assets/contenuti/tecniche.json` | Schede: categorie, passi, punti chiave, errori, fonti |
| `assets/contenuti/anim/*.json` | Pose nel tempo per ogni animazione (cm; x avanti, y su, z destra) |
| `assets/contenuti/impara.json` | Glossario, comandi, conteggio, Dōjō kun, 20 principi, etichetta |
| `lib/engine/` | Interpolazione delle pose, cinematica inversa, camera, disegno a matita |
| `lib/data/` | Catalogo, contenuti di Impara, progressi (diario, ripasso, percorso, quiz, allenamenti, compiti del dojo) |
| `lib/ui/` | Schermate |
| `lib/services/voice.dart` | Voce che chiama tecniche e conteggio |

Il motore è il port del prototipo HTML: `test/engine_test.dart` controlla che il manichino coincida con quello del prototipo (valori in `test/riferimento_prototipo.json`).

## Comandi

```sh
flutter pub get
flutter test
flutter run
```

La CI su GitHub esegue analisi e test, e produce un APK di debug e la versione web come artifact.

## Stato

- **Home**: obiettivo del giorno e serie, prossima lezione, allenamento su misura, compiti del dojo, tecniche da ripassare, principio di oggi.
- **Percorso**: lezioni da 5 minuti per kyu con verifica di 3 domande, esame simulato (parte pratica guidata dalla voce e 8 domande).
- **Catalogo** e **scheda tecnica**: animazione, viste, velocità, passi, voce, significato dei kata, ripasso a intervalli.
- **Correggi la posizione** (zenkutsu, kokutsu, kiba, musubi, heiko): fotocamera dal vivo o foto, riconoscimento della postura sul telefono con ML Kit, consigli a voce. Sul web restano gli esempi disegnati.
- **Impara**: glossario parlante, comandi e conteggio, quiz per kyu, Dōjō kun e 20 principi, etichetta.
- **Profilo**: grado, diario con calendario e promemoria giornaliero (notifica locale, salta i giorni già allenati), il mio dojo (codici KAT- compatibili con il prototipo), preferiti, programma per cintura.

Da provare su un telefono vero: fotocamera, foto e notifiche (in CI si compila l'APK ma non si esegue). Per iOS il Podfile deve chiedere almeno iOS 15.5 (richiesto da ML Kit).

Testi riscritti a partire da: Caprioli, *Shotokan karate-do* (UISP 2013); Nakayama, *Best Karate*; scheda Heian Nidan di dojoshotokan.it. Alcuni passi sono ancora da verificare con un istruttore (campo `da_verificare`).
