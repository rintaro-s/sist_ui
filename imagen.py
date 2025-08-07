import requests
import base64
import os
import json
from PIL import Image
from io import BytesIO

# --- Configuration ---
API_URL = "http://127.0.0.1:7860"
OUTPUT_DIR = "theme_assets"

# --- Aesthetic Definition (Worldview) ---
# This style prompt will be added to every image to ensure a consistent look and feel.
STYLE_PROMPT = (
    "masterpiece, best quality, UI design, game UI, "
    "dark academia aesthetic, gothic chic, elegant, ornate, intricate details, "
    "atmospheric lighting, muted colors, design-tic, emotional, "
    "dark polished wood, wrought iron filigree, gold and silver inlay, aged paper."
)

# This negative prompt will be used to avoid common issues in UI element generation.
NEGATIVE_PROMPT = (
    "(worst quality, low quality, normal quality:1.4), ugly, blurry, "
    "text, signature, watermark, username, artist name, jpeg artifacts, noisy, "
    "3d render, photorealistic, photo, realistic, human, face, body."
)

# --- Asset Generation Plan ---
# A list of all assets to be generated, with their specific prompts and dimensions.
ASSETS_TO_GENERATE = [
    # # --- Desktop ---
    # {
    #     "path": "desktop",
    #     "filename": "wallpaper.png",
    #     "width": 1280,  # 2560 -> 1280
    #     "height": 720,  # 1440 -> 720
    #     "prompt": "beautiful and mysterious landscape at twilight, glowing flowers, ancient ruins, painterly style, matte painting, epic, cinematic, atmospheric perspective.",
    # },
    # {
    #     "path": "desktop",
    #     "filename": "taskbar_background.png",
    #     "width": 1280,  # 2560 -> 1280
    #     "height": 35,   # 70 -> 35
    #     "prompt": "ornate horizontal border, seamless, tileable, intricate gold filigree on dark wood texture, clean lines.",
    # },
    # --- Window Decorations ---
    # {
    #     "path": "window",
    #     "filename": "window_titlebar_background.png",
    #     "width": 512,   # 1024 -> 512
    #     "height": 20,   # 40 -> 20
    #     "prompt": "ornate horizontal banner, seamless, tileable, aged parchment texture with subtle gothic patterns.",
    # },
    {
        "path": "window", "filename": "window_close_normal.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate X symbol), glowing ruby red gem, centered, flat background.",
    },
    {
        "path": "window", "filename": "window_close_hover.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate X symbol), brightly glowing ruby red gem, centered, flat background, high contrast.",
    },
    {
        "path": "window", "filename": "window_close_pressed.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate X symbol), deep red gem with inner light, centered, flat background, inset shadow.",
    },
    {
        "path": "window", "filename": "window_maximize_normal.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate square symbol), glowing emerald green gem, centered, flat background.",
    },
    {
        "path": "window", "filename": "window_maximize_hover.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate square symbol), brightly glowing emerald green gem, centered, flat background, high contrast.",
    },
    {
        "path": "window", "filename": "window_maximize_pressed.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate square symbol), deep green gem with inner light, centered, flat background, inset shadow.",
    },
    {
        "path": "window", "filename": "window_minimize_normal.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate underscore symbol), glowing amber gem, centered, flat background.",
    },
    {
        "path": "window", "filename": "window_minimize_hover.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate underscore symbol), brightly glowing amber gem, centered, flat background, high contrast.",
    },
    {
        "path": "window", "filename": "window_minimize_pressed.png", "width": 32, "height": 32,
        "prompt": "UI button, (ornate underscore symbol), deep amber gem with inner light, centered, flat background, inset shadow.",
    },
    # --- Icons ---
    {
        "path": "icons", "filename": "icon_app_default.png", "width": 128, "height": 128,
        "prompt": "UI icon, a beautiful ornate silver gear, centered, simple background, clean lines.",
    },
    {
        "path": "icons", "filename": "icon_folder.png", "width": 128, "height": 128,
        "prompt": "UI icon, an ornate leather-bound folder with a gold clasp, centered, simple background.",
    },
    {
        "path": "icons", "filename": "icon_file_document.png", "width": 128, "height": 128,
        "prompt": "UI icon, a piece of aged parchment with a single elegant quill pen, centered, simple background.",
    },
    {
        "path": "icons", "filename": "icon_terminal.png", "width": 128, "height": 128,
        "prompt": "UI icon, a stylized command prompt symbol >_ made of glowing green magical runes, centered, simple background.",
    },
    {
        "path": "icons", "filename": "icon_settings.png", "width": 128, "height": 128,
        "prompt": "UI icon, interlocking ornate silver and gold gears, intricate, centered, simple background.",
    },
    # --- Cursors ---
    {
        "path": "cursors", "filename": "cursor_default.png", "width": 32, "height": 32,
        "prompt": "UI cursor, ornate elegant mouse pointer arrow, silver filigree, sharp tip, centered, simple background, high contrast.",
    },
    {
        "path": "cursors", "filename": "cursor_hand.png", "width": 32, "height": 32,
        "prompt": "UI cursor, elegant pointing hand, gauntlet with filigree, centered, simple background, high contrast.",
    },
    {
        "path": "cursors", "filename": "cursor_text.png", "width": 32, "height": 32,
        "prompt": "UI cursor, ornate I-beam symbol, glowing silver, centered, simple background, high contrast.",
    },
    {
        "path": "cursors", "filename": "cursor_resize.png", "width": 32, "height": 32,
        "prompt": "UI cursor, ornate double-headed arrow, centered, simple background, high contrast.",
    },
    {
        "path": "cursors", "filename": "cursor_busy.png", "width": 32, "height": 32,
        "prompt": "UI cursor, ornate spinning hourglass with glowing sand, centered, simple background, high contrast.",
    },
]

