#!/bin/bash
echo "========================================"
echo "[WAN22-GGUF-5B] WORKER v1.3"
echo "========================================"

# Aguardar volume estar disponivel
echo "[WAN22-GGUF-5B] Aguardando volume..."
for i in {1..30}; do
    if [ -d "/runpod-volume/wan22_gguf_5b_models/unet" ]; then
        echo "[WAN22-GGUF-5B] Volume encontrado!"
        break
    fi
    echo "  Tentativa $i/30..."
    sleep 2
done

# Verificar volume
echo ""
echo "[WAN22-GGUF-5B] Verificando volume:"
ls -la /runpod-volume/ 2>/dev/null || echo "  /runpod-volume nao existe"

if [ -d "/runpod-volume/wan22_gguf_5b_models" ]; then
    echo ""
    echo "[WAN22-GGUF-5B] Modelos disponiveis:"
    ls -la /runpod-volume/wan22_gguf_5b_models/unet/ 2>/dev/null
    ls -la /runpod-volume/wan22_gguf_5b_models/vae/ 2>/dev/null
    ls -la /runpod-volume/wan22_gguf_5b_models/text_encoders/ 2>/dev/null
    ls -la /runpod-volume/wan22_gguf_5b_models/clip_vision/ 2>/dev/null
fi

# Verificar extra_model_paths.yaml
echo ""
echo "[WAN22-GGUF-5B] extra_model_paths.yaml:"
cat /comfyui/extra_model_paths.yaml

# Iniciar ComfyUI
echo ""
echo "[WAN22-GGUF-5B] Iniciando ComfyUI..."
cd /comfyui
python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --disable-auto-launch \
    --disable-metadata \
    --extra-model-paths-config /comfyui/extra_model_paths.yaml &

# Aguardar ComfyUI iniciar
echo "[WAN22-GGUF-5B] Aguardando ComfyUI..."
sleep 30

# Iniciar handler
echo "[WAN22-GGUF-5B] Iniciando handler..."
cd /
exec python -u /handler.py
