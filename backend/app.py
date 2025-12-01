import io
import os
import json
import random
from typing import List, Optional

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import Response
from PIL import Image, ImageDraw
from google import genai
from google.genai import types

app = FastAPI(title="Pet Battler Backend")

import json

@app.post("/generate/creature")
async def generate_creature(
    description: str = Form(...),
    photo: UploadFile = File(...),
):
    """
    Full pipeline:
    1. Analyze photo + description with Gemini (Text/Multimodal) -> Get Stats + Visual JSON Spec + Safety Check.
    2. If safe, use the Visual JSON Spec to prompt Nano Banana (Imagen) -> Get Sprite Sheet.
    3. Return Stats + Image.
    """
    print(f"Received creature generation request.")
    
    api_key = os.environ.get("GOOGLE_CLOUD_API_KEY")
    if not api_key:
        return Response(content=json.dumps({"error": "GOOGLE_CLOUD_API_KEY not set"}).encode(), status_code=500, media_type="application/json")
    
    if not api_key.startswith("AQ."):
        print(f"WARNING: API Key '{api_key[:5]}...' does not start with 'AQ.'. This may be an invalid key.")
        return Response(content=json.dumps({"error": "Invalid API Key format. Key must start with 'AQ.'. Get one!"}).encode(), status_code=401, media_type="application/json")

    try:
        client = genai.Client(
            vertexai=True,
            api_key=api_key,
        )
        
        # Read photo bytes
        photo_bytes = await photo.read()
        
        mime_type = photo.content_type
        if not mime_type or mime_type == "application/octet-stream":
            mime_type = "image/jpeg"

        # --- Step 1: Analysis & Spec Generation ---
        # We ask Gemini to analyze the image and return a strict JSON structure.
        
        analysis_prompt = f"""You are a retro game designer specializing in 16-bit pixel art creatures. Analyze this image and the user description: "{description}".

**TASK 1 - SAFETY CHECK:**
Is this a photo of a human/person? If yes, set "isHuman" to true.

**TASK 2 - CREATURE STATS:**
Generate creative fantasy creature stats inspired by the subject. The creature should feel like a Pokemon or fantasy RPG monster with:
- A creative Name (inspired by the subject + elemental/attribute fusion)
- 1-2 Types (e.g., Fire, Water, Electric, Grass, Psychic, Dragon, Dark, Fairy, Normal, etc.)
- Flavor text describing the creature's behavior or habitat
- Balanced stats: HP (30-100), Attack (20-80), Defense (20-80), Speed (20-80)

**TASK 3 - VISUAL SPECIFICATION FOR PIXEL ART:**
Create a DETAILED specification for generating a 4-frame pixel art sprite sheet (128x32 px total):

• **Subject**: Describe the creature as a pixel art sprite (e.g., "A small fire salamander with flame tail")
• **Palette**: Provide 4-6 specific colors in hex format or color names suited for 16-bit pixel art
  - Include outline/border color (usually black or dark)
  - Main body colors (2-3 colors)
  - Accent/detail colors (1-2 colors)
  - NO pure white (#FFFFFF) in the creature palette
  
• **Animation**: Describe EACH of the 4 frames specifically for an idle looping animation:
  - Frame 1: [starting pose, e.g., "body centered, wings up"]
  - Frame 2: [intermediate movement, e.g., "body slightly down, wings at middle"]
  - Frame 3: [peak movement, e.g., "body lowest, wings fully down"]
  - Frame 4: [return movement, e.g., "body rising, wings starting to go up - loops back to frame 1"]
  
• **Details**: Key visual features (eyes, limbs, special effects like flames/sparkles, proportions)
  - Describe the creature's silhouette and key identifying features
  - Mention any special effects (fire, electricity, aura, etc.)
  - Note size relative to the 32x32 frame (small, medium, fills frame)

Return ONLY valid JSON matching this schema:
{{
  "isHuman": boolean,
  "stats": {{
    "name": "string",
    "types": ["string", "string"],
    "flavorText": "string",
    "hp": int, "attack": int, "defense": int, "speed": int
  }},
  "visualSpec": {{
    "subject": "detailed pixel art creature description",
    "palette": ["#hexcolor1", "#hexcolor2", "color name", ...],
    "animation": "Frame 1: [pose]. Frame 2: [pose]. Frame 3: [pose]. Frame 4: [pose].",
    "details": "key visual features, proportions, special effects"
  }}
}}"""
        
        # Call Gemini 2.5 Flash Lite (Multimodal)
        analysis_response = client.models.generate_content(
            model='gemini-2.5-flash-lite',
            contents=[
                types.Content(
                    role="user",
                    parts=[
                        types.Part.from_text(text=analysis_prompt),
                        types.Part.from_bytes(data=photo_bytes, mime_type=mime_type),
                    ]
                )
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json"
            )
        )
        
        if not analysis_response.text:
            return Response(content=json.dumps({"error": "Failed to analyze image"}).encode(), status_code=500, media_type="application/json")
            
        data = json.loads(analysis_response.text)
        
        if data.get("isHuman", False):
            json.dumps(data)
            return Response(content=json.dumps({"error": "Human detected! Only pets are allowed."}).encode(), status_code=400, media_type="application/json")

        # --- Step 2: Image Generation with Gemini 2.5 Flash Image ---
        visual_spec = data.get("visualSpec", {})
        image_prompt = f"""Create a pixel art sprite sheet for a fantasy creature with PRECISE specifications:

🎯 CRITICAL REQUIREMENTS:
• Canvas: EXACTLY 128 pixels wide × 32 pixels tall
• Layout: 4 animation frames side-by-side, each frame is 32×32 pixels
• Frame positions: Frame 1 (x:0-31), Frame 2 (x:32-63), Frame 3 (x:64-95), Frame 4 (x:96-127)
• Background: Pure white (#FFFFFF) - this will be made transparent

🎨 CREATURE SPECIFICATION:
• Subject: {visual_spec.get('subject')}
• Style: Classic 16-bit JRPG pixel art (like Pokemon Gen 2-3)
• Details: {visual_spec.get('details')}
• Color Palette: {', '.join(visual_spec.get('palette', []))} (avoid pure white #FFFFFF in the creature itself)

🎬 ANIMATION SEQUENCE ({visual_spec.get('animation', 'idle loop')}):
Each frame must show a CLEAR, DISTINCT pose that creates a smooth looping animation:
• Frame 1: Starting pose
• Frame 2: Intermediate movement
• Frame 3: Peak of movement
• Frame 4: Return movement (should flow back to Frame 1)

💎 PIXEL ART RULES:
• NO anti-aliasing or blur effects
• NO gradients (use dithering patterns if needed)
• Sharp, crisp edges on every pixel
• Limited color palette with clear outlines (black or dark borders)
• Each frame must be clearly separated and properly aligned
• The creature should be centered in each 32×32 frame
• Maintain consistent size and position across all frames
• Use dithering for shading, not smooth gradients

⚠️ CRITICAL: The creature itself must NOT use pure white pixels - use off-white or light grays. Only the background should be pure white (#FFFFFF)."""
        
        print(f"Generating image with Gemini 2.5 Flash Image")

        image_response = client.models.generate_content(
            model='gemini-3-pro-image-preview',
            contents=[
                types.Content(
                    role="user",
                    parts=[types.Part.from_text(text=image_prompt)]
                )
            ],
            config=types.GenerateContentConfig(
                temperature=1,
                top_p=0.95,
                response_modalities=["IMAGE"],
                safety_settings = [types.SafetySetting(
                    category="HARM_CATEGORY_HATE_SPEECH",
                    threshold="OFF"
                ),types.SafetySetting(
                    category="HARM_CATEGORY_DANGEROUS_CONTENT",
                    threshold="OFF"
                ),types.SafetySetting(
                    category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    threshold="OFF"
                ),types.SafetySetting(
                    category="HARM_CATEGORY_HARASSMENT",
                    threshold="OFF"
                )],
                image_config=types.ImageConfig(
                    aspect_ratio="21:9",
                    image_size="1K",
                    output_mime_type="image/png",
                ),  
            )
        )

        # Extract image from response
        final_img_bytes = None
        if image_response.candidates:
            for part in image_response.candidates[0].content.parts:
                if hasattr(part, 'inline_data') and part.inline_data:
                    final_img_bytes = part.inline_data.data
                    break
        
        if not final_img_bytes:
            return Response(content=json.dumps({"error": "No image generated"}).encode(), status_code=500, media_type="application/json")
        
        # Convert white background to transparent and resize to 128x32
        with Image.open(io.BytesIO(final_img_bytes)) as img:
            # Convert to RGBA if not already
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            # Get pixel data
            pixels = img.load()
            width, height = img.size
            
            # Replace white/near-white pixels with transparent
            # Threshold: if R, G, B are all > 240, make it transparent
            for y in range(height):
                for x in range(width):
                    r, g, b, a = pixels[x, y]
                    if r > 240 and g > 240 and b > 240:
                        pixels[x, y] = (r, g, b, 0)  # Set alpha to 0 (transparent)
            
            # Resize to ensure 128x32
            img = img.resize((128, 32), Image.Resampling.NEAREST)
            buf = io.BytesIO()
            img.save(buf, format='PNG')
            final_img_bytes = buf.getvalue()
        
        # Return combined result
        import base64
        img_b64 = base64.b64encode(final_img_bytes).decode('utf-8')
        
        return {
            "stats": data["stats"],
            "image": img_b64
        }

    except Exception as e:
        print(f"Error in generation pipeline: {e}")
        return Response(content=json.dumps({"error": str(e)}).encode(), status_code=500, media_type="application/json")

@app.get("/health")
def health_check():
    return {"status": "ok"}
