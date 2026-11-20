#!/usr/bin/env python3
"""Aggiunge a tecniche.json e impara.json le schede generate (uso: build.py <cartella contenuti>)."""
import json, subprocess, sys, os, shutil
HERE = os.path.dirname(os.path.abspath(__file__)); DST = sys.argv[1]
sys.path.insert(0, os.path.join(HERE, 'contenuti'))
subprocess.run(['node', os.path.join(HERE, 'tech.js')], check=True)
meta = json.load(open(os.path.join(HERE, 'out/meta.json')))
from tecniche_nuove import T, K, C, N
from regole import REGOLE
tp = os.path.join(DST, 'tecniche.json'); tj = json.load(open(tp))
cats = {c['id']: c for c in tj['categorie']}
if 'kumite' not in cats:
    kc = {'id': 'kumite', 'nome_it': 'Kumite di base', 'nome_jp': 'Kumite', 'tecniche': []}
    i = [c['id'] for c in tj['categorie']].index('kata'); tj['categorie'].insert(i, kc); cats['kumite'] = kc
def put(cat, e):
    lst = cats[cat]['tecniche']; ids = [x['id'] for x in lst]
    if e['id'] in ids: lst[ids.index(e['id'])] = e
    else: lst.append(e)
for cat, id_, jp, it, kyu, desc, passi, pk, err, dv in T:
    mk = meta[id_]['marks']
    put(cat, {'id': id_, 'nome_jp': jp, 'nome_it': it, 'kyu': kyu, 'descrizione': desc,
              'passi': [{'n': i + 1, 'testo': p, 't_anim': mk[min(i, len(mk) - 1)]} for i, p in enumerate(passi)],
              'punti_chiave': pk, 'errori_comuni': err, 'animazione': {'pose': f'anim/{id_}.json'}, 'stato': 'animata',
              'fonti': [C, N], 'da_verificare': dv})
for id_, jp, it, kyu, desc, pk, err in K:
    mk, rows = meta[id_]['marks'], meta[id_]['rows']
    put('kumite', {'id': id_, 'nome_jp': jp, 'nome_it': it, 'kyu': kyu, 'descrizione': desc,
              'sequenza': [{'passo': r[0], 'tecnica': r[1], 'posizione': r[2], 'kiai': bool(r[3]) if len(r) > 3 else False, 't_anim': mk[i]} for i, r in enumerate(rows)],
              'punti_chiave': pk, 'errori_comuni': err, 'animazione': {'pose': f'anim/{id_}.json'}, 'stato': 'animata',
              'fonti': [C, N], 'da_verificare': []})
tj['versione'] = max(tj.get('versione', 4), 5)
json.dump(tj, open(tp, 'w'), ensure_ascii=False, indent=2)
ad = os.path.join(DST, 'anim'); used = {e['id'] for e in [*T] for e in [dict(id=e[1])]} | {k[0] for k in K}
for f in os.listdir(os.path.join(HERE, 'out/anim')):
    if f[:-5] in used: shutil.copy(os.path.join(HERE, 'out/anim', f), ad)
ip = os.path.join(DST, 'impara.json'); ij = json.load(open(ip)); ij['regole'] = REGOLE
json.dump(ij, open(ip, 'w'), ensure_ascii=False, indent=2)
print('schede:', sum(len(c['tecniche']) for c in tj['categorie']))
