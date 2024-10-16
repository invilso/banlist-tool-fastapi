
# BanlistTools Fast API

## Python:

### Installation:

Clone the repository:
```bash
git clone https://github.com/invilso/banlist-tool-fastapi.git
```

Navigate to the directory:
```bash
cd banlist-tool-fastapi
```

Create a virtual environment:
```bash
python -m venv env
```

Activate the virtual environment:
```bash
# Linux:
source env/bin/activate 
# Windows:
cd env/Scripts
activate.bat
```

Install dependencies:
```bash
pip install -r requirements.txt
```

Run the server on `localhost` with port `8000`, with auto-reload support:
```bash
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### Code Style Recommendations:
- Follow **PEP8** for consistent formatting.
- Use **docstrings** for documenting methods and classes.
- Avoid long functions — aim for modular code with clear, single-responsibility functions.
- Apply **DRY (Don't Repeat Yourself)** and **KISS (Keep It Simple, Stupid)** principles.

### Useful Installation Tips:
- Always run `pip install -r requirements.txt` in a virtual environment to prevent conflicts with global packages.
- Ensure you are using **Python 3.8+** for compatibility.
- If working in a team, use **pre-commit hooks** for linting and formatting checks.
- If needed, extend the `requirements.txt` file with development dependencies like **black** for formatting or **pytest** for testing.

## API:

### Get Banlist:
```http
Method: POST
Request Body: JSON
Example JSON: {"server": 0, "count": 0}
Response Data: JSON list with banlist strings (the first string in the list starts with a `\n` symbol)
Endpoint: /banlist/get
```

### LongPoll for new banlist entry:
```http
Method: POST
Request Body: JSON
Example JSON: {"server": 0, "ban": "The last banlist entry you have"}
Response Data: JSON with the new banlist entry or `[false]`
Endpoint: /banlist/longpoll
```

### Web Version of Banlist:
```http
Method: GET
Response Data: HTML page
Endpoint: /banlist/web/{server}/{number_of_entries}
```

## Lua:

### Installation:
Copy the script from the `Lua` directory to your game folder. 

Change the values of `serverip` and `serverport` to match the values you used when starting the server.

### Lua Code Style:
- Stick to **consistent indentation** and avoid deeply nested loops.
- Comment complex sections, especially where you're interacting with APIs or network operations.
- Use local variables as much as possible to avoid global pollution.
