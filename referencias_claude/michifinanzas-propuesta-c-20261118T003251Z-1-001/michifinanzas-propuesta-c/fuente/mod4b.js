/* ======================= Ahorros y préstamos a terceros ======================= */
function Savings({s,ui,set,open}){
  const tab=ui.saveTab;
  const lent=sum(s.loans,l=>l.amount), back=sum(s.loans,l=>l.returned), pend=lent-back;
  const status=l=>l.returned>=l.amount?['Devuelto','ok']:l.returned>0?['Parcialmente devuelto','soft']:['Pendiente','warn2'];
  return html`<div>
   <div class="tabs" role="tablist" aria-label="Sección">${[['ahorro','Mi ahorro'],['prest','Dinero prestado']].map(([k,l])=>html`<button key=${k} role="tab" aria-selected=${tab===k} onClick=${()=>set({saveTab:k})}>${l}</button>`)}</div>
   ${tab==='ahorro'?html`<div>
    <section class="sbal" aria-label="Ahorro acumulado"><small>Ahorro acumulado</small><span class="amt">${fmt(s.savings)}</span><p>Un poquito hoy, un gran paso mañana.</p>
     <div class="row2"><button class="btn p sm" onClick=${()=>open('saving',{type:'Aporte'})}><${I} n="plus" s=${18}/>Separar dinero</button><button class="btn s sm" disabled=${!s.savings} onClick=${()=>open('saving',{type:'Retiro'})}>Retirar</button></div></section>
    <${Note}>Separar y retirar son movimientos internos: no cuentan como ingresos ni gastos. Tu ahorro no se suma al dinero disponible.<//>
    <${SecHead} title="Tu historial"><span class="mut">${s.smoves.length}</span><//>
    <div class="card" style=${{paddingBlock:s.smoves.length?'4px':'16px'}}>${s.smoves.length?s.smoves.map(m=>html`<div class="row" key=${m.id} style=${{cursor:'default'}}>
      <span class="bub" style=${{background:m.type==='Aporte'?'var(--primary-soft)':'var(--sunk)',color:m.type==='Aporte'?'var(--primary)':'var(--ink2)'}}><${I} n=${m.type==='Aporte'?'piggy':'out'} s=${20}/></span>
      <span><span class="t" style=${{display:'block'}}>${m.type==='Aporte'?'Aporte a tus ahorros':'Retiro de ahorros'}</span><span class="s" style=${{display:'block'}}>${m.type==='Aporte'?'Desde':'Hacia'} ${accOf(m.acc).name} · ${dayLabel(m.date)}</span></span>
      <span class=${'amt '+(m.type==='Aporte'?'':'mut')} style=${{color:m.type==='Aporte'?'var(--primary)':null}}>${m.type==='Aporte'?'+':'−'}${fmt(m.amount)}</span></div>`)
     :html`<${Empty} cat="ahorros" title="Tu primer aporte empieza aquí" text="Separa un poquito de lo que recibes y míralo crecer." action="Separar dinero" onAction=${()=>open('saving',{type:'Aporte'})}/>`}</div>
   </div>`:html`<div>
    <div class="card"><${Vals} items=${[['Prestado',fmt(lent)],['Devuelto',fmt(back),'pos'],['Pendiente por cobrar',fmt(pend),pend?'warn':'']]}/>
     <button class="btn p" style=${{marginTop:'14px'}} onClick=${()=>open('loan')}><${I} n="hand" s=${20}/>Prestar dinero</button></div>
    <${Note}>Es dinero que le prestaste a otras personas. No es tu ahorro ni una deuda tuya.<//>
    <${SecHead} title="Préstamos"><span class="mut">${s.loans.length}</span><//>
    ${s.loans.length?s.loans.map(l=>{const [st,k]=status(l),left=l.amount-l.returned,late=left>0&&l.due&&l.due<TODAY;return html`<div class="card loanc" key=${l.id}>
      <div class="h3"><span class="bub"><${I} n="user" s=${20}/></span><span><b>${l.person}</b><span class="mut">Entregado el ${longDate(l.date)} desde ${accOf(l.acc).name}</span></span><${Tag} kind=${k}>${st}<//></div>
      <${Vals} items=${[['Prestado',fmt(l.amount)],['Devuelto',fmt(l.returned),'pos'],['Pendiente',fmt(left),left?'warn':'']]}/>
      <${Bar} value=${l.returned} total=${l.amount} color="var(--pos)" label=${`Devuelto ${pct(l.returned,l.amount)} %`}/>
      ${l.due&&left>0&&html`<p class=${late?'warnline':'caption'}>${late?html`<${I} n="alert" s=${16}/>`:''}Devolución acordada: ${longDate(l.due)} · ${dueLabel(l.due)}</p>`}
      <div class="row2">${left>0&&html`<button class="btn p sm" onClick=${()=>open('loanRet',l)}>Registrar devolución</button>`}<button class="btn s sm" onClick=${()=>open('loanHist',l)}>Devoluciones (${l.rets.length})</button></div>
     </div>`})
    :html`<div class="card"><${Empty} cat="vacio" title="Sin préstamos" text="Todavía no has prestado dinero a nadie." action="Prestar dinero" onAction=${()=>open('loan')}/></div>`}
   </div>`}
  </div>`;
}

