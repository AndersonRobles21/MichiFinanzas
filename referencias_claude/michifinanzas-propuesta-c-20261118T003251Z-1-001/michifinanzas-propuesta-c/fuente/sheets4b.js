/* ======================= Hojas de Ahorros y Configuración ======================= */
function SavingSheet({s,dispatch,close,toast,edit}){
  const type=edit.type, ap=type==='Aporte';const [v,setV]=useState('');const [acc,setAcc]=useState(ap?'bancolombia':'efectivo');const [date,setDate]=useState(TODAY);const [tried,setTried]=useState(false);
  const amt=Number(v||0);const err=!amt?'Escribe un monto mayor que cero.':ap&&amt>(s.bal[acc]||0)?'Uy, parece que no alcanza la platica para eso.':!ap&&amt>s.savings?'No puedes retirar más de lo que tienes ahorrado.':'';
  return html`<${Sheet} title=${ap?'Aporte a tus ahorros':'Retiro de ahorros'} onClose=${close} footer=${html`<button class="btn p" onClick=${()=>{setTried(true);if(err)return;dispatch({t:'saving',type,v:amt,acc,date});close();toast(ap?'Aporte guardado. ¡Buen trabajo!':'Retiro listo. El saldo ya está actualizado.',true)}}><${I} n="check"/>${ap?'Guardar aporte':'Guardar retiro'}</button>`}>
   <${Money} id="sv-monto" label="Monto" value=${v} onChange=${setV}/><${Err} m=${tried&&err}/>
   <span class="fl">${ap?'¿De dónde sale?':'¿A dónde va?'}</span><${AccPicker} bal=${s.bal} value=${acc} onPick=${setAcc} label="Medio del movimiento"/>
   <ul class="tlist"><li><span>Tu ahorro quedará en</span><b class="amt">${sfmt(s.savings+(ap?amt:-amt))}</b></li><li><span>${accOf(acc).name} quedará en</span><b class="amt">${sfmt((s.bal[acc]||0)+(ap?-amt:amt))}</b></li></ul>
   <label class="fl" for="sv-fecha">Fecha</label><input id="sv-fecha" type="date" class="field" value=${date} max=${TODAY} onInput=${e=>setDate(e.target.value||TODAY)}/>
   <p class="hint">No cuenta como ingreso ni gasto.</p>
  <//>`;
}
function LoanSheet({s,dispatch,close,toast}){
  const [f,setF]=useState({person:'',amount:'',acc:'nequi',date:TODAY,due:''});const [step,setStep]=useState(1);const [tried,setTried]=useState(false);
  const amt=Number(f.amount||0);
  const err=!f.person.trim()?'Escribe el nombre de la persona.':!amt?'Escribe un monto mayor que cero.':amt>(s.bal[f.acc]||0)?'Uy, parece que no alcanza la platica para eso.':f.due&&f.due<=f.date?'La fecha acordada debe ser posterior a la entrega.':'';
  const save=()=>{dispatch({t:'loan',x:{id:uid(),person:normName(f.person),amount:amt,acc:f.acc,date:f.date,due:f.due||null,returned:0,rets:[]}});close();toast('¡Listo! El préstamo quedó registrado.',true)};
  return html`<${Sheet} title=${step===1?'Prestar dinero':'Revisar entrega'} onClose=${close} footer=${step===1?html`<button class="btn p" onClick=${()=>{setTried(true);if(!err)setStep(2)}}>Revisar entrega</button>`
    :html`<div class="two"><button class="btn s" onClick=${()=>setStep(1)}>Volver</button><button class="btn p" onClick=${save}>Confirmar entrega</button></div>`}>
   ${step===1?html`<div>
    <label class="fl" for="l-person" style=${{marginTop:'4px'}}>Persona</label><input id="l-person" class="field" placeholder="¿A quién le prestas?" value=${f.person} onInput=${e=>setF({...f,person:e.target.value})}/>
    <${Money} id="l-amount" label="Cantidad prestada" value=${f.amount} onChange=${v=>setF({...f,amount:v})}/>
    <span class="fl">Medio de entrega</span><${AccPicker} bal=${s.bal} value=${f.acc} onPick=${v=>setF({...f,acc:v})} label="Medio de entrega"/>
    <div class="two"><div><label class="fl" for="l-date">Fecha de entrega</label><input id="l-date" type="date" class="field" value=${f.date} max=${TODAY} onInput=${e=>setF({...f,date:e.target.value||TODAY})}/></div>
     <div><label class="fl" for="l-due">Fecha límite de pago</label><input id="l-due" type="date" class="field" value=${f.due} onInput=${e=>setF({...f,due:e.target.value})}/></div></div>
    <${Err} m=${tried&&err}/></div>`
   :html`<div><ul class="tlist"><li><span>Persona</span><b>${normName(f.person)}</b></li><li><span>Cantidad</span><b class="amt">${fmt(amt)}</b></li><li><span>Sale de</span><b>${accOf(f.acc).name}</b></li>
     <li><span>Fecha de entrega</span><b>${longDate(f.date)}</b></li><li><span>Devolución acordada</span><b>${f.due?longDate(f.due):'Sin fecha'}</b></li><li><span>Te quedarán en ${accOf(f.acc).name}</span><b class="amt">${fmt((s.bal[f.acc]||0)-amt)}</b></li></ul>
     <${Note}>El dinero sale de tu cuenta, pero no es un gasto: quedará como pendiente por cobrar.<//></div>`}
  <//>`;
}
function LoanReturn({s,dispatch,close,toast,edit:l}){
  const left=l.amount-l.returned;const [v,setV]=useState(String(left));const [acc,setAcc]=useState(l.acc);const [date,setDate]=useState(TODAY);const [tried,setTried]=useState(false);
  const amt=Number(v||0);const err=!amt?'Escribe un monto mayor que cero.':amt>left?'Esa cantidad supera lo que falta por cobrar.':'';
  return html`<${Sheet} title="Registrar devolución" onClose=${close} footer=${html`<button class="btn p" onClick=${()=>{setTried(true);if(err)return;dispatch({t:'loanRet',id:l.id,v:amt,acc,date});close();toast('Devolución guardada. El saldo ya está actualizado.',true)}}><${I} n="check"/>Guardar devolución</button>`}>
   <p class="mut" style=${{margin:'2px 0 4px'}}>${l.person} · pendiente por cobrar <b class="amt">${fmt(left)}</b></p>
   <${Money} id="lr-monto" label="Importe recibido" value=${v} onChange=${setV}/><${Err} m=${tried&&err}/>
   <span class="fl">Medio de recepción</span><${AccPicker} bal=${s.bal} value=${acc} onPick=${setAcc} label="Medio de recepción"/>
   <label class="fl" for="lr-fecha">Fecha</label><input id="lr-fecha" type="date" class="field" value=${date} max=${TODAY} onInput=${e=>setDate(e.target.value||TODAY)}/>
   <p class="hint">No cuenta como ingreso: es dinero que vuelve.</p>
  <//>`;
}
function LoanHist({close,edit:l}){return html`<${Sheet} title=${'Devoluciones de '+l.person} onClose=${close} footer=${html`<button class="btn s" onClick=${close}>Cerrar</button>`}>
  ${l.rets.length?html`<ul class="tlist">${l.rets.map((r,k)=>html`<li key=${k}><span>${longDate(r.date)} · ${accOf(r.acc).name}</span><b class="amt">${fmt(r.amount)}</b></li>`)}</ul>`:html`<p class="mut">Todavía no hay devoluciones.</p>`}<//>`}
