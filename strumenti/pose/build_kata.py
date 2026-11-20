#!/usr/bin/env python3
"""Aggiunge i kata generati da kata.js (uso: build_kata.py <cartella contenuti>)."""
import json, subprocess, sys, os, shutil
HERE = os.path.dirname(os.path.abspath(__file__)); DST = sys.argv[1]
sys.path.insert(0, os.path.join(HERE, 'contenuti'))
for f in ('kata.js', 'kata2.js', 'kata3.js'): subprocess.run(['node', os.path.join(HERE, f)], check=True)
meta = json.load(open(os.path.join(HERE, 'out/meta_kata.json')))
from kata_nuovi import KATA, C, N, Z, S
SECOND = {'jiin','chinte','nijushiho','sochin','unsu','gojushihosho','gojushihodai','meikyo','wankan'}
tp = os.path.join(DST, 'tecniche.json'); tj = json.load(open(tp))
lst = [c for c in tj['categorie'] if c['id'] == 'kata'][0]['tecniche']
ip = os.path.join(DST, 'impara.json'); ij = json.load(open(ip))
for id_, k in KATA.items():
    if id_ not in meta: continue
    mk, rows = meta[id_]['marks'], meta[id_]['rows']
    e = {'id': id_, 'nome_jp': k['jp'], 'nome_it': k['it'], 'kyu': k['kyu'], 'descrizione': k['desc'],
         'sequenza': [{'passo': r[0], 'tecnica': r[1], 'posizione': r[2], 'kiai': bool(r[3]) if len(r) > 3 else False, 't_anim': round(mk[i], 2)} for i, r in enumerate(rows)],
         'punti_chiave': k['pk'], 'errori_comuni': k['err'], 'animazione': {'pose': f'anim/{id_}.json'}, 'stato': 'animata',
         'fonti': [C, N, S if id_ in SECOND else Z], 'da_verificare': ['tracciato', 'animazione semplificata']}
    ids = [x['id'] for x in lst]
    if id_ in ids: lst[ids.index(id_)] = e
    else: lst.append(e)
    ij['significato_kata'][id_] = k['sig']
    shutil.copy(os.path.join(HERE, 'out/anim', id_ + '.json'), os.path.join(DST, 'anim'))
json.dump(tj, open(tp, 'w'), ensure_ascii=False, indent=2); json.dump(ij, open(ip, 'w'), ensure_ascii=False, indent=2)
print('kata:', len(lst))
