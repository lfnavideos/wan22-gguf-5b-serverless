#!/bin/bash
echo "========================================"
echo "[WAN22-GGUF-5B] WORKER v1.1"
echo "========================================"

# Symlinks do volume para modelos GGUF
if [ -d "/runpod-volume/wan22_gguf_5b_models" ]; then
    echo "[WAN22-GGUF-5B] Volume encontrado. Criando symlinks..."

    # Criar diretorios necessarios
    mkdir -p /comfyui/models/diffusion_models
    mkdir -p /comfyui/models/unet
    mkdir -p /comfyui/models/vae
    mkdir -p /comfyui/models/text_encoders
    mkdir -p /comfyui/models/clip
    mkdir -p /comfyui/models/clip_vision
    mkdir -p /comfyui/models/wan
    mkdir -p /comfyui/models/t5

    # Listar conteudo do volume
    echo "[WAN22-GGUF-5B] Conteudo do volume:"
    ls -la /runpod-volume/wan22_gguf_5b_models/

    # GGUF model vai em multiplos lugares para compatibilidade
    for f in /runpod-volume/wan22_gguf_5b_models/unet/*; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            echo "[WAN22-GGUF-5B] Linking UNET: $fname"
            ln -sf "$f" /comfyui/models/unet/"$fname"
            ln -sf "$f" /comfyui/models/diffusion_models/"$fname"
            ln -sf "$f" /comfyui/models/wan/"$fname"
        fi
    done

    # VAE
    for f in /runpod-volume/wan22_gguf_5b_models/vae/*; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            echo "[WAN22-GGUF-5B] Linking VAE: $fname"
            ln -sf "$f" /comfyui/models/vae/"$fname"
        fi
    done

    # Text encoders
    for f in /runpod-volume/wan22_gguf_5b_models/text_encoders/*; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            echo "[WAN22-GGUF-5B] Linking T5: $fname"
            ln -sf "$f" /comfyui/models/text_encoders/"$fname"
            ln -sf "$f" /comfyui/models/t5/"$fname"
            ln -sf "$f" /comfyui/models/clip/"$fname"
        fi
    done

    # CLIP Vision
    for f in /runpod-volume/wan22_gguf_5b_models/clip_vision/*; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            echo "[WAN22-GGUF-5B] Linking CLIP Vision: $fname"
            ln -sf "$f" /comfyui/models/clip_vision/"$fname"
        fi
    done

    echo ""
    echo "[WAN22-GGUF-5B] === Verificando symlinks ==="
    echo "diffusion_models:"
    ls -la /comfyui/models/diffusion_models/ 2>/dev/null || echo "  (vazio)"
    echo "vae:"
    ls -la /comfyui/models/vae/ 2>/dev/null || echo "  (vazio)"
    echo "text_encoders:"
    ls -la /comfyui/models/text_encoders/ 2>/dev/null || echo "  (vazio)"
    echo "clip_vision:"
    ls -la /comfyui/models/clip_vision/ 2>/dev/null || echo "  (vazio)"
else
    echo "[WAN22-GGUF-5B] AVISO: Volume nao encontrado em /runpod-volume/wan22_gguf_5b_models"
    echo "[WAN22-GGUF-5B] Listando /runpod-volume/:"
    ls -la /runpod-volume/ 2>/dev/null || echo "  (nao existe)"
fi

# Iniciar ComfyUI em background
echo ""
echo "[WAN22-GGUF-5B] Iniciando ComfyUI..."
cd /comfyui
python main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch --disable-metadata &
echo "[WAN22-GGUF-5B] ComfyUI iniciado em background"

# Aguardar ComfyUI iniciar
sleep 10

# Iniciar handler
echo "[WAN22-GGUF-5B] Iniciando handler..."
cd /
exec python -u /handler.py
