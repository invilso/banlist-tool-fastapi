from serializer import Serializer
from fastapi.responses import JSONResponse
import asyncio
import json

class Logic():
    async def longPoll(self, server_id, ban):
        s = Serializer()
        respdata = [False]
        for i in range(120):
            check = await s.longpollGet(server_id, ban)
            if check != False:
                respdata = check
                return JSONResponse(respdata)
            await asyncio.sleep(10)
        return JSONResponse(respdata)

    async def getJson(self, server_id, count):
        s = Serializer()
        r = await s.get(server_id, count)
        return JSONResponse(r)
    
    async def getWeb(self, server, count):
        s = Serializer()
        r = await s.get(server, count)
        return r
