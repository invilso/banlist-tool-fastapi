import json
import asyncio

class Serializer():
     
    async def get(self, server:int, coun:int):
        try:
            if server == 0:
                with open("rpg.json", "r", encoding="utf-8") as f:
                    return json.load(f)[0:coun]
            elif server == 1:
                with open("1rp.json", "r", encoding="utf-8") as f:
                    return  json.load(f)[0:coun]
            elif server == 2:
                with open("2rp.json", "r", encoding="utf-8") as f:
                    return json.load(f)[0:coun]
        except:
            return ['Строки ещё не загрузились']

    async def longpollGet(self, server: int, ban: str):
        if server == 0:
            return await self.getLongpollLine('rpg.json', ban)
        elif server == 1:
            return await self.getLongpollLine('1rp.json', ban)
        elif server == 2:
            return await self.getLongpollLine('2rp.json', ban)
    
    async def getLongpollLine(self, server: str, ban: str):
        try:
            with open(server, "r", encoding="utf-8") as f: 
                try:  
                    return await self.checkLongPoll(json.load(f)[0], ban)
                except Exception:
                    return False
        except:
            return ['Строки ещё не загрузились']
    
    async def checkLongPoll(self, line: str, ban: str):
        if line[1:] != ban:
            return [line[1:]]
        else:
            return False