/* ======================= Configuración ======================= */
function Settings({s,ui,set,open,menu,confirm,dispatch,toast}){
  const [name,setName]=useState(ui.userName);const [tried,setTried]=useState(false);
  const nn=normName(name), nameOk=!!nn&&NAME_RE.test(nn);
  const used=c=>s.expenses.filter(e=>e.cat===c).length+s.plans.filter(p=>p.cat===c).length+s.debts.filter(x=>x.cat===c).length;
  const delCat=c=>{const u=used(c);
    if(c==='Suscripción')return confirm({title:'Esta categoría es necesaria para el historial',body:'La categoría Suscripción se conserva para tu historial de pagos.',icon:'lock'});
    if(u)return confirm({title:'Esta categoría está en uso y no se puede quitar',body:`Tiene ${u} ${u===1?'registro asociado':'registros asociados'}. Quitarla dejaría ese historial sin categoría.`,icon:'lock'});
    if(s.cats.filter(x=>x!=='Suscripción').length<=1)return confirm({title:'Necesitas al menos una categoría',body:'Deja al menos una categoría para organizar tus gastos.',icon:'info'});
    confirm({title:'¿Quitar esta categoría?',body:`«${c}» ya no aparecerá al registrar gastos.`,ok:'Quitar categoría',cancel:'Conservar',danger:true,icon:'trash',action:()=>{dispatch({t:'delCat',c});toast('Categoría quitada.')}});};
  const delAcc=a=>accHasHistory(s,a.id)||s.bal[a.id]?confirm({title:'Esta cuenta tiene historial',body:'Las cuentas con movimientos no se eliminan, para proteger tu historial. Puedes cambiarle el nombre.',icon:'lock'})
    :confirm({title:'¿Eliminar esta cuenta?',body:`«${a.name}» no tiene movimientos. Se quitará de tu lista.`,ok:'Eliminar cuenta',cancel:'Conservar',danger:true,icon:'trash',action:()=>{dispatch({t:'delAcc',id:a.id});toast('Cuenta eliminada.')}});
  const trMenu=t=>menu({title:`${accOf(t.from).name} → ${accOf(t.to).name} · ${fmt(t.amount)}`,items:[['pencil','Editar transferencia',()=>open('transfer',t)],
    ['undo','Revertir',()=>confirm({title:'¿Revertir esta transferencia?',body:'Se revertirán ambos movimientos y el saldo volverá al origen.',ok:'Revertir',cancel:'Conservar',danger:true,icon:'undo',action:()=>{dispatch({t:'revertTransfer',tr:t});toast('Transferencia revertida.')}}),true]]});
  return html`<div>
   <p class="lead">Personaliza tus preferencias locales.</p>
   <div class="card setsec"><h3>Tu nombre</h3>
    <label class="fl" for="cfg-name" style=${{marginTop:'8px'}}>Nombre</label>
    <div class="inl-add" style=${{marginTop:0}}><input id="cfg-name" class="field" value=${name} onInput=${e=>setName(e.target.value)}/><button class="btn s sm" onClick=${()=>{setTried(true);if(!nameOk)return;set({userName:nn});setTried(false);toast('Nombre guardado.')}}>Guardar nombre</button></div>
    <${Err} m=${tried&&!nameOk&&'Usa solo letras españolas y espacios entre nombres.'}/></div>
   <div class="card setsec"><h3>Categorías de gastos</h3><span class="mut">Las categorías con gastos no se pueden quitar, para proteger tu historial.</span>
    ${s.cats.map(c=>{const u=used(c),prot=c==='Suscripción';return html`<div class="srow" key=${c}><span class="bub" style=${{color:catInfo(c)[1]}}><${I} n=${catInfo(c)[0]} s=${18}/></span>
      <span><b>${c}</b><span class="mut">${prot?'Necesaria para conservar el historial de suscripciones':u?`${u} ${u===1?'registro':'registros'} · en uso`:'Disponible para nuevos gastos'}</span></span>
      <span class="acts"><button class="ib" aria-label=${'Editar '+c} disabled=${prot} onClick=${()=>open('catForm',{name:c})}><${I} n="pencil" s=${18}/></button><button class="ib" aria-label=${'Quitar '+c} onClick=${()=>delCat(c)}>${prot||u?html`<${I} n="lock" s=${18}/>`:html`<${I} n="trash" s=${18}/>`}</button></span></div>`})}
    <button class="btn o" onClick=${()=>open('catForm')}><${I} n="plus" s=${18}/>Agregar categoría</button></div>
   <div class="card setsec"><h3>Cuentas digitales</h3><span class="mut">Agrega las que uses; no crearemos bancos por ti.</span>
    ${ACC.filter(a=>a.kind==='digital').length?ACC.filter(a=>a.kind==='digital').map(a=>{const h=accHasHistory(s,a.id);return html`<div class="srow" key=${a.id}><span class="bub" style=${{color:a.color}}><${I} n=${a.icon} s=${18}/></span>
      <span><b>${a.name}</b><span class="mut">${fmt(s.bal[a.id]||0)} · ${h?'con historial':'sin movimientos'}</span></span>
      <span class="acts"><button class="ib" aria-label=${'Editar '+a.name} onClick=${()=>open('accForm',a)}><${I} n="pencil" s=${18}/></button><button class="ib" aria-label=${'Eliminar '+a.name} onClick=${()=>delAcc(a)}>${h?html`<${I} n="lock" s=${18}/>`:html`<${I} n="trash" s=${18}/>`}</button></span></div>`})
     :html`<p class="mut" style=${{fontSize:'14px'}}>Aún no tienes cuentas digitales. Agrega las que uses; no crearemos bancos por ti.</p>`}
    <button class="btn o" onClick=${()=>open('accForm')}><${I} n="plus" s=${18}/>Agregar cuenta digital</button></div>
   <div class="card setsec"><h3>Transferencias internas</h3><span class="mut">Mueve dinero entre efectivo y tus cuentas sin registrarlo como ingreso o gasto. Toca una para editarla o revertirla.</span>
    ${s.transfers.length?s.transfers.map(t=>html`<${TransferRow} t=${t} key=${t.id} onOpen=${trMenu}/>`):html`<p class="mut" style=${{fontSize:'14px'}}>Todavía no hay transferencias.</p>`}
    <button class="btn s" style=${{marginTop:'12px'}} onClick=${()=>open('transfer')}><${I} n="swap" s=${18}/>Registrar transferencia</button></div>
   <div class="card setsec disabledrow" aria-disabled="true"><h3>Apariencia</h3><span class="mut">Espacio reservado para elegir tema claro u oscuro. Hoy la app solo tiene tema oscuro.</span>
    <div class="srow"><span class="bub"><${I} n="sun" s=${18}/></span><span><b>Tema</b><span class="mut">Claro · Oscuro</span></span><${Tag}>Próximamente<//></div></div>
   <div class="card setsec"><h3>Datos locales</h3><span class="mut">Los registros se almacenan en este dispositivo. No se sincronizan con otros celulares.</span>
    <button class="btn dd" onClick=${()=>confirm({title:'¿Borrar todos tus datos?',body:'Se borrarán ingresos, gastos, deudas, préstamos, ahorros, planes de gastos futuros y sus reservas. Las categorías se conservarán. No podrás deshacerlo.',ok:'Sí, borrar todo',cancel:'Conservar mis datos',danger:true,icon:'trash',action:()=>{dispatch({t:'wipe'});toast('Listo, borramos tus datos financieros.')}})}><${I} n="trash" s=${18}/>Borrar todos los datos</button></div>
  </div>`;
}
