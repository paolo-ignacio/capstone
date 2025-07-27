from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class ChatMessage(BaseModel):
    user_id: str
    message: str
    timestamp: datetime
    message_type: str  # 'user' or 'assistant'
    conversation_id: str
    context_sources: Optional[List[dict]] = None