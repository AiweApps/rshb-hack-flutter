"""Local, single-device MCP proof. Bridge listens only on loopback."""
import json, os, secrets, threading, time, uuid
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Literal
from mcp.server.fastmcp import FastMCP

CONFIG=Path(os.environ.get('RETAIL_BRIDGE_CONFIG',str(Path.home()/'.config/aiwe-wine-perekrestok/device-bridge.json')))
config=json.loads(CONFIG.read_text());token=config['token']
condition=threading.Condition();serial=threading.Lock();pending=None;last_seen=0.
class Handler(BaseHTTPRequestHandler):
 def log_message(self,*args):pass
 def reply(self,status,body):
  data=json.dumps(body,ensure_ascii=False).encode();self.send_response(status);self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
 def authorized(self):return secrets.compare_digest(self.headers.get('Authorization',''),'Bearer '+token)
 def do_GET(self):
  global last_seen
  if not self.authorized():self.reply(401,{'error':'unauthorized'});return
  if self.path!='/next':self.reply(404,{});return
  with condition:
   last_seen=time.monotonic()
   if pending and not pending['sent'] and pending['deadline']>time.monotonic():pending['sent']=True;job=pending['command']
   else:job=None
  self.reply(200,{'command':job})
 def do_POST(self):
  if not self.authorized():self.reply(401,{'error':'unauthorized'});return
  if self.path!='/result':self.reply(404,{});return
  try:
   length=int(self.headers.get('Content-Length','0'))
   if not 0<length<1000000:raise ValueError()
   result=json.loads(self.rfile.read(length))
  except Exception:self.reply(400,{});return
  with condition:
   if not pending or result.get('id')!=pending['command']['id'] or pending['deadline']<time.monotonic():self.reply(409,{'error':'expired_job'});return
   pending['result']=result;condition.notify_all()
  self.reply(200,{'ok':True})

def execute(operation,**args):
 global pending
 if not serial.acquire(blocking=False):return {'error':'device_busy'}
 try:
  with condition:
   if time.monotonic()-last_seen>4:return {'error':'device_offline','instruction':'Open Retail WebView Probe and keep it in foreground.'}
   command={'id':str(uuid.uuid4()),'operation':operation,**args}
   pending={'command':command,'deadline':time.monotonic()+25,'sent':False,'result':None}
   while not pending['result']:
    left=pending['deadline']-time.monotonic()
    if left<=0:return {'error':'device_timeout','request_id':command['id']}
    condition.wait(left)
   result=pending['result'];result['source']='perekrestok_android_webview';return result
 finally:
  with condition:pending=None
  serial.release()

mcp=FastMCP('Perekrestok Android WebView prototype')
@mcp.tool()
def session_status()->dict:
 """Check whether the paired foreground Android app is connected. Does not verify retailer availability."""
 return {'connected':time.monotonic()-last_seen<4,'transport':'local USB reverse tunnel','production_ready':False}
@mcp.tool()
def select_store(store_id:Literal[817,814])->dict:
 """Select Taganrog catalog: 817 CityCentre Gogolevsky2/1 or 814 Arbuz Bakinskaya65. Catalog is not pickup ordering."""
 return execute('select_store',store_id=store_id)
@mcp.tool()
def search_products(query:str,store_id:Literal[817,814],page:int=1)->dict:
 """Find real products and kopek prices in the requested Taganrog store. Selects catalog and verifies returned SAP store. Never interpret balance_state as exact stock count."""
 if not 1<=len(query.strip())<=100 or not 1<=page<=20:return {'error':'invalid_arguments'}
 return execute('search_products',query=query.strip(),store_id=store_id,page=page)
@mcp.tool()
def get_product(product_id:int,store_id:Literal[817,814])->dict:
 """Read a retailer product card after selecting requested store; stock is qualitative, availability for ordering is not claimed."""
 if product_id<=0:return {'error':'invalid_product_id'}
 return execute('get_product',product_id=product_id,store_id=store_id)

if __name__=='__main__':
 server=ThreadingHTTPServer(('127.0.0.1',18765),Handler)
 threading.Thread(target=server.serve_forever,daemon=True).start()
 try:mcp.run(transport='stdio')
 finally:server.shutdown();server.server_close()
