#!/bin/bash
echo "========================================"
echo "[WAN22-GGUF-5B] WORKER v2.0 - DEBUG MODE"
echo "========================================"

# ===========================================
# FASE 1: DEBUG - Descobrir onde estão os arquivos
# ===========================================
echo ""
echo "=== FASE 1: DEBUG DO VOLUME ==="

echo ""
echo "[DEBUG] Listando /runpod-volume (raiz):"
ls -la /runpod-volume/ 2>/dev/null || echo "  /runpod-volume NAO EXISTE"

echo ""
echo "[DEBUG] Procurando arquivos .gguf:"
find /runpod-volume -name "*.gguf" 2>/dev/null || echo "  Nenhum .gguf encontrado"

echo ""
echo "[DEBUG] Procurando arquivos .safetensors:"
find /runpod-volume -name "*.safetensors" 2>/dev/null | head -10 || echo "  Nenhum .safetensors encontrado"

echo ""
echo "[DEBUG] Estrutura de diretorios (3 niveis):"
find /runpod-volume -maxdepth 3 -type d 2>/dev/null || echo "  Nao foi possivel listar"

# ===========================================
# FASE 2: Descobrir o caminho correto dos modelos
# ===========================================
echo ""
echo "=== FASE 2: LOCALIZANDO MODELOS ==="

MODELS_PATH=""

# Tentar varios caminhos possiveis
POSSIBLE_PATHS=(
    "/runpod-volume/wan22_gguf_5b_models"
    "/runpod-volume/workspace/wan22_gguf_5b_models"
    "/runpod-volume/models"
    "/workspace/wan22_gguf_5b_models"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    echo "Verificando: $path"
    if [ -d "$path/unet" ] || [ -d "$path" ]; then
        # Verificar se tem arquivos .gguf
        if find "$path" -name "*.gguf" 2>/dev/null | grep -q .; then
            MODELS_PATH="$path"
            echo "  -> ENCONTRADO!"
            break
        fi
    fi
    echo "  -> Nao encontrado"
done

# Se nao encontrou, tentar busca generica
if [ -z "$MODELS_PATH" ]; then
    echo ""
    echo "Tentando busca generica por .gguf..."
    GGUF_FILE=$(find /runpod-volume -name "*.gguf" 2>/dev/null | head -1)
    if [ -n "$GGUF_FILE" ]; then
        # Pegar o diretorio pai do pai (unet -> wan22_gguf_5b_models)
        MODELS_PATH=$(dirname $(dirname "$GGUF_FILE"))
        echo "  -> Encontrado em: $MODELS_PATH"
    fi
fi

# Verificacao final
if [ -z "$MODELS_PATH" ]; then
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERRO CRITICO: Modelos NAO encontrados!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    echo "Estrutura completa do volume:"
    ls -laR /runpod-volume/ 2>/dev/null || echo "Volume vazio ou nao montado"
    echo ""
    echo "O worker vai continuar, mas ComfyUI nao tera modelos."
fi

echo ""
echo "MODELS_PATH final: $MODELS_PATH"

# ===========================================
# FASE 3: Criar symlinks de DIRETORIO
# ===========================================
echo ""
echo "=== FASE 3: CRIANDO SYMLINKS ==="

# Garantir diretorios existem
mkdir -p /comfyui/models/unet
mkdir -p /comfyui/models/diffusion_models
mkdir -p /comfyui/models/vae
mkdir -p /comfyui/models/text_encoders
mkdir -p /comfyui/models/clip_vision
mkdir -p /comfyui/models/clip

if [ -n "$MODELS_PATH" ]; then
    # Funcao para criar link de diretorio
    link_dir() {
        local source="$1"
        local target="$2"
        
        if [ -d "$source" ]; then
            echo "Linkando: $source -> $target"
            rm -rf "$target"
            ln -s "$source" "$target"
            ls -la "$target/" 2>/dev/null | head -3
        else
            echo "Fonte nao existe: $source"
        fi
    }
    
    # GGUF loader usa models/unet (IMPORTANTE!)
    link_dir "$MODELS_PATH/unet" "/comfyui/models/unet"
    
    # Tambem linkar para diffusion_models (compatibilidade)
    if [ -d "$MODELS_PATH/unet" ]; then
        echo "Linkando unet -> diffusion_models tambem"
        rm -rf /comfyui/models/diffusion_models
        ln -s "$MODELS_PATH/unet" /comfyui/models/diffusion_models
    fi
    
    # VAE
    link_dir "$MODELS_PATH/vae" "/comfyui/models/vae"
    
    # Text Encoders
    link_dir "$MODELS_PATH/text_encoders" "/comfyui/models/text_encoders"
    
    # CLIP Vision
    link_dir "$MODELS_PATH/clip_vision" "/comfyui/models/clip_vision"
    
    # Tambem linkar text_encoders para clip (alguns nodes usam)
    if [ -d "$MODELS_PATH/text_encoders" ]; then
        rm -rf /comfyui/models/clip
        ln -s "$MODELS_PATH/text_encoders" /comfyui/models/clip
    fi
fi

# ===========================================
# FASE 4: Verificacao final
# ===========================================
echo ""
echo "=== FASE 4: VERIFICACAO FINAL ==="

echo ""
echo "models/unet/:"
ls -la /comfyui/models/unet/ 2>/dev/null || echo "  (vazio)"

echo ""
echo "models/diffusion_models/:"
ls -la /comfyui/models/diffusion_models/ 2>/dev/null || echo "  (vazio)"

echo ""
echo "models/vae/:"
ls -la /comfyui/models/vae/ 2>/dev/null || echo "  (vazio)"

echo ""
echo "models/text_encoders/:"
ls -la /comfyui/models/text_encoders/ 2>/dev/null || echo "  (vazio)"

echo ""
echo "models/clip_vision/:"
ls -la /comfyui/models/clip_vision/ 2>/dev/null || echo "  (vazio)"

# ===========================================
# FASE 5: Iniciar ComfyUI
# ===========================================
echo ""
echo "=== FASE 5: INICIANDO COMFYUI ==="

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
# FASE 6: Handler
# ===========================================
echo ""
echo "=== FASE 6: INICIANDO HANDLER ==="
cd /
exec python -u /handler.py
