#!/bin/bash
echo "========================================"
echo "[WAN22-GGUF-5B] WORKER v3.1 - TI2V 5B"
echo "========================================"

# ===========================================
# FASE 1: Verificar volume
# ===========================================
echo ""
echo "=== FASE 1: VERIFICANDO VOLUME ==="

echo "Conteudo de /runpod-volume:"
ls -la /runpod-volume/ 2>/dev/null || echo "  Volume NAO montado!"

MODELS_PATH="/runpod-volume/wan22_gguf_5b_models"
SHARED_MODELS="/runpod-volume/wan22_models"

echo ""
echo "Modelos GGUF: $MODELS_PATH"
ls -la $MODELS_PATH/ 2>/dev/null || echo "  Nao encontrado"

echo ""
echo "Modelos compartilhados: $SHARED_MODELS"
ls -la $SHARED_MODELS/ 2>/dev/null || echo "  Nao encontrado"

# ===========================================
# FASE 2: Criar symlinks
# ===========================================
echo ""
echo "=== FASE 2: CRIANDO SYMLINKS ==="

# Garantir diretorios existem
mkdir -p /comfyui/models/unet
mkdir -p /comfyui/models/diffusion_models
mkdir -p /comfyui/models/vae
mkdir -p /comfyui/models/text_encoders
mkdir -p /comfyui/models/clip_vision
mkdir -p /comfyui/models/clip

# Funcao para linkar arquivo individual
link_file() {
    local source="$1"
    local target="$2"

    if [ -e "$source" ]; then
        # Resolver symlink se necessario
        if [ -L "$source" ]; then
            source=$(readlink -f "$source")
        fi
        echo "  $target <- $source"
        ln -sf "$source" "$target"
    else
        echo "  AVISO: $source nao existe"
    fi
}

# === UNET (GGUF) ===
echo ""
echo "[UNET - GGUF]"
link_file "$MODELS_PATH/unet/Wan2.2-TI2V-5B-Q4_K_M.gguf" "/comfyui/models/unet/Wan2.2-TI2V-5B-Q4_K_M.gguf"
link_file "$MODELS_PATH/unet/Wan2.2-TI2V-5B-Q4_K_M.gguf" "/comfyui/models/diffusion_models/Wan2.2-TI2V-5B-Q4_K_M.gguf"

# === VAE ===
echo ""
echo "[VAE]"
link_file "$MODELS_PATH/vae/Wan2.2_VAE.safetensors" "/comfyui/models/vae/Wan2.2_VAE.safetensors"

# === TEXT ENCODERS ===
echo ""
echo "[TEXT ENCODERS]"
# Usar do caminho original se o symlink nao funcionar
if [ -e "$SHARED_MODELS/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors" ]; then
    link_file "$SHARED_MODELS/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors" "/comfyui/models/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors"
else
    link_file "$MODELS_PATH/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors" "/comfyui/models/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors"
fi

# === CLIP VISION ===
echo ""
echo "[CLIP VISION]"
# Usar do caminho original
if [ -e "$SHARED_MODELS/clip/sigclip_vision_patch14_384.safetensors" ]; then
    link_file "$SHARED_MODELS/clip/sigclip_vision_patch14_384.safetensors" "/comfyui/models/clip_vision/sigclip_vision_patch14_384.safetensors"
else
    link_file "$MODELS_PATH/clip/sigclip_vision_patch14_384.safetensors" "/comfyui/models/clip_vision/sigclip_vision_patch14_384.safetensors"
fi

# ===========================================
# FASE 3: Verificacao final
# ===========================================
echo ""
echo "=== FASE 3: VERIFICACAO FINAL ==="

echo ""
echo "=== unet/ ==="
ls -lh /comfyui/models/unet/ 2>/dev/null || echo "(vazio)"

echo ""
echo "=== vae/ ==="
ls -lh /comfyui/models/vae/ 2>/dev/null || echo "(vazio)"

echo ""
echo "=== text_encoders/ ==="
ls -lh /comfyui/models/text_encoders/ 2>/dev/null || echo "(vazio)"

echo ""
echo "=== clip_vision/ ==="
ls -lh /comfyui/models/clip_vision/ 2>/dev/null || echo "(vazio)"

# ===========================================
# FASE 4: Iniciar ComfyUI
# ===========================================
echo ""
echo "=== FASE 4: INICIANDO COMFYUI ==="

cd /comfyui
python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --disable-auto-launch \
    --disable-metadata &

echo "ComfyUI iniciado em background"
echo "Aguardando 30 segundos para inicializacao..."
sleep 30

# ===========================================
# FASE 5: Handler
# ===========================================
echo ""
echo "=== FASE 5: INICIANDO HANDLER ==="
cd /
exec python -u /handler.py
