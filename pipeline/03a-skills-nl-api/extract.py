import json
from google.cloud import language_v1

client = language_v1.LanguageServiceClient()
rows = json.load(open("sample.json"))

with open("entities.jsonl", "w") as out:
    for i, r in enumerate(rows, 1):
        doc = language_v1.Document(
            content=r["description"],
            type_=language_v1.Document.Type.PLAIN_TEXT)
        resp = client.analyze_entities(request={"document": doc})
        for e in resp.entities:
            out.write(json.dumps({
                "job_id": int(r["job_id"]),
                "title": r["title"],
                "entity": e.name,
                "entity_type": language_v1.Entity.Type(e.type_).name,
                "salience": round(e.salience, 4)
            }) + "\n")
        print(f"{i}/{len(rows)} done: {r['title'][:50]}")
