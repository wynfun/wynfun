// Writes data/games.json (payout tables the server uses) by reading them out of the real game code in index.html.
// needs playwright (dev only):  NODE_PATH=$(npm root -g) node tools/gen-games.js [--check]
const fs=require('fs'),path=require('path');const {chromium}=require('playwright');
(async()=>{const root=path.join(__dirname,'..');const b=await chromium.launch();const p=await b.newPage();
await p.route('**/*',r=>{const u=r.request().url();if(u.startsWith('file://'))r.continue();else r.abort()});
await p.goto('file://'+path.join(root,'index.html'));await p.waitForFunction(()=>typeof plTbl==='function'&&typeof wwTbl==='function'&&typeof ghMult==='function'&&typeof CR==='object');
const out=await p.evaluate(()=>{const o={plinko:{},wheel:{},gem:{},crash:{edge:CR.edge,rate:CR.rate,max:CR.max}};
 [8,10,12,14,16].forEach(n=>{o.plinko[n]={};['low','med','high'].forEach(r=>{o.plinko[n][r]=plTbl(n,r).m})});
 [10,20,30,40].forEach(n=>{o.wheel[n]={};['low','med','high'].forEach(r=>{o.wheel[n][r]=wwTbl(n,r).vals})});
 for(let m=1;m<=24;m++){const a=[];for(let k=0;k<=25-m;k++)a.push(ghMult(k,m));o.gem[m]=a}
 return o});
await b.close();const txt=JSON.stringify(out);const f=path.join(root,'data','games.json');
if(process.argv[2]==='--check'){const cur=fs.existsSync(f)?fs.readFileSync(f,'utf8'):'';if(cur!==txt){console.error('data/games.json is out of date. Run: node tools/gen-games.js');process.exit(1)}console.log('games.json up to date');process.exit(0)}
fs.writeFileSync(f,txt);console.log('wrote',f,txt.length,'bytes')})();
