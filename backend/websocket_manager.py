from fastapi import WebSocket
from typing import Dict, List

class ConnectionManager:
    def __init__(self):
        self.rooms: Dict[str, List[WebSocket]] = {}

    async def connect(self, room_id: str, websocket: WebSocket):
        await websocket.accept()
        if room_id not in self.rooms:
            self.rooms[room_id] = []
        self.rooms[room_id].append(websocket)

    def disconnect(self, room_id: str, websocket: WebSocket):
        self.rooms[room_id].remove(websocket)

    async def broadcast(self, room_id: str, message: str):
        for connection in self.rooms.get(room_id, []):
            await connection.send_text(message)

manager = ConnectionManager()