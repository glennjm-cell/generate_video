# Base image
FROM wlsdml1114/multitalk-base:1.7

# ------------------------------------------------
# Environment (CRITICAL)
# ------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV BUILDKIT_INLINE_CACHE=0
ENV RUNPOD_DISABLE_BUILD_CACHE=1

# ------------------------------------------------
# System deps (git REQUIRED)
# ------------------------------------------------
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------
# Python deps
# ------------------------------------------------
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir \
        runpod \
        websocket-client \
        huggingface_hub[hf_transfer]

# ------------------------------------------------
# Workdir
# ------------------------------------------------
WORKDIR /app

# ------------------------------------------------
# Clone ComfyUI ONLY (NO MODELS)
# ------------------------------------------------
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git /ComfyUI && \
    pip install --no-cache-dir -r /ComfyUI/requirements.txt

# ------------------------------------------------
# Custom nodes (NO combined installs)
# ------------------------------------------------
RUN cd /ComfyUI/custom_nodes && \
    git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    pip install --no-cache-dir -r ComfyUI-Manager/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone --depth=1 https://github.com/city96/ComfyUI-GGUF.git && \
    pip install --no-cache-dir -r ComfyUI-GGUF/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone --depth=1 https://github.com/kijai/ComfyUI-KJNodes.git && \
    pip install --no-cache-dir -r ComfyUI-KJNodes/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone --depth=1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    pip install --no-cache-dir -r ComfyUI-VideoHelperSuite/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone --depth=1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    pip install --no-cache-dir -r ComfyUI-WanVideoWrapper/requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone --depth=1 https://github.com/orssorbit/ComfyUI-wanBlockswap.git

# ------------------------------------------------
# Create model dirs ONLY (NO downloads)
# ------------------------------------------------
RUN mkdir -p /ComfyUI/models/{diffusion_models,vae,text_encoders,loras,clip_vision}

# ------------------------------------------------
# Copy serverless code
# ------------------------------------------------
COPY . /app
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml

RUN chmod +x /app/entrypoint.sh

# ------------------------------------------------
# Start
# ------------------------------------------------
CMD ["/app/entrypoint.sh"]
