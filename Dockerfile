# Base image (CUDA + Python already set up)
FROM wlsdml1114/multitalk-base:1.7

# -----------------------------
# 🔒 Build safety
# -----------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV BUILDKIT_INLINE_CACHE=0

# -----------------------------
# Python deps
# -----------------------------
RUN pip install -U pip && \
    pip install runpod websocket-client "huggingface_hub[hf_transfer]"

# -----------------------------
# Working directory
# -----------------------------
WORKDIR /app

# -----------------------------
# Clone ComfyUI (CODE ONLY)
# -----------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI && \
    pip install -r /ComfyUI/requirements.txt

# -----------------------------
# Custom Nodes (isolated installs)
# -----------------------------
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    pip install -r ComfyUI-Manager/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    pip install -r ComfyUI-GGUF/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    pip install -r ComfyUI-KJNodes/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    pip install -r ComfyUI-VideoHelperSuite/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    pip install -r ComfyUI-WanVideoWrapper/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/orssorbit/ComfyUI-wanBlockswap.git

# -----------------------------
# Model directories ONLY
# (NO safetensors downloads at build time)
# -----------------------------
RUN mkdir -p /ComfyUI/models/{diffusion_models,vae,text_encoders,loras,clip_vision}

# -----------------------------
# Copy serverless files
# -----------------------------
COPY . /app
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml

# Entrypoint
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
