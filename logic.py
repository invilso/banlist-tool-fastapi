import time
from serializer import Serializer
from fastapi.responses import JSONResponse
import asyncio
import json
import os
from parse import Parser

parser = Parser()

class Logic():
    servers = ['rpg', '1rp', '2rp']

    async def updateBans(self, server_id: int) -> None:
        try:
            _, _, _, _, _, _, _, _, mtime, _ = os.stat(self.servers[server_id]+'.json')
            if mtime+300 < time.time():
                parser.parse(server_id)
            return None
        except FileNotFoundError:
            parser.parse(server_id)
        
    async def longPoll(self, server_id: int, ban: str) -> JSONResponse:
        s = Serializer()
        respdata = [False]
        for i in range(120):
            check = await s.longpollGet(server_id, ban)
            if check != False:
                respdata = check
                return JSONResponse(respdata)
            await asyncio.sleep(10)
        return JSONResponse(respdata)

    async def getJson(self, server_id: int, count: int) -> JSONResponse:
        s = Serializer()
        r = await s.get(server_id, count)
        return JSONResponse(r)
    
    async def getWeb(self, server: int, count: int) -> list[str]:
        s = Serializer()
        r = await s.get(server, count)
        return r
