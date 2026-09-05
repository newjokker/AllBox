'use strict';
const defaults=JSON.parse(document.querySelector('#pcbDefaults').textContent);
const $=s=>document.querySelector(s), form=$('#pcbForm'), storageKey='allbox.pcb.v1';
let revision=0, timer, validationController, validState=null, busy=false;
let cloudName='', cloudDirty=true, cloudMode='save', cloudBusy=false;
let renderer,scene,camera,controls,model,home;
const bools=Object.keys(defaults).filter(k=>typeof defaults[k]==='boolean');
const choices=Object.keys(defaults).filter(k=>typeof defaults[k]==='string');
function message(text){$('#status').textContent=text;}
function error(text=''){$('#error').textContent=text;$('#error').hidden=!text;}
function numberInput(label,value,key){
  const wrap=document.createElement('label');wrap.textContent=label;
  const input=document.createElement('input');input.type='number';input.step='any';input.value=value;
  input.dataset.key=key;input.required=true;wrap.append(input);return wrap;
}
function selectInput(label,options,value,key){
  const wrap=document.createElement('label');wrap.textContent=label;
  const select=document.createElement('select');select.dataset.key=key;
  for(const [v,text] of options){const option=new Option(text,v);select.add(option);}
  select.value=value;wrap.append(select);return wrap;
}
function makeRow(host,title){
  const row=document.createElement('div');row.className='edit-row';
  const head=document.createElement('div');head.className='row-head';
  const name=document.createElement('span');name.textContent=title;
  const remove=document.createElement('button');remove.type='button';remove.textContent='删除';remove.setAttribute('aria-label','删除'+title);
  remove.addEventListener('click',()=>{row.remove();changed();});head.append(name,remove);
  const fields=document.createElement('div');fields.className='fields';row.append(head,fields);host.append(row);
  return {row,fields};
}
function addPost(point=[0,0]){
  const {fields}=makeRow($('#postRows'),'安装孔');fields.append(numberInput('X · 向右为正',point[0],'x'),numberInput('Y · 向后为正',point[1],'y'));
}
const faces=[['front','前面 −Y'],['back','后面 +Y'],['left','左面 −X'],['right','右面 +X'],['top','盖板'],['bottom','底板']];
function addHole(h=['back','rect',0,4,8,4]){
  const {row,fields}=makeRow($('#holeRows'),'额外开孔');
  const side=!['top','bottom'].includes(h[0]),height=h[1]==='circle'?h[4]:h[5];
  fields.append(selectInput('所在面',faces,h[0],'face'),selectInput('形状',[['rect','矩形'],['circle','圆孔']],h[1],'shape'),
    numberInput('横向中心',h[2],'offset'),numberInput(side?'孔下沿离外底面':'Y 中心（向后为正）',side?h[3]-height/2:h[3],'vertical'),
    numberInput(h[1]==='circle'?'直径':'宽度',h[4],'width'),numberInput('高度',height,'height'));
  function labels(){
    const face=row.querySelector('[data-key=face]').value,shape=row.querySelector('[data-key=shape]').value;
    row.querySelector('[data-key=vertical]').parentElement.firstChild.textContent=['top','bottom'].includes(face)?'Y 中心（向后为正）':'孔下沿离外底面';
    row.querySelector('[data-key=offset]').parentElement.firstChild.textContent=['left','right'].includes(face)?'Y 中心（向后为正）':'X 中心（向右为正）';
    row.querySelector('[data-key=width]').parentElement.firstChild.textContent=shape==='circle'?'直径':'宽度';
    row.querySelector('[data-key=height]').parentElement.hidden=shape==='circle';
    row.querySelector('[data-key=height]').disabled=shape==='circle';
  }
  row.addEventListener('change',labels);labels();
}
function readRow(row){return Object.fromEntries([...row.querySelectorAll('[data-key]')].map(e=>[e.dataset.key,e.tagName==='SELECT'?e.value:Number(e.value)]));}
function payload(){
  const p={};for(const [key,value] of Object.entries(defaults)){
    if(Array.isArray(value))continue;
    const el=form.elements.namedItem(key);p[key]=bools.includes(key)?el.checked:choices.includes(key)?el.value:el.value===''?null:Number(el.value);
  }
  p.screw_post_positions_custom=[...$('#postRows').children].map(row=>{const p=readRow(row);return[p.x,p.y];});
  p.box_holes_custom=[...$('#holeRows').children].map(row=>{const h=readRow(row),height=h.shape==='circle'?h.width:h.height;
    const center=['top','bottom'].includes(h.face)?h.vertical:h.vertical+height/2;
    return [h.face,h.shape,h.offset,center,h.width,...(h.shape==='rect'?[h.height]:[])];});
  return p;
}
function setValues(p){
  for(const [key,value] of Object.entries(p)){
    const el=form.elements.namedItem(key);if(!el)continue;
    if(bools.includes(key))el.checked=value;else if(!Array.isArray(value))el.value=value;
  }
  $('#postRows').replaceChildren();p.screw_post_positions_custom.forEach(addPost);
  $('#holeRows').replaceChildren();p.box_holes_custom.forEach(addHole);updateVisibility();
}
function updateVisibility(){
  const custom=form.elements.screw_post_layout.value==='custom';$('#customPosts').hidden=!custom;
  for(const key of ['pcb_mount_hole_spacing_x','pcb_mount_hole_spacing_y']){
    form.elements[key].closest('label').hidden=custom;form.elements[key].disabled=custom;
  }
  const manual=form.elements.height_mode.value==='manual';form.elements.upper_box_height_manual.closest('label').hidden=!manual;form.elements.upper_box_height_manual.disabled=!manual;

}
function changed(){
  cloudDirty=true;updateCloudStatus();
  revision++;validState=null;error();updateVisibility();clearTimeout(timer);
  validationController?.abort();message('参数已修改；3D 需重新生成。正在计算尺寸…');
  timer=setTimeout(validateCurrent,300);
}
async function api(path,p,signal){
  const res=await fetch(path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p),signal});
  if(!res.ok){let data={};try{data=await res.json();}catch{}throw new Error(data.error||`请求失败（${res.status}）`);}
  return res;
}
async function validateCurrent(){
  const rev=revision;validationController=new AbortController();
  try{
    const res=await api('/api/pcb/validate',payload(),validationController.signal),data=await res.json();
    if(rev!==revision)return null;
    validState=data;error();drawPlan(data.params,data.dimensions);summary(data.dimensions);
    persistDraft(data.params);
    if(!busy)message('尺寸已更新 · 3D 模型需点击生成；下载会使用当前参数。');
    return data;
  }catch(e){if(e.name!=='AbortError'&&rev===revision){validState=null;error(e.message);message('参数需调整；图示保留上一次有效尺寸。');}return null;}
}
function fmt(n){return Number(n.toFixed(2)).toString();}
function summary(d){
  const data=[['盒内净尺寸',`${fmt(d.inner_width)} × ${fmt(d.inner_length)}`],['盒体外尺寸',`${fmt(d.box_width)} × ${fmt(d.box_length)} × ${fmt(d.total_height)}`],['上盖高 / 板上净空',`${fmt(d.upper_box_height)} / ${fmt(d.above_pcb)}`]];
  $('#metrics').replaceChildren(...data.map(([label,value])=>{const div=document.createElement('div');div.append(document.createTextNode(label));const strong=document.createElement('strong');strong.textContent=value+' ';const unit=document.createElement('small');unit.textContent='mm';strong.append(unit);div.append(strong);return div;}));
}
function drawPlan(p,d){
  const svg=$('#plan'),NS='http://www.w3.org/2000/svg';svg.replaceChildren();
  const scale=Math.min(490/d.box_width,280/d.box_length),cx=350,cy=205;
  const x=v=>cx+v*scale,y=v=>cy-v*scale;
  function node(tag,attrs,text){const el=document.createElementNS(NS,tag);for(const[k,v]of Object.entries(attrs))el.setAttribute(k,v);if(text!==undefined)el.textContent=text;svg.append(el);return el;}
  function rect(left,back,w,l,fill,stroke,r=0){return node('rect',{x:x(left),y:y(back),width:w*scale,height:l*scale,rx:r*scale,fill,stroke,'stroke-width':1.4});}
  function text(px,py,value,color='#b8ccbc',size=12){node('text',{x:px,y:py,fill:color,'font-size':size,'text-anchor':'middle'},value);}
  rect(-d.box_width/2,d.box_length/2,d.box_width,d.box_length,'#34483b','#95ad9b',p.corner_radius);
  rect(-d.inner_width/2,d.inner_length/2,d.inner_width,d.inner_length,'#122018','#587660',Math.max(p.corner_radius-p.wall_thickness,0));
  const xs=d.posts.map(p=>p[0]),ys=d.posts.map(p=>p[1]);
  const minx=Math.min(...xs),maxx=Math.max(...xs),miny=Math.min(...ys),maxy=Math.max(...ys);
  rect(-d.inner_width/2,miny,d.inner_width,p.hole_wall_front,'#674a2e','none');
  const range=rect(minx,maxy,d.hole_span_x,d.hole_span_y,'#253d2c','#9fc7a7');range.setAttribute('stroke-dasharray','5 4');
  for(const[px,py]of d.posts){node('circle',{cx:x(px),cy:y(py),r:4.5,fill:'#13251a',stroke:'#ffbe82','stroke-width':1.4});node('path',{d:`M ${x(px)-7} ${y(py)} h 14 M ${x(px)} ${y(py)-7} v 14`,stroke:'#ffbe82','stroke-width':.6});}
  text(x((minx+maxx)/2),y((miny+maxy)/2)+4,`孔距 ${fmt(d.hole_span_x)} × ${fmt(d.hole_span_y)}`,'#e0efdf',11);
  function gapLabel(ax,ay,bx,by,label,tx,ty){
    node('line',{x1:x(ax),y1:y(ay),x2:x(bx),y2:y(by),stroke:'#d0ba90','stroke-width':1,'stroke-dasharray':'3 2'});
    text(tx,ty,label,'#ffe0b8',10);
  }
  const midx=(minx+maxx)/2,midy=(miny+maxy)/2;
  gapLabel(midx,miny,midx,-d.inner_length/2,`前 ${fmt(p.hole_wall_front)}`,x(midx)+32,y((miny-d.inner_length/2)/2)+4);
  gapLabel(midx,maxy,midx,d.inner_length/2,`后 ${fmt(p.hole_wall_back)}`,x(midx)+32,y((maxy+d.inner_length/2)/2)+4);
  gapLabel(minx,midy,-d.inner_width/2,midy,`左 ${fmt(p.hole_wall_left)}`,x((minx-d.inner_width/2)/2),y(midy)-10);
  gapLabel(maxx,midy,d.inner_width/2,midy,`右 ${fmt(p.hole_wall_right)}`,x((maxx+d.inner_width/2)/2),y(midy)-10);
  if(p.box_holes_enabled)for(const h of p.box_holes_custom){
    const [face,shape,offset,vertical,width]=h,height=shape==='circle'?width:h[5];
    if(['front','back'].includes(face)){
      const wallY=(face==='front'?-1:1)*d.box_length/2;
      node('line',{x1:x(offset-width/2),x2:x(offset+width/2),y1:y(wallY),y2:y(wallY),stroke:'#f7ac71','stroke-width':5});
    }else if(['left','right'].includes(face)){
      const wallX=(face==='left'?-1:1)*d.box_width/2;
      node('line',{x1:x(wallX),x2:x(wallX),y1:y(offset-width/2),y2:y(offset+width/2),stroke:'#f7ac71','stroke-width':5});
    }else{
      const cut=shape==='circle'?node('circle',{cx:x(offset),cy:y(vertical),r:width*scale/2,fill:'none',stroke:'#f7ac71'}):rect(offset-width/2,vertical+height/2,width,height,'none','#f7ac71');
      if(face==='bottom')cut.setAttribute('stroke-dasharray','3 2');
    }
  }
  const top=y(d.box_length/2)-24,bottom=y(-d.box_length/2)+30,left=x(-d.box_width/2),right=x(d.box_width/2);
  node('path',{d:`M ${left} ${top+6} v -12 M ${left} ${top} H ${right} M ${right} ${top+6} v -12`,stroke:'#8ba18f',fill:'none'});
  text(cx,top-10,`横向 X · ${fmt(d.box_width)} mm`);
  text(cx,bottom,'前 FRONT · −Y', '#efa26b');
  text(right+40,cy,`${fmt(d.box_length)}`);text(right+40,cy+17,'mm', '#a1b3a5',10);
  text(left-35,cy,'左 −X','#a1b3a5',10);
  text(cx,top-32,'后 BACK · +Y','#a1b3a5',10);
}
function showTab(modelTab){
  $('#planHost').hidden=modelTab;$('#modelHost').hidden=!modelTab;$('#resetCamera').hidden=!modelTab;
  $('#planTab').setAttribute('aria-pressed',String(!modelTab));$('#modelTab').setAttribute('aria-pressed',String(modelTab));
  if(modelTab&&!model)message('点击“生成 3D 预览”查看真实模型。');
  if(modelTab&&renderer)resizeViewer();
}
function resizeViewer(){
  const box=$('#modelHost').getBoundingClientRect();if(!renderer||!box.width||!box.height)return;
  renderer.setSize(box.width,box.height,false);camera.aspect=box.width/box.height;camera.updateProjectionMatrix();
}
function initViewer(){
  if(renderer)return;
  if(typeof THREE==='undefined')throw new Error('3D 组件加载失败，请刷新；仍可下载 STL。');
  renderer=new THREE.WebGLRenderer({antialias:true,alpha:true});renderer.setPixelRatio(Math.min(devicePixelRatio||1,2));
  renderer.outputEncoding=THREE.sRGBEncoding;$('#canvasHost').append(renderer.domElement);
  scene=new THREE.Scene();camera=new THREE.PerspectiveCamera(38,1,.1,5000);camera.up.set(0,0,1);
  controls=new THREE.OrbitControls(camera,renderer.domElement);controls.enableDamping=true;
  scene.add(new THREE.HemisphereLight(0xe6f2e5,0x253b2a,.85));
  const light=new THREE.DirectionalLight(0xffe3c6,.9);light.position.set(100,-120,200);scene.add(light);
  const grid=new THREE.GridHelper(500,50,0x60806a,0x294532);grid.rotation.x=Math.PI/2;grid.position.z=-.2;scene.add(grid);
  new ResizeObserver(resizeViewer).observe($('#modelHost'));
  renderer.setAnimationLoop(()=>{if(!$('#modelHost').hidden){controls.update();renderer.render(scene,camera);}});
}
function renderModel(buffer){
  showTab(true);initViewer();const geometry=new THREE.STLLoader().parse(buffer);geometry.computeVertexNormals();geometry.computeBoundingBox();
  const box=geometry.boundingBox,center=box.getCenter(new THREE.Vector3()),size=box.getSize(new THREE.Vector3());
  geometry.translate(-center.x,-center.y,-box.min.z);
  if(model){scene.remove(model);model.geometry.dispose();model.material.dispose();}
  model=new THREE.Mesh(geometry,new THREE.MeshStandardMaterial({color:0xe99458,roughness:.68,side:THREE.DoubleSide}));scene.add(model);
  const radius=Math.max(size.length()/2,10),target=new THREE.Vector3(0,0,size.z*.3),position=new THREE.Vector3(1.2,-1.6,1.2).normalize().multiplyScalar(radius*3.2).add(target);
  home={position,target};camera.far=radius*40;controls.minDistance=radius*.3;controls.maxDistance=radius*12;resetCamera();resizeViewer();
}
function resetCamera(){if(home){camera.position.copy(home.position);controls.target.copy(home.target);camera.updateProjectionMatrix();controls.update();}}
function saveBlob(blob,filename){const url=URL.createObjectURL(blob),link=document.createElement('a');link.href=url;link.download=filename;document.body.append(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);}
function setBusy(value){busy=value;for(const id of ['preview','download','downloadScad'])$('#'+id).disabled=value;$('#preview').textContent=value?'正在处理…':'生成 3D 预览';}
async function generate(kind,download=false){
  if(busy||!form.reportValidity())return;
  clearTimeout(timer);setBusy(true);error();const rev=revision;
  try{
    const state=await validateCurrent();if(!state||rev!==revision)return;
    message(kind==='scad'?'正在准备 SCAD…':'正在生成模型，首次可能需要几十秒…');
    const res=await api(`/api/pcb/${kind}${download?'?download=1':''}`,state.params);
    if(download){saveBlob(await res.blob(),`pcb_box_${state.params.part}.${kind}`);message(rev===revision?'已下载 · 模型按打印方向摆放。':'已下载点击时的参数版本；表单参数已修改。');}
    else{const buffer=await res.arrayBuffer();if(rev!==revision){message('生成期间参数有修改，请重新生成以查看最新模型。');return;}renderModel(buffer);message('3D 已更新 · 与当前参数一致。');}
  }catch(e){error(e.message);message('生成未完成，请调整参数或重试。');}finally{setBusy(false);}
}
async function importConfig(raw){
  const candidate=raw.config??raw;
  const res=await api('/api/pcb/validate',candidate),state=await res.json();setValues(state.params);changed();
}
$('#preview').addEventListener('click',()=>generate('stl'));
$('#download').addEventListener('click',()=>generate('stl',true));
$('#downloadScad').addEventListener('click',()=>generate('scad',true));
$('#addPost').addEventListener('click',()=>{addPost();changed();});
$('#addHole').addEventListener('click',()=>{addHole();changed();});
$('#planTab').addEventListener('click',()=>showTab(false));$('#modelTab').addEventListener('click',()=>showTab(true));$('#resetCamera').addEventListener('click',resetCamera);
form.addEventListener('input',changed);form.addEventListener('change',changed);
// Export controls live outside the parameter form but are associated with it.
for(const el of document.querySelectorAll('[form=pcbForm]'))el.addEventListener('change',changed);
form.addEventListener('submit',e=>{e.preventDefault();generate('stl');});
$('#restore').addEventListener('click',()=>{cloudName='';setValues(defaults);changed();});
$('#exportConfig').addEventListener('click',async()=>{if(!form.reportValidity())return;clearTimeout(timer);const state=await validateCurrent();if(state)saveBlob(new Blob([JSON.stringify({version:2,config:state.params},null,2)],{type:'application/json'}),'pcb_box_config.json');});
$('#importFile').addEventListener('click',()=>$('#configFile').click());
$('#configFile').addEventListener('change',async e=>{const file=e.target.files[0];if(!file)return;try{if(file.size>32768)throw new Error('配置文件不能超过 32 KB');await importConfig(JSON.parse(await file.text()));cloudName='';updateCloudStatus();}catch(err){error('导入失败：'+err.message);}e.target.value='';});

