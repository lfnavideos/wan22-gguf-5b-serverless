#!/bin/bash
echo "========================================"
echo "[WAN22-GGUF-5B] WORKER v1.0"
echo "========================================"

# Symlinks do volume para modelos GGUF
if [ -d "/runpod-volume/wan22_gguf_5b_models" ]; then
    echo "[WAN22-GGUF-5B] Criando symlinks..."

    # GGUF model vai em unet (para ComfyUI-GGUF loader)
    ln -sf /runpod-volume/wan22_gguf_5b_models/unet/* /comfyui/models/unet/ 2>/dev/null || true

    # Tambem em diffusion_models (compatibilidade)
    ln -sf /runpod-volume/wan22_gguf_5b_models/unet/* /comfyui/models/diffusion_models/ 2>/dev/null || true

    # VAE, text encoders, etc
    for dir in vae text_encoders loras clip clip_vision; do
        ln -sf /runpod-volume/wan22_gguf_5b_models/$dir/* /comfyui/models/$dir/ 2>/dev/null || true
    done

    echo "[WAN22-GGUF-5B] Symlinks OK"
    echo "[WAN22-GGUF-5B] Modelos disponiveis:"
    ls -la /comfyui/models/unet/ 2>/dev/null || echo "  (nenhum em unet)"
    ls -la /comfyui/models/diffusion_models/ 2>/dev/null | head -5
else
    echo "[WAN22-GGUF-5B] AVISO: Volume nao encontrado em /runpod-volume/wan22_gguf_5b_models"
    echo "[WAN22-GGUF-5B] Certifique-se de configurar o Network Volume com os modelos"
fi

# Iniciar ComfyUI em background
cd /comfyui
python main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch --disable-metadata &
echo "[WAN22-GGUF-5B] ComfyUI iniciado em background"

# Iniciar handler
echo "[WAN22-GGUF-5B] Iniciando handler..."
cd /
exec python -u /handler.py
