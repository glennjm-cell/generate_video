FROM wlsdml1114/multitalk-base:1.7

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Core deps
RUN pip install -U pip \
 && pip install runpod websocket-client "huggingface_hub[hf_transfer]"

WORKDIR /app

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI \
 && pip install -r /ComfyUI/requirements.txt

# ---- Custom nodes ----
WORKDIR /ComfyUI/custom_nodes

RUN git clone https://github.com/Comfy-Org/ComfyUI-Manager.git
RUN git clone https://github.com/city96/ComfyUI-GGUF.git
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git
RUN git clone https://github.com/orssorbit/ComfyUI-wanBlockswap.git

# ---- Install requirements ONE BY ONE (important) ----
RUN pip install -r /ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt
RUN pip install -r /ComfyUI/custom_nodes/ComfyUI-GGUF/requirements.txt
RUN pip install -r /ComfyUI/custom_nodes/ComfyUI-KJNodes/requirements.txt
RUN pip install -r /ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt
RUN pip install -r /ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt

# ---- Models ----
RUN mkdir -p /ComfyUI/models/{diffusion_models,vae,text_encoders,loras,clip_vision}

RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/I2V/Wan2_2-I2V-A14B-HIGH_fp8_e4m3fn_scaled_KJ.safetensors \
 -O /ComfyUI/models/diffusion_models/Wan2_2-I2V-A14B-HIGH_fp8_e4m3fn_scaled_KJ.safetensors

RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/I2V/Wan2_2-I2V-A14B-LOW_fp8_e4m3fn_scaled_KJ.safetensors \
 -O /ComfyUI/models/diffusion_models/Wan2_2-I2V-A14B-LOW_fp8_e4m3fn_scaled_KJ.safetensors

RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors \
 -O /ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors

RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors \
 -O /ComfyUI/models/text_encoders/umt5-xxl-enc-bf16.safetensors

RUN wget -q https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors \
 -O /ComfyUI/models/clip_vision/clip_vision_h.safetensors

# Lightning LoRAs
RUN wget -q https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors \
 -O /ComfyUI/models/loras/high_noise_model.safetensors

RUN wget -q https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors \
 -O /ComfyUI/models/loras/low_noise_model.safetensors

# ---- Your Tenexa LoRA ----
RUN wget -q https://huggingface.co/Gjm1234/tenexa-wan22-lora/resolve/main/wan22-k3nk4llinon3-16epoc-full-high-k3nk.safetensors \
 -O /ComfyUI/models/loras/tenexa-wan22-lora.safetensors

# ---- Serverless files ----
WORKDIR /app
COPY . /app
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml

RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