def show_images_and_select(images, asset_info):
    """Display images and let the user select one."""
    temp_files = []
    print(f"  表示: {asset_info['filename']} の候補を開きます...")
    for idx, img_b64 in enumerate(images):
        img_data = base64.b64decode(img_b64)
        temp_path = f"temp_{asset_info['filename']}_{idx}.png"
        with open(temp_path, "wb") as f:
            f.write(img_data)
        temp_files.append(temp_path)
        # Open image with default viewer (cross-platform)
        try:
            # PIL.Image.show() is often ignored or opens in background, so use OS open
            if os.name == 'nt':
                os.startfile(temp_path)
            elif os.name == 'posix':
                if 'DISPLAY' in os.environ:
                    os.system(f'xdg-open "{temp_path}"')
                else:
                    print(f"  画像ファイル: {temp_path}")
            else:
                print(f"  画像ファイル: {temp_path}")
        except Exception as e:
            print(f"  画像表示エラー: {e}")
            print(f"  画像ファイル: {temp_path}")

    print("  各画像が外部ビューアで開かれているはずです。")
    print("  もし画像が表示されない場合は、下記のファイルを手動で開いてください:")
    for i, path in enumerate(temp_files):
        print(f"    [{i+1}] {path}")

    # ユーザーに選択させる
    while True:
        try:
            sel = int(input(f"  どの画像を採用しますか？ (1-{len(images)}): "))
            if 1 <= sel <= len(images):
                break
        except Exception:
            pass
        print("  無効な入力です。")
    selected = sel - 1

    # 採用画像を返す
    selected_data = base64.b64decode(images[selected])
    # 一時ファイル削除
    for i, path in enumerate(temp_files):
        if i != selected and os.path.exists(path):
            try:
                os.remove(path)
            except Exception:
                pass
    return selected_data

def generate_image(asset_info):
    """Generates a single image using the Stable Diffusion API (batch size 4, GPU)."""

    # --- プロンプトの強化と明示的な指示 ---
    full_prompt = (
        f"{asset_info['prompt']}, "
        "no text, no watermark, no signature, "
        "no logo, no UI chrome, "
        "highly detailed, sharp focus, "
        "centered, clean, flat, "
        "2d illustration, concept art, "
        "no human, no face, no animal, "
        f"{STYLE_PROMPT}"
    )

    payload = {
        "prompt": full_prompt,
        "negative_prompt": (
            NEGATIVE_PROMPT +
            ", border, frame, logo, icon, emoji, cartoon, comic, manga, "
            "distorted, cropped, cut-off, out of frame, "
            "nsfw, nude, naked, "
            "text, watermark, signature, artist name, "
            "bad anatomy, bad proportions, "
            "extra limbs, missing limbs, "
            "deformed, mutated, "
            "blurry, lowres, jpeg artifacts"
        ),
        "sampler_name": "DPM++ 2M",
        "steps": 20,
        "cfg_scale": 7,
        "width": asset_info["width"],
        "height": asset_info["height"],
        "batch_size": 4,
        "enable_hr": False,
        "override_settings": {
            "sd_model_checkpoint": "animagineXLV31_v31.safetensors [e3c47aedb0]",
            "CLIP_stop_at_last_layers": 2,  # CLIPの層を浅くして意味不明な画像を減らす
        },
        "override_settings_restore_afterwards": True,
        "seed": -1,  # 毎回ランダム
        "restore_faces": False,
        "tiling": False,
    }

    print(f"Requesting: {asset_info['filename']} ({asset_info['width']}x{asset_info['height']}) [batch=4, model=animagineXLV31_v31.safetensors, sampler=DPM++ 2M, steps=20]")

    try:
        response = requests.post(url=f'{API_URL}/sdapi/v1/txt2img', json=payload, timeout=600)
        response.raise_for_status()
        r = response.json()
    except requests.exceptions.RequestException as e:
        print(f"  \033[91mError: API request failed for {asset_info['filename']}. Is the server running with --api?\033[0m")
        print(f"   Details: {e}")
        return

    if 'images' not in r or not r['images']:
        print(f"  \033[91mError: No image data received for {asset_info['filename']}.\033[0m")
        print(f"   API Response: {r}")
        return

    # --- Show images and let user select ---
    selected_image_data = show_images_and_select(r['images'], asset_info)

    # --- Save the selected image ---
    output_path = os.path.join(OUTPUT_DIR, asset_info["path"])
    os.makedirs(output_path, exist_ok=True)
    file_path = os.path.join(output_path, asset_info["filename"])
    with open(file_path, 'wb') as f:
        f.write(selected_image_data)
    print(f"  \033[92mSuccess! Saved to {file_path}\033[0m")


if __name__ == "__main__":
    print("--- Starting UI Asset Generation ---")
    
    # Check if the base directory exists
    if not os.path.exists(OUTPUT_DIR):
        print(f"Error: Base directory '{OUTPUT_DIR}' does not exist. Please create it first.")
        exit()

    for asset in ASSETS_TO_GENERATE:
        generate_image(asset)
        
    print("--- Asset Generation Complete ---")