function CatSheet({s,dispatch,close,toast,edit}){
  const [v,setV]=useState(edit?edit.name:'');const [tried,setTried]=useState(false);const n=normName(v);
  const err=!n?'Escribe un nombre para la categoría.':s.cats.some(c=>c.toLowerCase()===n.toLowerCase()&&c!==(edit&&edit.name))?'Ya tienes una categoría con ese nombre.':'';
  return html`<${Sheet} title=${edit?'Editar categoría':'Agregar categoría'} onClose=${close} footer=${html`<button class="btn p" onClick=${()=>{setTried(true);if(err)return;dispatch(edit?{t:'renameCat',from:edit.name,to:n}:{t:'addCat',c:n});close();toast(edit?'Categoría actualizada.':'Categoría agregada. Ya puedes usarla.',true)}}>${edit?'Guardar':'Agregar'}</button>`}>
   <label class="fl" for="cat-n" style=${{marginTop:'4px'}}>Nombre</label><input id="cat-n" class="field" maxlength="30" placeholder="Ej. Mascotas" value=${v} onInput=${e=>setV(e.target.value)}/><${Err} m=${tried&&err}/>
   ${edit&&html`<p class="hint">El cambio se aplica también a los gastos que ya tienen esta categoría.</p>`}<//>`;
}
function AccSheet({dispatch,close,toast,edit}){
  const [v,setV]=useState(edit?edit.name:'');const [tried,setTried]=useState(false);const n=normName(v);
  const err=!n?'Escribe el nombre de la cuenta.':ACC.some(a=>a.name.toLowerCase()===n.toLowerCase()&&a.id!==(edit&&edit.id))?'Ya tienes una cuenta con ese nombre.':'';
  return html`<${Sheet} title=${edit?'Editar cuenta':'Nueva cuenta digital'} onClose=${close} footer=${html`<button class="btn p" onClick=${()=>{setTried(true);if(err)return;dispatch({t:'acc',id:edit&&edit.id,name:n});close();toast(edit?'Cuenta actualizada.':'Cuenta digital agregada.',true)}}>Guardar</button>`}>
   <label class="fl" for="acc-n" style=${{marginTop:'4px'}}>Nombre de la cuenta</label><input id="acc-n" class="field" maxlength="40" placeholder="Ej. Mi billetera" value=${v} onInput=${e=>setV(e.target.value)}/><${Err} m=${tried&&err}/>
   <p class="hint">${edit?'El nuevo nombre aparece en todo tu historial.':'Empieza con saldo $ 0. Para llenarla, registra un ingreso o una transferencia.'}</p><//>`;
}
