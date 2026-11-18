const {chromium}=require('playwright');
const U=''+require('url').pathToFileURL(require('path').join(__dirname,'..','index.html')).href+'';
const ok=(c,m)=>{console.log((c?'OK  ':'FAIL')+' '+m); if(!c) process.exitCode=1;};
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1280,height:1000}});
 const errs=[];p.on('pageerror',e=>errs.push(e.message));
 await p.route(/fonts\.(googleapis|gstatic)\.com/,r=>r.abort());
 await p.goto(U);await p.evaluate(()=>{try{localStorage.clear()}catch(e){}});await p.reload();
 const ph=p.locator('.phone').first(); const J=n=>p.locator('.jumps').getByRole('button',{name:n,exact:true});
 const t=async()=>await ph.locator('.bar h2').textContent();
 // Ahorros
 await ph.locator('.nav button',{hasText:'Más'}).click(); await ph.locator('.row',{hasText:'Ahorros'}).click(); ok(await t()==='Ahorros y préstamos','ahorros');
 ok((await ph.textContent('.sbal')).includes('300.000'),'ahorro 300.000'); ok(await ph.locator('.row').count()===4,'4 movimientos');
 await ph.getByRole('button',{name:'Retirar'}).click(); await ph.locator('#sv-monto').fill('500000'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('No puedes retirar'),'retiro excede');
 await ph.locator('#sv-monto').fill('100000'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sbal')).includes('200.000'),'retiro aplicado');
 await ph.getByRole('button',{name:/Separar dinero/}).click(); await ph.locator('#sv-monto').fill('50000'); ok((await ph.textContent('.sheet .tlist')).includes('250.000'),'preview ahorro'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sbal')).includes('250.000'),'aporte aplicado');
 await p.screenshot({path:'sav1.png'});
 await ph.locator('.tabs button',{hasText:'Dinero prestado'}).click(); ok(await ph.locator('.loanc').count()===2,'2 préstamos');
 ok((await ph.locator('.loanc',{hasText:'Julián'}).textContent()).includes('Parcialmente devuelto'),'estado parcial'); ok((await ph.locator('.loanc',{hasText:'Valentina'}).textContent()).includes('Devuelto'),'estado devuelto');
 await ph.locator('.loanc',{hasText:'Julián'}).getByRole('button',{name:'Registrar devolución'}).click(); await ph.locator('#lr-monto').fill('200000'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('supera lo que falta'),'devolución excede');
 await ph.locator('#lr-monto').fill('100000'); await ph.locator('.sf .btn').click(); ok((await ph.locator('.loanc',{hasText:'Julián'}).textContent()).includes('Devuelto'),'devolución completa');
 await ph.getByRole('button',{name:/Prestar dinero/}).click(); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('nombre de la persona'),'valida persona');
 await ph.locator('#l-person').fill('Tomás'); await ph.locator('#l-amount').fill('60000'); await ph.locator('#l-due').fill('2026-11-10'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('posterior a la entrega'),'fecha acordada');
 await ph.locator('#l-due').fill('2026-12-20'); await ph.locator('.sf .btn').click(); ok((await ph.locator('.sheet h3').textContent())==='Revisar entrega','revisar entrega');
 await ph.locator('.sf .btn.p').click(); ok(await ph.locator('.loanc').count()===3,'préstamo nuevo');
 await p.screenshot({path:'sav2.png'});
 // Configuración
 await J('Configuración').click(); ok(await t()==='Configuración','configuración');
 await ph.locator('#cfg-name').fill('Laura 3'); await ph.getByRole('button',{name:'Guardar nombre'}).click(); ok((await ph.textContent('.setsec')).includes('Usa solo letras'),'nombre inválido');
 await ph.locator('#cfg-name').fill('Laura'); await ph.getByRole('button',{name:'Guardar nombre'}).click(); ok(await ph.locator('.toast').isVisible(),'nombre guardado');
 await ph.locator('[aria-label="Quitar Hogar"]').click(); ok((await ph.locator('.dlg h3').textContent()).includes('en uso'),'categoría en uso'); await ph.locator('.dlg .btn').click();
 await ph.locator('[aria-label="Quitar Suscripción"]').click(); ok((await ph.locator('.dlg h3').textContent()).includes('necesaria'),'suscripción protegida'); await ph.locator('.dlg .btn').click();
 ok(await ph.locator('[aria-label="Editar Suscripción"]').isDisabled(),'no editar suscripción');
 await ph.getByRole('button',{name:'Agregar categoría'}).click(); await ph.locator('#cat-n').fill('hogar'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('Ya tienes'),'categoría duplicada');
 await ph.locator('#cat-n').fill('Mascotas'); await ph.locator('.sf .btn').click(); ok(await ph.locator('.srow',{hasText:'Mascotas'}).count()===1,'categoría agregada');
 await ph.locator('[aria-label="Editar Mascotas"]').click(); await ph.locator('#cat-n').fill('Mascotas y veterinaria'); await ph.locator('.sf .btn').click(); ok(await ph.locator('.srow',{hasText:'Mascotas y veterinaria'}).count()===1,'categoría renombrada');
 await ph.locator('[aria-label="Quitar Mascotas y veterinaria"]').click(); await ph.locator('.dlg .btn.d').click(); ok(await ph.locator('.srow',{hasText:'Mascotas'}).count()===0,'categoría quitada');
 await ph.locator('[aria-label="Eliminar Nequi"]').click(); ok((await ph.locator('.dlg h3').textContent()).includes('historial'),'cuenta con historial'); await ph.locator('.dlg .btn').click();
 await ph.getByRole('button',{name:'Agregar cuenta digital'}).click(); await ph.locator('#acc-n').fill('Nu'); await ph.locator('.sf .btn').click(); ok(await ph.locator('.srow',{hasText:'Nu'}).count()>=1,'cuenta agregada');
 await ph.locator('[aria-label="Editar Nu"]').click(); await ph.locator('#acc-n').fill('Nu Colombia'); await ph.locator('.sf .btn').click(); ok(await ph.locator('.srow',{hasText:'Nu Colombia'}).count()===1,'cuenta renombrada');
 await ph.locator('.nav .reg').click(); await ph.locator('.opt').nth(1).click(); ok(await ph.locator('.pk',{hasText:'Nu Colombia'}).count()===1,'cuenta nueva en selector'); await ph.locator('.sheet [aria-label=Cerrar]').click();
 await ph.locator('[aria-label="Eliminar Nu Colombia"]').click(); await ph.locator('.dlg .btn.d').click(); ok(await ph.locator('.srow',{hasText:'Nu Colombia'}).count()===0,'cuenta eliminada');
 await ph.locator('.setsec .row',{hasText:'Bancolombia → Nequi'}).click(); await ph.locator('.mo',{hasText:'Revertir'}).click(); await ph.locator('.dlg .btn.d').click(); ok(await ph.locator('.setsec .row',{hasText:'Bancolombia → Nequi'}).count()===0,'transferencia revertida');
 await ph.locator('.setsec .row',{hasText:'Nequi → Efectivo'}).click(); await ph.locator('.mo',{hasText:'Editar'}).click(); ok((await ph.locator('.sheet h3').textContent())==='Editar transferencia','editar transferencia');
 await ph.locator('#t-monto').fill('120000'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.setsec .row')).includes('120.000'),'transferencia editada');
 await p.screenshot({path:'cfg.png'});
 await ph.getByRole('button',{name:'Borrar todos los datos'}).click(); ok((await ph.locator('.dlg h3').textContent())==='¿Borrar todos tus datos?','diálogo borrar'); await ph.locator('.dlg .btn.d').click();
 await ph.locator('.nav button',{hasText:'Inicio'}).click(); ok((await ph.locator('.hero .big').textContent()).includes('$ 0'),'datos borrados');
 ok((await ph.locator('.hello').textContent()).includes('Laura'),'nombre en saludo');
 // Comparar y responsive
 await p.locator('.seg button',{hasText:'Con datos'}).click(); await p.locator('.seg button',{hasText:'Comparar'}).click();
 for(const [n,f] of [['Ahorros y préstamos','c-sav'],['Configuración','c-cfg'],['Ingresos','c-inc']]){await J(n).click();await p.waitForTimeout(150);await p.screenshot({path:f+'.png'});}
 for(const w of [390,360]){await p.setViewportSize({width:w,height:800});for(const n of ['Ahorros y préstamos','Configuración','Ingresos']){await J(n).click();const ov=await p.evaluate(()=>document.documentElement.scrollWidth-innerWidth);if(ov>0)ok(false,'overflow '+w+' '+n+' '+ov);}}
 ok(true,'responsive revisado'); ok(errs.length===0,'sin errores JS '+errs.join(' | '));
 await b.close();})();