function updateCloudStatus(){
  $('#cloudStatus').textContent=cloudName?`当前：${cloudName} · ${cloudDirty?'有未保存修改':'已与云端同步'}`:'当前：新配置，尚未保存到云端。';
}
function persistDraft(params){
  try{localStorage.setItem(storageKey,JSON.stringify({config:params,cloudName,cloudDirty}));}catch{}
}
async function getCloud(path){
  const res=await fetch(path,{cache:'no-store'});
  const data=await res.json();if(!res.ok)throw new Error(data.error||'云端配置读取失败');return data;
}
function cloudError(text=''){$('#cloudError').textContent=text;$('#cloudError').hidden=!text;}
function cloudLoading(value){
  cloudBusy=value;for(const id of ['cloudSelect','cloudName','cloudSubmit','cloudCancel'])$('#'+id).disabled=value;
}
async function openCloud(mode){
  if(mode==='save'&&!form.reportValidity())return;
  cloudMode=mode;cloudError();$('#cloudTitle').textContent=mode==='save'?'保存配置':'选择云端配置';
  $('#cloudSubmit').textContent=mode==='save'?'保存到云端':'加载配置';
  $('#cloudNameLabel').hidden=mode!=='save';$('#cloudName').value=cloudName;
  $('#cloudHint').textContent=mode==='save'?'同名保存会更新云端配置，上一版自动备份。':'加载所选配置后，可继续调整并生成模型。';
  $('#cloudSelect').replaceChildren(new Option(mode==='save'?'＋ 新建配置':'请选择配置',''));
  $('#cloudDialog').showModal();cloudLoading(true);
  try{
    const entries=await getCloud('/api/pcb/configs');
    for(const item of entries)$('#cloudSelect').add(new Option(item.name,item.name));
    if(entries.some(item=>item.name===cloudName))$('#cloudSelect').value=cloudName;
    if(!entries.length&&mode==='load')$('#cloudHint').textContent='还没有云端配置。先调整参数，再点击“保存配置”。';
  }catch(e){cloudError(e.message);}finally{cloudLoading(false);}
}
$('#saveConfig').addEventListener('click',()=>openCloud('save'));
$('#loadConfig').addEventListener('click',()=>openCloud('load'));
$('#cloudCancel').addEventListener('click',()=>$('#cloudDialog').close());
$('#cloudDialog').addEventListener('cancel',e=>{if(cloudBusy)e.preventDefault();});
$('#cloudSelect').addEventListener('change',()=>{if(cloudMode==='save')$('#cloudName').value=$('#cloudSelect').value;});
$('#cloudForm').addEventListener('submit',async e=>{
  e.preventDefault();if(cloudBusy)return;cloudError();cloudLoading(true);
  try{
    if(cloudMode==='save'){
      const name=$('#cloudName').value.trim();if(!name)throw new Error('请填写配置名称');
      clearTimeout(timer);const rev=revision,state=await validateCurrent();
      if(!state||rev!==revision)throw new Error('请先修正表单参数后再保存');
      const res=await api('/api/pcb/configs',{name,config:state.params}),saved=await res.json();
      cloudName=saved.name;cloudDirty=rev!==revision;updateCloudStatus();
      if(rev===revision)persistDraft(state.params);
      message(saved.backup?'已保存到云端，上一版已备份。':'已保存到云端，可在其他设备选择此配置。');
    }else{
      const name=$('#cloudSelect').value;if(!name)throw new Error('请选择要加载的配置');
      const saved=await getCloud('/api/pcb/configs/'+encodeURIComponent(name));
      await importConfig(saved);cloudName=saved.name;cloudDirty=false;updateCloudStatus();persistDraft(saved.config);
    }
    $('#cloudDialog').close();
  }catch(err){cloudError(err.message);}finally{cloudLoading(false);}
});
setValues(defaults);
(async()=>{
  try{
    const saved=localStorage.getItem(storageKey);
    if(saved){
      const draft=JSON.parse(saved);await importConfig(draft);
      cloudName=typeof draft.cloudName==='string'?draft.cloudName:'';
      // A restored draft can be older than the server version on another device.
      cloudDirty=true;updateCloudStatus();return;
    }
  }catch{message('本地草稿无法恢复，已使用模型默认参数。');}
  await validateCurrent();
})();
