# Wan 2.2 TI2V 5B GGUF - RunPod Serverless

Endpoint otimizado para geracao de video I2V com modelo GGUF quantizado.

## Vantagens

| Metrica | Wan 2.1 14B (atual) | Wan 2.2 5B GGUF |
|---------|---------------------|-----------------|
| VRAM | ~20GB (offload) | ~10-12GB |
| Tempo/clip | ~160s | ~40-60s |
| Custo/clip | $0.030 | ~$0.008-0.012 |

## Modelos Necessarios

Baixar e colocar no Network Volume em `/wan22_gguf_5b_models/`:

### 1. Modelo GGUF (escolher um)

**Recomendado: Q4_K_M** (melhor balanco qualidade/velocidade)

```bash
# Criar estrutura
mkdir -p /runpod-volume/wan22_gguf_5b_models/unet

# Baixar Q4_K_M (~3.4GB)
wget -O /runpod-volume/wan22_gguf_5b_models/unet/wan2.2-ti2v-5b-Q4_K_M.gguf \
  "https://huggingface.co/QuantStack/Wan2.2-TI2V-5B-GGUF/resolve/main/wan2.2-ti2v-5b-Q4_K_M.gguf"
```

Outras opcoes:
- Q3_K_M (~2.5GB) - mais rapido, qualidade OK
- Q5_K_M (~3.8GB) - mais lento, melhor qualidade
- Q8_0 (~5.4GB) - mais lento, qualidade maxima

### 2. VAE Wan 2.2

```bash
mkdir -p /runpod-volume/wan22_gguf_5b_models/vae

wget -O /runpod-volume/wan22_gguf_5b_models/vae/wan2.2_vae.safetensors \
  "https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B/resolve/main/vae/wan2.2_vae.safetensors"
```

### 3. Text Encoder

```bash
mkdir -p /runpod-volume/wan22_gguf_5b_models/text_encoders

wget -O /runpod-volume/wan22_gguf_5b_models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
```

### 4. CLIP Vision (opcional, se nao estiver na imagem)

```bash
mkdir -p /runpod-volume/wan22_gguf_5b_models/clip_vision

wget -O /runpod-volume/wan22_gguf_5b_models/clip_vision/clip_vision_h.safetensors \
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
```

## Estrutura Final do Volume

```
/runpod-volume/wan22_gguf_5b_models/
├── unet/
│   └── wan2.2-ti2v-5b-Q4_K_M.gguf      # ~3.4GB
├── vae/
│   └── wan2.2_vae.safetensors          # ~335MB
├── text_encoders/
│   └── umt5_xxl_fp8_e4m3fn_scaled.safetensors  # ~4.8GB
└── clip_vision/
    └── clip_vision_h.safetensors       # ~1.1GB (opcional)
```

**Total: ~9-10GB**

## Deploy no RunPod

### 1. Criar Network Volume
- Regiao: mesma do endpoint
- Tamanho: 15GB minimo
- Baixar modelos conforme acima

### 2. Build da Imagem
```bash
docker build -t seu-usuario/wan22-gguf-5b-serverless:latest .
docker push seu-usuario/wan22-gguf-5b-serverless:latest
```

### 3. Criar Serverless Endpoint
- Template: Custom
- Container Image: `seu-usuario/wan22-gguf-5b-serverless:latest`
- GPU: RTX 4090 (24GB) ou A10G (24GB)
- Network Volume: o volume criado acima
- Max Workers: 1-3

## Uso

Ver `modules/runpod_wan22_gguf_5b_client.py` para cliente Python.

## Troubleshooting

### Erro: "Model not found"
- Verificar se os modelos estao no volume correto
- Verificar symlinks no start.sh

### Erro: "Out of memory"
- Usar quantizacao menor (Q3_K_M ou Q3_K_S)
- Reduzir resolucao para 480x832

### Erro: "GGUF loader not found"
- Verificar se ComfyUI-GGUF foi clonado corretamente
