from pydantic import BaseModel


class BanlistLongPolling(BaseModel):
    server: int
    ban: str

class BanlistGetRaw(BaseModel):
    server: int
    count: int

