const {chromium}=require('playwright');
const ok=(c,m)=>{console.log((c?'OK  ':'FAIL')+' '+m); if(!c) process.exitCode=1;};
(async()=>{const b=await chromium.launch();const errs=[];
 for(const w of [1280,393,360]){const p=await b.newPage({viewport:{width:w,height:900}});p.on('pageerror',e=>errs.push(w+': '+e.message));
  await p.route(/fonts\.(googleapis|gstatic)\.com/,r=>r.abort());await p.goto(''+require('url').pathToFileURL(require('path').join(__dirname,'..','index.html')).href+'');
  const names=await p.locator('.jumps button').allTextContents();let over=[];
  for(const theme of ['Claro','Oscuro']) for(const data of ['Con datos','Sin datos']) for(const st of ['Normal','Cargando','Error']){
   await p.locator('.seg button',{hasText:theme}).click();await p.locator('.seg button',{hasText:data}).click();await p.locator('.seg button',{hasText:st}).click();
   for(const n of names){await p.keyboard.press('Escape');await p.locator('.jumps').getByRole('button',{name:n,exact:true}).click();
    const ov=await p.evaluate(()=>document.documentElement.scrollWidth-innerWidth);if(ov>0)over.push(`${theme}/${data}/${st}/${n}:${ov}`);
    const phOver=await p.evaluate(()=>{const ph=document.querySelector('.phone');const b=ph.querySelector('.body,.onb,.sb');if(!b)return 0;return b.scrollWidth-b.clientWidth});if(phOver>1)over.push(`interno ${theme}/${data}/${st}/${n}:${phOver}`);}}
  ok(over.length===0,`${w}px: ${names.length} atajos × 12 combinaciones sin desbordes `+over.slice(0,6).join(' | '));
  await p.close();}
 ok(errs.length===0,'sin errores JS en el recorrido '+errs.slice(0,3).join(' | '));
 // teclado: diálogo y menú
 const p=await b.newPage({viewport:{width:1280,height:900}});await p.route(/fonts\.(googleapis|gstatic)\.com/,r=>r.abort());await p.goto(''+require('url').pathToFileURL(require('path').join(__dirname,'..','index.html')).href+'');
 await p.locator('.jumps').getByRole('button',{name:'Suscripciones',exact:true}).click();const ph=p.locator('.phone').first();
 await ph.locator('[aria-label="Acciones de Netflix"]').click();ok(await p.evaluate(()=>document.activeElement.classList.contains('mo')||document.activeElement.getAttribute('aria-label')==='Cerrar'),'foco entra al menú');
 await p.keyboard.press('Escape');ok(await ph.locator('.mo').count()===0,'Esc cierra menú');
 await ph.locator('[aria-label="Acciones de Netflix"]').click();await ph.locator('.mo',{hasText:'Cancelar suscripción'}).click();
 ok(await p.evaluate(()=>document.activeElement.closest('.dlg')!==null),'foco en el diálogo');ok((await p.evaluate(()=>document.activeElement.textContent))==='Volver','foco en la opción segura');
 await p.keyboard.press('Escape');ok(await ph.locator('.dlg').count()===0,'Esc cierra diálogo');
 const unnamed=await p.evaluate(()=>[...document.querySelectorAll('.phone button')].filter(x=>!(x.getAttribute('aria-label')||x.textContent.trim())).length);ok(unnamed===0,'todos los botones tienen nombre ('+unnamed+')');
 await b.close();})();
