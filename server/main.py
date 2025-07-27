import asyncio
from fastapi import FastAPI, WebSocket, Depends
from pydantic_models.chat_body import ChatBody
from services.search_service import SearchService
from services.llm_service import LLMService
from datetime import datetime
import uuid

app = FastAPI()

# Initialize services
search_service = SearchService()
llm_service = LLMService()

# Store active WebSocket connections
active_connections = {}

@app.websocket("/ws/chat")
async def websocket_chat_endpoint(websocket: WebSocket):
    await websocket.accept()
    
    # Generate a conversation ID if not provided
    conversation_id = str(uuid.uuid4())
    user_id = None

    try:
        # Send conversation ID to client
        await websocket.send_json({
            "type": "conversation_id",
            "data": conversation_id
        })

        while True:
            data = await websocket.receive_json()
            query = data.get("query")
            user_id = data.get("user_id", "anonymous")
            
            # Store user message
            user_message = {
                'user_id': user_id,
                'message': query,
                'timestamp': datetime.utcnow(),
                'message_type': 'user',
                'conversation_id': conversation_id
            }
            search_service.store_chat_message(user_message)

            # Get vector search results
            search_results = search_service.vector_search(query)

            # Get conversation history
            history = search_service.get_conversation_history(conversation_id)
            
            # Send search results
            await websocket.send_json({
                "type": "search_result",
                "data": [
                    {
                        "title": result["metadata"].get("title", ""),
                        "url": result["metadata"].get("firebase_url", ""),
                        "content": result["metadata"].get("text", ""),
                        "relevance_score": result["score"]
                    }
                    for result in search_results
                ]
            })

            # Generate and stream response
            for chunk in llm_service.generate_response(query, search_results, history):
                await asyncio.sleep(0.1)
                await websocket.send_json({
                    "type": "content",
                    "data": chunk
                })

            # Store assistant's response
            assistant_message = {
                'user_id': 'assistant',
                'message': chunk,  # Store the last chunk as the complete response
                'timestamp': datetime.utcnow(),
                'message_type': 'assistant',
                'conversation_id': conversation_id,
                'context_sources': search_results
            }
            search_service.store_chat_message(assistant_message)

    except Exception as e:
        print(f"Unexpected error occurred: {e}")
    finally:
        if conversation_id in active_connections:
            del active_connections[conversation_id]
        await websocket.close()

@app.post("/chat")
def chat_endpoint(body: ChatBody):
    conversation_id = str(uuid.uuid4())
    search_results = search_service.vector_search(body.query)
    history = search_service.get_conversation_history(conversation_id)
    response = llm_service.generate_response(body.query, search_results, history)
    return response


# import asyncio
# from fastapi import FastAPI, WebSocket, Depends
# from pydantic_models.chat_body import ChatBody
# from services.search_service import SearchService
# from services.llm_service import LLMService
# from datetime import datetime
# import uuid

# app = FastAPI()

# # Initialize services
# search_service = SearchService()
# llm_service = LLMService()

# # Store active WebSocket connections
# active_connections = {}

# @app.websocket("/ws/chat")
# async def websocket_chat_endpoint(websocket: WebSocket):
#     await websocket.accept()
    
#     # Generate a conversation ID if not provided
#     conversation_id = str(uuid.uuid4())
#     user_id = None

#     try:
#         # Send conversation ID to client
#         await websocket.send_json({
#             "type": "conversation_id",
#             "data": conversation_id
#         })

#         while True:
#             data = await websocket.receive_json()
#             query = data.get("query")
#             user_id = data.get("user_id", "anonymous")
            
#             # Store user message
#             user_message = {
#                 'user_id': user_id,
#                 'message': query,
#                 'timestamp': datetime.utcnow(),
#                 'message_type': 'user',
#                 'conversation_id': conversation_id
#             }
#             search_service.store_chat_message(user_message)

#             # Get vector search results
#             search_results = search_service.vector_search(query)

#             # Get conversation history
#             history = search_service.get_conversation_history(conversation_id)
            
#             # Send search results
#             await websocket.send_json({
#                 "type": "search_result",
#                 "data": [
#                     {
#                         "title": result["metadata"].get("title", ""),
#                         "url": result["metadata"].get("firebase_url", ""),
#                         "content": result["metadata"].get("text", ""),
#                         "relevance_score": result["score"]
#                     }
#                     for result in search_results
#                 ]
#             })

#             # Generate and stream response
#             for chunk in llm_service.generate_response(query, search_results, history):
#                 await asyncio.sleep(0.1)
#                 await websocket.send_json({
#                     "type": "content",
#                     "data": chunk
#                 })

#             # Store assistant's response
#             assistant_message = {
#                 'user_id': 'assistant',
#                 'message': chunk,  # Store the last chunk as the complete response
#                 'timestamp': datetime.utcnow(),
#                 'message_type': 'assistant',
#                 'conversation_id': conversation_id,
#                 'context_sources': search_results
#             }
#             search_service.store_chat_message(assistant_message)

#     except Exception as e:
#         print(f"Unexpected error occurred: {e}")
#     finally:
#         if conversation_id in active_connections:
#             del active_connections[conversation_id]
#         await websocket.close()

# @app.post("/chat")
# def chat_endpoint(body: ChatBody):
#     conversation_id = str(uuid.uuid4())
#     search_results = search_service.vector_search(body.query)
#     history = search_service.get_conversation_history(conversation_id)
#     response = llm_service.generate_response(body.query, search_results, history)
#     return response