from typing import List
from sentence_transformers import SentenceTransformer
import numpy as np

class SortSourceService:
    def __init__(self):
        self.embedding_model = SentenceTransformer("all-MiniLM-L6-v2")

    def sort_sources(self, query: str, search_results: List[dict]) -> List[dict]:
        try:
            # Encode the query once
            query_embedding = self.embedding_model.encode(query)

            # Filter out entries with missing/short content
            filtered_results = [
                res for res in search_results
                if res.get("content") and len(res["content"].strip()) > 100
            ]

            if not filtered_results:
                print("No valid content found in search results.")
                return []

            contents = [res["content"] for res in filtered_results]

            # Batch encode contents
            content_embeddings = self.embedding_model.encode(
                contents, batch_size=8, convert_to_numpy=True
            )

            query_norm = np.linalg.norm(query_embedding)
            content_norms = np.linalg.norm(content_embeddings, axis=1)

            # Prevent division by zero
            content_norms = np.where(content_norms == 0, 1e-10, content_norms)

            similarities = np.dot(content_embeddings, query_embedding) / (content_norms * query_norm)

            # Attach scores and filter
            relevant_docs = []
            for res, score in zip(filtered_results, similarities):
                res["relevance_score"] = float(score)
                if score > 0.5:
                    relevant_docs.append(res)

            # Return sorted by score
            return sorted(relevant_docs, key=lambda x: x["relevance_score"], reverse=True)

        except Exception as e:
            print("Sort error:", e)
            return []
