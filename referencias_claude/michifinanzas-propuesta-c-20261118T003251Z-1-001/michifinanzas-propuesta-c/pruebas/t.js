const {chromium}=require('playwright');
const U=''+require('url').pathToFileURL(require('path').join(__dirname,'..','index.html')).href+'';
const ok=(c,m)=>{console.log((c?'OK  ':'FAIL')+' '+m); if(!c) process.exitCode=1;};
(async()=>{
 const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1280,height:1000}});
 const errs=[]; p.on('pageerror',e=>errs.push(e.message)); p.on('console',m=>['error','warning'].includes(m.type())&&errs.push(m.type()+': '+m.text().slice(0,200)));
 await p.route(/fonts\.(googleapis|gstatic)\.com/,r=>r.abort());
 await p.goto(U); await p.waitForSelector('.phone');
 const ph=p.locator('.phone').first();
 ok(await ph.locator('.bar h2').textContent()==='Inicio','título Inicio');
 ok((await ph.locator('.hero .big').textContent()).includes('2.450.000'),'saldo total');
 await ph.locator('.split button').nth(1).click(); ok(await ph.locator('.acclist li').count()===3,'despliega cuentas digitales');
 ok((await ph.textContent('.month')).includes('2.000.000')&&(await ph.textContent('.month')).includes('750.000'),'resumen mes');
 ok(await ph.locator('.due').count()===4,'4 próximos pagos');
 await p.screenshot({path:'inicio.png'});
 // Registrar → gasto
 await ph.locator('.nav .reg').click(); ok(await ph.locator('.opt').count()===3,'hoja registrar 3 opciones');
 await ph.locator('.opt').nth(1).click(); ok((await ph.locator('.sheet h3').textContent())==='Nuevo gasto','abre nuevo gasto');
 await ph.locator('.sf .btn').click(); ok(await ph.locator('.err').count()===3,'3 errores de validación');
 await ph.locator('#g-monto').fill('400000'); ok((await ph.textContent('.preview')).includes('No alcanza'),'saldo insuficiente efectivo');
 await ph.locator('.pk',{hasText:'Nequi'}).click(); ok((await ph.textContent('.preview')).includes('400.000'),'te quedarán 400.000');
 await ph.locator('#g-nombre').fill('Zapatos'); await ph.locator('.sheet .chip',{hasText:'Ocio'}).click();
 await p.screenshot({path:'form.png'});
 await ph.locator('.sf .btn').click(); ok(await ph.locator('.toast').isVisible(),'toast éxito');
 ok((await ph.locator('.hero .big').textContent()).includes('2.050.000'),'saldo actualizado');
 // Movimientos
 await ph.locator('.nav button',{hasText:'Movimientos'}).click(); ok(await ph.locator('.bar h2').textContent()==='Movimientos','título movimientos');
 ok((await ph.textContent('.sum')).includes('1.150.000'),'total gastado actualizado');
 ok(await ph.locator('.row.debt').count()===2,'2 abonos de deuda diferenciados');
 await ph.locator('.row.debt').first().click(); ok((await ph.locator('.sheet h3').textContent())==='Abono de deuda','abono solo lectura');
 await ph.locator('.sheet .btn').click();
 await ph.locator('.chips .chip',{hasText:'Comida'}).click(); ok(await ph.locator('.row').count()===2,'filtro categoría');
 await ph.locator('.chips .chip',{hasText:'Todas'}).click();
 await ph.locator('.row:not(.debt)').first().click(); ok((await ph.locator('.sheet h3').textContent())==='Editar gasto','editar gasto');
 await ph.locator('.sheet [aria-label=Cerrar]').click();
 await ph.locator('[aria-label="Mes anterior"]').click(); ok((await ph.textContent('.monthsel')).includes('Octubre'),'mes anterior');
 await p.screenshot({path:'gastos.png'});
 // Cuentas
 await p.locator('.jumps').getByRole('button',{name:'Cuentas',exact:true}).click(); ok(await ph.locator('.bar h2').textContent()==='Cuentas','cuentas');
 ok(await ph.locator('.acc').count()===4,'4 cuentas');
 await ph.locator('.acc').nth(1).click(); ok(await ph.locator('.acc ul li').count()>=1,'despliega movimientos de cuenta');
 await ph.locator('.btn.p',{hasText:'Transferir'}).click(); ok((await ph.locator('.sheet h3').textContent())==='Transferir dinero','abre transferencia');
 await ph.locator('#t-monto').fill('100000'); await ph.locator('.sf .btn').click(); ok(await ph.locator('.toast').isVisible(),'transferencia guardada');
 await p.screenshot({path:'cuentas.png'});
 await ph.locator('[aria-label=Volver]').click(); ok(await ph.locator('.bar h2').textContent()==='Más','volver a Más');
 // Estadísticas
 await ph.locator('.row',{hasText:'Estadísticas'}).click(); ok(await ph.locator('.bar h2').textContent()==='Estadísticas','estadísticas');
 ok(await ph.locator('.donut svg circle').count()>3,'dona dibujada');
 for(const t of ['Efectivo','Digital','General']){await ph.locator('.tabs button',{hasText:t}).click(); ok(await ph.locator('.donut').count()+await ph.locator('text=Sin gastos en este período.').count()>0,'pestaña '+t);}
 await ph.locator('.tabs button',{hasText:'Digital'}).click(); ok(await ph.locator('.acct').count()===3,'cuentas digitales en stats');
 for(const k of ['Mes anterior','Últimos 7 días','Últimos 30 días','Este mes']) await ph.locator('.chips .chip',{hasText:k}).click();
 await ph.locator('.tabs button',{hasText:'General'}).click();
 await p.screenshot({path:'stats.png'});
 // Ingreso
 await ph.locator('.nav .reg').click(); await ph.locator('.opt').first().click();
 await ph.locator('#i-monto').fill('500000'); ok((await ph.textContent('.left')).includes('Todo el dinero'),'un destino asigna todo');
 await ph.locator('.sheet .link',{hasText:'Agregar otro destino'}).click(); ok(await ph.locator('.dest').count()===2,'segundo destino');
 await ph.locator('.dest input').nth(0).fill('300000'); ok((await ph.textContent('.left')).includes('200.000'),'falta por asignar 200.000');
 ok(await ph.locator('.sf .btn').isDisabled(),'guardar deshabilitado');
 await ph.locator('.dest input').nth(1).fill('200000'); ok(await ph.locator('.sf .btn').isEnabled(),'guardar habilitado');
 await ph.locator('.sheet .chip',{hasText:'Préstamo'}).click(); ok((await ph.textContent('.sheet')).includes('También se creará una deuda'),'aviso préstamo');
 await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('cuántas cuotas'),'préstamo pide cuotas'); await ph.locator('#i-cuotas').fill('5'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.toast')).includes('Deudas'),'ingreso préstamo guardado y deuda creada');
 // Compromisos y Más
 await ph.locator('.nav button',{hasText:'Compromisos'}).click(); ok(await ph.locator('.due').count()===8,'compromisos con préstamo nuevo');
 // tema y comparar
 await p.locator('.seg button',{hasText:'Oscuro'}).click(); ok(await p.locator('.phone.t-dark').count()===1,'tema oscuro');
 await p.locator('.jumps').getByRole('button',{name:'Inicio',exact:true}).click(); await p.screenshot({path:'inicio-dark.png'});
 await p.locator('.seg button',{hasText:'Comparar'}).click(); ok(await p.locator('.phone').count()===2,'comparar 2 teléfonos');
 await p.locator('.jumps').getByRole('button',{name:'Estadísticas',exact:true}).click(); await p.screenshot({path:'compare-stats.png'});
 await p.locator('.jumps').getByRole('button',{name:'Gastos',exact:true}).click(); await p.screenshot({path:'compare-gastos.png'});
 await p.locator('.jumps').getByRole('button',{name:'Cuentas',exact:true}).click(); await p.screenshot({path:'compare-cuentas.png'});
 await p.locator('.jumps').getByRole('button',{name:'Inicio',exact:true}).click(); await p.screenshot({path:'compare-inicio.png'});
 await p.locator('.jumps').getByRole('button',{name:'Formulario de gasto',exact:true}).click(); await p.screenshot({path:'compare-form.png'});
 await p.keyboard.press('Escape');
 // vacío
 await p.locator('.seg button',{hasText:'Sin datos'}).click(); await p.locator('.jumps').getByRole('button',{name:'Gastos',exact:true}).click();
 ok(await p.locator('.phone').first().locator('.empty img').count()>0,'estado vacío con gato');
 await p.screenshot({path:'compare-empty.png'});
 await p.locator('.jumps').getByRole('button',{name:'Estadísticas',exact:true}).click(); ok((await p.locator('.phone').first().textContent()).includes('Aún no hay datos'),'stats vacío');
 // móvil
 await p.setViewportSize({width:390,height:844}); await p.locator('.seg button',{hasText:'Con datos'}).click(); await p.locator('.seg button',{hasText:'Claro'}).click();
 await p.locator('.jumps').getByRole('button',{name:'Inicio',exact:true}).click();
 const ov=await p.evaluate(()=>document.documentElement.scrollWidth-innerWidth); ok(ov<=0,'sin scroll horizontal a 390 ('+ov+')');
 await p.screenshot({path:'movil.png'});
 const bad=errs.filter(e=>!/fonts|Failed to load resource/.test(e)); ok(bad.length===0,'sin errores: '+bad.slice(0,5).join(' | '));
 await b.close();
})();
