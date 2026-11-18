{
const {useState,useReducer,useEffect,useRef}=React;
const html=htmLite(React.createElement);

/* ======================= Utilidades ======================= */
const fmt=n=>'$ '+Math.round(Math.abs(n)).toLocaleString('es-CO');
const sfmt=n=>(n<0?'−':'')+fmt(n);
const TODAY='2026-11-17';
const MES=['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
const MESL=['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
const pad=n=>String(n).padStart(2,'0');
const d=s=>new Date(s+'T12:00:00');
const iso=x=>`${x.getFullYear()}-${pad(x.getMonth()+1)}-${pad(x.getDate())}`;
const days=(a,b)=>Math.round((d(b)-d(a))/864e5);
const addDays=(s,n)=>{const x=d(s);x.setDate(x.getDate()+n);return iso(x)};
const addMonths=(s,n,anchor)=>{const x=d(s);const day=anchor||x.getDate();x.setDate(1);x.setMonth(x.getMonth()+n);const last=new Date(x.getFullYear(),x.getMonth()+1,0).getDate();x.setDate(Math.min(day,last));return iso(x)};
const dayLabel=s=>{const n=days(s,TODAY);if(n===0)return 'Hoy';if(n===1)return 'Ayer';const x=d(s);return `${x.getDate()} de ${MES[x.getMonth()]}`+(x.getFullYear()!==2026?' '+x.getFullYear():'')};
const longDate=s=>{const x=d(s);return `${x.getDate()} de ${MESL[x.getMonth()].toLowerCase()} de ${x.getFullYear()}`};
const dueLabel=s=>{const n=days(TODAY,s);return n<0?`Venció hace ${-n} ${-n===1?'día':'días'}`:n===0?'Hoy':n===1?'Mañana':`En ${n} días`};
const digits=v=>String(v).replace(/\D/g,'').slice(0,10);
const pct=(a,b)=>b?Math.round(a/b*100):0;
const uid=()=>Math.random().toString(36).slice(2,8);
const sum=(a,f)=>a.reduce((t,x)=>t+f(x),0);
const normName=v=>v.trim().replace(/\s+/g,' ');
const NAME_RE=/^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+( [A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$/;

/* ======================= Íconos ======================= */
const P={home:['M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z'],list:['M8 6h13','M8 12h13','M8 18h13','M3.5 6h.01','M3.5 12h.01','M3.5 18h.01'],plus:['M12 5v14','M5 12h14'],
cal:['M4 5h16v16H4z','M16 3v4','M8 3v4','M4 10h16'],grid:['M4 4h7v7H4z','M13 4h7v7h-7z','M4 13h7v7H4z','M13 13h7v7h-7z'],in:['M17 7 7 17','M16 17H7V8'],out:['M7 17 17 7','M8 7h9v9'],
swap:['M7 4 3 8l4 4','M3 8h14','M17 20l4-4-4-4','M21 16H7'],cash:['M2 7h20v10H2z','M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5','M6 12h.01','M18 12h.01'],
mobile:['M7 2h10a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1','M11 18h2'],bank:['M3 10 12 4l9 6','M5 10v8','M10 10v8','M14 10v8','M19 10v8','M3 20h18'],
chev:['m9 6 6 6-6 6'],chevd:['m6 9 6 6 6-6'],back:['m15 6-6 6 6 6'],x:['M18 6 6 18','m6 6 12 12'],check:['M20 6 9 17l-5-5'],lock:['M6 11h12v10H6z','M8 11V7a4 4 0 0 1 8 0v4'],
bulb:['M9 18h6','M10 22h4','M12 2a7 7 0 0 0-4 12.7V16h8v-1.3A7 7 0 0 0 12 2'],chart:['M3 3v18h18','M8 17v-6','M13 17V7','M18 17v-9'],
gear:['M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6','M12 2v3','M12 19v3','M4.9 4.9 7 7','M17 17l2.1 2.1','M2 12h3','M19 12h3','M4.9 19.1 7 17','M17 7l2.1-2.1'],
piggy:['M19 10c0-3-3-5-7-5S4 7 4 10c0 2 1 3.5 2.5 4.5V18h3v-2h5v2h3v-3.5c1-.6 1.6-1.4 1.9-2.5H21v-2z','M15 9h.01'],
card:['M2 6h20v12H2z','M2 10h20','M6 15h4'],repeat:['M17 2l4 4-4 4','M3 11V9a3 3 0 0 1 3-3h15','M7 22l-4-4 4-4','M21 13v2a3 3 0 0 1-3 3H3'],
target:['M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18','M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8','M12 12h.01'],alert:['M12 3 2 21h20z','M12 10v5','M12 18h.01'],
info:['M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18','M12 11v6','M12 7.5h.01'],debt:['M4 4h16v16H4z','M8 9h8','M8 13h8','M8 17h5'],
food:['M5 3v8a3 3 0 0 0 6 0V3','M8 3v18','M17 3c-2 0-3 3-3 6s1 4 3 4v8'],bus:['M5 4h14v12H5z','M5 11h14','M7 16v4','M17 16v4','M8 13.5h.01','M16 13.5h.01'],
bolt:['M13 2 4 14h7l-1 8 9-12h-7z'],heart:['M12 20s-8-5-8-11a5 5 0 0 1 8-3 5 5 0 0 1 8 3c0 6-8 11-8 11'],play:['M4 5h16v14H4z','M10 9l5 3-5 3z'],
signal:['M4 18v-2','M9 18v-5','M14 18V9','M19 18V5'],batt:['M3 8h16v8H3z','M21 11v2'],pencil:['M4 20h4L19 9l-4-4L4 16z','M14 6l4 4'],
wallet:['M3 7h16a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z','M3 7l13-4v4','M16 13.5h2'],dots:['M12 5h.01','M12 12h.01','M12 19h.01'],
trash:['M4 7h16','M10 11v6','M14 11v6','M6 7l1 13h10l1-13','M9 7V4h6v3'],tag:['M3 12V4h8l10 10-8 8z','M7.5 8.5h.01'],bag:['M5 8h14l-1 13H6z','M9 8V6a3 3 0 0 1 6 0v2'],
clock:['M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18','M12 7v5l3 2'],undo:['M9 14 4 9l5-5','M4 9h11a5 5 0 0 1 0 10h-3'],hand:['M7 11V6a2 2 0 0 1 4 0v5','M11 10V4a2 2 0 0 1 4 0v6','M15 10V6a2 2 0 0 1 4 0v8a7 7 0 0 1-7 7H11a7 7 0 0 1-6-3.5L3 14a2 2 0 0 1 3.4-2L8 14'],
user:['M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8','M4 21a8 8 0 0 1 16 0'],sun:['M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8','M12 2v2','M12 20v2','M4.9 4.9l1.4 1.4','M17.7 17.7l1.4 1.4','M2 12h2','M20 12h2'],
db:['M12 3c4.4 0 8 1.3 8 3s-3.6 3-8 3-8-1.3-8-3 3.6-3 8-3','M4 6v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6','M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6']};
const I=({n,s=22})=>html`<svg class="ic" width=${s} height=${s} viewBox="0 0 24 24" aria-hidden="true">${(P[n]||P.tag).map(p=>html`<path d=${p} key=${p}/>`)}</svg>`;
const Cat=({k,size='M',plate,alt=''})=>html`<span class=${'cat cat-'+size+(plate?' plate':'')}><img src=${CATS[k]} alt=${alt}/></span>`;

/* ======================= Datos de ejemplo ======================= */
const ACC0=[{id:'efectivo',name:'Efectivo',kind:'cash',color:'var(--c3)',icon:'cash'},{id:'nequi',name:'Nequi',kind:'digital',color:'var(--c1)',icon:'mobile'},
 {id:'daviplata',name:'Daviplata',kind:'digital',color:'var(--c2)',icon:'mobile'},{id:'bancolombia',name:'Bancolombia',kind:'digital',color:'var(--c4)',icon:'bank'}];
let ACC=ACC0.map(a=>({...a}));
const accOf=id=>ACC.find(a=>a.id===id)||{id,name:'Cuenta',color:'var(--c7)',icon:'wallet'};
const CATS_={'Hogar':['home','var(--c1)'],'Comida':['food','var(--c2)'],'Transporte':['bus','var(--c3)'],'Servicios':['bolt','var(--c4)'],'Salud':['heart','var(--c6)'],'Ocio':['play','var(--c5)'],'Suscripción':['repeat','var(--c7)'],'Pago de deuda':['debt','var(--c7)'],'Tecnología':['bag','var(--c5)']};
const catInfo=c=>CATS_[c]||['tag','var(--c7)'];
const E=(date,name,cat,acc,amount,debt,ref)=>({id:uid(),date,name,cat,acc,amount,debt:debt||null,ref:ref||null});
const SEED=()=>({
 bal:{efectivo:350000,nequi:800000,daviplata:500000,bancolombia:800000},
 cats:['Hogar','Comida','Transporte','Servicios','Salud','Ocio','Tecnología','Suscripción'],
 expenses:[E('2026-11-17','Droguería','Salud','efectivo',23200),E('2026-11-16','Almuerzo','Comida','efectivo',32000),E('2026-11-15','Abono préstamo de Carlos','Pago de deuda','efectivo',60000,'Deuda · cuota 3 de 10','carlos'),
  E('2026-11-14','Recarga transporte','Transporte','efectivo',48000),E('2026-11-12','Spotify','Suscripción','nequi',16900,null,'spotify'),E('2026-11-10','Abono Addi','Pago de deuda','daviplata',85000,'Crédito de compra · cuota 2 de 6','addi1'),
  E('2026-11-08','Mercado','Comida','nequi',95000),E('2026-11-03','Internet hogar','Servicios','bancolombia',89900),E('2026-11-01','Arriendo','Hogar','bancolombia',300000),
  E('2026-10-30','Abono préstamo de Carlos','Pago de deuda','efectivo',60000,'Deuda · cuota 2 de 10','carlos'),E('2026-10-27','Mercado','Comida','efectivo',64500),E('2026-10-24','Regalo cumpleaños','Ocio','efectivo',70000),
  E('2026-10-21','Netflix','Suscripción','nequi',26900,null,'netflix'),E('2026-10-20','Transporte','Transporte','efectivo',52000),E('2026-10-18','Cine','Ocio','nequi',38000),E('2026-10-12','Spotify','Suscripción','nequi',16900,null,'spotify'),
  E('2026-10-10','Abono Addi','Pago de deuda','daviplata',85000,'Crédito de compra · cuota 1 de 6','addi1'),E('2026-10-06','Mercado','Comida','nequi',132000),E('2026-10-05','Abono Sistecrédito','Pago de deuda','nequi',130000,'Crédito de compra · cuota 2 de 4','siste1'),
  E('2026-10-03','Internet hogar','Servicios','bancolombia',89900),E('2026-10-01','Arriendo','Hogar','bancolombia',300000)],
 incomes:[{id:uid(),date:'2026-11-09',type:'Dinero extra',amount:200000,dest:[['nequi',200000]]},{id:uid(),date:'2026-11-01',type:'Sueldo',amount:1800000,dest:[['bancolombia',1300000],['nequi',300000],['efectivo',200000]]},
  {id:uid(),date:'2026-10-01',type:'Sueldo',amount:1800000,dest:[['bancolombia',1300000],['nequi',300000],['efectivo',200000]]}],
 transfers:[{id:uid(),date:'2026-11-16',from:'bancolombia',to:'nequi',amount:150000},{id:uid(),date:'2026-11-06',from:'nequi',to:'efectivo',amount:100000}],
 subs:[{id:'netflix',name:'Netflix',price:26900,freq:'Mensual',next:'2026-11-21',day:21,acc:'nequi',active:true,pays:[{date:'2026-10-21',amount:26900,acc:'nequi'}]},
  {id:'spotify',name:'Spotify',price:16900,freq:'Mensual',next:'2026-12-12',day:12,acc:'nequi',active:true,pays:[{date:'2026-11-12',amount:16900,acc:'nequi'},{date:'2026-10-12',amount:16900,acc:'nequi'}]},
  {id:'disney',name:'Disney+',price:38900,freq:'Mensual',next:'2026-09-03',day:3,acc:'bancolombia',active:false,pays:[{date:'2026-08-03',amount:38900,acc:'bancolombia'}]}],
 plans:[{id:'soat',name:'SOAT de la moto',cat:'Transporte',need:420000,plan:420000,freq:'Mensual',start:'2026-10-15',due:'2026-12-15',reserved:180000,resAcc:'bancolombia',status:'activo',notes:''},
  {id:'navidad',name:'Regalos de Navidad',cat:'Ocio',need:300000,plan:240000,freq:'Quincenal',start:'2026-11-01',due:'2026-12-20',reserved:0,resAcc:null,status:'activo',notes:'Sobrinos y amigo secreto'},
  {id:'ingles',name:'Matrícula curso de inglés',cat:'Servicios',need:250000,plan:250000,freq:'Fecha única',start:'2026-08-01',due:'2026-10-01',reserved:250000,resAcc:'nequi',status:'completado',notes:''},
  {id:'viaje',name:'Viaje a Villa de Leyva',cat:'Ocio',need:600000,plan:300000,freq:'Mensual',start:'2026-06-01',due:'2026-09-15',reserved:0,resAcc:null,status:'archivado',notes:''}],
 debts:[{id:'carlos',name:'Préstamo de Carlos',orig:600000,quota:60000,n:10,paidQ:3,paid:180000,hist:1,next:'2026-11-30',day:30,entity:null,date:'2026-08-30',pays:[{date:'2026-11-15',amount:60000,acc:'efectivo'},{date:'2026-10-30',amount:60000,acc:'efectivo'}]},
  {id:'addi1',name:'Addi · Audífonos',orig:510000,quota:85000,n:6,paidQ:2,paid:170000,hist:0,next:'2026-12-10',day:10,entity:'addi',cat:'Tecnología',date:'2026-09-10',pays:[{date:'2026-11-10',amount:85000,acc:'daviplata'},{date:'2026-10-10',amount:85000,acc:'daviplata'}]},
  {id:'siste1',name:'Sistecrédito · Celular',orig:520000,quota:130000,n:4,paidQ:2,paid:260000,hist:0,next:'2026-12-05',day:5,entity:'siste',cat:'Tecnología',date:'2026-08-05',pays:[{date:'2026-10-05',amount:130000,acc:'nequi'},{date:'2026-09-05',amount:130000,acc:'nequi'}]},
  {id:'mama',name:'Préstamo de mamá',orig:200000,quota:100000,n:2,paidQ:2,paid:200000,hist:0,next:null,day:1,entity:null,date:'2026-06-01',pays:[{date:'2026-08-01',amount:100000,acc:'efectivo'},{date:'2026-07-01',amount:100000,acc:'efectivo'}]}],
 entities:[{id:'addi',name:'Addi',limit:600000,retired:false,hist:[{date:'2026-10-02',from:500000,to:600000},{date:'2026-08-20',from:0,to:500000}]},
  {id:'siste',name:'Sistecrédito',limit:800000,retired:false,hist:[{date:'2026-08-01',from:0,to:800000}]}],
 savings:300000,
 smoves:[{id:uid(),date:'2026-11-02',type:'Aporte',amount:100000,acc:'bancolombia'},{id:uid(),date:'2026-10-20',type:'Retiro',amount:50000,acc:'efectivo'},{id:uid(),date:'2026-10-02',type:'Aporte',amount:150000,acc:'bancolombia'},{id:uid(),date:'2026-09-02',type:'Aporte',amount:100000,acc:'bancolombia'}],
 loans:[{id:'julian',person:'Julián',amount:150000,acc:'nequi',date:'2026-10-05',due:'2026-11-30',returned:50000,rets:[{date:'2026-11-05',amount:50000,acc:'nequi'}]},
  {id:'vale',person:'Valentina',amount:80000,acc:'efectivo',date:'2026-09-12',due:'2026-10-12',returned:80000,rets:[{date:'2026-10-10',amount:80000,acc:'efectivo'}]}]});
const EMPTY=()=>({bal:{efectivo:0,nequi:0,daviplata:0,bancolombia:0},cats:['Hogar','Comida','Transporte','Servicios','Salud','Ocio','Suscripción'],expenses:[],incomes:[],transfers:[],subs:[],plans:[],debts:[],entities:[],savings:0,smoves:[],loans:[]});
const RANGES={mes:['2026-11-01',TODAY,'Este mes'],ant:['2026-10-01','2026-10-31','Mes anterior'],d7:[addDays(TODAY,-6),TODAY,'Últimos 7 días'],d30:[addDays(TODAY,-29),TODAY,'Últimos 30 días']};
const inR=(s,[a,b])=>s>=a&&s<=b;
const totalBal=s=>sum(Object.values(s.bal),x=>x);
const SUBF={Semanal:[52/12,'semana'],Mensual:[1,'mes'],Trimestral:[1/3,'trimestre'],Anual:[1/12,'año']};
const PLANF={Diario:1,Semanal:7,Quincenal:15,Mensual:30,'Fecha única':0};
const debtLeft=x=>x.orig-x.paid;
const planLeft=p=>Math.max(0,p.plan-p.reserved);
const planReco=p=>{const step=PLANF[p.freq];const left=planLeft(p);const dd=Math.max(0,days(TODAY,p.due));if(!left)return 0;if(!step)return left;const n=Math.max(1,Math.ceil(dd/step));return Math.ceil(left/n/100)*100;};
const entUsed=(s,e)=>sum(s.debts.filter(x=>x.entity===e.id),debtLeft);
const upcoming=s=>[
 ...s.subs.filter(x=>x.active).map(x=>({key:'s'+x.id,kind:'Suscripción',icon:'repeat',name:x.name,date:x.next,amount:x.price,sub:`Suscripción ${x.freq.toLowerCase()} · ${accOf(x.acc).name}`,to:'subs'})),
 ...s.debts.filter(x=>debtLeft(x)>0&&x.next).map(x=>({key:'d'+x.id,kind:'Cuota',icon:x.entity?'card':'debt',name:x.name,date:x.next,amount:Math.min(x.quota,debtLeft(x)),sub:`Cuota ${x.paidQ+1} de ${x.n} · ${x.entity?'crédito de compra':'deuda'}`,to:'debts'})),
 ...s.plans.filter(x=>x.status==='activo').map(x=>({key:'p'+x.id,kind:'Gasto futuro',icon:'target',name:x.name,date:x.due,amount:x.need,reserved:x.reserved,sub:`Gasto futuro · reservado ${fmt(x.reserved)}`,to:'plans'}))
].sort((a,b)=>a.date.localeCompare(b.date));

/* ======================= Reductor ======================= */
function reducer(s,a){
  if(a.t==='reset'){ACC=ACC0.map(x=>({...x}));return a.empty?EMPTY():SEED();}
  const bal={...s.bal}; const up=(k,id,f)=>s[k].map(x=>x.id===id?f(x):x); const exp=(e)=>[e,...s.expenses].sort((x,y)=>y.date.localeCompare(x.date));
  switch(a.t){
    case 'expense':{ if(a.old)bal[a.old.acc]+=a.old.amount; bal[a.e.acc]-=a.e.amount;
      const ex=a.old?s.expenses.map(x=>x.id===a.old.id?a.e:x):[a.e,...s.expenses]; return {...s,bal,expenses:ex.sort((x,y)=>y.date.localeCompare(x.date))}; }
    case 'delExpense':bal[a.e.acc]+=a.e.amount;return {...s,bal,expenses:s.expenses.filter(x=>x.id!==a.e.id)};
    case 'transfer':{ if(a.old){bal[a.old.from]+=a.old.amount;bal[a.old.to]-=a.old.amount;} bal[a.tr.from]-=a.tr.amount;bal[a.tr.to]+=a.tr.amount;
      return {...s,bal,transfers:a.old?s.transfers.map(x=>x.id===a.old.id?a.tr:x):[a.tr,...s.transfers]}; }
    case 'revertTransfer':bal[a.tr.from]+=a.tr.amount;bal[a.tr.to]-=a.tr.amount;return {...s,bal,transfers:s.transfers.filter(x=>x.id!==a.tr.id)};
    case 'income':{ if(a.old)a.old.dest.forEach(([acc,v])=>bal[acc]-=v); a.i.dest.forEach(([acc,v])=>bal[acc]+=v);
      const inc=(a.old?s.incomes.map(x=>x.id===a.old.id?a.i:x):[a.i,...s.incomes]).sort((x,y)=>y.date.localeCompare(x.date));
      return {...s,bal,incomes:inc,debts:a.debt?[a.debt,...s.debts]:s.debts}; }
    case 'delIncome':a.i.dest.forEach(([acc,v])=>bal[acc]-=v);return {...s,bal,incomes:s.incomes.filter(x=>x.id!==a.i.id)};
    /* Suscripciones */
    case 'sub':return {...s,subs:a.old?up('subs',a.x.id,()=>a.x):[...s.subs,a.x]};
    case 'paySub':{const x=s.subs.find(y=>y.id===a.id);bal[a.acc]-=x.price;const step={Semanal:[7,0],Mensual:[0,1],Trimestral:[0,3],Anual:[0,12]}[x.freq];
      const next=step[0]?addDays(x.next,step[0]):addMonths(x.next,step[1],x.day);
      return {...s,bal,expenses:exp(E(TODAY,x.name,'Suscripción',a.acc,x.price,null,x.id)),subs:up('subs',a.id,y=>({...y,next,pays:[{date:TODAY,amount:y.price,acc:a.acc},...y.pays]}))};}
    case 'subActive':return {...s,subs:up('subs',a.id,y=>({...y,active:a.on,next:a.on&&y.next<TODAY?addMonths(TODAY,0,y.day)<TODAY?addMonths(TODAY,1,y.day):addMonths(TODAY,0,y.day):y.next}))};
    /* Gastos futuros */
    case 'plan':return {...s,plans:a.old?up('plans',a.x.id,()=>a.x):[a.x,...s.plans],cats:a.newCat&&!s.cats.includes(a.newCat)?[...s.cats.slice(0,-1),a.newCat,s.cats[s.cats.length-1]]:s.cats};
    case 'reserve':bal[a.acc]-=a.v;return {...s,bal,plans:up('plans',a.id,p=>({...p,reserved:p.reserved+a.v,resAcc:a.acc}))};
    case 'release':{const p=s.plans.find(x=>x.id===a.id);bal[a.acc]+=p.reserved;return {...s,bal,plans:up('plans',a.id,x=>({...x,reserved:0,resAcc:null}))};}
    case 'planStatus':return {...s,plans:up('plans',a.id,p=>({...p,status:a.st}))};
    case 'delPlan':return {...s,plans:s.plans.filter(p=>p.id!==a.id)};
    case 'addCat':return {...s,cats:[...s.cats.slice(0,-1),a.c,s.cats[s.cats.length-1]]};
    /* Deudas */
    case 'debt':return {...s,debts:[a.x,...s.debts]};
    case 'payDebt':{const x=s.debts.find(y=>y.id===a.id);bal[a.acc]-=a.v;const paid=x.paid+a.v,done=paid>=x.orig;
      const q=done?x.n:Math.min(x.n,x.paidQ+(a.opt==='cuota'||a.v>=x.quota?Math.max(1,Math.floor(a.v/x.quota)):0));
      const e=E(a.date,x.entity?'Abono '+x.name.split(' · ')[0]:'Abono '+x.name.charAt(0).toLowerCase()+x.name.slice(1),'Pago de deuda',a.acc,a.v,`${x.entity?'Crédito de compra':'Deuda'} · ${a.opt==='todo'||done?'pago total':`cuota ${Math.min(q,x.n)} de ${x.n}`}`,x.id);
      return {...s,bal,expenses:exp(e),debts:up('debts',a.id,y=>({...y,paid,paidQ:q,next:done?null:addMonths(y.next||TODAY,1,y.day),pays:[{date:a.date,amount:a.v,acc:a.acc},...y.pays]}))};}
    case 'delDebt':return {...s,debts:s.debts.filter(x=>x.id!==a.id)};
    /* Créditos */
    case 'entity':return {...s,entities:[...s.entities,a.x]};
    case 'limit':return {...s,entities:up('entities',a.id,e=>({...e,limit:a.v,hist:[{date:TODAY,from:e.limit,to:a.v},...e.hist]}))};
    case 'retire':return {...s,entities:up('entities',a.id,e=>({...e,retired:true}))};
    /* Ahorros y préstamos */
    case 'saving':{const k=a.type==='Aporte'?1:-1;bal[a.acc]-=k*a.v;return {...s,bal,savings:s.savings+k*a.v,smoves:[{id:uid(),date:a.date,type:a.type,amount:a.v,acc:a.acc},...s.smoves]};}
    case 'loan':bal[a.x.acc]-=a.x.amount;return {...s,bal,loans:[a.x,...s.loans]};
    case 'loanRet':bal[a.acc]+=a.v;return {...s,bal,loans:up('loans',a.id,l=>({...l,returned:l.returned+a.v,rets:[{date:a.date,amount:a.v,acc:a.acc},...l.rets]}))};
    /* Configuración */
    case 'renameCat':return {...s,cats:s.cats.map(c=>c===a.from?a.to:c),expenses:s.expenses.map(e=>e.cat===a.from?{...e,cat:a.to}:e),plans:s.plans.map(p=>p.cat===a.from?{...p,cat:a.to}:p)};
    case 'delCat':return {...s,cats:s.cats.filter(c=>c!==a.c)};
    case 'acc':{ if(a.id){ACC=ACC.map(x=>x.id===a.id?{...x,name:a.name}:x);return {...s};}
      const id='acc'+uid();ACC=[...ACC,{id,name:a.name,kind:'digital',color:'var(--c6)',icon:'wallet'}];return {...s,bal:{...bal,[id]:0}}; }
    case 'delAcc':{ACC=ACC.filter(x=>x.id!==a.id);delete bal[a.id];return {...s,bal};}
    case 'wipe':return {...EMPTY(),cats:s.cats,bal:Object.fromEntries(Object.keys(s.bal).map(k=>[k,0]))};
  } return s;
}
const accHasHistory=(s,id)=>s.expenses.some(e=>e.acc===id)||s.incomes.some(i=>i.dest.some(([a])=>a===id))||s.transfers.some(t=>t.from===id||t.to===id)||s.smoves.some(m=>m.acc===id)||s.loans.some(l=>l.acc===id)||s.subs.some(x=>x.acc===id);

/* ======================= Componentes ======================= */
const Money=({value,onChange,label,id})=>html`<div class="money"><label for=${id}>${label}</label>
  <div class="inp"><span>$</span><input id=${id} inputmode="numeric" autocomplete="off" placeholder="0" style=${{width:((value?Number(value).toLocaleString('es-CO'):'0').length+0.6)+'ch'}} value=${value?Number(value).toLocaleString('es-CO'):''} onInput=${e=>onChange(digits(e.target.value))} aria-label=${label}/></div><div class="line"></div></div>`;
const MoneyField=({id,label,value,onChange,hint})=>html`<div><label class="fl" for=${id}>${label}</label><input id=${id} class="field" inputmode="numeric" placeholder="$ 0" value=${value?'$ '+Number(value).toLocaleString('es-CO'):''} onInput=${e=>onChange(digits(e.target.value))}/>${hint&&html`<p class="hint" style=${{margin:'4px 2px 0'}}>${hint}</p>`}</div>`;
const AccPicker=({bal,value,onPick,exclude,label})=>html`<div class="picker" role="group" aria-label=${label}>
  ${ACC.filter(a=>a.id!==exclude).map(a=>html`<button key=${a.id} type="button" class="pk" aria-pressed=${value===a.id} onClick=${()=>onPick(a.id)}>
   <small><i class="dot" style=${{background:a.color}}></i>${a.name}</small><span class="amt">${fmt(bal[a.id]||0)}</span></button>`)}</div>`;
const Chips=({opts,value,onPick,label,icons})=>html`<div class="chips wrap" role="group" aria-label=${label}>${opts.map(o=>html`<button key=${o} type="button" class="chip" aria-pressed=${value===o} onClick=${()=>onPick(o)}>${icons&&html`<${I} n=${catInfo(o)[0]} s=${16}/>`}${o}</button>`)}</div>`;
const Err=({m})=>m?html`<p class="err" role="alert"><${I} n="alert" s=${15}/>${m}</p>`:null;
const Sheet=({title,onClose,children,footer})=>{
  const ref=useRef();
  useEffect(()=>{const el=ref.current;el&&el.querySelector('input,button.pk,button.opt,button.mo')?.focus();const k=e=>e.key==='Escape'&&onClose();document.addEventListener('keydown',k);return()=>document.removeEventListener('keydown',k)},[]);
  return html`<div class="scrim" onClick=${onClose}></div><div class="sheet" role="dialog" aria-modal="true" aria-label=${title} ref=${ref}>
   <div class="grab"></div><div class="sh"><h3>${title}</h3><button class="ib" aria-label="Cerrar" onClick=${onClose}><${I} n="x"/></button></div>
   <div class="sb">${children}</div>${footer&&html`<div class="sf">${footer}</div>`}</div>`;
};
/* Diálogo de confirmación unificado */
const Dialog=({dlg,close})=>{const ref=useRef();useEffect(()=>{ref.current?.querySelector('button')?.focus();const k=e=>e.key==='Escape'&&close();document.addEventListener('keydown',k);return()=>document.removeEventListener('keydown',k)},[]);
  return html`<div class="scrim" style=${{zIndex:30}} onClick=${close}></div><div class="dlg" role="alertdialog" aria-modal="true" aria-labelledby="dlg-t" ref=${ref}>
   ${dlg.icon&&html`<span class=${'dlg-ic '+(dlg.danger?'neg':'')}><${I} n=${dlg.icon}/></span>`}<h3 id="dlg-t">${dlg.title}</h3><p>${dlg.body}</p>
   <div class="dlg-a">${dlg.ok?html`<button class="btn s" onClick=${close}>${dlg.cancel||'Cancelar'}</button><button class=${'btn '+(dlg.danger?'d':'p')} onClick=${()=>{close();dlg.action&&dlg.action()}}>${dlg.ok}</button>`
     :html`<button class="btn s" onClick=${close}>${dlg.cancel||'Entendido'}</button>`}</div></div>`};
/* Menú de acciones (hoja inferior) */
const MenuSheet=({m,close})=>html`<${Sheet} title=${m.title} onClose=${close}>${m.items.map(([ic,t,fn,danger])=>html`<button key=${t} class=${'mo'+(danger?' danger':'')} onClick=${()=>{close();fn()}}><${I} n=${ic} s=${20}/>${t}</button>`)}<//>`;
const Empty=({cat='vacio',title,text,action,onAction})=>html`<div class="empty"><${Cat} k=${cat} size="M"/><b>${title}</b><p>${text}</p>${action&&html`<button class="btn s" onClick=${onAction}>${action}</button>`}</div>`;
const Tag=({kind='soft',icon,children})=>html`<span class=${'tag '+kind}>${icon&&html`<${I} n=${icon} s=${13}/>`}${children}</span>`;
const Vals=({items})=>html`<div class="vals">${items.map(([l,v,c])=>html`<div key=${l}><small>${l}</small><span class=${'amt '+(c||'')}>${v}</span></div>`)}</div>`;
const Bar=({value,total,color='var(--primary)',label})=>html`<div class="prog big" role="img" aria-label=${label||`${pct(value,total)} %`}><i style=${{width:Math.min(100,pct(value,total))+'%',background:color}}></i></div>`;
/* Cupo: utilizado + disponible */
const Cupo=({used,limit})=>{const u=Math.min(used,limit),av=Math.max(0,limit-used);return html`<div class="cupo" role="img" aria-label=${`Cupo utilizado ${fmt(u)} de ${fmt(limit)}; disponible ${fmt(av)}`}>
  <div class="cupo-bar"><i class="u" style=${{width:pct(u,limit)+'%'}}></i><i class="a" style=${{width:pct(av,limit)+'%'}}></i></div>
  <div class="cupo-l"><span><i class="dot" style=${{background:'var(--orange)'}}></i>Utilizado <b class="amt">${fmt(u)}</b></span><span><i class="dot" style=${{background:'var(--pos)'}}></i>Disponible <b class="amt">${fmt(av)}</b></span></div></div>`};
const SecHead=({title,children})=>html`<div class="sec"><h3>${title}</h3>${children}</div>`;
const ExpenseRow=({e,onOpen})=>{const [ic]=catInfo(e.cat);const a=accOf(e.acc);
  return html`<button class=${'row'+(e.debt?' debt':'')} onClick=${()=>onOpen(e)} aria-label=${`${e.name}, ${fmt(e.amount)}${e.debt?', abono de deuda, solo lectura':''}`}>
   <span class="bub">${e.debt?html`<${I} n="lock" s=${20}/>`:html`<${I} n=${ic} s=${20}/>`}</span>
   <span><span class="t" style=${{display:'block'}}>${e.name}</span><span class="s" style=${{display:'block'}}>${e.debt?e.debt:e.cat} · ${a.name}</span></span>
   <span class="right"><span class="amt neg">−${fmt(e.amount)}</span>${e.debt&&html`<span class="tag lock">Solo lectura</span>`}</span></button>`};
const IncomeRow=({i,onOpen})=>html`<button class="row" onClick=${onOpen?()=>onOpen(i):undefined} style=${onOpen?null:{cursor:'default'}} aria-label=${`${i.type}, ${fmt(i.amount)}`}><span class="bub" style=${{background:'var(--pos-soft)',color:'var(--pos)'}}><${I} n="in" s=${20}/></span>
  <span><span class="t" style=${{display:'block'}}>${i.type}</span><span class="s" style=${{display:'block'}}>${i.dest.map(([a])=>accOf(a).name).join(', ')}</span></span><span class="amt pos">+${fmt(i.amount)}</span></button>`;
const TransferRow=({t,onOpen})=>html`<button class="row" onClick=${onOpen?()=>onOpen(t):undefined} style=${onOpen?null:{cursor:'default'}}><span class="bub" style=${{background:'var(--primary-soft)',color:'var(--primary)'}}><${I} n="swap" s=${20}/></span>
  <span><span class="t" style=${{display:'block'}}>Transferencia</span><span class="s" style=${{display:'block'}}>${accOf(t.from).name} → ${accOf(t.to).name} · ${dayLabel(t.date)}</span></span><span class="amt">${fmt(t.amount)}</span></button>`;
const Due=({x,onOpen})=>{const n=days(TODAY,x.date);const dd=d(x.date);
  return html`<button class="due" onClick=${onOpen} aria-label=${`${x.name}, ${fmt(x.amount)}, ${dueLabel(x.date)}`}><span class="date" aria-hidden="true"><b>${dd.getDate()}</b><span>${MES[dd.getMonth()]}</span></span>
   <span><span class="t" style=${{display:'block'}}>${x.name}</span><span class="s" style=${{display:'block'}}>${x.sub}</span>
   ${x.reserved!=null&&html`<div class="prog" role="img" aria-label=${`Reservado ${pct(x.reserved,x.amount)} %`}><i style=${{width:pct(x.reserved,x.amount)+'%'}}></i></div>`}</span>
   <span class="right"><span class="amt">${fmt(x.amount)}</span><span class=${'tag '+(n<=7?'warn':'soft')}>${n<=7?html`<${I} n="alert" s=${13}/>`:''}${dueLabel(x.date)}</span></span></button>`};
const Note=({icon='info',children})=>html`<p class="note2"><${I} n=${icon} s=${18}/><span>${children}</span></p>`;

/* ======================= Pantallas principales ======================= */
function Inicio({s,ui,go,open}){
  const [openAcc,setOpenAcc]=useState(false);
  const total=totalBal(s), dig=total-s.bal.efectivo, r=RANGES.mes;
  const inc=sum(s.incomes.filter(i=>inR(i.date,r)),i=>i.amount), exp=sum(s.expenses.filter(e=>inR(e.date,r)),e=>e.amount);
  const recent=[...s.expenses.map(e=>({...e,k:'e'})),...s.incomes.map(i=>({...i,k:'i'})),...s.transfers.map(t=>({...t,k:'t'}))].sort((a,b)=>b.date.localeCompare(a.date)).slice(0,4);
  const p=pct(exp,inc), due=upcoming(s);
  return html`<div>
   <p class="hello">Hola, <b>${ui.userName}</b>. Así va tu dinero hoy.</p>
   <section class="hero" aria-label="Dinero disponible">
    <${Cat} k="inicio" size="M" plate/>
    <small>Dinero disponible</small><span class="amt big">${fmt(total)}</span>
    <div class="split">
     <button onClick=${()=>go('cuentas')}><small><i class="dot" style=${{background:'var(--yellow)'}}></i>Efectivo</small><span class="amt">${fmt(s.bal.efectivo)}</span></button>
     <button aria-expanded=${openAcc} onClick=${()=>setOpenAcc(!openAcc)}><small><i class="dot" style=${{background:'#C9A7F0'}}></i>Digital <${I} n=${openAcc?'chevd':'chev'} s=${16}/></small><span class="amt">${fmt(dig)}</span></button>
    </div>
    ${openAcc&&html`<ul class="acclist">${ACC.filter(a=>a.kind==='digital').map(a=>html`<li key=${a.id}><span><${I} n=${a.icon} s=${18}/>${a.name}</span><span class="amt">${fmt(s.bal[a.id]||0)}</span></li>`)}</ul>`}
    <button class="more" onClick=${()=>go('cuentas')}>Ver cuentas y transferencias <${I} n="chev" s=${18}/></button>
   </section>
   <div class="quick">
    <button class="qa in" onClick=${()=>open('income')}><i><${I} n="in"/></i>Agregar ingreso</button>
    <button class="qa out" onClick=${()=>open('expense')}><i><${I} n="out"/></i>Registrar gasto</button>
    <button class="qa tr" onClick=${()=>open('transfer')}><i><${I} n="swap"/></i>Transferir</button>
   </div>
   <${SecHead} title=${MESL[10]+' 2026'}><button class="link" onClick=${()=>go('stats')}>Estadísticas <${I} n="chev" s=${16}/></button><//>
   <div class="card">
    <div class="month"><div class="metric"><small>Ingresos del mes</small><span class="amt pos">${fmt(inc)}</span></div><div class="metric"><small>Gastos del mes</small><span class="amt neg">${fmt(exp)}</span></div></div>
    <div class="meter" style=${{marginTop:'14px'}} role="img" aria-label=${`Has gastado el ${p} % de tus ingresos`}><i style=${{width:Math.min(p,100)+'%',background:'var(--neg)'}}></i></div>
    <p class="caption">${inc?`Has gastado el ${p} % de lo que recibiste este mes.`:'Aún no registras ingresos este mes.'}</p>
    <button class="saving" onClick=${()=>go('savings')}><span style=${{display:'flex',gap:'8px',alignItems:'center'}}><${I} n="piggy" s=${20}/>Ahorro acumulado</span><span class="amt">${fmt(s.savings)}</span></button>
   </div>
   <${SecHead} title="Próximos pagos">${due.length>0&&html`<button class="link" onClick=${()=>go('comp')}>Ver todos <${I} n="chev" s=${16}/></button>`}<//>
   <div class="card">${due.length?due.slice(0,4).map(x=>html`<${Due} x=${x} key=${x.key} onOpen=${()=>go(x.to)}/>`):html`<${Empty} title="Nada pendiente" text="No tienes pagos o planes próximos."/>`}</div>
   <${SecHead} title="Movimientos recientes">${recent.length>0&&html`<button class="link" onClick=${()=>go('mov')}>Ver todos <${I} n="chev" s=${16}/></button>`}<//>
   <div class="card" style=${{paddingBlock:'6px'}}>${recent.length?recent.map(m=>m.k==='e'?html`<${ExpenseRow} e=${m} key=${m.id} onOpen=${x=>open(x.debt?'debtinfo':'expense',x)}/>`:m.k==='i'?html`<${IncomeRow} i=${m} key=${m.id}/>`:html`<${TransferRow} t=${m} key=${m.id}/>`)
     :html`<${Empty} title="Sin movimientos" text="Cuando registres un ingreso o un gasto, aparecerá aquí."/>`}</div>
   ${inc>0&&html`<${Note} icon="bulb">Consejo: aparta el ahorro apenas recibas el sueldo; lo que queda es lo que puedes gastar.<//>`}
  </div>`;
}

function Movimientos({s,ui,set,open,menu,confirm,dispatch,toast}){
  const tab=ui.movTab, month=ui.month, r=month==='nov'?RANGES.mes:RANGES.ant;
  const list=s.expenses.filter(e=>inR(e.date,r)), total=sum(list,e=>e.amount);
  const incs=s.incomes.filter(i=>inR(i.date,r)), inc=sum(incs,i=>i.amount);
  const byCat=Object.entries(list.reduce((m,e)=>(m[e.cat]=(m[e.cat]||0)+e.amount,m),{})).sort((a,b)=>b[1]-a[1]);
  const shown=list.filter(e=>!ui.cat||e.cat===ui.cat);
  const groups=shown.reduce((m,e)=>((m[e.date]=m[e.date]||[]).push(e),m),{});
  const igroups=incs.reduce((m,e)=>((m[e.date]=m[e.date]||[]).push(e),m),{});
  const incMenu=i=>menu({title:`${i.type} · ${fmt(i.amount)}`,items:[['pencil','Editar ingreso',()=>open('income',i)],['trash','Eliminar ingreso',()=>confirm({title:'¿Eliminar este ingreso?',body:`Se descontarán ${fmt(i.amount)} de ${i.dest.map(([a])=>accOf(a).name).join(', ')}. No podrás deshacerlo.`,ok:'Eliminar',danger:true,icon:'trash',action:()=>{dispatch({t:'delIncome',i});toast('Ingreso eliminado.')}}),true]]});
  const byType=['Sueldo','Dinero extra','Préstamo recibido'].map(t=>[t,sum(incs.filter(i=>i.type===t),i=>i.amount)]).filter(x=>x[1]);
  return html`<div>
   <div class="tabs" role="tablist" aria-label="Tipo de movimiento">${[['gastos','Gastos'],['ingresos','Ingresos']].map(([k,l])=>html`<button key=${k} role="tab" aria-selected=${tab===k} onClick=${()=>set({movTab:k})}>${l}</button>`)}</div>
   <div class="monthsel"><button class="ib" aria-label="Mes anterior" disabled=${month==='oct'} onClick=${()=>set({month:'oct',cat:null})}><${I} n="back"/></button><b>${month==='nov'?'Noviembre':'Octubre'} 2026</b><button class="ib" aria-label="Mes siguiente" disabled=${month==='nov'} onClick=${()=>set({month:'nov',cat:null})}><${I} n="chev"/></button></div>
   ${tab==='gastos'?html`<div>
    <div class="card sum"><small class="mut">Total gastado</small><span class="amt big neg">${fmt(total)}</span>
     <span class="mut" style=${{fontSize:'13px'}}>${list.length} movimientos${inc?` · ${pct(total,inc)} % de tus ingresos`:''}</span>
     ${total>0&&html`<div class="catbar" role="img" aria-label="Gastos por categoría">${byCat.map(([c,v])=>html`<i key=${c} style=${{width:pct(v,total)+'%',background:catInfo(c)[1]}}></i>`)}</div>
     <div class="leg">${byCat.slice(0,4).map(([c,v])=>html`<span key=${c}><i class="dot" style=${{background:catInfo(c)[1]}}></i>${c} ${fmt(v)}</span>`)}</div>`}
    </div>
    ${list.length>0&&html`<div class="chips" role="group" aria-label="Filtrar por categoría" style=${{marginTop:'14px'}}>
     <button class="chip" aria-pressed=${!ui.cat} onClick=${()=>set({cat:null})}>Todas</button>
     ${byCat.map(([c])=>html`<button key=${c} class="chip" aria-pressed=${ui.cat===c} onClick=${()=>set({cat:c})}><${I} n=${catInfo(c)[0]} s=${16}/>${c}</button>`)}</div>`}
    ${list.length?Object.entries(groups).map(([day,es])=>html`<div key=${day}><p class="day">${dayLabel(day)}</p><div class="card" style=${{paddingBlock:'4px'}}>${es.map(e=>html`<${ExpenseRow} e=${e} key=${e.id} onOpen=${x=>open(x.debt?'debtinfo':'expense',x)}/>`)}</div></div>`)
     :html`<div class="card" style=${{marginTop:'14px'}}><${Empty} title="Todavía no hay gastos por aquí" text="Registra tu primer gasto y aquí verás en qué se va tu dinero." action="Registrar gasto" onAction=${()=>open('expense')}/></div>`}
    ${list.some(e=>e.debt)&&html`<${Note} icon="lock">Los abonos de deudas aparecen aquí porque restan de tu dinero, pero se editan desde Compromisos › Deudas.<//>`}
   </div>`:html`<div>
    <div class="card sum"><small class="mut">Total recibido</small><span class="amt big pos">${fmt(inc)}</span>
     ${byType.length>0&&html`<div class="leg" style=${{marginTop:'8px'}}>${byType.map(([t,v])=>html`<span key=${t}>${t} ${fmt(v)}</span>`)}</div>`}
     <button class="btn s" style=${{marginTop:'14px'}} onClick=${()=>open('income')}><${I} n="plus" s=${18}/>Agregar ingreso</button></div>
    ${incs.length?Object.entries(igroups).map(([day,is])=>html`<div key=${day}><p class="day">${dayLabel(day)}</p><div class="card" style=${{paddingBlock:'4px'}}>${is.map(i=>html`<${IncomeRow} i=${i} key=${i.id} onOpen=${incMenu}/>`)}</div></div>`)
     :html`<div class="card" style=${{marginTop:'14px'}}><${Empty} cat="vacio" title="Sin ingresos este mes" text="Cuando recibas dinero, regístralo y repártelo entre efectivo y tus cuentas." action="Agregar ingreso" onAction=${()=>open('income')}/></div>`}
    ${incs.some(i=>i.type==='Préstamo recibido')&&html`<${Note}>Los préstamos recibidos también aparecen en Deudas y no cuentan como dinero ganado.<//>`}
   </div>`}
  </div>`;
}

function Cuentas({s,ui,set,open,go}){
  const total=totalBal(s), dig=total-s.bal.efectivo;
  const spent=id=>sum(s.expenses.filter(e=>e.acc===id&&inR(e.date,RANGES.mes)),e=>e.amount);
  const AccCard=({a})=>{const o=ui.acc===a.id;const last=[...s.expenses.filter(e=>e.acc===a.id).map(e=>[e.date,e.name,-e.amount]),...s.incomes.flatMap(i=>i.dest.filter(([x])=>x===a.id).map(([,v])=>[i.date,i.type,v])),
      ...s.transfers.filter(t=>t.from===a.id||t.to===a.id).map(t=>[t.date,t.from===a.id?'Transferencia a '+accOf(t.to).name:'Transferencia de '+accOf(t.from).name,t.from===a.id?-t.amount:t.amount])].sort((x,y)=>y[0].localeCompare(x[0])).slice(0,3);
    return html`<button class="card acc" aria-expanded=${o} onClick=${()=>set({acc:o?null:a.id})}>
     <div class="h"><span class="bub" style=${{background:'var(--sunk)',color:a.color}}><${I} n=${a.icon} s=${20}/></span>
      <span><b style=${{display:'block'}}>${a.name}</b><span class="mut" style=${{fontSize:'13px',display:'block'}}>${pct(s.bal[a.id]||0,total)} % del total</span><span class="mut" style=${{fontSize:'13px',display:'block'}}>Salió <span class="nw">${fmt(spent(a.id))}</span> este mes</span></span>
      <span class="amt">${fmt(s.bal[a.id]||0)}</span></div>
     ${o&&html`<ul>${last.length?last.map(([dt,n,v],k)=>html`<li key=${k}><span>${dayLabel(dt)} · ${n}</span><span class=${'amt '+(v<0?'neg':'pos')}>${v<0?'−':'+'}${fmt(v)}</span></li>`):html`<li><span class="mut">Sin movimientos todavía.</span></li>`}</ul>`}
    </button>`};
  return html`<div>
   <div class="card"><small class="mut">Total de tu dinero</small><span class="amt" style=${{fontSize:'34px',display:'block',lineHeight:1.15}}>${fmt(total)}</span>
    <div class="dist" role="img" aria-label="Distribución del dinero por cuenta">${total>0&&ACC.map(a=>html`<i key=${a.id} style=${{width:pct(s.bal[a.id]||0,total)+'%',background:a.color}}></i>`)}</div>
    <div class="leg">${ACC.map(a=>html`<span key=${a.id}><i class="dot" style=${{background:a.color}}></i>${a.name} ${pct(s.bal[a.id]||0,total)} %</span>`)}</div>
    <div style=${{marginTop:'16px'}}><button class="btn p" onClick=${()=>open('transfer')}><${I} n="swap"/>Transferir entre cuentas</button></div>
   </div>
   <${SecHead} title="Efectivo"><span class="amt mut">${fmt(s.bal.efectivo)}</span><//>
   <${AccCard} a=${ACC[0]}/>
   <${SecHead} title="Digital"><span class="amt mut">${fmt(dig)}</span><//>
   ${ACC.slice(1).map(a=>html`<${AccCard} a=${a} key=${a.id}/>`)}
   <${SecHead} title="Transferencias recientes"><//>
   <div class="card" style=${{paddingBlock:'4px'}}>${s.transfers.length?s.transfers.slice(0,3).map(t=>html`<${TransferRow} t=${t} key=${t.id}/>`):html`<p class="mut" style=${{margin:'12px 0'}}>Todavía no has movido dinero entre tus cuentas.</p>`}</div>
   <p class="hint">Las transferencias no cuentan como ingreso ni gasto. Para editarlas o revertirlas, y para agregar o renombrar cuentas, ve a <button class="link inl" onClick=${()=>go('settings')}>Configuración</button>.</p>
  </div>`;
}

/* Gráficos */
const Donut=({items,total,center})=>{let off=0;const R=52,C=2*Math.PI*R;
  return html`<svg viewBox="0 0 132 132" role="img" aria-label=${center}><circle cx="66" cy="66" r=${R} fill="none" stroke="var(--sunk)" stroke-width="18"/>
   ${items.map(([k,v,c])=>{const len=v/total*C;const el=html`<circle key=${k} cx="66" cy="66" r=${R} fill="none" stroke=${c} stroke-width="18" stroke-dasharray=${`${Math.max(len-2,0.5)} ${C}`} stroke-dashoffset=${-off} transform="rotate(-90 66 66)"/>`;off+=len;return el})}
   <text x="66" y="62" text-anchor="middle" style=${{font:'800 15px Nunito,sans-serif',fill:'var(--ink)'}}>${fmt(total)}</text><text x="66" y="80" text-anchor="middle" style=${{font:'12px Inter,sans-serif',fill:'var(--ink2)'}}>gastado</text></svg>`};
const Line=({cur,prev,labels})=>{const W=330,H=120,max=Math.max(...cur,...prev,1),x=i=>8+i*(W-16)/Math.max(cur.length-1,1),y=v=>H-14-v/max*(H-26);
  const path=a=>a.map((v,i)=>`${i?'L':'M'}${x(i).toFixed(1)} ${y(v).toFixed(1)}`).join(' ');
  return html`<svg class="spark" viewBox=${`0 0 ${W} ${H}`} preserveAspectRatio="none" role="img" aria-label=${`Gasto acumulado: ${fmt(cur[cur.length-1])}`}>
   <path d=${`M8 ${H-14}H${W-8}`} stroke="var(--line)"/>
   ${prev.length>0&&html`<path d=${path(prev)} fill="none" stroke="var(--ink2)" stroke-width="2" stroke-dasharray="4 5" vector-effect="non-scaling-stroke"/>`}
   <path d=${path(cur)+` L${x(cur.length-1)} ${H-14} L8 ${H-14}Z`} fill="var(--primary-soft)" opacity=".7"/>
   <path d=${path(cur)} fill="none" stroke="var(--primary)" stroke-width="3" vector-effect="non-scaling-stroke" stroke-linejoin="round"/>
   <circle cx=${x(cur.length-1)} cy=${y(cur[cur.length-1])} r="4" fill="var(--primary)"/></svg>
   <div class="bx"><span style=${{textAlign:'left'}}>${labels[0]}</span><span style=${{textAlign:'right'}}>${labels[1]}</span></div>`};

function Stats({s,ui,set}){
  const r=RANGES[ui.period], tab=ui.statsTab;
  const medium=e=>tab==='general'||(tab==='efectivo'?e.acc==='efectivo':e.acc!=='efectivo');
  const ex=s.expenses.filter(e=>inR(e.date,r)&&medium(e)), spent=sum(ex,e=>e.amount);
  const incs=s.incomes.filter(i=>inR(i.date,r)), inc=sum(incs,i=>i.type==='Préstamo recibido'?0:i.amount);
  const byCat=Object.entries(ex.reduce((m,e)=>(m[e.cat]=(m[e.cat]||0)+e.amount,m),{})).sort((a,b)=>b[1]-a[1]).map(([c,v])=>[c,v,catInfo(c)[1]]);
  const n=days(r[0],r[1])+1, dayList=Array.from({length:n},(_,i)=>addDays(r[0],i));
  const cum=a=>{let t=0;return a.map(v=>t+=v)};
  const perDay=(list,ds)=>ds.map(dd=>sum(list.filter(e=>e.date===dd),e=>e.amount));
  const cur=cum(perDay(ex,dayList));
  const prevDays=ui.period==='mes'?dayList.map(x=>'2026-10'+x.slice(7)):dayList.map(x=>addDays(x,-n));
  const prev=ui.period==='ant'?[]:cum(perDay(s.expenses.filter(e=>medium(e)),prevDays));
  const weeks=[];for(let i=0;i<n;i+=7)weeks.push(dayList.slice(i,i+7));
  const wk=weeks.map(w=>[w[0],sum(incs.filter(x=>w.includes(x.date)),x=>x.amount),sum(ex.filter(e=>w.includes(e.date)),e=>e.amount)]);
  const wmax=Math.max(1,...wk.flatMap(w=>[w[1],w[2]]));
  const cashBal=s.bal.efectivo, digBal=totalBal(s)-cashBal;
  const reserved=sum(s.plans.filter(p=>p.status==='activo'),p=>p.reserved);
  const has=s.expenses.length+s.incomes.length>0;
  return html`<div>
   <div class="chips" role="group" aria-label="Periodo">${Object.entries(RANGES).map(([k,v])=>html`<button key=${k} class="chip" aria-pressed=${ui.period===k} onClick=${()=>set({period:k})}>${v[2]}</button>`)}</div>
   <div class="tabs" role="tablist" aria-label="Vista" style=${{marginTop:'6px'}}>${[['general','General'],['efectivo','Efectivo'],['digital','Digital']].map(([k,l])=>html`<button key=${k} role="tab" aria-selected=${tab===k} onClick=${()=>set({statsTab:k})}>${l}</button>`)}</div>
   ${!has?html`<div class="card"><${Empty} cat="estadisticas" title="Aún no hay datos" text="Cuando tengas ingresos o gastos, aquí veremos cómo se mueve tu dinero."/></div>`:html`<div>
   <div class="kpis">${tab==='general'?html`<div><small>Ingresos</small><span class="amt pos">${fmt(inc)}</span></div><div><small>Gastos</small><span class="amt neg">${fmt(spent)}</span></div><div><small>Restante</small><span class="amt">${inc?sfmt(inc-spent):'—'}</span></div>`
     :html`<div><small>Gastado</small><span class="amt neg">${fmt(spent)}</span></div><div><small>Movimientos</small><span class="amt">${ex.length}</span></div><div><small>Saldo actual</small><span class="amt">${fmt(tab==='efectivo'?cashBal:digBal)}</span></div>`}</div>
   <${SecHead} title="Gastos por categoría"><//>
   <div class="card">${spent?html`<div class="donut"><${Donut} items=${byCat} total=${spent} center=${`Gastos por categoría, total ${fmt(spent)}`}/>
     <ul class="lg">${byCat.slice(0,6).map(([c,v,col])=>html`<li key=${c}><i class="dot" style=${{background:col}}></i><span>${c}</span><b>${pct(v,spent)} %</b></li>`)}</ul></div>`
     :html`<p class="mut" style=${{margin:0}}>Sin gastos en este período.</p>`}</div>
   ${tab==='general'&&html`<div><${SecHead} title="Evolución del dinero"><span class="leg"><span><i class="dot" style=${{background:'var(--pos)'}}></i>Ingresos</span><span><i class="dot" style=${{background:'var(--neg)'}}></i>Gastos</span></span><//>
    <div class="card"><div class="bars" role="img" aria-label="Ingresos y gastos por semana">${wk.map(([w,i,g])=>html`<div class="g" key=${w}><i style=${{height:Math.max(1,i/wmax*100)+'%',background:'var(--pos)'}} title=${'Ingresos '+fmt(i)}></i><i style=${{height:Math.max(1,g/wmax*100)+'%',background:'var(--neg)'}} title=${'Gastos '+fmt(g)}></i></div>`)}</div>
     <div class="bx">${wk.map(([w])=>html`<span key=${w}>${d(w).getDate()} ${MES[d(w).getMonth()]}</span>`)}</div></div></div>`}
   <${SecHead} title="Tendencia de gastos">${prev.length>0&&html`<span class="leg"><span><i class="dot" style=${{background:'var(--primary)'}}></i>Ahora</span><span>- - Antes</span></span>`}<//>
   <div class="card"><${Line} cur=${cur} prev=${prev} labels=${[`${d(r[0]).getDate()} ${MES[d(r[0]).getMonth()]}`,`${d(r[1]).getDate()} ${MES[d(r[1]).getMonth()]}`]}/>
    <p class="caption">${prev.length?(()=>{const a=cur[cur.length-1],b=prev[prev.length-1],df=a-b;return df>0?`Vas ${fmt(df)} por encima del período anterior.`:`Vas ${fmt(-df)} por debajo del período anterior.`})():'Gasto acumulado del mes.'}</p></div>
   ${tab==='digital'&&html`<div><${SecHead} title="Por cuenta digital"><//><div class="card" style=${{paddingBlock:'4px'}}>
    ${ACC.slice(1).map(a=>{const g=sum(ex.filter(e=>e.acc===a.id),e=>e.amount),b=s.bal[a.id]||0;return html`<div class="acct" key=${a.id}><span class="t"><i class="dot" style=${{background:a.color}}></i>${a.name}</span><span class="amt">${fmt(b)}</span>
      <span class="mut" style=${{fontSize:'13px'}}>Salió ${fmt(g)} en el período</span><span class="mut" style=${{fontSize:'13px'}}>saldo actual</span>
      <div class="meter" role="img" aria-label=${`${pct(g,g+b)} % usado`}><i style=${{width:pct(g,g+b)+'%',background:a.color}}></i></div></div>`})}</div></div>`}
   ${tab==='general'&&html`<${Note}>Los abonos de deudas se cuentan una sola vez y los préstamos recibidos no cuentan como ingreso. Lo reservado para gastos futuros (${fmt(reserved)}) y los aportes al ahorro no cuentan como gasto.<//>`}
   </div>`}
  </div>`;
}

/* ======================= Compromisos ======================= */
function Compromisos({s,go}){
  const due=upcoming(s), mes=sum(due.filter(x=>x.date<='2026-11-30'&&x.kind!=='Gasto futuro'),x=>x.amount);
  const subsM=sum(s.subs.filter(x=>x.active),x=>x.price*SUBF[x.freq][0]);
  const debtsL=sum(s.debts,debtLeft), active=s.entities.filter(e=>!e.retired), avail=sum(active,e=>Math.max(0,e.limit-entUsed(s,e)));
  const plansA=s.plans.filter(p=>p.status==='activo');
  const mods=[['repeat','Suscripciones',`${s.subs.filter(x=>x.active).length} activas · ${fmt(subsM)} al mes`,'subs'],['target','Gastos futuros',`${plansA.length} ${plansA.length===1?'plan activo':'planes activos'} · ${fmt(sum(plansA,p=>p.reserved))} reservados`,'plans'],
   ['debt','Deudas y préstamos',`Saldo por pagar ${fmt(debtsL)}`,'debts'],['card','Créditos de compra',active.length?`${active.length} ${active.length===1?'entidad':'entidades'} · disponible ${fmt(avail)}`:'Sin entidades','credits']];
  return html`<div>
   <div class="card"><small class="mut">Por pagar en lo que queda de noviembre</small><span class="amt" style=${{fontSize:'30px',display:'block'}}>${fmt(mes)}</span><p class="caption" style=${{marginTop:'2px'}}>Suscripciones y cuotas. Los gastos futuros se cubren con lo que reservas.</p></div>
   <${SecHead} title="Módulos"><//>
   <div class="card menu" style=${{paddingBlock:'2px'}}>${mods.map(([ic,t,sub,to])=>html`<button class="row" key=${t} onClick=${()=>go(to)}><span class="bub"><${I} n=${ic} s=${20}/></span><span><span class="t" style=${{display:'block'}}>${t}</span><span class="s" style=${{display:'block'}}>${sub}</span></span><${I} n="chev" s=${18}/></button>`)}</div>
   <${SecHead} title="Próximos pagos"><//>
   <div class="card">${due.length?due.map(x=>html`<${Due} x=${x} key=${x.key} onOpen=${()=>go(x.to)}/>`):html`<${Empty} title="Nada pendiente" text="No tienes pagos o planes próximos."/>`}</div>
  </div>`;
}

function Subs({s,open,menu,confirm,dispatch,toast}){
  const act=s.subs.filter(x=>x.active), canc=s.subs.filter(x=>!x.active);
  const m=sum(act,x=>x.price*SUBF[x.freq][0]);
  const Card=({x})=>{const n=days(TODAY,x.next);return html`<div class=${'card subc'+(x.active?'':' off')}>
    <div class="h3"><span class="bub"><${I} n="repeat" s=${20}/></span><span><b>${x.name}</b><span class="mut">${fmt(x.price)} · ${x.freq.toLowerCase()} · ${accOf(x.acc).name}</span></span>
     <button class="ib" aria-label=${'Acciones de '+x.name} onClick=${()=>menu({title:x.name,items:x.active?[['pencil','Editar',()=>open('subForm',x)],['clock','Historial',()=>open('subHist',x)],['x','Cancelar suscripción',()=>confirm({title:'¿Cancelar esta suscripción?',body:'Su historial de pagos y gastos se conservará.',ok:'Cancelar suscripción',cancel:'Volver',danger:true,icon:'repeat',action:()=>{dispatch({t:'subActive',id:x.id,on:false});toast('Suscripción cancelada. Su historial sigue guardado.')}}),true]]
       :[['undo','Reactivar',()=>{dispatch({t:'subActive',id:x.id,on:true});toast('Suscripción reactivada.')}],['clock','Historial',()=>open('subHist',x)]]})}><${I} n="dots"/></button></div>
    ${x.active?html`<div class="subn"><span>Próximo cobro <b>${longDate(x.next)}</b></span><${Tag} kind=${n<=7?'warn':'soft'} icon=${n<=7?'alert':null}>${n===0?'Próximo cobro hoy':dueLabel(x.next)}<//></div>
     <div class="row2"><button class="btn p sm" onClick=${()=>open('subPay',x)}>Pagar</button><button class="btn s sm" onClick=${()=>open('subHist',x)}>Historial</button></div>`
     :html`<div class="row2"><${Tag}>Cancelada<//><button class="btn s sm" onClick=${()=>{dispatch({t:'subActive',id:x.id,on:true});toast('Suscripción reactivada.')}}>Reactivar</button></div>`}
   </div>`};
  return html`<div>
   <p class="lead">Ten a la vista tus cobros recurrentes.</p>
   <div class="card"><${Vals} items=${[['Estimado mensual',fmt(m)],['Compromiso anual estimado',fmt(m*12)]]}/>
    <button class="btn p" style=${{marginTop:'14px'}} onClick=${()=>open('subForm')}><${I} n="plus"/>Agregar suscripción</button></div>
   <${Note} icon="lock">Los pagos solo se registran cuando confirmas la acción. No hay cobros automáticos.<//>
   <${SecHead} title="Activas"><span class="mut">${act.length}</span><//>
   ${act.length?act.sort((a,b)=>a.next.localeCompare(b.next)).map(x=>html`<${Card} x=${x} key=${x.id}/>`):html`<div class="card"><${Empty} title="Todavía no tienes suscripciones" text="Agrega tus cobros recurrentes y consulta cuánto representan cada mes." action="Agregar la primera" onAction=${()=>open('subForm')}/></div>`}
   ${canc.length>0&&html`<div><${SecHead} title="Canceladas"><span class="mut">${canc.length}</span><//>${canc.map(x=>html`<${Card} x=${x} key=${x.id}/>`)}</div>`}
  </div>`;
}

function Plans({s,ui,set,open,menu,confirm,dispatch,toast}){
  const st=ui.planTab, list=s.plans.filter(p=>p.status===st), total=totalBal(s);
  const empty={activo:'Todavía no hay planes por aquí. Crea uno para empezar.',completado:'Todavía no has completado ningún plan.',archivado:'Todavía no hay planes archivados.'}[st];
  const Card=({p})=>{const left=Math.max(0,p.need-p.reserved), reco=planReco(p), late=p.status==='activo'&&p.due<TODAY;
    const items=p.status==='activo'?[['pencil','Editar plan',()=>open('planForm',p)],['check','Marcar como completado',()=>{dispatch({t:'planStatus',id:p.id,st:'completado'});toast('Estado actualizado.')}],['db','Archivar',()=>{dispatch({t:'planStatus',id:p.id,st:'archivado'});toast('Estado actualizado.')}],
      ['trash','Eliminar plan',()=>p.reserved?confirm({title:'Primero libera el dinero',body:'Libera primero el dinero reservado para poder eliminar el plan.',icon:'lock'}):confirm({title:'¿Borrar este plan?',body:'Se eliminará el plan. No podrás deshacerlo.',ok:'Eliminar plan',danger:true,icon:'trash',action:()=>{dispatch({t:'delPlan',id:p.id});toast('Plan eliminado.')}}),true]]
      :[['undo','Volver a activar',()=>{dispatch({t:'planStatus',id:p.id,st:'activo'});toast('Estado actualizado.')}],['trash','Eliminar plan',()=>p.reserved?confirm({title:'Primero libera el dinero',body:'Libera primero el dinero reservado para poder eliminar el plan.',icon:'lock'}):confirm({title:'¿Borrar este plan?',body:'Se eliminará el plan. No podrás deshacerlo.',ok:'Eliminar plan',danger:true,icon:'trash',action:()=>{dispatch({t:'delPlan',id:p.id});toast('Plan eliminado.')}}),true]];
    return html`<div class="card planc">
     <div class="h3"><span class="bub" style=${{color:catInfo(p.cat)[1]}}><${I} n=${catInfo(p.cat)[0]} s=${20}/></span><span><b>${p.name}</b><span class="mut">${p.cat} · ${p.freq} · para el ${longDate(p.due)}</span></span>
      <button class="ib" aria-label=${'Acciones de '+p.name} onClick=${()=>menu({title:p.name,items})}><${I} n="dots"/></button></div>
     <${Vals} items=${[['Necesitas',fmt(p.need)],['Planeas guardar',fmt(p.plan)],['Reservado de verdad',fmt(p.reserved),'pos'],['Todavía falta',fmt(left),left?'':'pos']]}/>
     <${Bar} value=${p.reserved} total=${p.need} label=${`Reservado ${pct(p.reserved,p.need)} % de lo que necesitas`}/>
     <p class="caption">${p.reserved?`${pct(p.reserved,p.need)} % reservado en ${accOf(p.resAcc).name}.`:'Aún no has reservado dinero para este plan.'}${p.notes?' '+p.notes+'.':''}</p>
     ${late&&html`<p class="warnline"><${I} n="alert" s=${16}/>La fecha ya pasó. Puedes ajustar el plan para ponerte al día.</p>`}
     ${p.status==='activo'&&reco>0&&!late&&html`<p class="reco"><${I} n="bulb" s=${16}/>Para llegar a tiempo, reserva <b class="amt">${fmt(reco)}</b> ${p.freq==='Fecha única'?'antes de la fecha':'por '+{Diario:'día',Semanal:'semana',Quincenal:'quincena',Mensual:'mes'}[p.freq]}.</p>`}
     ${p.status==='activo'&&html`<div class="row2"><button class="btn p sm" disabled=${!planLeft(p)} onClick=${()=>open('reserve',p)}>Reservar</button>${p.reserved>0&&html`<button class="btn s sm" onClick=${()=>open('release',p)}>Liberar reserva</button>`}</div>`}
     ${p.status!=='activo'&&html`<div class="row2"><${Tag}>${p.status==='completado'?'Completado':'Archivado'}<//><button class="btn s sm" onClick=${()=>{dispatch({t:'planStatus',id:p.id,st:'activo'});toast('Estado actualizado.')}}>Volver a activar</button></div>`}
    </div>`};
  return html`<div>
   <p class="lead">Organiza con tiempo lo que vas a necesitar.</p>
   <div class="card"><${Vals} items=${[['Dinero disponible',fmt(total)],['Reservado en planes',fmt(sum(s.plans.filter(p=>p.status==='activo'),p=>p.reserved))]]}/>
    <p class="caption">El saldo cambia al confirmar una reserva.</p>
    <button class="btn p" style=${{marginTop:'12px'}} onClick=${()=>open('planForm')}><${I} n="plus"/>Nuevo plan</button></div>
   <div class="tabs" role="tablist" aria-label="Estado de los planes" style=${{marginTop:'16px'}}>${[['activo','Activos'],['completado','Completados'],['archivado','Archivados']].map(([k,l])=>html`<button key=${k} role="tab" aria-selected=${st===k} onClick=${()=>set({planTab:k})}>${l} <span class="cnt">${s.plans.filter(p=>p.status===k).length}</span></button>`)}</div>
   ${list.length?list.map(p=>html`<${Card} p=${p} key=${p.id}/>`):html`<div class="card"><${Empty} title="Sin planes" text=${empty} action=${st==='activo'?'Nuevo plan':null} onAction=${()=>open('planForm')}/></div>`}
  </div>`;
}

function Debts({s,ui,set,open,menu,confirm,dispatch,toast,go}){
  const ent=ui.param&&s.entities.find(e=>e.id===ui.param);
  const base=s.debts.filter(x=>!ent||x.entity===ent.id);
  const st=ui.debtTab, list=base.filter(x=>st==='pend'?debtLeft(x)>0:debtLeft(x)<=0);
  const Card=({x})=>{const left=debtLeft(x),done=left<=0;return html`<div class="card debtc">
    <div class="h3"><span class="bub"><${I} n=${x.entity?'card':'debt'} s=${20}/></span><span><b>${x.name}</b><span class="mut">${x.entity?'Crédito de compra':'Deuda'} · desde ${dayLabel(x.date)}</span></span>
     <${Tag} kind=${done?'ok':'warn2'}>${done?'Pagada':'Pendiente'}<//></div>
    <${Vals} items=${[['Monto original',fmt(x.orig)],['Total pagado',fmt(x.paid),'pos'],['Saldo restante',fmt(left),done?'':'neg'],['Cuota',`${fmt(x.quota)} · ${Math.min(x.paidQ,x.n)} de ${x.n}`]]}/>
    <${Bar} value=${x.paid} total=${x.orig} color="var(--pos)" label=${`Pagado ${pct(x.paid,x.orig)} %`}/>
    ${x.hist>0&&html`<p class="caption"><${Tag} icon="clock">${x.hist} ${x.hist===1?'cuota':'cuotas'} como dato histórico<//> no descontaron dinero ni crearon gastos.</p>`}
    ${!done&&x.next&&html`<p class="caption">Próximo pago: <b>${longDate(x.next)}</b> · ${dueLabel(x.next)}</p>`}
    <div class="row2">${!done&&html`<button class="btn p sm" onClick=${()=>open('debtPay',x)}>Registrar abono</button>`}<button class="btn s sm" onClick=${()=>open('debtHist',x)}>Historial (${x.pays.length})</button>
     <button class="ib" aria-label=${'Acciones de '+x.name} onClick=${()=>menu({title:x.name,items:[...(x.hist?[['clock','Revisar dato histórico',()=>confirm({title:'Dato histórico de cuotas',body:`${x.hist} ${x.hist===1?'cuota se marcó':'cuotas se marcaron'} como pagadas al crear la deuda. Se conservará como referencia histórica: el total pagado lo incluye, pero no hubo movimiento de dinero.`,ok:'Conservar referencia',icon:'clock',action:()=>toast('Referencia guardada para tenerla presente.')})]]:[]),
       ['trash','Borrar deuda',()=>confirm({title:'¿Borrar esta deuda?',body:'Se borrará junto con su historial de pagos. No podrás deshacerlo.',ok:'Borrar deuda',cancel:'Conservar',danger:true,icon:'trash',action:()=>{dispatch({t:'delDebt',id:x.id});toast('Deuda borrada junto con su historial.')}}),true]]})}><${I} n="dots"/></button></div>
   </div>`};
  return html`<div>
   <p class="lead">Controla tus cuotas, abonos y saldos pendientes. Aquí solo te ayudamos a tenerlas en orden.</p>
   ${ent&&html`<div class="filter"><span><${I} n="card" s=${18}/>Deudas de <b>${ent.name}</b></span><button class="link" onClick=${()=>set({param:null})}>Ver todas</button></div>`}
   <div class="card"><${Vals} items=${[['Saldo por pagar',fmt(sum(base,debtLeft)),'neg'],['Total pagado',fmt(sum(base,x=>x.paid)),'pos']]}/>
    <p class="caption">${base.filter(x=>debtLeft(x)>0).length} pendientes · las compras a crédito se registran desde <button class="link inl" onClick=${()=>go('credits')}>Créditos de compra</button>.</p>
    <button class="btn p" style=${{marginTop:'12px'}} onClick=${()=>open('debtForm')}><${I} n="plus"/>Nueva deuda</button></div>
   <div class="tabs" role="tablist" aria-label="Estado de las deudas" style=${{marginTop:'16px'}}>${[['pend','Pendientes'],['pag','Pagadas']].map(([k,l])=>html`<button key=${k} role="tab" aria-selected=${st===k} onClick=${()=>set({debtTab:k})}>${l} <span class="cnt">${base.filter(x=>k==='pend'?debtLeft(x)>0:debtLeft(x)<=0).length}</span></button>`)}</div>
   ${list.length?list.map(x=>html`<${Card} x=${x} key=${x.id}/>`):html`<div class="card"><${Empty} title=${st==='pend'?'Todavía no hay deudas por aquí':'Ninguna deuda pagada aún'} text="Tus compras a crédito y préstamos aparecerán aquí."/></div>`}
  </div>`;
}

function Credits({s,open,go}){
  const act=s.entities.filter(e=>!e.retired);
  const lim=sum(act,e=>e.limit), used=sum(act,e=>entUsed(s,e));
  return html`<div>
   <p class="lead">Organiza tus compras y el cupo de cada entidad. No es un préstamo de dinero: el cupo se usa al comprar.</p>
   ${act.length?html`<div class="card"><small class="mut">Resumen general</small>
     <${Vals} items=${[['Cupo aprobado',fmt(lim)],['Cupo disponible',fmt(Math.max(0,lim-used)),'pos'],['Cupo utilizado',fmt(used)],['Deuda pendiente',fmt(used),'neg']]}/>
     <${Cupo} used=${used} limit=${lim}/></div>`:''}
   <${SecHead} title="Tus entidades"><button class="link" onClick=${()=>open('entityForm')}><${I} n="plus" s=${16}/>Agregar entidad</button><//>
   ${act.length?act.map(e=>html`<button class="card acc entc" key=${e.id} onClick=${()=>go('credit',e.id)}>
     <div class="h"><span class="bub"><${I} n="card" s=${20}/></span><span><b style=${{display:'block'}}>${e.name}</b><span class="mut" style=${{fontSize:'13px'}}>Aprobado ${fmt(e.limit)} · ${s.debts.filter(x=>x.entity===e.id&&debtLeft(x)>0).length} compras activas</span></span><${I} n="chev" s=${18}/></div>
     <${Cupo} used=${entUsed(s,e)} limit=${e.limit}/></button>`)
    :html`<div class="card"><${Empty} cat="vacio" title="Todavía no hay entidades registradas" text="Agrega una entidad para empezar a organizar tus compras." action="Agregar entidad de crédito" onAction=${()=>open('entityForm')}/></div>`}
  </div>`;
}

function CreditDetail({s,ui,open,go,confirm,dispatch,toast,back}){
  const e=s.entities.find(x=>x.id===ui.param); if(!e)return html`<div class="card"><${Empty} title="La entidad ya no existe." text="Vuelve a Créditos de compra."/></div>`;
  const used=entUsed(s,e), purch=s.debts.filter(x=>x.entity===e.id), pays=purch.flatMap(x=>x.pays.map(p=>({...p,name:x.name}))).sort((a,b)=>b.date.localeCompare(a.date));
  const retire=()=>used>0?confirm({title:'Todavía hay deudas pendientes',body:'Primero termina de pagar las deudas de esta entidad.',icon:'lock'})
    :confirm({title:'¿Retirar esta entidad?',body:'Se ocultará de tu lista, pero sus compras y movimientos quedarán guardados.',ok:'Retirar entidad',cancel:'Conservar',danger:true,icon:'card',action:()=>{dispatch({t:'retire',id:e.id});toast('Entidad retirada.');back()}});
  return html`<div>
   <div class="card"><small class="mut">Crédito de compra · ${e.name}</small>
    <${Vals} items=${[['Cupo aprobado',fmt(e.limit)],['Cupo disponible',fmt(Math.max(0,e.limit-used)),'pos'],['Cupo utilizado',fmt(used)],['Deuda pendiente',fmt(used),'neg']]}/>
    <${Cupo} used=${used} limit=${e.limit}/>
    <div class="row2" style=${{marginTop:'14px'}}><button class="btn p sm" onClick=${()=>open('purchase',e)}><${I} n="bag" s=${18}/>Nueva compra</button><button class="btn s sm" onClick=${()=>open('limit',e)}>Actualizar cupo</button></div>
    <button class="link" style=${{marginTop:'14px'}} onClick=${()=>go('debts',e.id)}>Ver deudas asociadas <${I} n="chev" s=${16}/></button></div>
   <${SecHead} title="Compras y movimientos"><//>
   <div class="card" style=${{paddingBlock:purch.length?'4px':'16px'}}>${purch.length?purch.map(x=>html`<div class="prow" key=${x.id}>
     <span class="bub" style=${{color:catInfo(x.cat)[1]}}><${I} n=${catInfo(x.cat)[0]} s=${20}/></span>
     <span><b>${x.name.split(' · ')[1]||x.name}</b><span class="mut">${dayLabel(x.date)} · ${x.cat||'Compra'} · ${Math.min(x.paidQ,x.n)} de ${x.n} cuotas</span><${Bar} value=${x.paid} total=${x.orig} color="var(--pos)"/></span>
     <span class="right"><span class="amt">${fmt(x.orig)}</span><span class="mut" style=${{fontSize:'12px'}}>${debtLeft(x)>0?'debe '+fmt(debtLeft(x)):'pagada'}</span></span></div>`)
     :html`<p class="mut" style=${{margin:0}}>Todavía no hay compras en esta entidad.</p>`}</div>
   <${SecHead} title="Pagos realizados"><//>
   <div class="card" style=${{paddingBlock:pays.length?'4px':'16px'}}>${pays.length?html`<ul class="tlist" style=${{margin:0}}>${pays.map((p,k)=>html`<li key=${k}><span>${dayLabel(p.date)} · ${p.name.split(' · ')[1]||p.name} · ${accOf(p.acc).name}</span><b class="amt">${fmt(p.amount)}</b></li>`)}</ul>`:html`<p class="mut" style=${{margin:0}}>Todavía no hay pagos.</p>`}</div>
   <${SecHead} title="Cambios de cupo"><//>
   <div class="card" style=${{paddingBlock:e.hist.length?'4px':'16px'}}>${e.hist.length?html`<ul class="tlist" style=${{margin:0}}>${e.hist.map((h,k)=>html`<li key=${k}><span>${dayLabel(h.date)}</span><span><span class="mut">${fmt(h.from)} → </span><b class="amt">${fmt(h.to)}</b></span></li>`)}</ul>`:html`<p class="mut" style=${{margin:0}}>Todavía no hay cambios registrados.</p>`}</div>
   <button class="btn dd" style=${{marginTop:'18px'}} onClick=${retire}><${I} n="trash" s=${18}/>Retirar entidad</button>
  </div>`;
}

/* ======================= Más ======================= */
function Mas({s,go}){
  const items=[['bank','Cuentas','Efectivo y cuentas digitales','cuentas'],['chart','Estadísticas','General, efectivo y digital','stats'],
   ['piggy','Ahorros y préstamos','Ahorro '+fmt(s.savings)+' · préstamos a terceros','savings'],['gear','Configuración','Nombre, categorías, cuentas, transferencias','settings']];
  return html`<div class="card menu" style=${{paddingBlock:'2px'}}>${items.map(([ic,t,sub,to])=>html`<button class="row" key=${t} onClick=${()=>go(to)}><span class="bub"><${I} n=${ic} s=${20}/></span><span><span class="t" style=${{display:'block'}}>${t}</span><span class="s" style=${{display:'block'}}>${sub}</span></span><${I} n="chev" s=${18}/></button>`)}</div>`;
}
/*MODULES_4B*/

/* ======================= Hojas de registro básicas ======================= */
function RegisterSheet({close,open}){
  const o=[['income','in','Ingreso','Sueldo, dinero extra o préstamo recibido','var(--pos-soft)','var(--pos)'],['expense','out','Gasto','Compras, servicios y pagos del día','var(--neg-soft)','var(--neg)'],['transfer','swap','Transferencia','Mover dinero entre efectivo y cuentas; no es ingreso ni gasto','var(--primary-soft)','var(--primary)']];
  return html`<${Sheet} title="¿Qué quieres registrar?" onClose=${close}>${o.map(([k,ic,t,sub,bg,fg])=>html`<button class="opt" key=${k} onClick=${()=>open(k)}><i style=${{background:bg,color:fg}}><${I} n=${ic}/></i><span><b>${t}</b><span>${sub}</span></span><${I} n="chev" s=${18}/></button>`)}<//>`;
}
function ExpenseSheet({s,dispatch,close,toast,edit,confirm}){
  const [f,setF]=useState(edit?{amount:String(edit.amount),acc:edit.acc,name:edit.name,cat:edit.cat,date:edit.date,note:''}:{amount:'',acc:'efectivo',name:'',cat:'',date:TODAY,note:''});
  const [tried,setTried]=useState(false);
  const amt=Number(f.amount||0), avail=(s.bal[f.acc]||0)+(edit&&edit.acc===f.acc?edit.amount:0), left=avail-amt;
  const errs={amount:!amt?'Escribe un monto mayor que cero.':left<0?'El saldo de esta cuenta es insuficiente.':'',name:!f.name.trim()?'Escribe el nombre del gasto.':'',cat:!f.cat?'Elige una categoría.':''};
  const save=()=>{setTried(true);if(Object.values(errs).some(Boolean))return;
    dispatch({t:'expense',old:edit,e:{...(edit||{}),id:edit?edit.id:uid(),date:f.date,name:f.name.trim(),cat:f.cat,acc:f.acc,amount:amt,debt:null}});
    close();toast(edit?'Cambios guardados.':'¡Listo! Otro movimiento bajo control.',true)};
  const cats=s.cats.filter(c=>c!=='Suscripción');
  return html`<${Sheet} title=${edit?'Editar gasto':'Nuevo gasto'} onClose=${close} footer=${html`<button class="btn p" onClick=${save}><${I} n="check"/>${edit?'Guardar cambios':'Guardar gasto'}</button>`}>
   <${Money} id="g-monto" label="¿Cuánto gastaste?" value=${f.amount} onChange=${v=>setF({...f,amount:v})}/><${Err} m=${tried&&errs.amount}/>
   <span class="fl">¿De dónde sale el dinero?</span>
   <${AccPicker} bal=${s.bal} value=${f.acc} onPick=${v=>setF({...f,acc:v})} label="Origen del dinero"/>
   <div class=${'preview'+(left<0?' bad':'')} aria-live="polite"><span>${left<0?'No alcanza el saldo de '+accOf(f.acc).name:'Te quedarán en '+accOf(f.acc).name}</span><span class="amt">${sfmt(left)}</span></div>
   <label class="fl" for="g-nombre">Nombre del gasto</label><input id="g-nombre" class="field" placeholder="Ej. Compra semanal" value=${f.name} onInput=${e=>setF({...f,name:e.target.value})}/><${Err} m=${tried&&errs.name}/>
   <span class="fl">Categoría</span>
   <${Chips} opts=${cats} value=${f.cat} onPick=${c=>setF({...f,cat:c})} label="Categoría" icons/><${Err} m=${tried&&errs.cat}/>
   ${edit&&edit.cat==='Suscripción'&&html`<${Note}>Este gasto viene de un pago de suscripción.<//>`}
   <div class="two"><div><label class="fl" for="g-fecha">Fecha</label><input id="g-fecha" type="date" class="field" value=${f.date} max=${TODAY} onInput=${e=>setF({...f,date:e.target.value||TODAY})}/></div>
    <div><label class="fl" for="g-nota">Nota (opcional)</label><input id="g-nota" class="field" value=${f.note} onInput=${e=>setF({...f,note:e.target.value})}/></div></div>
   ${edit&&html`<button class="btn dd" style=${{marginTop:'16px'}} onClick=${()=>confirm({title:'¿Borrar este gasto?',body:`Se devolverán ${fmt(edit.amount)} a ${accOf(edit.acc).name}. No podrás deshacerlo.`,ok:'Borrar gasto',cancel:'Conservar',danger:true,icon:'trash',action:()=>{dispatch({t:'delExpense',e:edit});close();toast('Gasto borrado.')}})}><${I} n="trash" s=${18}/>Borrar gasto</button>`}
  <//>`;
}
function TransferSheet({s,dispatch,close,toast,edit}){
  const [f,setF]=useState(edit?{from:edit.from,to:edit.to,amount:String(edit.amount),note:edit.note||''}:{from:'bancolombia',to:'nequi',amount:'',note:''});const [tried,setTried]=useState(false);
  const amt=Number(f.amount||0), bal={...s.bal}; if(edit){bal[edit.from]+=edit.amount;bal[edit.to]-=edit.amount;}
  const err=f.from===f.to?'Elige un destino distinto al origen.':!amt?'Escribe un monto mayor que cero.':amt>bal[f.from]?'No alcanza el saldo de esta opción.':'';
  const save=()=>{setTried(true);if(err)return;dispatch({t:'transfer',old:edit,tr:{id:edit?edit.id:uid(),date:edit?edit.date:TODAY,from:f.from,to:f.to,amount:amt,note:f.note}});close();toast(edit?'Transferencia guardada.':'Transferencia lista. Tus saldos ya están actualizados.',true)};
  return html`<${Sheet} title=${edit?'Editar transferencia':'Transferir dinero'} onClose=${close} footer=${html`<button class="btn p" onClick=${save}><${I} n="swap"/>Confirmar transferencia</button>`}>
   <${Money} id="t-monto" label="¿Cuánto vas a mover?" value=${f.amount} onChange=${v=>setF({...f,amount:v})}/>
   <span class="fl">Desde</span><${AccPicker} bal=${bal} value=${f.from} onPick=${v=>setF({...f,from:v,to:v===f.to?ACC.find(a=>a.id!==v).id:f.to})} label="Desde"/>
   <span class="fl">Hacia</span><${AccPicker} bal=${bal} value=${f.to} exclude=${f.from} onPick=${v=>setF({...f,to:v})} label="Hacia"/>
   <${Err} m=${tried&&err}/>
   <span class="fl">Así quedarán tus saldos</span>
   <ul class="tlist" aria-live="polite">${[[f.from,-amt],[f.to,amt]].map(([a,v])=>html`<li key=${a}><span>${accOf(a).name}</span><span><span class="mut">${fmt(bal[a])} → </span><b class=${'amt '+(bal[a]+v<0?'neg':'')}>${sfmt(bal[a]+v)}</b></span></li>`)}</ul>
   <label class="fl" for="t-nota">Nota (opcional)</label><input id="t-nota" class="field" value=${f.note} onInput=${e=>setF({...f,note:e.target.value})}/>
   <p class="hint">No cuenta como ingreso ni gasto.</p>
  <//>`;
}
function IncomeSheet({s,dispatch,close,toast,edit}){
  const [f,setF]=useState(edit?{amount:String(edit.amount),type:edit.type,dest:edit.dest.map(([a,v])=>[a,String(v)]),cuotas:''}:{amount:'',type:'Sueldo',dest:[['bancolombia','']],cuotas:''});const [tried,setTried]=useState(false);
  const amt=Number(f.amount||0), assigned=sum(f.dest,([,v])=>Number(v||0)), left=amt-assigned;
  const setD=(i,k,v)=>setF({...f,dest:f.dest.map((x,j)=>j===i?(k?[x[0],v]:[v,x[1]]):x)});
  const loan=f.type==='Préstamo recibido'&&!edit;
  const err=!amt?'Escribe un monto mayor que cero.':left!==0?'Reparte todo el valor recibido antes de guardar.':new Set(f.dest.map(x=>x[0])).size<f.dest.length?'Cada destino debe ser distinto.':loan&&!(Number(f.cuotas)>=1)?'Indica cuántas cuotas son.':'';
  const save=()=>{setTried(true);if(err)return;const i={id:edit?edit.id:uid(),date:edit?edit.date:TODAY,type:f.type,amount:amt,dest:f.dest.map(([a,v])=>[a,Number(v)])};
    const n=Number(f.cuotas);const debt=loan?{id:uid(),name:'Préstamo recibido',orig:amt,quota:Math.ceil(amt/n),n,paidQ:0,paid:0,hist:0,next:addMonths(TODAY,1),day:17,entity:null,date:TODAY,pays:[]}:null;
    dispatch({t:'income',old:edit,i,debt});close();toast(edit?'Cambios guardados.':loan?'Ingreso guardado y la deuda quedó en Deudas.':'¡Listo! El ingreso quedó repartido.',true)};
  return html`<${Sheet} title=${edit?'Editar ingreso':'Agregar ingreso'} onClose=${close} footer=${html`<button class="btn p" disabled=${!!amt&&left!==0} onClick=${save}><${I} n="check"/>${edit?'Guardar cambios':'Guardar ingreso'}</button>`}>
   <${Money} id="i-monto" label="Valor recibido" value=${f.amount} onChange=${v=>setF({...f,amount:v,dest:f.dest.length===1?[[f.dest[0][0],v]]:f.dest})}/>
   <span class="fl">Tipo de ingreso</span><${Chips} opts=${['Sueldo','Dinero extra','Préstamo recibido']} value=${f.type} onPick=${t=>setF({...f,type:t})} label="Tipo de ingreso"/>
   ${loan&&html`<div><${Note}>También se creará una deuda para hacerle seguimiento. No cuenta como dinero ganado.<//><label class="fl" for="i-cuotas">Número de cuotas</label><input id="i-cuotas" class="field" inputmode="numeric" value=${f.cuotas} onInput=${e=>setF({...f,cuotas:digits(e.target.value).slice(0,3)})}/></div>`}
   <span class="fl">¿Dónde quedó el dinero?</span>
   ${f.dest.map(([a,v],i)=>html`<div class="dest" key=${i}><select class="field" aria-label=${'Destino '+(i+1)} value=${a} onChange=${e=>setD(i,0,e.target.value)}>${ACC.map(x=>html`<option value=${x.id} key=${x.id}>${x.name}</option>`)}</select>
     <input class="field" inputmode="numeric" aria-label=${'Importe para '+accOf(a).name} placeholder="$ 0" value=${v?'$ '+Number(v).toLocaleString('es-CO'):''} onInput=${e=>setD(i,1,digits(e.target.value))}/>
     <button class="ib" aria-label="Quitar destino" disabled=${f.dest.length===1} onClick=${()=>setF({...f,dest:f.dest.filter((_,j)=>j!==i)})}><${I} n="x" s=${18}/></button></div>`)}
   ${f.dest.length<ACC.length&&html`<button class="link" style=${{margin:'2px 0 0'}} onClick=${()=>setF({...f,dest:[...f.dest,[ACC.find(x=>!f.dest.some(d=>d[0]===x.id)).id,'']]})}><${I} n="plus" s=${18}/>Agregar otro destino</button>`}
   <div class=${'left'+(amt&&left===0?' ok':'')} aria-live="polite"><span>${!amt?'Escribe el valor recibido':left===0?'Todo el dinero tiene destino':left>0?'Falta por asignar':'Asignaste de más'}</span><span class="amt">${fmt(left)}</span></div>
   <${Err} m=${tried&&err}/>
  <//>`;
}
function DebtInfo({e,close}){return html`<${Sheet} title="Abono de deuda" onClose=${close} footer=${html`<button class="btn s" onClick=${close}>Entendido</button>`}>
  <p style=${{margin:'4px 0 10px'}}><b>${e.name}</b> · ${fmt(e.amount)}</p><p class="mut" style=${{margin:0}}>${e.debt}. Se pagó desde ${accOf(e.acc).name} · ${dayLabel(e.date)}.</p>
  <${Note} icon="lock">Este abono se registró desde Deudas. Para corregirlo, ve a Compromisos › Deudas y préstamos.<//><//>`}

/* ======================= Hojas de Compromisos ======================= */
function SubForm({s,dispatch,close,toast,edit}){
  const [f,setF]=useState(edit?{name:edit.name,price:String(edit.price),freq:edit.freq,next:edit.next,acc:edit.acc}:{name:'',price:'',freq:'Mensual',next:addDays(TODAY,7),acc:'nequi'});const [tried,setTried]=useState(false);
  const p=Number(f.price||0);const err={name:!f.name.trim()?'Escribe el nombre del servicio.':'',price:!p?'Escribe un precio mayor que cero.':''};
  const save=()=>{setTried(true);if(err.name||err.price)return;dispatch({t:'sub',old:edit,x:{...(edit||{pays:[],active:true}),id:edit?edit.id:uid(),name:f.name.trim(),price:p,freq:f.freq,next:f.next,day:d(f.next).getDate(),acc:f.acc}});close();toast(edit?'Suscripción actualizada.':'Suscripción guardada.',true)};
  return html`<${Sheet} title=${edit?'Editar suscripción':'Nueva suscripción'} onClose=${close} footer=${html`<button class="btn p" onClick=${save}><${I} n="check"/>${edit?'Guardar cambios':'Guardar'}</button>`}>
   <label class="fl" for="s-name" style=${{marginTop:'4px'}}>Nombre del servicio</label><input id="s-name" class="field" placeholder="Por ejemplo, música o streaming" value=${f.name} onInput=${e=>setF({...f,name:e.target.value})}/><${Err} m=${tried&&err.name}/>
   <${MoneyField} id="s-price" label="Precio por cobro" value=${f.price} onChange=${v=>setF({...f,price:v})} hint=${p?`Equivale a ${fmt(p*SUBF[f.freq][0])} al mes.`:null}/><${Err} m=${tried&&err.price}/>
   <span class="fl">Frecuencia</span><${Chips} opts=${Object.keys(SUBF)} value=${f.freq} onPick=${v=>setF({...f,freq:v})} label="Frecuencia"/>
   <label class="fl" for="s-next">Próximo pago</label><input id="s-next" type="date" class="field" value=${f.next} onInput=${e=>setF({...f,next:e.target.value||f.next})}/>
   <span class="fl">Medio de pago habitual</span><${AccPicker} bal=${s.bal} value=${f.acc} onPick=${v=>setF({...f,acc:v})} label="Medio de pago habitual"/>
   <p class="hint">No se cobra nada automáticamente: cada pago lo confirmas tú.</p>
  <//>`;
}
function SubPay({s,dispatch,close,toast,edit:x}){
  const [acc,setAcc]=useState(x.acc);const left=(s.bal[acc]||0)-x.price;
  const step={Semanal:[7,0],Mensual:[0,1],Trimestral:[0,3],Anual:[0,12]}[x.freq];const next=step[0]?addDays(x.next,step[0]):addMonths(x.next,step[1],x.day);
  return html`<${Sheet} title=${'Pagar '+x.name} onClose=${close} footer=${html`<div class="two"><button class="btn s" onClick=${close}>Ahora no</button><button class="btn p" disabled=${left<0} onClick=${()=>{dispatch({t:'paySub',id:x.id,acc});close();toast('¡Listo! El pago quedó registrado en tus gastos.',true)}}>Confirmar pago</button></div>`}>
   <div class="bigamt"><small>Valor del cobro</small><span class="amt">${fmt(x.price)}</span></div>
   <span class="fl">¿Desde dónde pagas?</span><${AccPicker} bal=${s.bal} value=${acc} onPick=${setAcc} label="Medio de pago"/>
   <div class=${'preview'+(left<0?' bad':'')}><span>${left<0?'No alcanza el saldo de '+accOf(acc).name:'Te quedarán en '+accOf(acc).name}</span><span class="amt">${sfmt(left)}</span></div>
   <${Note}>Se registrará como gasto en la categoría «Suscripción» y el próximo cobro pasará al ${longDate(next)}.<//>
  <//>`;
}
function SubHist({close,edit:x}){return html`<${Sheet} title=${'Pagos de '+x.name} onClose=${close} footer=${html`<button class="btn s" onClick=${close}>Cerrar</button>`}>
  ${x.pays.length?html`<ul class="tlist">${x.pays.map((p,k)=>html`<li key=${k}><span>${longDate(p.date)} · ${accOf(p.acc).name}</span><b class="amt">${fmt(p.amount)}</b></li>`)}</ul>`:html`<p class="mut">Todavía no hay pagos registrados.</p>`}<//>`}
function PlanForm({s,dispatch,close,toast,edit,confirm}){
  const [f,setF]=useState(edit?{name:edit.name,cat:edit.cat,need:String(edit.need),plan:String(edit.plan),freq:edit.freq,start:edit.start,due:edit.due,notes:edit.notes}:{name:'',cat:'',need:'',plan:'',freq:'Mensual',start:TODAY,due:addMonths(TODAY,2),notes:''});
  const [tried,setTried]=useState(false);const [newCat,setNewCat]=useState(null);const [nc,setNc]=useState('');
  const need=Number(f.need||0),plan=Number(f.plan||0);
  const err={name:!f.name.trim()?'Escribe un nombre para tu plan.':'',cat:!f.cat?'Elige una categoría.':'',need:!need?'Escribe un valor mayor que cero.':'',plan:plan>need?'No planees guardar más de lo que necesitas.':edit&&plan<edit.reserved?'Lo planeado no puede ser menor que lo ya reservado.':'',dates:f.start>=f.due?'La fecha de inicio debe ser anterior a la fecha en que lo necesitas.':''};
  const save=()=>{setTried(true);if(Object.values(err).some(Boolean))return;dispatch({t:'plan',old:edit,newCat:newCat,x:{...(edit||{reserved:0,resAcc:null,status:'activo'}),id:edit?edit.id:uid(),name:f.name.trim(),cat:f.cat,need,plan:plan||need,freq:f.freq,start:f.start,due:f.due,notes:f.notes.trim()}});close();toast(edit?'Plan actualizado.':'Plan guardado. Ya puedes organizarlo.',true)};
  const cats=[...s.cats.filter(c=>c!=='Suscripción'),...(newCat&&!s.cats.includes(newCat)?[newCat]:[])];
  const preview={...f,need,plan:plan||need,reserved:edit?edit.reserved:0};const reco=need?planReco(preview):0;
  return html`<${Sheet} title=${edit?'Editar plan':'Nuevo gasto futuro'} onClose=${close} footer=${html`<button class="btn p" onClick=${save}><${I} n="check"/>${edit?'Guardar cambios':'Guardar plan'}</button>`}>
   <label class="fl" for="p-name" style=${{marginTop:'4px'}}>Nombre del gasto</label><input id="p-name" class="field" placeholder="Ej. SOAT, matrícula, regalos" value=${f.name} onInput=${e=>setF({...f,name:e.target.value})}/><${Err} m=${tried&&err.name}/>
   <span class="fl">Categoría</span><${Chips} opts=${cats} value=${f.cat} onPick=${c=>setF({...f,cat:c})} label="Categoría" icons/>
   ${newCat===null?html`<button class="link" style=${{marginTop:'6px'}} onClick=${()=>setNewCat('')}><${I} n="plus" s=${16}/>Agregar categoría personalizada</button>`
    :!cats.includes(newCat)||newCat===''?html`<div class="inl-add"><input class="field" aria-label="Nombre de categoría" placeholder="Nombre de categoría" value=${nc} onInput=${e=>setNc(e.target.value)}/><button class="btn s sm" onClick=${()=>{const c=normName(nc);if(!c)return;if(cats.some(x=>x.toLowerCase()===c.toLowerCase())){setNc('');return;}setNewCat(c);setF({...f,cat:c})}}>Agregar</button></div>`:''}
   <${Err} m=${tried&&err.cat}/>
   <div class="two"><${MoneyField} id="p-need" label="Valor que necesitas" value=${f.need} onChange=${v=>setF({...f,need:v})}/><${MoneyField} id="p-plan" label="Cantidad que planeas guardar" value=${f.plan} onChange=${v=>setF({...f,plan:v})}/></div>
   <${Err} m=${tried&&(err.need||err.plan)}/>
   <span class="fl">Frecuencia</span><${Chips} opts=${Object.keys(PLANF)} value=${f.freq} onPick=${v=>setF({...f,freq:v})} label="Frecuencia"/>
   <div class="two"><div><label class="fl" for="p-start">Empezar</label><input id="p-start" type="date" class="field" value=${f.start} onInput=${e=>setF({...f,start:e.target.value||f.start})}/></div><div><label class="fl" for="p-due">Lo necesitas el</label><input id="p-due" type="date" class="field" value=${f.due} onInput=${e=>setF({...f,due:e.target.value||f.due})}/></div></div>
   <${Err} m=${tried&&err.dates}/>
   ${reco>0&&html`<p class="reco"><${I} n="bulb" s=${16}/>Recomendado: reservar <b class="amt">${fmt(reco)}</b> ${f.freq==='Fecha única'?'antes de la fecha':'por '+{Diario:'día',Semanal:'semana',Quincenal:'quincena',Mensual:'mes'}[f.freq]}.</p>`}
   <label class="fl" for="p-notes">Notas (opcional)</label><input id="p-notes" class="field" value=${f.notes} onInput=${e=>setF({...f,notes:e.target.value})}/>
   <p class="hint">El dinero solo se descontará después de confirmar una reserva.</p>
  <//>`;
}
function Reserve({s,dispatch,close,toast,edit:p}){
  const left=planLeft(p);const [v,setV]=useState(String(Math.min(planReco(p)||left,left)));const [acc,setAcc]=useState(p.resAcc||'bancolombia');const [tried,setTried]=useState(false);
  const amt=Number(v||0),total=totalBal(s),after=(s.bal[acc]||0)-amt;
  const err=!amt?'Escribe una cantidad mayor que cero.':amt>left?'Supera lo que planeaste guardar para este plan.':after<0?'Uy, parece que no alcanza la platica para eso.':'';
  return html`<${Sheet} title="Confirmar reserva" onClose=${close} footer=${html`<div class="two"><button class="btn s" onClick=${close}>Ahora no</button><button class="btn p" onClick=${()=>{setTried(true);if(err)return;dispatch({t:'reserve',id:p.id,v:amt,acc});close();toast('Reserva confirmada. El dinero ya está apartado.',true)}}>Confirmar reserva</button></div>`}>
   <ul class="tlist"><li><span>Concepto</span><b>${p.name}</b></li><li><span>Dinero disponible antes de reservar</span><b class="amt">${fmt(total)}</b></li><li><span>Todavía falta por reservar</span><b class="amt">${fmt(left)}</b></li></ul>
   <${Money} id="r-monto" label="Valor que vas a reservar" value=${v} onChange=${setV}/><${Err} m=${tried&&err}/>
   <span class="fl">Medio reservado</span><${AccPicker} bal=${s.bal} value=${acc} onPick=${setAcc} label="Medio reservado"/>
   <div class=${'preview'+(after<0?' bad':'')}><span>Saldo disponible después de confirmar</span><span class="amt">${sfmt(total-amt)}</span></div>
   <p class="hint">El dinero queda apartado de ${accOf(acc).name}; no cuenta como gasto.</p>
  <//>`;
}
function Release({s,dispatch,close,toast,edit:p}){
  const [acc,setAcc]=useState(p.resAcc||'efectivo');
  return html`<${Sheet} title="¿Liberar lo reservado?" onClose=${close} footer=${html`<div class="two"><button class="btn s" onClick=${close}>Conservar</button><button class="btn p" onClick=${()=>{dispatch({t:'release',id:p.id,acc});close();toast('Listo, ese dinero volvió a estar disponible.',true)}}>Liberar dinero</button></div>`}>
   <div class="bigamt"><small>Reservado para ${p.name}</small><span class="amt">${fmt(p.reserved)}</span></div>
   <span class="fl">Medio al que vuelve</span><${AccPicker} bal=${s.bal} value=${acc} onPick=${setAcc} label="Medio al que vuelve"/>
   <p class="hint">El plan sigue activo; solo vuelve el dinero a tu saldo disponible.</p>
  <//>`;
}
function DebtForm({dispatch,close,toast}){
  const [f,setF]=useState({name:'',orig:'',quota:'',n:'',hist:'0',next:''});const [tried,setTried]=useState(false);
  const o=Number(f.orig||0),q=Number(f.quota||0),n=Number(f.n||0),h=Number(f.hist||0);
  const err=!f.name.trim()?'Escribe un nombre para la deuda.':!o?'Escribe un monto mayor que cero.':!q?'Escribe una cuota mayor que cero.':!n?'Indica cuántas cuotas son.':h>n?'No pueden estar pagadas más cuotas de las que hay.':'';
  const save=()=>{setTried(true);if(err)return;const paid=Math.min(o,h*q);dispatch({t:'debt',x:{id:uid(),name:f.name.trim(),orig:o,quota:q,n,paidQ:h,paid,hist:h,next:f.next||null,day:f.next?d(f.next).getDate():1,entity:null,date:TODAY,pays:[]}});close();toast('¡Listo! La deuda quedó guardada.',true)};
  return html`<${Sheet} title="Nueva deuda" onClose=${close} footer=${html`<button class="btn p" onClick=${save}><${I} n="check"/>Guardar deuda</button>`}>
   <label class="fl" for="d-name" style=${{marginTop:'4px'}}>Nombre o descripción</label><input id="d-name" class="field" placeholder="Ej. Préstamo de un familiar" value=${f.name} onInput=${e=>setF({...f,name:e.target.value})}/>
   <div class="two"><${MoneyField} id="d-orig" label="Monto original" value=${f.orig} onChange=${v=>setF({...f,orig:v})}/><${MoneyField} id="d-quota" label="Valor de la cuota" value=${f.quota} onChange=${v=>setF({...f,quota:v})}/></div>
   <div class="two"><div><label class="fl" for="d-n">Número total de cuotas</label><input id="d-n" class="field" inputmode="numeric" value=${f.n} onInput=${e=>setF({...f,n:digits(e.target.value).slice(0,3)})}/></div>
    <div><label class="fl" for="d-h">Cuotas indicadas como pagadas</label><input id="d-h" class="field" inputmode="numeric" value=${f.hist} onInput=${e=>setF({...f,hist:digits(e.target.value).slice(0,3)})}/></div></div>
   <p class="hint">Las cuotas indicadas como pagadas son un dato histórico: no descuentan dinero ni crean gastos.</p>
   <label class="fl" for="d-next">Próximo pago (opcional)</label><input id="d-next" type="date" class="field" value=${f.next} onInput=${e=>setF({...f,next:e.target.value})}/>
   <${Err} m=${tried&&err}/>
   <${Note}>¿Es una compra con Addi, Sistecrédito u otra entidad? Regístrala en Créditos de compra para que use el cupo.<//>
  <//>`;
}
function DebtPay({s,dispatch,close,toast,edit:x}){
  const left=debtLeft(x);const [opt,setOpt]=useState('cuota');const [v,setV]=useState('');const [acc,setAcc]=useState('efectivo');const [date,setDate]=useState(TODAY);const [step,setStep]=useState(1);const [tried,setTried]=useState(false);
  const amt=opt==='cuota'?Math.min(x.quota,left):opt==='todo'?left:Number(v||0);const after=(s.bal[acc]||0)-amt;
  const err=!amt?'Escribe un abono mayor que cero.':amt>left?'Ese abono supera lo que todavía debes.':after<0?'No alcanza el saldo de esta opción.':'';
  return html`<${Sheet} title=${step===1?'Registrar abono':'Revisar abono'} onClose=${close} footer=${step===1?html`<button class="btn p" onClick=${()=>{setTried(true);if(!err)setStep(2)}}>Revisar abono</button>`
    :html`<div class="two"><button class="btn s" onClick=${()=>setStep(1)}>Volver</button><button class="btn p" onClick=${()=>{dispatch({t:'payDebt',id:x.id,v:amt,acc,date,opt});close();toast('¡Buen avance! El abono quedó registrado y el saldo actualizado.',true)}}>Registrar abono real</button></div>`}>
   ${step===1?html`<div>
    <p class="mut" style=${{margin:'2px 0 10px'}}>${x.name} · saldo por pagar <b class="amt">${fmt(left)}</b></p>
    <div class="opts3" role="radiogroup" aria-label="Tipo de abono">${[['cuota','Pagar cuota',fmt(Math.min(x.quota,left))],['todo','Pagar todo',fmt(left)],['otro','Abonar otro valor','Tú decides']].map(([k,l,sub])=>html`<button key=${k} role="radio" aria-checked=${opt===k} class="pk" aria-pressed=${opt===k} onClick=${()=>setOpt(k)}><small>${l}</small><span class="amt" style=${{fontSize:'14px'}}>${sub}</span></button>`)}</div>
    ${opt==='otro'&&html`<${Money} id="a-monto" label="Monto del abono" value=${v} onChange=${setV}/>`}
    <span class="fl">¿Desde dónde quieres pagar?</span><${AccPicker} bal=${s.bal} value=${acc} onPick=${setAcc} label="Medio de pago"/>
    <label class="fl" for="a-fecha">Fecha del abono</label><input id="a-fecha" type="date" class="field" value=${date} max=${TODAY} onInput=${e=>setDate(e.target.value||TODAY)}/>
    <${Err} m=${tried&&err}/></div>`
   :html`<div><ul class="tlist"><li><span>Deuda</span><b>${x.name}</b></li><li><span>Abono</span><b class="amt">${fmt(amt)}</b></li><li><span>Desde</span><b>${accOf(acc).name}</b></li><li><span>Fecha</span><b>${longDate(date)}</b></li>
     <li><span>Saldo restante después</span><b class="amt">${fmt(left-amt)}</b></li><li><span>Te quedarán en ${accOf(acc).name}</span><b class="amt">${fmt(after)}</b></li></ul>
     <${Note}>El abono descuenta el dinero y cuenta como gasto solo por el valor pagado.<//></div>`}
  <//>`;
}
function DebtHist({close,edit:x}){return html`<${Sheet} title="Historial de pagos" onClose=${close} footer=${html`<button class="btn s" onClick=${close}>Cerrar historial</button>`}>
  <p class="mut" style=${{margin:'0 0 6px'}}>${x.name}</p>
  ${x.pays.length?html`<ul class="tlist">${x.pays.map((p,k)=>html`<li key=${k}><span>${longDate(p.date)} · ${accOf(p.acc).name}</span><b class="amt">${fmt(p.amount)}</b></li>`)}</ul>`:html`<p class="mut">Todavía no hay abonos por aquí. Cada avance cuenta.</p>`}
  ${x.hist>0&&html`<${Note} icon="clock">${x.hist} ${x.hist===1?'cuota aparece':'cuotas aparecen'} como pagadas por dato histórico y no tienen movimiento asociado.<//>`}<//>`}
function EntityForm({dispatch,close,toast,s}){
  const [n,setN]=useState('');const [v,setV]=useState('');const [tried,setTried]=useState(false);
  const err=!n.trim()?'Escribe el nombre de la entidad.':s.entities.some(e=>!e.retired&&e.name.toLowerCase()===n.trim().toLowerCase())?'Ya tienes una entidad con ese nombre.':!Number(v)?'Escribe un cupo mayor que cero.':'';
  return html`<${Sheet} title="Agregar entidad" onClose=${close} footer=${html`<button class="btn p" onClick=${()=>{setTried(true);if(err)return;dispatch({t:'entity',x:{id:uid(),name:n.trim(),limit:Number(v),retired:false,hist:[{date:TODAY,from:0,to:Number(v)}]}});close();toast('Entidad agregada.',true)}}>Guardar entidad</button>`}>
   <label class="fl" for="e-name" style=${{marginTop:'4px'}}>Nombre de la entidad</label><input id="e-name" class="field" placeholder="Ej. Addi" value=${n} onInput=${e=>setN(e.target.value)}/>
   <${MoneyField} id="e-lim" label="Cupo aprobado" value=${v} onChange=${setV}/><${Err} m=${tried&&err}/>
   <p class="hint">Es el cupo para compras a cuotas, no dinero que entra a tus cuentas.</p><//>`;
}
function LimitForm({s,dispatch,close,toast,edit:e}){
  const used=entUsed(s,e);const [v,setV]=useState(String(e.limit));const [tried,setTried]=useState(false);const nv=Number(v||0);
  const err=!nv?'Escribe un cupo mayor que cero.':nv<used?'No puede ser menor al cupo utilizado.':'';
  return html`<${Sheet} title="Actualizar cupo" onClose=${close} footer=${html`<button class="btn p" onClick=${()=>{setTried(true);if(err)return;dispatch({t:'limit',id:e.id,v:nv});close();toast('Cupo actualizado. El utilizado no cambió.',true)}}>Guardar nuevo cupo</button>`}>
   <ul class="tlist"><li><span>Cupo aprobado actual</span><b class="amt">${fmt(e.limit)}</b></li><li><span>Cupo utilizado</span><b class="amt">${fmt(used)}</b></li></ul>
   <${Money} id="l-monto" label="Nuevo cupo aprobado" value=${v} onChange=${setV}/><${Err} m=${tried&&err}/>
   <div class=${'preview'+(nv<used?' bad':'')}><span>Nuevo cupo disponible</span><span class="amt">${sfmt(nv-used)}</span></div><//>`;
}
function Purchase({s,dispatch,close,toast,edit:e}){
  const avail=Math.max(0,e.limit-entUsed(s,e));
  const [f,setF]=useState({desc:'',cat:'',total:'',date:TODAY,n:'3',quota:'',first:addMonths(TODAY,1)});const [tried,setTried]=useState(false);const [auto,setAuto]=useState(true);
  const t=Number(f.total||0),n=Number(f.n||0),q=auto&&n?Math.ceil(t/n):Number(f.quota||0),lastQ=t-q*(n-1);
  const err={desc:!f.desc.trim()?'Escribe una descripción.':'',cat:!f.cat?'Elige una categoría.':'',total:!t?'Escribe un valor mayor que cero.':t>avail?'No hay suficiente cupo disponible. Revisa el cupo de la entidad.':'',n:!(n>=1&&n<=600)?'Indica entre 1 y 600 cuotas.':'',q:!q?'Escribe un valor de cuota mayor que cero.':q*(n-1)>=t&&n>1?'Las primeras cuotas superan el valor de la compra.':''};
  const save=()=>{setTried(true);if(Object.values(err).some(Boolean))return;dispatch({t:'debt',x:{id:uid(),name:`${e.name} · ${f.desc.trim()}`,orig:t,quota:q,n,paidQ:0,paid:0,hist:0,next:f.first,day:d(f.first).getDate(),entity:e.id,cat:f.cat,date:f.date,pays:[]}});close();toast('Compra guardada y agregada a Deudas.',true)};
  return html`<${Sheet} title=${'Nueva compra · '+e.name} onClose=${close} footer=${html`<button class="btn p" onClick=${save}><${I} n="bag" s=${20}/>Guardar compra</button>`}>
   <div class="preview" style=${{marginTop:0}}><span>Cupo disponible</span><span class="amt">${fmt(avail)}</span></div>
   <label class="fl" for="c-desc">¿Qué compraste?</label><input id="c-desc" class="field" placeholder="Descripción" value=${f.desc} onInput=${x=>setF({...f,desc:x.target.value})}/><${Err} m=${tried&&err.desc}/>
   <span class="fl">Categoría</span><${Chips} opts=${s.cats.filter(c=>c!=='Suscripción')} value=${f.cat} onPick=${c=>setF({...f,cat:c})} label="Categoría" icons/><${Err} m=${tried&&err.cat}/>
   <div class="two"><${MoneyField} id="c-total" label="Valor de la compra" value=${f.total} onChange=${v=>setF({...f,total:v})}/><div><label class="fl" for="c-date">Fecha de compra</label><input id="c-date" type="date" class="field" value=${f.date} max=${TODAY} onInput=${x=>setF({...f,date:x.target.value||TODAY})}/></div></div>
   <${Err} m=${tried&&err.total}/>
   <div class="two"><div><label class="fl" for="c-n">Número de cuotas</label><input id="c-n" class="field" inputmode="numeric" value=${f.n} onInput=${x=>setF({...f,n:digits(x.target.value).slice(0,3)})}/></div>
    <${MoneyField} id="c-q" label="Valor de cada cuota" value=${auto?String(q||''):f.quota} onChange=${v=>{setAuto(false);setF({...f,quota:v})}}/></div>
   <${Err} m=${tried&&(err.n||err.q)}/>
   ${n>1&&q&&lastQ!==q&&lastQ>0&&html`<p class="hint">La última cuota se ajustará para completar el total: ${fmt(lastQ)}.</p>`}
   <label class="fl" for="c-first">Vencimiento de la primera cuota</label><input id="c-first" type="date" class="field" value=${f.first} onInput=${x=>setF({...f,first:x.target.value||f.first})}/>
   <${Note}>La compra se guarda como deuda en esta entidad. No descuenta dinero ni cuenta como gasto hasta que pagues cada cuota.<//>
  <//>`;
}
/*SHEETS_4B*/

/* ======================= Bienvenida y cuentas iniciales ======================= */
const SUGG=['Nequi','Daviplata','Bancolombia','Davivienda','Nu','BBVA','Lulo Bank','dale!','Movii','RappiPay'];
function Welcome({ui,set}){
  const norm=normName(ui.onbName), valid=!!norm&&NAME_RE.test(norm);
  const next=()=>{set({onbTried:true});if(valid)set({onb:'cuentas',onbTried:false});};
  return html`<div class="onbwrap"><div class="onb">
   <div class="onb-top"><span class="brand">MichiFinanzas</span><span class="step">Paso 1 de 2</span></div>
   <div class="onb-hero" aria-hidden="true"><i class="blob b1"></i><i class="blob b2"></i><i class="blob b3"></i><i class="blob b4"></i><${Cat} k="icono" size="L" alt=""/></div>
   <h2 class="onb-h">¡Hola! Antes de empezar, pon tu nombre para que podamos organizar tu dinero juntos.</h2>
   <label class="fl" for="w-name">Tu nombre</label>
   <input id="w-name" class="field" autocomplete="given-name" autocapitalize="words" value=${ui.onbName} aria-invalid=${ui.onbTried&&!valid} aria-describedby="w-err" onInput=${e=>set({onbName:e.target.value})} onKeyDown=${e=>e.key==='Enter'&&next()}/>
   ${ui.onbTried&&!valid?html`<p class="err" id="w-err" role="alert"><${I} n="alert" s=${15}/>Usa solo letras y espacios; no dejes el campo vacío.</p>`:html`<p class="hint" id="w-err">Solo letras y espacios. Se guarda únicamente en este celular.</p>`}
  </div><div class="onb-foot"><button class="btn p" onClick=${next}>Continuar</button></div></div>`;
}
function SetupAccounts({ui,set}){
  const sel=ui.onbSel, has=n=>sel.some(x=>x.toLowerCase()===n.toLowerCase());
  const toggle=n=>set({onbSel:has(n)?sel.filter(x=>x!==n):[...sel,n]});
  const finish=()=>{const name=normName(ui.onbName)||'Andrea';set({onb:null,screen:'inicio',stack:[],userName:name,sheet:null,toast:{m:`¡Listo, ${name}! Ya puedes organizar tu dinero.`,ok:true,id:Date.now()}})};
  return html`<div class="onbwrap"><div class="onb">
   <div class="onb-top"><button class="ib back" aria-label="Volver al paso 1" onClick=${()=>set({onb:'nombre'})}><${I} n="back"/></button><span class="step">Paso 2 de 2</span></div>
   <div class="onb-head"><div><h2 class="onb-h">¿Qué cuentas digitales utilizas?</h2></div><${Cat} k="icono" size="S"/></div>
   <p class="onb-p">Elige las que usas. No registraremos saldos ni movimientos.</p>
   <span class="fl" style=${{marginTop:0}}>Bancos y billeteras</span>
   <div class="tiles" role="group" aria-label="Bancos y billeteras">${SUGG.map(n=>html`<button key=${n} class="tile" aria-pressed=${has(n)} onClick=${()=>toggle(n)}>
     <span class="bub"><${I} n=${['Bancolombia','Davivienda','BBVA'].includes(n)?'bank':'wallet'} s=${18}/></span><span class="tn">${n}</span><span class="ck"><${I} n="check" s=${14}/></span></button>`)}</div>
   <button class="btn o" onClick=${()=>set({sheet:'custom',edit:null})}><${I} n="plus" s=${18}/>Agregar cuenta personalizada</button>
   <${SecHead} title="Confirma tus cuentas"><span class="mut" style=${{fontSize:'13px'}}>${sel.length} ${sel.length===1?'cuenta':'cuentas'}</span><//>
   <div class="card" style=${{paddingBlock:sel.length?'6px':'16px'}}>
    ${sel.length?html`<p class="mut" style=${{fontSize:'13px',margin:'6px 0 4px'}}>Revisa la lista; puedes editarla antes de continuar.</p>${sel.map(n=>html`<div class="selrow" key=${n}>
      <span class="bub"><${I} n="wallet" s=${18}/></span><span><b style=${{display:'block',fontWeight:600}}>${n}</b>${!SUGG.includes(n)&&html`<span class="mut" style=${{fontSize:'12px'}}>Personalizada</span>`}</span>
      <span style=${{display:'flex'}}><button class="ib" aria-label=${'Editar '+n} onClick=${()=>set({sheet:'custom',edit:n})}><${I} n="pencil" s=${18}/></button><button class="ib" aria-label=${'Quitar '+n} onClick=${()=>set({onbSel:sel.filter(x=>x!==n)})}><${I} n="x" s=${18}/></button></span></div>`)}`
     :html`<p class="mut" style=${{margin:0,textAlign:'center'}}>Aún no seleccionaste ninguna cuenta.</p>`}
   </div>
  </div><div class="onb-foot"><button class="btn p" onClick=${finish}>${sel.length?'Confirmar y continuar':'Continuar sin cuentas'}</button>
   ${!sel.length&&html`<p class="hint">Podrás agregar cuentas más adelante en Configuración.</p>`}</div></div>`;
}
function CustomAccountSheet({ui,set,close}){
  const [v,setV]=useState(ui.edit||'');const [tried,setTried]=useState(false);
  const n=normName(v), dup=ui.onbSel.some(x=>x.toLowerCase()===n.toLowerCase()&&x!==ui.edit);
  const err=!n?'Escribe el nombre de la cuenta.':dup?'Ya agregaste una cuenta con ese nombre.':'';
  const save=()=>{setTried(true);if(err)return;set({onbSel:ui.edit?ui.onbSel.map(x=>x===ui.edit?n:x):[...ui.onbSel,n],sheet:null,edit:null})};
  return html`<${Sheet} title=${ui.edit?'Editar cuenta digital':'Agregar cuenta digital'} onClose=${close} footer=${html`<button class="btn p" onClick=${save}>Guardar</button>`}>
   <label class="fl" for="c-name" style=${{marginTop:'6px'}}>Nombre de la cuenta</label>
   <input id="c-name" class="field" maxlength="40" placeholder="Ej. Mi billetera" value=${v} onInput=${e=>setV(e.target.value)} onKeyDown=${e=>e.key==='Enter'&&save()}/>
   <div class="count">${v.length}/40</div>
   <${Err} m=${tried&&err}/>
   <p class="hint">Solo guardamos el nombre: no pedimos claves, números de cuenta ni saldos.</p>
  <//>`;
}

/* ======================= Teléfono ======================= */
const TITLES={inicio:'Inicio',mov:'Movimientos',cuentas:'Cuentas',stats:'Estadísticas',comp:'Compromisos',mas:'Más',subs:'Suscripciones',plans:'Gastos futuros',debts:'Deudas y préstamos',credits:'Créditos de compra',credit:'Detalle de crédito',savings:'Ahorros y préstamos',settings:'Configuración'};
const NAVTAB={inicio:'inicio',mov:'mov',comp:'comp',mas:'mas',cuentas:'mas',stats:'mas',subs:'comp',plans:'comp',debts:'comp',credits:'comp',credit:'comp',savings:'mas',settings:'mas'};
const ROOTS=['inicio','mov','comp','mas'];
const SCREENS={inicio:Inicio,mov:Movimientos,cuentas:Cuentas,stats:Stats,comp:Compromisos,mas:Mas,subs:Subs,plans:Plans,debts:Debts,credits:Credits,credit:CreditDetail,savings:Savings,settings:Settings};
const SHEETS={register:RegisterSheet,expense:ExpenseSheet,transfer:TransferSheet,income:IncomeSheet,debtinfo:null,subForm:SubForm,subPay:SubPay,subHist:SubHist,planForm:PlanForm,reserve:Reserve,release:Release,
  debtForm:DebtForm,debtPay:DebtPay,debtHist:DebtHist,entityForm:EntityForm,limit:LimitForm,purchase:Purchase,
  saving:SavingSheet,loan:LoanSheet,loanRet:LoanReturn,loanHist:LoanHist,catForm:CatSheet,accForm:AccSheet};
function Phone({theme,s,ui,set,dispatch}){
  const go=(v,param=null)=>set(u=>ROOTS.includes(v)?{screen:v,param:null,stack:[],sheet:null,cat:null}:{screen:v,param,stack:[...u.stack,{screen:u.screen,param:u.param}],sheet:null});
  const back=()=>set(u=>{const st=[...u.stack];const p=st.pop()||{screen:NAVTAB[u.screen]||'inicio',param:null};return {screen:p.screen,param:p.param,stack:st,sheet:null}});
  const open=(k,x)=>set({sheet:k,edit:x||null});
  const close=()=>set({sheet:null,edit:null});
  const toast=(m,ok)=>set({toast:{m,ok,id:Date.now()}});
  const confirm=dlg=>set({dlg});
  const menu=m=>set({menu:m});
  const body=useRef();useEffect(()=>{body.current&&(body.current.scrollTop=0)},[ui.screen,ui.param]);
  const sub=!ROOTS.includes(ui.screen);
  const P_={s,ui,set,go,back,open,close,toast,confirm,menu,dispatch};
  const Scr=SCREENS[ui.screen]||Inicio, Sh=ui.sheet&&SHEETS[ui.sheet];
  const title=ui.screen==='credit'?((s.entities.find(e=>e.id===ui.param)||{}).name||'Detalle de crédito'):TITLES[ui.screen];
  return html`<div class=${'phone t-'+theme} data-theme-name=${theme}>
   <div class="status" aria-hidden="true"><span>9:41</span><span><${I} n="signal" s=${16}/><${I} n="batt" s=${18}/></span></div>
   ${ui.onb?html`${ui.onb==='nombre'?html`<${Welcome} ui=${ui} set=${set}/>`:html`<${SetupAccounts} ui=${ui} set=${set}/>`}
    ${ui.sheet==='custom'&&html`<${CustomAccountSheet} ui=${ui} set=${set} close=${close} key=${ui.edit||'nueva'}/>`}`:html`
   <header class="bar">${sub&&html`<button class="ib back" aria-label="Volver" onClick=${back}><${I} n="back"/></button>`}<h2>${title}</h2>
    ${ui.screen==='cuentas'&&html`<button class="ib" aria-label="Transferir dinero" onClick=${()=>open('transfer')}><${I} n="swap"/></button>`}</header>
   <main class="body" ref=${body}>${ui.demo==='normal'?html`<${Scr} ...${P_}/>`:html`<${DemoState} ui=${ui} set=${set}/>`}</main>
   <nav class="nav" aria-label="Navegación principal">
    ${[['inicio','home','Inicio'],['mov','list','Movimientos'],null,['comp','cal','Compromisos'],['mas','grid','Más']].map(x=>x?html`<button key=${x[0]} aria-current=${NAVTAB[ui.screen]===x[0]?'page':null} onClick=${()=>go(x[0])}><${I} n=${x[1]}/>${x[2]}</button>`
      :html`<button key="reg" class="reg" aria-label="Registrar ingreso, gasto o transferencia" onClick=${()=>open('register')}><i><${I} n="plus" s=${26}/></i>Registrar</button>`)}
   </nav>
   ${ui.sheet==='debtinfo'&&html`<${DebtInfo} e=${ui.edit} close=${close}/>`}
   ${Sh&&html`<${Sh} ...${P_} edit=${ui.edit} key=${ui.sheet+(ui.edit&&ui.edit.id||'')}/>`}`}
   ${ui.menu&&html`<${MenuSheet} m=${ui.menu} close=${()=>set({menu:null})}/>`}
   ${ui.dlg&&html`<${Dialog} dlg=${ui.dlg} close=${()=>set({dlg:null})}/>`}
   ${ui.toast&&html`<div class="toast" role="status" key=${ui.toast.id}>${ui.toast.ok!==false?html`<${Cat} k="exitoso" size="S"/>`:html`<span style=${{padding:'0 6px'}}><${I} n="info" s=${20}/></span>`}<span>${ui.toast.m}</span></div>`}
  </div>`;
}
/* Estados de carga y error (para revisar el diseño) */
const ERRS={inicio:'Ups, no pudimos cargar tu resumen.',mov:'Ups, no pudimos cargar tus gastos.',cuentas:'No pudimos cargar tus cuentas.',stats:'Ups, tus estadísticas no cargaron esta vez.',comp:'No pudimos cargar tus compromisos.',mas:'No pudimos cargar esta sección.',
  subs:'No pudimos cargar tus suscripciones.',plans:'Ups, no pudimos cargar tus planes.',debts:'Ups, tus deudas no cargaron esta vez.',credits:'No pudimos cargar tus créditos.',credit:'No pudimos cargar tus créditos.',savings:'Ups, tus ahorros no cargaron esta vez.',settings:'Ups, tus ajustes no cargaron esta vez.'};
function DemoState({ui,set}){
  if(ui.demo==='loading')return html`<div aria-busy="true" aria-label="Cargando"><div class="skel h"></div><div class="skel"></div><div class="skel s"></div><div class="skel"></div><div class="skel s"></div><p class="mut" style=${{textAlign:'center'}}>Estamos cargando tu información...</p></div>`;
  return html`<div class="card" style=${{marginTop:'10px'}}><div class="empty"><${Cat} k="vacio" size="M"/><b>${ERRS[ui.screen]}</b><p>Tus datos siguen guardados en este celular. Intenta de nuevo en un momento.</p><button class="btn p" style=${{width:'auto'}} onClick=${()=>set({demo:'normal'})}>Intentar de nuevo</button></div></div>`;
}

/* ======================= Página ======================= */
const SWATCH=[['Fondo','#FFF8EF','#1C1625'],['Superficie','#FFFFFF','#271F33'],['Superficie hundida','#F8EEE2','#211A2C'],['Tarjeta de saldo','#5B2A86','#3A2B52'],['Texto principal','#2B1E36','#FFF4E6'],['Texto secundario','#6E6077','#C4B6CF'],
 ['Principal','#5B2A86','#C9A7F0'],['Principal suave','#EFE4F7','#3B2D52'],['Borde de campo','#9C8F80','#7E6F8C'],['Separador','#EFE3D3','#3A3047'],['Positivo','#237A50','#6FD3A0'],['Negativo','#C03636','#FF8C82'],['Advertencia','#8A5300 / #FFF1D6','#F6C744'],
 ['Naranja calicó (decorativo)','#F2994A','#F2A766'],['Amarillo (decorativo)','#F6C744','#F6C744'],['Placa del gato','#FFF1DF','#F6EADB']];
const JUMPS=[['Arranque',[['Bienvenida',{onb:'nombre'}],['Cuentas iniciales',{onb:'cuentas'}]]],
 ['Principal',[['Inicio',{screen:'inicio'}],['Gastos',{screen:'mov',movTab:'gastos'}],['Ingresos',{screen:'mov',movTab:'ingresos'}],['Cuentas',{screen:'cuentas'}],['Estadísticas',{screen:'stats'}]]],
 ['Compromisos',[['Suscripciones',{screen:'subs'}],['Gastos futuros',{screen:'plans'}],['Deudas',{screen:'debts'}],['Créditos',{screen:'credits'}],['Detalle Addi',{screen:'credit',param:'addi'}]]],
 ['Más',[['Ahorros y préstamos',{screen:'savings'}],['Configuración',{screen:'settings'}]]],
 ['Hojas',[['Botón Registrar',{sheet:'register'}],['Formulario de gasto',{sheet:'expense'}],['Agregar ingreso',{sheet:'income'}],['Transferir',{sheet:'transfer'}]]]];
const INVENT=[['Arranque','Bienvenida (nombre) · Cuentas iniciales','Cuenta personalizada (agregar y editar)'],
 ['Inicio','Saldo, efectivo y digital, acciones rápidas, resumen del mes, próximos pagos, movimientos, consejo','Registrar (ingreso, gasto, transferencia)'],
 ['Movimientos','Gastos (filtro, mes, categorías) · Ingresos (por tipo)','Nuevo y editar gasto, borrar gasto, abono de solo lectura, agregar y editar ingreso con reparto y préstamo, menú y eliminar ingreso'],
 ['Cuentas','Total, distribución, efectivo, cuentas digitales, transferencias recientes','Transferir dinero'],
 ['Estadísticas','Periodos · pestañas General, Efectivo y Digital','—'],
 ['Compromisos','Por pagar del mes, módulos, próximos pagos','—'],
 ['Suscripciones','Estimados, activas, canceladas','Nueva y editar, pagar, historial, menú, cancelar y reactivar'],
 ['Gastos futuros','Dinero disponible · Activos, Completados, Archivados','Nuevo y editar plan, categoría personalizada, confirmar reserva, liberar, completar, archivar, reactivar, eliminar'],
 ['Deudas y préstamos','Resumen · Pendientes y Pagadas · filtro por entidad','Nueva deuda (dato histórico), registrar abono con revisión, historial, revisar dato histórico, borrar'],
 ['Créditos de compra','Resumen general, entidades con cupo · Detalle de la entidad','Agregar entidad, nueva compra, actualizar cupo, retirar entidad'],
 ['Ahorros y préstamos','Mi ahorro · Dinero prestado','Separar y retirar, prestar con revisión, registrar devolución, historial de devoluciones'],
 ['Configuración','Nombre, categorías, cuentas digitales, transferencias, apariencia (reservado), datos locales','Categoría, cuenta, editar y revertir transferencia, borrar todos los datos'],
 ['Estados','Carga, error con «Intentar de nuevo», vacíos con gato','Diálogo de confirmación único, menú de acciones, aviso de éxito']];
const COMPS=['Tarjeta de saldo','Tarjeta de resumen con valores','Campo monetario grande','Campo monetario en línea','Selector de cuenta con saldo','Vista previa de saldo','Chips de categoría, periodo y frecuencia','Pestañas segmentadas','Fila de gasto, abono, ingreso y transferencia','Fila de próximo pago','Barra de progreso','Barra de cupo (utilizado / disponible)','Etiquetas de estado','Dona, barras y línea','Recomendación','Aviso informativo','Estado vacío con gato','Carga y error','Hoja inferior','Menú de acciones','Diálogo de confirmación','Aviso de éxito','Barra superior y barra inferior'];
function App(){
  const [s,dispatch]=useReducer(reducer,null,()=>reducer(null,{t:'reset'}));
  const [ui,setUi]=useState({screen:'inicio',param:null,stack:[],movTab:'gastos',month:'nov',cat:null,statsTab:'general',period:'mes',acc:null,sheet:null,edit:null,toast:null,dlg:null,menu:null,
    planTab:'activo',debtTab:'pend',saveTab:'ahorro',demo:'normal',onb:null,onbName:'',onbSel:[],onbTried:false,userName:'Andrea'});
  const [mode,setMode]=useState(()=>{try{return localStorage.getItem('michi-mode')||'light'}catch(e){return 'light'}});
  const [empty,setEmpty]=useState(false);
  const set=p=>setUi(u=>({...u,...(typeof p==='function'?p(u):p)}));
  useEffect(()=>{try{localStorage.setItem('michi-mode',mode)}catch(e){}},[mode]);
  useEffect(()=>{if(!ui.toast)return;const t=setTimeout(()=>set({toast:null}),3200);return()=>clearTimeout(t)},[ui.toast]);
  const phones=mode==='both'?['light','dark']:[mode];
  const isOn=p=>p.sheet?ui.sheet===p.sheet&&!ui.onb:p.onb?ui.onb===p.onb:!ui.onb&&!ui.sheet&&ui.screen===p.screen&&(!p.movTab||ui.movTab===p.movTab)&&(!p.param||ui.param===p.param);
  return html`<div class="shell">
   <div class="top"><div><h1>MichiFinanzas · propuesta C</h1><p>Prototipo navegable con todas las pantallas de la app. Datos de ejemplo; nada se guarda.</p></div>
    <div class="ctrls">
     <div class="seg" role="group" aria-label="Tema">${[['light','Claro'],['dark','Oscuro'],['both','Comparar']].map(([k,l])=>html`<button key=${k} aria-pressed=${mode===k} onClick=${()=>setMode(k)}>${l}</button>`)}</div>
     <div class="seg" role="group" aria-label="Datos">${[[false,'Con datos'],[true,'Sin datos']].map(([k,l])=>html`<button key=${l} aria-pressed=${empty===k} onClick=${()=>{setEmpty(k);dispatch({t:'reset',empty:k});set({sheet:null,acc:null,cat:null,dlg:null,menu:null,param:ui.screen==='credit'?'addi':ui.param})}}>${l}</button>`)}</div>
     <div class="seg" role="group" aria-label="Estado de carga">${[['normal','Normal'],['loading','Cargando'],['error','Error']].map(([k,l])=>html`<button key=${k} aria-pressed=${ui.demo===k} onClick=${()=>set({demo:k})}>${l}</button>`)}</div>
    </div></div>
   <div class="jumps">${JUMPS.map(([g,items])=>html`<div class="jump" role="group" aria-label=${'Ir a: '+g} key=${g}><span class="jl">${g}</span>${items.map(([l,p])=>html`<button key=${l} aria-pressed=${isOn(p)}
     onClick=${()=>p.sheet?set({onb:null,sheet:p.sheet,edit:null,dlg:null,menu:null}):set({onb:p.onb||null,screen:p.screen||ui.screen,movTab:p.movTab||ui.movTab,param:p.param||null,stack:p.screen&&!ROOTS.includes(p.screen)?[{screen:NAVTAB[p.screen],param:null}].concat(p.screen==='credit'?[{screen:'credits',param:null}]:[]):[],sheet:null,dlg:null,menu:null,onbTried:false})}>${l}</button>`)}</div>`)}</div>
   <div class="stage">${phones.map(t=>html`<div key=${t}>${mode==='both'&&html`<div class="label">${t==='light'?'Tema claro':'Tema oscuro'}</div>`}<${Phone} theme=${t} s=${s} ui=${ui} set=${set} dispatch=${dispatch}/></div>`)}</div>
   <section class="specs" aria-labelledby="spec-t">
    <h2 id="spec-t">Especificaciones de la propuesta C</h2>
    <p>Valores para llevar a Figma y, después, a <code>ThemeData</code> de Flutter. El texto cumple al menos 4,5:1 y los bordes de campo 3:1 sobre su superficie.</p>
    <h3>Colores: claro · oscuro</h3>
    <div class="tok">${SWATCH.map(([n,a,b])=>html`<div key=${n}><i style=${{background:a.split(' ')[0]}}></i><i style=${{background:b}}></i><span style=${{fontFamily:'Inter'}}><b>${n}</b><span>${a} · ${b}</span></span></div>`)}</div>
    <h3>Tipografía</h3>
    <div class="scroll"><table class="sp"><thead><tr><th>Uso</th><th>Fuente</th><th>Tamaño / peso</th></tr></thead><tbody>
     <tr><td>Saldo principal</td><td>Nunito, números tabulares</td><td>38 px / 800</td></tr><tr><td>Total de pantalla</td><td>Nunito</td><td>30–34 px / 800</td></tr>
     <tr><td>Título de barra superior</td><td>Nunito</td><td>20 px / 800</td></tr><tr><td>Título de sección</td><td>Nunito</td><td>17 px / 800</td></tr>
     <tr><td>Montos en listas</td><td>Nunito</td><td>15–19 px / 800</td></tr><tr><td>Texto</td><td>Inter</td><td>15 px / 400–600</td></tr><tr><td>Secundario y etiquetas</td><td>Inter</td><td>12–13 px / 500–600</td></tr></tbody></table></div>
    <h3>Medidas</h3>
    <p>Radios: 14 (campos, chips cuadrados, íconos), 16–20 (tarjetas), 24 (tarjeta de saldo), 28 (hojas inferiores), 999 (chips). Espaciado base 4: 8, 10, 12, 14, 16, 22. Áreas táctiles de 44 px o más. Gatos en tres tamaños: L 148 × 132, M 96 × 88, S 44 × 42.</p>
    <h3>Pantallas incluidas</h3>
    <div class="scroll"><table class="sp"><thead><tr><th>Módulo</th><th>Pantalla</th><th>Hojas inferiores y diálogos</th></tr></thead><tbody>
     ${INVENT.map(([m,p,h])=>html`<tr key=${m}><td>${m}</td><td>${p}</td><td>${h}</td></tr>`)}</tbody></table></div>
    <h3>Componentes</h3>
    <p>${COMPS.join(' · ')}.</p>
    <h3>Navegación</h3>
    <p>Barra inferior: Inicio, Movimientos, Registrar (botón central), Compromisos y Más. Compromisos agrupa Suscripciones, Gastos futuros, Deudas y Créditos; Más agrupa Cuentas, Estadísticas, Ahorros y préstamos y Configuración. Las pantallas internas tienen botón Volver y recuerdan de dónde vienes (por ejemplo, Detalle de crédito › Deudas asociadas › Volver).</p>
   </section>
  </div>`;
}
ReactDOM.createRoot(document.getElementById('root')).render(html`<${App}/>`);
}
