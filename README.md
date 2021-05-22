# BanlistTools Fast API
## Python:
### Установка:
Клонируем репозиторий:
>git clone https://github.com/invilso/banlist-tool-fastapi.git

Переходим в директорию:
>cd banlist-tool-fastapi

Создаем виртуальное окружение:
>python -venv env

Активируем виртуальное окружение:
>source env/bin/activate - Linux

>souce env/Scripts/activate.bat - Windows

Устанавливаем зависимости:
>pip install -r requirements.txt

Запускаем на localhost и 8000 порте, с поддержкой автоперезагрузки при изменениях:
>uvicorn main:app --host 127.0.0.1 --port 8000 --reload

### API:
#### Получение банлиста:
```
Метод: POST
Req Body: JSON
Вид Request JSON: {"server": 0, "count": 0}
Возвращаемые данные: JSON со списком строк банлиста (первая строка в списке имеет символ \n в начале)
Cсылка: http://45.95.203.231:8000/banlist/get
```

#### LongPoll получения новой строки:
>Метод: POST

>Req Body: JSON

>Вид Request JSON: {"server": 0, "ban": "Последняя строка банлиста которая у вас есть"}

>Возвращаемые данные: JSON с новой строкой банлиста, или [false]

>Ссылка: http://45.95.203.231:8000/banlist/longpoll

#### WEB версия банлиста:
>Метод: GET

>Возвращаемые даные: html страничка

>http://45.95.203.231:8000/banlist/web/{сервер}/{количество строк}

## Lua:
### Установка:
Скопировать скрипт из директории Lua в папку с игрой.
Изменить содержимое перменных serverip и serverport на значения которые вы указывали при запуске сервера.
