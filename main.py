from logic import Logic
import asyncio
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles 
from fastapi.templating import Jinja2Templates
from models import BanlistLongPolling, BanlistGetRaw

logic = Logic()

app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

@app.get("/banlist/web/{server_id}/{count}")
async def getWeb228(request: Request, server_id: int, count: int):
    await logic.updateBans(server_id)
    return templates.TemplateResponse("main.html", {'request': request, "server_id": server_id, "count": count, 'bans': await logic.getWeb(server_id, count)})

@app.post("/banlist/longpoll")
async def longPoll228(*, longpoll: BanlistLongPolling):
    await logic.updateBans(longpoll.server)
    return await logic.longPoll(longpoll.server, longpoll.ban)

@app.post("/banlist/get")
async def getJson228(*, r: BanlistGetRaw):
    await logic.updateBans(r.server)
    return await logic.getJson(r.server, r.count)