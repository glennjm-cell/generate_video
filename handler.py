import runpod
import os
import websocket
import base64
import json
import uuid
import logging
import urllib.request
import subprocess
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

SERVER = os.getenv("SERVER_ADDRESS", "127.0.0.1")
CLIENT_ID = str(uuid.uuid4())


def to_16(x):
    return max(16, int(round(x / 16) * 16))


def download(url, out):
    subprocess.run(["wget", "-O", out, url], check=True)
    return out


def load_workflow(path):
    with open(path, "r") as f:
        return json.load(f)


def queue(prompt):
    req = json.dumps({"prompt": prompt, "client_id": CLIENT_ID}).encode()
    return json.loads(
        urllib.request.urlopen(
            urllib.request.Request(f"http://{SERVER}:8188/prompt", req)
        ).read()
    )


def history(pid):
    return json.loads(
        urllib.request.urlopen(f"http://{SERVER}:8188/history/{pid}").read()
    )


def handler(job):
    data = job["input"]

    img = data.get("image_url")
    if not img:
        raise Exception("image_url required")

    os.makedirs("/tmp", exist_ok=True)
    img_path = "/tmp/input.png"
    download(img, img_path)

    prompt = load_workflow("workflow.json")

    # Basic params
    w = to_16(data.get("width", 480))
    h = to_16(data.get("height", 832))
    length = data.get("length", 81)

    prompt["244"]["inputs"]["image"] = img_path
    prompt["235"]["inputs"]["value"] = w
    prompt["236"]["inputs"]["value"] = h
    prompt["541"]["inputs"]["num_frames"] = length

    prompt["135"]["inputs"]["positive_prompt"] = data.get("prompt", "")
    prompt["135"]["inputs"]["negative_prompt"] = data.get(
        "negative_prompt",
        "low quality, jpeg artifacts, deformed"
    )

    # --- LoRA injection (THIS IS THE FIX) ---
    lora = data.get("lora_pairs", [])

    high = "high_noise_model.safetensors"
    low = "low_noise_model.safetensors"
    hw = lw = 1.0

    if lora:
        pair = lora[0]
        high = pair.get("high", high)
        low = pair.get("low", low)
        hw = pair.get("high_weight", hw)
        lw = pair.get("low_weight", lw)

    prompt["279"]["inputs"]["lora_0"] = high
    prompt["279"]["inputs"]["strength_0"] = hw
    prompt["553"]["inputs"]["lora_0"] = low
    prompt["553"]["inputs"]["strength_0"] = lw

    logger.info(f"HIGH LoRA: {high} ({hw})")
    logger.info(f"LOW  LoRA: {low} ({lw})")

    # --- Execute ---
    ws = websocket.WebSocket()
    ws.connect(f"ws://{SERVER}:8188/ws?clientId={CLIENT_ID}")

    pid = queue(prompt)["prompt_id"]

    while True:
        msg = ws.recv()
        if isinstance(msg, str):
            m = json.loads(msg)
            if m["type"] == "executing" and m["data"]["node"] is None:
                break

    ws.close()

    out = history(pid)[pid]["outputs"]
    for node in out.values():
        if "gifs" in node:
            path = node["gifs"][0]["fullpath"]
            with open(path, "rb") as f:
                return {"video": base64.b64encode(f.read()).decode()}

    return {"error": "No video produced"}


runpod.serverless.start({"handler": handler})
