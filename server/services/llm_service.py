from typing import List
import google.generativeai as genai
from config import Settings

settings = Settings()

class LLMService:
    def __init__(self):
        genai.configure(api_key=settings.GEMINI_API_KEY)
        self.model = genai.GenerativeModel("learnlm-2.0-flash-experimental")

    def generate_response(self, query: str, search_results: List[dict]):
        context_text = "\n\n".join([
            f"Source {i+1} from {result['metadata']['original_filename']}:\n{result['metadata']['text']}"
            for i, result in enumerate(search_results)
        ])

        full_prompt = f"""
        Context from document search:
        {context_text}

        Query: {query}

        Can you create a contract agreement.
        
        """

        response = self.model.generate_content(full_prompt, stream=True)

        for chunk in response:
            yield chunk.text


# from typing import List
# import google.generativeai as genai
# from config import Settings

# settings = Settings()

# class LLMService:
#     def __init__(self):
#         genai.configure(api_key=settings.GEMINI_API_KEY)
#         self.model = genai.GenerativeModel("learnlm-2.0-flash-experimental")

#     def generate_response(self, query: str, search_results: List[dict], history: List[dict] = None):
#         # Format conversation history
#         history_text = ""
#         if history:
#             history_text = "\n".join([
#                 f"{'User' if msg['message_type'] == 'user' else 'Assistant'}: {msg['message']}"
#                 for msg in history[-5:]  # Include last 5 messages
#             ])

#         # Format search results
#         context_text = "\n\n".join([
#             f"Source {i+1} from {result['metadata']['original_filename']}:\n{result['metadata']['text']}"
#             for i, result in enumerate(search_results)
#         ])

#         full_prompt = f"""
#         Previous conversation:
#         {history_text}

#         Context from document search:
#         {context_text}

#         Query: {query}

#         Can you create a contract agreement based on the context and previous conversation.
        
#         """

#         response = self.model.generate_content(full_prompt, stream=True)

#         for chunk in response:
#             yield chunk.text