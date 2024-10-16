from get_forum import LoginAndGet
from memory_profiler import memory_usage
import json
import time
import re


class Parser():
    servers = ['rpg', '1rp', '2rp']
    forum = LoginAndGet()

    def parse(self, serv: int) -> None:
        server = self.servers[serv]
        url = f"https://gta-trinity.com/forum/api/monitoring/?columns[0][orderable]=true&columns[0][search][regex]=false&columns[1][data]=1&columns[1][name]=&columns[1][searchable]=true&columns[1][orderable]=false&columns[1][search][value]=&columns[1][search][regex]=false&order[0][column]=0&order[0][dir]=desc&start=0&length=4000&search[regex]=true&monitoring={server}ban"
        data = json.loads(self.forum.getF(url, False))
        banlist = [entry[1] for entry in data.get("data", [])]
        with open(f'{server}.json', "w+", encoding="utf-8") as f:
            json.dump(banlist, f, ensure_ascii=False, indent=4)

# p = Parser()
# while True:
#     for value in p.servers:
#         try:
#             print(time.strftime('%H:%M:%S') +':'+value+' start parsed || RAM: '+ str(memory_usage()))
#             p.parse(value)
#             print(time.strftime('%H:%M:%S') +':'+value+' end parsed || RAM: '+ str(memory_usage()))
#         except Exception as err:
#             print(time.strftime('%H:%M:%S') +':'+value+' error parsed || RAM: '+ str(memory_usage()) + ' || Error: '+str(err))
#         time.sleep(15)
