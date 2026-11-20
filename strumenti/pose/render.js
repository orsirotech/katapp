// uso: node render.js out.png file.json[:t1,t2,...] ...   (vista opzionale con @vista)
const { chromium } = require('playwright'); const fs = require('fs');
(async () => {
  const out = process.argv[2], specs = process.argv.slice(3);
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1600, height: 1000 } });
  await p.goto('file://' + __dirname + '/proto.html'); await p.waitForTimeout(800);
  const items = [];
  for (const s of specs) { let [f, ts] = s.split(':'); let view = null; if (ts && ts.includes('@')) [ts, view] = ts.split('@'); else if (f.includes('@')) [f, view] = f.split('@');
    const j = JSON.parse(fs.readFileSync(f)); const times = ts ? ts.split(',').map(Number) : j.passi_t.map((t, i) => i ? t + .05 : t);
    items.push({ j, times, view: view || j.vista, name: f.split('/').pop() }); }
  const imgs = await p.evaluate((items) => {
    const {drawTech,eIO,eOut,eIn,W,MAINH}=window.__K; const E = { inOut: eIO, out: eOut, in: eIn, linear: undefined }; const res = [];
    for (const { j, times, view, name } of items) {
      const anim = { D: j.durata, keys: j.chiavi.map(k => [k.t, k.pose, E[k.ease]]), marks: j.passi_t, kiai: j.kiai, follow: j.segue_camera ? 1 : 0 };
      times.forEach((t, i) => { const c = document.createElement('canvas'); c.width = W; c.height = MAINH; const x = c.getContext('2d'); drawTech(x, anim, t, view, false); res.push({ src: c.toDataURL(), label: name + ' #' + i + ' t=' + t.toFixed(2) }); });
    }
    return res;
  }, items);
  const cols = Math.min(4, imgs.length);
  const html = `<body style="margin:0;background:#fff;font:12px sans-serif"><div style="display:grid;grid-template-columns:repeat(${cols},390px);gap:4px">` + imgs.map(i => `<div><img src="${i.src}" style="width:390px"><div>${i.label}</div></div>`).join('') + '</div></body>';
  await p.setContent(html); await p.screenshot({ path: out, fullPage: true }); await b.close();
})();
