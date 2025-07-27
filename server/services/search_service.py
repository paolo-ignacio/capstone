from config import Settings
from pinecone import Pinecone
from sentence_transformers import SentenceTransformer

settings = Settings()

class SearchService:
    def __init__(self):
        # Initialize Pinecone client
        self.pc = Pinecone(api_key=settings.PINECONE_API_KEY)
        self.index = self.pc.Index(settings.PINECONE_INDEX_NAME)
        # Initialize the sentence transformer model
        self.model = SentenceTransformer('multi-qa-MiniLM-L6-dot-v1')

    def vector_search(self, query: str):
        try:
            # Generate embedding for the query
            query_embedding = self.model.encode(query).tolist()

            # Search Pinecone with the query embedding
            search_response = self.index.query(
                vector=query_embedding,
                top_k=5,  # Adjust number of results as needed
                include_metadata=True
            )

            # Format results
            results = []
            for match in search_response['matches']:
                results.append({
                    'score': match['score'],
                    'metadata': match['metadata']
                })

            return results

        except Exception as e:
            print(f"Search error: {e}")
            return []
        
# from config import Settings
# from pinecone import Pinecone
# from sentence_transformers import SentenceTransformer
# import uuid
# from datetime import datetime

# settings = Settings()

# class SearchService:
#     def __init__(self):
#         self.pc = Pinecone(api_key=settings.PINECONE_API_KEY)
#         self.index = self.pc.Index(settings.PINECONE_INDEX_NAME)
#         self.model = SentenceTransformer('multi-qa-MiniLM-L6-dot-v1')
        
#     def vector_search(self, query: str):
#         try:
#             query_embedding = self.model.encode(query).tolist()
#             search_response = self.index.query(
#                 vector=query_embedding,
#                 top_k=5,
#                 include_metadata=True
#             )
#             return search_response['matches']
#         except Exception as e:
#             print(f"Search error: {e}")
#             return []

#     def store_chat_message(self, message: dict):
#         try:
#             # Generate embedding for the message
#             message_embedding = self.model.encode(message['message']).tolist()
            
#             # Create a unique ID for the message
#             message_id = str(uuid.uuid4())
            
#             # Store the message with its metadata in Pinecone
#             self.index.upsert(vectors=[{
#                 'id': f"chat_{message_id}",
#                 'values': message_embedding,
#                 'metadata': {
#                     'user_id': message['user_id'],
#                     'message': message['message'],
#                     'timestamp': message['timestamp'].isoformat(),
#                     'message_type': message['message_type'],
#                     'conversation_id': message['conversation_id'],
#                     'context_sources': message.get('context_sources', [])
#                 }
#             }])
            
#             return message_id
#         except Exception as e:
#             print(f"Error storing chat message: {e}")
#             return None

#     def get_conversation_history(self, conversation_id: str, limit: int = 10):
#         try:
#             # Query Pinecone for messages from this conversation
#             query_response = self.index.query(
#                 vector=[0] * self.model.get_sentence_embedding_dimension(),  # dummy vector
#                 top_k=limit,
#                 include_metadata=True,
#                 filter={
#                     'conversation_id': {'$eq': conversation_id}
#                 }
#             )
            
#             # Sort messages by timestamp
#             messages = [
#                 {
#                     'message': match['metadata']['message'],
#                     'user_id': match['metadata']['user_id'],
#                     'timestamp': datetime.fromisoformat(match['metadata']['timestamp']),
#                     'message_type': match['metadata']['message_type'],
#                     'context_sources': match['metadata'].get('context_sources', [])
#                 }
#                 for match in query_response['matches']
#             ]
            
#             return sorted(messages, key=lambda x: x['timestamp'])
#         except Exception as e:
#             print(f"Error retrieving conversation history: {e}")
#             return []