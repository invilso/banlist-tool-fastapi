import json
import asyncio

class Serializer():
     
    async def get(self, server:int, coun:int):
        if server == 0:
            with open("rpg.json", "r", encoding="utf-8") as f:
                return await json.load(f)[::coun]
        elif server == 1:
            with open("rp.json", "r", encoding="utf-8") as f:
                return await json.load(f)[::coun]
        elif server == 2:
            with open("rp2.json", "r", encoding="utf-8") as f:
                return await json.load(f)[::coun]

    async def longpollGet(self, server: int, ban: str):
        if server == 0:
            return self.getLongpollLines('rpg.json', ban)
        elif server == 1:
            return self.getLongpollLines('rp.json', ban)
        elif server == 2:
            return self.getLongpollLines('rp2.json', ban)
    
    async def getLongpollLine(self, server: str, ban: str):
        with open(server, "r", encoding="utf-8") as f: 
            try:  
                return await self.checkLongPoll(json.load(f)[0]), ban)
            except Exception:
                return False
    
    async def checkLongPoll(self, line: str, ban: str):
        if line[1:] != ban:
            return [line[1:]]
        else:
            return False