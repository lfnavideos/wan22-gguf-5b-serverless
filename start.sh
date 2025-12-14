#!/bin/bash
echo "========================================"
echo "[WAN22-GGUF-5B] WORKER v3.0 - TI2V 5B"
echo "========================================"

# ===========================================
# FASE 1: Verificar volume
# ===========================================
echo ""
echo "=== FASE 1: VERIFICANDO VOLUME ==="

echo "Conteudo de /runpod-volume:"
ls -la /runpod-volume/ 2>/dev/null || echo "  Volume NAO montado!"

MODELS_PATH="/runpod-volume/wan22_gguf_5b_models"

if [ -d "$MODELS_PATH" ]; then
    echo ""
    echo "Modelos encontrados em: $MODELS_PATH"
    echo "Estrutura:"
    ls -la $MODELS_PATH/
else
    echo ""
    echo "ERRO: $MODELS_PATH nao existe!"
    echo "Procurando .gguf..."
    find /runpod-volume -name "*.gguf" 2>/dev/null | head -5
fi

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

# Funcao para linkar arquivos de um diretorio
link_files() {
    local source_dir="$1"
    local target_dir="$2"
    local desc="$3"

    echo ""
    echo "[$desc]"

    if [ -d "$source_dir" ]; then
        # Resolver symlinks no diretorio fonte
        for file in "$source_dir"/*; do
            if [ -e "$file" ] || [ -L "$file" ]; then
                filename=$(basename "$file")
                # Se for symlink, seguir para o arquivo real
                if [ -L "$file" ]; then
                    real_file=$(readlink -f "$file")
                    echo "  Linkando (via symlink): $filename"
                    ln -sf "$real_file" "$target_dir/$filename"
                else
                    echo "  Linkando: $filename"
                    ln -sf "$file" "$target_dir/$filename"
                fi
            fi
        done
        echo "  Resultado:"
        ls -lh "$target_dir/" 2>/dev/null | head -5
    else
        echo "  Diretorio fonte nao existe: $source_dir"
    fi
}

# UNET/Diffusion Models (GGUF)
link_files "$MODELS_PATH/unet" "/comfyui/models/unet" "UNET (GGUF)"
link_files "$MODELS_PATH/unet" "/comfyui/models/diffusion_models" "Diffusion Models"

# VAE
link_files "$MODELS_PATH/vae" "/comfyui/models/vae" "VAE"

# Text Encoders
link_files "$MODELS_PATH/text_encoders" "/comfyui/models/text_encoders" "Text Encoders"
link_files "$MODELS_PATH/text_encoders" "/comfyui/models/clip" "CLIP (Text Encoders)"

# CLIP Vision
link_files "$MODELS_PATH/clip" "/comfyui/models/clip_vision" "CLIP Vision"

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
