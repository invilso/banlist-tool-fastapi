# Вибір базового іміджу
FROM python:3.10-slim

# Встановлення робочої директорії
WORKDIR /app

# Встановлюємо необхідні системні бібліотеки
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libffi-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Копіюємо файли проєкту в контейнер
COPY . .

# Встановлення залежностей
RUN pip install --no-cache-dir -r requirements.txt

# Команда для запуску FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
