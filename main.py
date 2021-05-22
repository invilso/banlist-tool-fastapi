from logic import Get
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles 
from fastapi.templating import Jinja2Templates
from models import BanlistLongPolling, BanlistGetRaw

logic = Get()

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

@app.get("/banlist/web/{server_id}/{count}")
async def getWeb(request: Request, server_id: int, count: int):
    return templates.TemplateResponse("main.html", {'request': request, "server_id": server_id, "count": count, 'bans': logic.getWeb(server_id, count)})

@app.post("/banlist/longpoll")
async def longPoll(*, longpoll: BanlistLongPolling):
    return await logic.longPoll(longpoll.server, longpoll.ban)

@app.post("/banlist/get")
async def getJson(*, r: BanlistGetRaw):
    return await logic.getJson(r.server, r.count)