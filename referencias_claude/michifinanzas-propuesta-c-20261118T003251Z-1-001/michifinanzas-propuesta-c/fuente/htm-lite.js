/* htm-lite: plantillas tipo JSX con template literals, para React (sin compilador). */
window.htmLite=function(h){
  const cache=new Map();
  const PROP={class:'className',for:'htmlFor',inputmode:'inputMode',autocomplete:'autoComplete',tabindex:'tabIndex',maxlength:'maxLength',readonly:'readOnly',autocapitalize:'autoCapitalize'};
  const propName=n=>PROP[n]||(/^(aria|data)-/.test(n)?n:n.replace(/-([a-z])/g,(_,c)=>c.toUpperCase()));
  const ws=c=>c===' '||c==='\n'||c==='\t'||c==='\r';
  function parse(statics){
    const root={kids:[]};const stack=[root];let cur=root;
    let mode='text',buf='',node=null,an='',q='';
    const text=()=>{if(buf){let t=buf;if(!(/\n/.test(t)&&/^\s*$/.test(t))){t=t.replace(/^\s*\n\s*/,'').replace(/\s*\n\s*$/,'').replace(/\s*\n\s*/g,' ');if(t)cur.kids.push({s:t});}}buf=''};
    const open=()=>{cur.kids.push(node);if(!node.self){stack.push(node);cur=node;}node=null;mode='text';};
    const endAttr=()=>{if(an){node.props.push([an,true]);an='';}};
    for(let i=0;i<statics.length;i++){
      const s=statics[i];
      for(let j=0;j<s.length;j++){const c=s[j];
        if(mode==='text'){if(c==='<'){text();mode='lt';}else buf+=c;}
        else if(mode==='lt'){if(c==='/'){mode='close';}else{node={tag:c,props:[],kids:[]};mode='name';}}
        else if(mode==='name'){if(ws(c))mode='attrs';else if(c==='/'){node.self=1;mode='attrs';}else if(c==='>')open();else node.tag+=c;}
        else if(mode==='attrs'){if(ws(c))continue;if(c==='/'){node.self=1;}else if(c==='>'){open();}else if(c==='.'){mode='dots';}else{an=c;mode='an';}}
        else if(mode==='dots'){/* "..." antes de un valor: se resuelve en el hueco */}
        else if(mode==='an'){if(c==='='){mode='eq';}else if(ws(c)){endAttr();mode='attrs';}else if(c==='/'){endAttr();node.self=1;mode='attrs';}else if(c==='>'){endAttr();open();}else an+=c;}
        else if(mode==='eq'){if(c==='"'||c==="'"){q=c;buf='';mode='qv';}else{buf=c;mode='uv';}}
        else if(mode==='qv'){if(c===q){node.props.push([an,buf]);an='';buf='';mode='attrs';}else buf+=c;}
        else if(mode==='uv'){if(ws(c)||c==='>'||c==='/'){node.props.push([an,buf]);an='';buf='';mode='attrs';if(c==='>')open();else if(c==='/')node.self=1;}else buf+=c;}
        else if(mode==='close'){if(c==='>'){stack.pop();cur=stack[stack.length-1];mode='text';buf='';}}
      }
      if(i<statics.length-1){const v={v:i};
        if(mode==='text'){text();cur.kids.push(v);}
        else if(mode==='lt'){node={tag:v,props:[],kids:[]};mode='name';}
        else if(mode==='name'){mode='attrs';}
        else if(mode==='eq'){node.props.push([an,v]);an='';mode='attrs';}
        else if(mode==='dots'){node.props.push(['...',v]);mode='attrs';}
        else if(mode==='close'){}
        else throw new Error('htm-lite: valor en posición no soportada ('+mode+')');
      }
    }
    if(mode!=='text'||stack.length!==1)throw new Error('htm-lite: plantilla sin cerrar');
    text();return root.kids;
  }
  function make(n,vals){
    if(n.s!=null)return n.s;
    if(n.v!=null&&!n.tag)return vals[n.v];
    const type=n.tag.v!=null?vals[n.tag.v]:n.tag;const props={};
    for(const [k,v] of n.props){const val=v&&v.v!=null?vals[v.v]:v;if(k==='...')Object.assign(props,val);else props[typeof type==='string'?propName(k):k]=val;}
    const kids=n.kids.map(k=>make(k,vals));
    return kids.length?h(type,props,...kids):h(type,props);
  }
  return function(statics,...vals){let t=cache.get(statics);if(!t){t=parse(statics);cache.set(statics,t);}
    const out=t.map(n=>make(n,vals));return out.length===1?out[0]:out;};
};
