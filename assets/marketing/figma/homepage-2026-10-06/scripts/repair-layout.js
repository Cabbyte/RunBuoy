await Promise.all(['Regular','Medium','Bold'].map(style=>figma.loadFontAsync({family:'Noto Sans SC',style})));
await figma.loadFontAsync({family:'SF Pro',style:'Bold'});
const mutated=[],created=[];
const rows=figma.currentPage.findAll(n=>n.type==='FRAME'&&n.layoutMode==='HORIZONTAL'&&!n.id.startsWith('I'));
for(const n of rows){let w=n.parent.width-(n.parent.paddingLeft||0)-(n.parent.paddingRight||0);if(n.name==='Brand')w=n.parent.width<600?168:200;if(n.name==='Navigation links')w=530;if(n.name==='Hero actions')w=460;n.primaryAxisSizingMode='FIXED';n.resize(w,n.height);n.counterAxisSizingMode='AUTO';n.clipsContent=false;mutated.push(n.id);}
for(const id of ['4:33','4:35']){const t=await figma.getNodeByIdAsync(id);t.componentPropertyReferences={};mutated.push(id);}
for(const id of ['6:88','6:212']){const n=await figma.getNodeByIdAsync(id);n.setProperties({'Label#4:4':'连接我的电脑'});mutated.push(id);}
const bg=await figma.getNodeByIdAsync('6:214');bg.resize(390,550);mutated.push(bg.id);
const mascot=bg.findOne(n=>n.name==='Mascot · independent asset');mascot.y=310;mutated.push(mascot.id);
const featured=await figma.getNodeByIdAsync('6:219');featured.y=54;mutated.push(featured.id);
const desktop=await figma.getNodeByIdAsync('6:70');const dash=desktop.findOne(n=>n.name==='ChatGPT / actual dashboard screenshot');dash.resize(1160,640);dash.effects=[];const image=dash.findOne(n=>n.name==='Actual plugin workspace');image.resize(1160,1212);image.fills=[{type:'IMAGE',imageHash:'da65403bc4b9eb3f736e1817721d2c0156bc01b8',scaleMode:'FILL'}];image.x=0;image.y=0;mutated.push(dash.id,image.id);
const mobile=await figma.getNodeByIdAsync('6:198');const mDash=mobile.findOne(n=>n.name==='ChatGPT / actual dashboard screenshot');mDash.name='ChatGPT / selected task · editable focus';const old=mDash.children[0];const removedNodeIds=[old.id];old.remove();mDash.effects=[];mDash.layoutMode='VERTICAL';mDash.primaryAxisSizingMode='AUTO';mDash.counterAxisSizingMode='FIXED';mDash.paddingLeft=mDash.paddingRight=mDash.paddingTop=mDash.paddingBottom=20;mDash.itemSpacing=16;mDash.fills=[{type:'SOLID',color:{r:1,g:1,b:1}}];mDash.resize(342,10);mDash.primaryAxisSizingMode='AUTO';
function t(s,size,bold,color){const n=figma.createText();n.fontName={family:'Noto Sans SC',style:bold?'Bold':'Regular'};n.fontSize=size;n.characters=s;n.name=s;n.fills=[{type:'SOLID',color:color||{r:.063,g:.102,b:.176}}];n.lineHeight={unit:'PERCENT',value:145};n.textAutoResize='HEIGHT';n.resize(302,n.height);mDash.appendChild(n);created.push(n.id);return n;}
t('运行中 · 模型训练',22,true);t('Studio GPU',18,false);t('Epoch 34 of 50                         68%',16,false);
const track=figma.createFrame();track.name='Explicit task progress';track.resize(302,12);track.cornerRadius=6;track.fills=[{type:'SOLID',color:{r:.86,g:.90,b:1}}];mDash.appendChild(track);created.push(track.id);const fill=figma.createRectangle();fill.resize(205,12);fill.cornerRadius=6;fill.fills=[{type:'SOLID',color:{r:.1,g:.5,b:1}}];track.appendChild(fill);created.push(fill.id);
t('验证损失降至 0.042，正在保存检查点。',18,false);mutated.push(mDash.id);
return {mutatedNodeIds:mutated,createdNodeIds:created,removedNodeIds,layouts:[desktop,mobile].map(n=>({id:n.id,width:n.width,height:n.height}))};
