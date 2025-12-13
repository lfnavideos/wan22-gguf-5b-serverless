# Wan 2.2 TI2V 5B GGUF Serverless Worker
# Modelo otimizado para baixo VRAM e alta velocidade
# Baseado em runpod/worker-comfyui com ComfyUI-GGUF
FROM runpod/worker-comfyui:5.6.0-base

# 1. Atualizar pip
RUN python -m pip install --upgrade pip setuptools wheel

# 2. Remover ComfyUI antigo e clonar versao nova
RUN rm -rf /comfyui && \
    git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    pip install --no-cache-dir -r requirements.txt

# 3. Atualizar PyTorch para CUDA 12.1
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 4. Instalar dependencias
RUN pip install --no-cache-dir \
    ftfy \
    accelerate>=1.2.1 \
    einops \
    diffusers>=0.33.0 \
    peft>=0.17.0 \
    sentencepiece>=0.2.0 \
    protobuf \
    pyloudnorm \
    gguf>=0.17.1 \
    opencv-python \
    scipy \
    transformers \
    safetensors \
    xformers \
    imageio[ffmpeg] \
    imageio-ffmpeg \
    av \
    ffmpeg-python

# 5. Instalar Custom Nodes
WORKDIR /comfyui/custom_nodes

# WanVideoWrapper (suporte Wan 2.2)
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && \
    pip install --no-cache-dir -r requirements.txt

# GGUF Loader (CRUCIAL para modelos quantizados)
RUN git clone https://github.com/city96/ComfyUI-GGUF.git && \
    cd ComfyUI-GGUF && \
    pip install --no-cache-dir -r requirements.txt || true

# VideoHelperSuite
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && \
    pip install --no-cache-dir -r requirements.txt || true

# KJNodes
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    cd ComfyUI-KJNodes && \
    pip install --no-cache-dir -r requirements.txt || true

# 6. Criar diretorios para modelos
WORKDIR /comfyui
RUN mkdir -p models/diffusion_models models/unet models/loras models/vae models/text_encoders models/clip models/clip_vision

# 7. Pre-download modelos pequenos na imagem
# CLIP Vision (~1.1GB) - necessario para I2V
RUN wget -q -O /comfyui/models/clip_vision/clip_vision_h.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" && \
    echo "CLIP Vision: $(ls -lh /comfyui/models/clip_vision/clip_vision_h.safetensors)"

# 8. Copiar scripts customizados
RUN if [ -f /start.sh ]; then mv /start.sh /start.sh.original; fi
RUN if [ -f /handler.py ]; then mv /handler.py /handler.py.original; fi

COPY handler.py /handler.py
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 9. Teste de imports
RUN python -c "import gguf; print('OK: gguf')" || echo "AVISO: gguf falhou"

CMD ["/start.sh"]
