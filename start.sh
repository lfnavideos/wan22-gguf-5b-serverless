#!/bin/bash
echo "========================================"
echo "[WAN22-GGUF-5B] WORKER v1.2"
echo "========================================"

# Debug: verificar volume
echo "[WAN22-GGUF-5B] Verificando volume..."
if [ -d "/runpod-volume" ]; then
    echo "[WAN22-GGUF-5B] /runpod-volume existe"
    ls -la /runpod-volume/
else
    echo "[WAN22-GGUF-5B] ERRO: /runpod-volume NAO existe!"
fi

if [ -d "/runpod-volume/wan22_gguf_5b_models" ]; then
    echo ""
    echo "[WAN22-GGUF-5B] Modelos no volume:"
    ls -laR /runpod-volume/wan22_gguf_5b_models/
else
    echo "[WAN22-GGUF-5B] ERRO: /runpod-volume/wan22_gguf_5b_models NAO existe!"
fi

# Verificar extra_model_paths.yaml
echo ""
echo "[WAN22-GGUF-5B] extra_model_paths.yaml:"
cat /comfyui/extra_model_paths.yaml

# Iniciar ComfyUI em background com extra model paths
echo ""
echo "[WAN22-GGUF-5B] Iniciando ComfyUI..."
cd /comfyui
python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --disable-auto-launch \
    --disable-metadata \
    --extra-model-paths-config /comfyui/extra_model_paths.yaml &

echo "[WAN22-GGUF-5B] ComfyUI iniciado em background"

# Aguardar ComfyUI iniciar
echo "[WAN22-GGUF-5B] Aguardando ComfyUI iniciar..."
sleep 15

# Iniciar handler
echo "[WAN22-GGUF-5B] Iniciando handler..."
cd /
exec python -u /handler.py
