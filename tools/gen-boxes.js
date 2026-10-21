// Writes data/boxes.json (what the server uses to decide results) from the box list in index.html.
// usage: node tools/gen-boxes.js          write the file
//        node tools/gen-boxes.js --check  exit 1 if the file is out of date
const fs=require('fs'),path=require('path');
const root=path.join(__dirname,'..');
const html=fs.readFileSync(path.join(root,'index.html'),'utf8').split('\n');
const a=html.findIndex(l=>l.startsWith('var P=['));
const b=html.findIndex((l,i)=>i>a&&l.startsWith(']\.map('));
if(a<0||b<0){console.error('box list not found');process.exit(2)}
const src=html.slice(a,b+1).join('\n').replace(/^var P=/,'global.PP=');
eval(src);
const out=PP.map(p=>({n:p.n,p:p.p,i:p.i.map(x=>[x[0],x[1],x[2],x[3]])}));
const txt=JSON.stringify(out);
const f=path.join(root,'data','boxes.json');
if(process.argv[2]==='--check'){const cur=fs.existsSync(f)?fs.readFileSync(f,'utf8'):'';if(cur!==txt){console.error('data/boxes.json is out of date. Run: node tools/gen-boxes.js');process.exit(1)}console.log('boxes.json up to date ('+out.length+' boxes)');process.exit(0)}
fs.writeFileSync(f,txt);console.log('wrote',f,out.length,'boxes',txt.length,'bytes');
