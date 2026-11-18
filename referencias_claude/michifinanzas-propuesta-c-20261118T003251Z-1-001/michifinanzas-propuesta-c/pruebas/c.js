const {chromium}=require('playwright');
const U=''+require('url').pathToFileURL(require('path').join(__dirname,'..','index.html')).href+'';
const ok=(c,m)=>{console.log((c?'OK  ':'FAIL')+' '+m); if(!c) process.exitCode=1;};
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1280,height:1000}});
 const errs=[];p.on('pageerror',e=>errs.push(e.message));
 await p.route(/fonts\.(googleapis|gstatic)\.com/,r=>r.abort());
 await p.goto(U);await p.evaluate(()=>{try{localStorage.clear()}catch(e){}});await p.reload();
 const ph=p.locator('.phone').first(); const J=n=>p.locator('.jumps').getByRole('button',{name:n,exact:true});
 const t=async()=>await ph.locator('.bar h2').textContent();
 // Inicio próximos pagos derivados
 ok(await ph.locator('.due').count()===4,'inicio 4 próximos');
 ok((await ph.locator('.due').first().textContent()).includes('Netflix'),'primero Netflix');
 // Compromisos
 await ph.locator('.nav button',{hasText:'Compromisos'}).click();
 ok((await ph.textContent('.card')).includes('86.900'),'por pagar noviembre 86.900');
 ok(await ph.locator('.due').count()===7,'7 próximos en compromisos');
 // Suscripciones
 await ph.locator('.row',{hasText:'Suscripciones'}).click(); ok(await t()==='Suscripciones','abre suscripciones');
 ok((await ph.textContent('.vals')).includes('43.800')&&(await ph.textContent('.vals')).includes('525.600'),'estimados');
 await ph.locator('.subc',{hasText:'Netflix'}).getByRole('button',{name:'Pagar'}).click();
 ok((await ph.locator('.sheet h3').textContent())==='Pagar Netflix','hoja pagar');
 ok((await ph.textContent('.sheet')).includes('21 de diciembre'),'próximo cobro movido');
 await ph.locator('.sf .btn.p').click(); ok(await ph.locator('.toast').isVisible(),'pago registrado');
 ok((await ph.textContent('.subc')).includes('21 de diciembre'),'tarjeta muestra nuevo cobro');
 await ph.locator('.subc',{hasText:'Netflix'}).getByRole('button',{name:'Historial'}).click(); ok(await ph.locator('.sheet .tlist li').count()===2,'historial 2 pagos'); await ph.locator('.sheet [aria-label=Cerrar]').click();
 await ph.locator('[aria-label="Acciones de Netflix"]').click(); await ph.locator('.mo',{hasText:'Cancelar suscripción'}).click();
 ok((await ph.locator('.dlg h3').textContent())==='¿Cancelar esta suscripción?','diálogo cancelar'); await ph.locator('.dlg .btn.d').click();
 ok(await ph.locator('.subc.off').count()===2,'2 canceladas');
 await ph.locator('.subc.off',{hasText:'Netflix'}).getByRole('button',{name:'Reactivar'}).click(); ok(await ph.locator('.subc.off').count()===1,'reactivada');
 await ph.getByRole('button',{name:'Agregar suscripción'}).click(); await ph.locator('.sf .btn').click(); ok(await ph.locator('.sheet .err').count()===2,'validación suscripción');
 await ph.locator('#s-name').fill('YouTube Premium'); await ph.locator('#s-price').fill('16900'); await ph.locator('.sheet .chip',{hasText:'Anual'}).click();
 ok((await ph.textContent('.sheet')).includes('al mes'),'equivalente mensual'); await ph.locator('.sf .btn').click(); ok(await ph.locator('.subc:not(.off)').count()===3,'nueva suscripción');
 await p.screenshot({path:'subs.png'});
 // Gastos futuros
 await J('Gastos futuros').click(); ok(await t()==='Gastos futuros','gastos futuros');
 ok(await ph.locator('.planc').count()===2,'2 planes activos');
 ok((await ph.locator('.planc').nth(1).textContent()).includes('Para llegar a tiempo'),'recomendación');
 await ph.locator('.planc',{hasText:'Regalos'}).getByRole('button',{name:'Reservar'}).click(); ok((await ph.locator('.sheet h3').textContent())==='Confirmar reserva','hoja reserva');
 await ph.locator('#r-monto').fill('999999'); await ph.locator('.sf .btn.p').click(); ok((await ph.textContent('.sheet .err')).includes('Supera'),'supera lo planeado');
 await ph.locator('#r-monto').fill('100000'); await ph.locator('.sf .btn.p').click(); ok(await ph.locator('.toast').isVisible(),'reserva confirmada');
 ok((await ph.locator('.planc',{hasText:'Regalos'}).textContent()).includes('100.000'),'reservado actualizado');
 await ph.locator('.planc',{hasText:'Regalos'}).getByRole('button',{name:'Liberar reserva'}).click(); await ph.locator('.sf .btn.p').click(); ok(await ph.locator('.planc',{hasText:'Regalos'}).getByRole('button',{name:'Liberar reserva'}).count()===0,'liberado');
 await ph.locator('[aria-label="Acciones de SOAT de la moto"]').click(); await ph.locator('.mo',{hasText:'Eliminar plan'}).click(); ok((await ph.locator('.dlg h3').textContent()).includes('libera'),'bloquea eliminar con reserva'); await ph.locator('.dlg .btn').click();
 await ph.locator('[aria-label="Acciones de Regalos de Navidad"]').click(); await ph.locator('.mo',{hasText:'Archivar'}).click(); ok(await ph.locator('.planc').count()===1,'archivado');
 await ph.locator('.tabs button',{hasText:'Archivados'}).click(); ok(await ph.locator('.planc').count()===2,'2 archivados');
 await ph.locator('.tabs button',{hasText:'Activos'}).click();
 await ph.getByRole('button',{name:'Nuevo plan'}).click(); await ph.locator('.sf .btn').click(); ok(await ph.locator('.sheet .err').count()>=2,'validación plan');
 await ph.locator('#p-name').fill('Mantenimiento moto'); await ph.locator('.sheet .chip',{hasText:'Transporte'}).click(); await ph.locator('#p-need').fill('200000'); await ph.locator('#p-plan').fill('300000');
 await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet')).includes('No planees guardar más'),'plan > necesidad'); await ph.locator('#p-plan').fill('200000');
 ok((await ph.textContent('.sheet')).includes('Recomendado'),'recomendado en form'); await ph.locator('.sf .btn').click(); ok(await ph.locator('.planc').count()===2,'plan creado');
 await p.screenshot({path:'plans.png'});
 // Deudas
 await J('Deudas').click(); ok(await t()==='Deudas y préstamos','deudas');
 ok(await ph.locator('.debtc').count()===3,'3 pendientes');
 ok((await ph.textContent('.vals')).includes('1.020.000'),'saldo por pagar');
 await ph.locator('.debtc',{hasText:'Carlos'}).getByRole('button',{name:'Registrar abono'}).click();
 await ph.locator('.opts3 .pk',{hasText:'Abonar otro'}).click(); await ph.locator('#a-monto').fill('900000'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('supera lo que todavía debes'),'abono excede');
 await ph.locator('.opts3 .pk',{hasText:'Pagar cuota'}).click(); await ph.locator('.sf .btn').click(); ok((await ph.locator('.sheet h3').textContent())==='Revisar abono','paso revisar');
 await ph.locator('.sf .btn.p').click(); ok(await ph.locator('.toast').isVisible(),'abono registrado');
 ok((await ph.locator('.debtc',{hasText:'Carlos'}).textContent()).includes('4 de 10'),'cuota 4 de 10');
 await ph.locator('.debtc',{hasText:'Carlos'}).getByRole('button',{name:/Historial/}).click(); ok(await ph.locator('.sheet .tlist li').count()===3,'historial 3'); await ph.locator('.sheet [aria-label=Cerrar]').click();
 await ph.locator('.tabs button',{hasText:'Pagadas'}).click(); ok(await ph.locator('.debtc').count()===1,'1 pagada'); await ph.locator('.tabs button',{hasText:'Pendientes'}).click();
 await ph.getByRole('button',{name:'Nueva deuda'}).click(); await ph.locator('#d-name').fill('Préstamo de Ana'); await ph.locator('#d-orig').fill('300000'); await ph.locator('#d-quota').fill('100000'); await ph.locator('#d-n').fill('3'); await ph.locator('#d-h').fill('1');
 await ph.locator('.sf .btn').click(); ok((await ph.locator('.debtc',{hasText:'Ana'}).textContent()).includes('dato histórico'),'deuda con dato histórico');
 await p.screenshot({path:'debts.png'});
 // Créditos
 await J('Créditos').click(); ok(await t()==='Créditos de compra','créditos'); ok(await ph.locator('.entc').count()===2,'2 entidades');
 await ph.locator('.entc',{hasText:'Addi'}).click(); ok(await t()==='Addi','detalle Addi');
 ok((await ph.textContent('.cupo')).includes('340.000')&&(await ph.textContent('.cupo')).includes('260.000'),'cupo utilizado y disponible');
 await ph.getByRole('button',{name:'Nueva compra'}).click(); await ph.locator('#c-desc').fill('Tenis'); await ph.locator('.sheet .chip',{hasText:'Ocio'}).click(); await ph.locator('#c-total').fill('400000');
 await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('No hay suficiente cupo'),'sin cupo');
 await ph.locator('#c-total').fill('250000'); await ph.locator('#c-n').fill('3'); ok((await ph.textContent('.sheet')).includes('última cuota'),'ajuste última cuota');
 await ph.locator('.sf .btn').click(); ok((await ph.locator('.prow').count())===2,'compra agregada');
 ok((await ph.textContent('.cupo')).includes('10.000'),'cupo disponible 10.000');
 await ph.getByRole('button',{name:'Actualizar cupo'}).click(); await ph.locator('#l-monto').fill('500000'); await ph.locator('.sf .btn').click(); ok((await ph.textContent('.sheet .err')).includes('No puede ser menor'),'cupo menor al usado');
 await ph.locator('#l-monto').fill('800000'); await ph.locator('.sf .btn').click(); ok(await ph.locator('.tlist').last().locator('li').count()===3,'historial cupo 3');
 await ph.getByRole('button',{name:/Ver deudas asociadas/}).click(); ok(await t()==='Deudas y préstamos'&&(await ph.textContent('.filter')).includes('Addi'),'deudas filtradas por Addi');
 ok(await ph.locator('.debtc').count()===2,'2 deudas Addi');
 await ph.locator('[aria-label=Volver]').click(); ok(await t()==='Addi','volver conserva detalle');
 await ph.getByRole('button',{name:'Retirar entidad'}).click(); ok((await ph.locator('.dlg h3').textContent()).includes('pendientes'),'no retira con deudas'); await ph.locator('.dlg .btn').click();
 await ph.locator('[aria-label=Volver]').click(); await ph.getByRole('button',{name:/Agregar entidad/}).first().click(); await ph.locator('#e-name').fill('Bold'); await ph.locator('#e-lim').fill('300000'); await ph.locator('.sf .btn').click();
 ok(await ph.locator('.entc').count()===3,'entidad nueva'); await ph.locator('.entc',{hasText:'Bold'}).click(); await ph.getByRole('button',{name:'Retirar entidad'}).click(); await ph.locator('.dlg .btn.d').click();
 ok(await t()==='Créditos de compra'&&await ph.locator('.entc').count()===2,'entidad retirada y vuelve');
 await p.screenshot({path:'credits.png'});
 // Inicio refleja
 await ph.locator('.nav button',{hasText:'Inicio'}).click(); ok(await ph.locator('.due').count()===4,'inicio sigue con próximos');
 // Ingresos tab
 await J('Ingresos').click(); ok(await ph.locator('.tabs button[aria-selected=true]').textContent()==='Ingresos','tab ingresos');
 await ph.locator('.row',{hasText:'Sueldo'}).click(); await ph.locator('.mo',{hasText:'Eliminar'}).click(); await ph.locator('.dlg .btn.d').click(); ok(await ph.locator('.row',{hasText:'Sueldo'}).count()===0,'ingreso eliminado');
 // estados
 await p.locator('.seg button',{hasText:'Cargando'}).click(); ok(await ph.locator('.skel').count()>0,'cargando');
 await p.locator('.seg button',{hasText:'Error'}).click(); ok(await ph.getByRole('button',{name:'Intentar de nuevo'}).count()===1,'error'); await ph.getByRole('button',{name:'Intentar de nuevo'}).click();
 // comparar capturas
 await p.locator('.seg button',{hasText:'Con datos'}).click(); await p.locator('.seg button',{hasText:'Comparar'}).click();
 for(const [n,f] of [['Suscripciones','c-subs'],['Gastos futuros','c-plans'],['Deudas','c-debts'],['Créditos','c-credits'],['Detalle Addi','c-addi']]){await J(n).click();await p.waitForTimeout(150);await p.screenshot({path:f+'.png'});}
 for(const w of [390,360]){await p.setViewportSize({width:w,height:800});for(const n of ['Suscripciones','Gastos futuros','Deudas','Créditos','Detalle Addi']){await J(n).click();const ov=await p.evaluate(()=>document.documentElement.scrollWidth-innerWidth);if(ov>0)ok(false,'overflow '+w+' '+n+' '+ov);}}
 ok(true,'responsive revisado');
 ok(errs.length===0,'sin errores JS '+errs.join(' | '));
 await b.close();})();
