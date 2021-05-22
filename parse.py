from get_forum import LoginAndGet
from memory_profiler import memory_usage
import json
import time
import re


class Parser():
    servers = ['rpg', 'rp', 'rp2']
    forum = LoginAndGet()

    def parse(self, server: str):
        with open(server+'.json', "w+", encoding="utf-8") as f:
            if server == 'rp2':
                f.write(json.dumps(re.split('<br>', self.forum.getF("http://gta-trinity.ru/"+server+"mon/bans.php", False))[5::], sort_keys=True, indent=4))
            else:
                f.write(json.dumps(re.split('<br>', self.forum.getF("http://gta-trinity.ru/"+server+"mon/bans.php", False))[6::], sort_keys=True, indent=4))

p = Parser()
while True:
    for value in p.servers:
        try:
            print(time.strftime('%H:%M:%S') +':'+value+' start parsed || RAM: '+ str(memory_usage()))
            p.parse(value)
            print(time.strftime('%H:%M:%S') +':'+value+' end parsed || RAM: '+ str(memory_usage()))
        except Exception as err:
            print(time.strftime('%H:%M:%S') +':'+value+' error parsed || RAM: '+ str(memory_usage()) + ' || Error: '+str(err))
        time.sleep(15)