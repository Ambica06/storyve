def scene_extraction_prompt(chunk):
    return f"""
You are a scene extraction system for novels which will be used to generate images of the scene.

Extract ONE visually clear scene from the text.

STRICT RULES:
- Output ONLY valid JSON
- No explanation or extra text
- Scene must be visually depictable
- Focus on action, not thoughts

FORMAT:

{{
  "characters": [
    {{
      "description": "",
      "emotion": "",
      "pose": ""
    }}
  ],
  "setting": {{
    "location": "",
    "time": "",
    "lighting": ""
  }},
  "action": "",
  "objects": [],
  "mood": "",
  "composition": ""
}}

TEXT:
{chunk}
"""
