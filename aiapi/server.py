import os

import falcon
import sentence_transformers

apikey = os.getenv('API_KEY')
if not apikey:
    raise Exception('API_KEY environment variable must be set')

loaded_models = {}

def fail(resp, status, message):
    resp.status = status
    resp.media = {'error': message}

class HealthResource:
    def on_get(self, _req, resp):
        resp.status = falcon.HTTP_200
        resp.media = {"o": "k"}

class EmbeddingsResource:
    def on_post(self, req, resp):
        if req.headers.get('API-KEY') != apikey:
            return fail(resp, falcon.HTTP_401, "Invalid Api-Key header")
        data = req.media
        txt = data.get('text')
        if txt is None:
            return fail(resp, falcon.HTTP_400, 'text parameter is required')
        model_name = data.get('model_name')
        if txt is None or model_name is None:
            return fail(resp, falcon.HTTP_400, 'model_name parameter is required')
        if model_name not in loaded_models:
            loaded_models[model_name] = sentence_transformers.SentenceTransformer(model_name, device="cpu")
        model = loaded_models[model_name]
        emb = model.encode(txt).tolist()
        resp.status = falcon.HTTP_200
        resp.media = {'embedding': emb}


app = falcon.App()
app.add_route('/embedding', EmbeddingsResource())
app.add_route('/healthz', HealthResource())
