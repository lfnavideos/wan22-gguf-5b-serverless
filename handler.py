# -*- coding: utf-8 -*-
"""
Custom Handler for Wan 2.2 TI2V 5B GGUF
Supports both full workflow and simplified API

Simplified API:
  - T2V: {"prompt": "...", "negative_prompt": "..."}
  - I2V: {"prompt": "...", "image": "base64..."}

Optional params: width, height, num_frames, steps, cfg, seed, frame_rate
"""

import os
import time
import json
import base64
import glob
import requests
import runpod
import random

COMFY_OUTPUT_PATH = os.environ.get('COMFY_OUTPUT_PATH', '/comfyui/output')
COMFY_API_URL = os.environ.get('COMFY_API_URL', 'http://127.0.0.1:8188')

# Default settings
DEFAULTS = {
    'width': 512,
    'height': 768,
    'num_frames': 25,
    'steps': 20,
    'cfg': 5.0,
    'shift': 8.0,
    'frame_rate': 12,
    'negative_prompt': 'blurry, low quality, distorted'
}


def build_t2v_workflow(params):
    """Build Text-to-Video workflow from simple params"""
    width = params.get('width', DEFAULTS['width'])
    height = params.get('height', DEFAULTS['height'])
    num_frames = params.get('num_frames', DEFAULTS['num_frames'])
    steps = params.get('steps', DEFAULTS['steps'])
    cfg = params.get('cfg', DEFAULTS['cfg'])
    shift = params.get('shift', DEFAULTS['shift'])
    seed = params.get('seed', random.randint(0, 2**32-1))
    frame_rate = params.get('frame_rate', DEFAULTS['frame_rate'])
    prompt = params.get('prompt', '')
    negative = params.get('negative_prompt', DEFAULTS['negative_prompt'])

    return {
        "10": {
            "class_type": "WanVideoModelLoader",
            "inputs": {
                "model": "Wan2.2-TI2V-5B-Q4_K_M.gguf",
                "base_precision": "fp16",
                "quantization": "disabled",
                "load_device": "main_device"
            }
        },
        "11": {
            "class_type": "LoadWanVideoT5TextEncoder",
            "inputs": {
                "model_name": "umt5-xxl-enc-fp8_e4m3fn.safetensors",
                "precision": "bf16"
            }
        },
        "12": {
            "class_type": "WanVideoVAELoader",
            "inputs": {
                "model_name": "Wan2.2_VAE.safetensors",
                "precision": "fp16"
            }
        },
        "20": {
            "class_type": "WanVideoTextEncode",
            "inputs": {
                "t5": ["11", 0],
                "positive_prompt": prompt,
                "negative_prompt": negative
            }
        },
        "25": {
            "class_type": "WanVideoEmptyEmbeds",
            "inputs": {
                "width": width,
                "height": height,
                "num_frames": num_frames
            }
        },
        "30": {
            "class_type": "WanVideoSampler",
            "inputs": {
                "model": ["10", 0],
                "text_embeds": ["20", 0],
                "image_embeds": ["25", 0],
                "steps": steps,
                "cfg": cfg,
                "shift": shift,
                "seed": seed,
                "scheduler": "euler",
                "riflex_freq_index": 0,
                "force_offload": True
            }
        },
        "40": {
            "class_type": "WanVideoDecode",
            "inputs": {
                "vae": ["12", 0],
                "samples": ["30", 0],
                "enable_vae_tiling": True,
                "tile_x": 256,
                "tile_y": 256,
                "tile_stride_x": 192,
                "tile_stride_y": 192
            }
        },
        "50": {
            "class_type": "VHS_VideoCombine",
            "inputs": {
                "images": ["40", 0],
                "frame_rate": frame_rate,
                "loop_count": 0,
                "filename_prefix": "wan22_t2v",
                "format": "video/h264-mp4",
                "pingpong": False,
                "save_output": True
            }
        }
    }


def build_i2v_workflow(params, image_filename):
    """Build Image-to-Video workflow from simple params"""
    width = params.get('width', DEFAULTS['width'])
    height = params.get('height', DEFAULTS['height'])
    num_frames = params.get('num_frames', DEFAULTS['num_frames'])
    steps = params.get('steps', DEFAULTS['steps'])
    cfg = params.get('cfg', DEFAULTS['cfg'])
    shift = params.get('shift', DEFAULTS['shift'])
    seed = params.get('seed', random.randint(0, 2**32-1))
    frame_rate = params.get('frame_rate', DEFAULTS['frame_rate'])
    prompt = params.get('prompt', '')
    negative = params.get('negative_prompt', DEFAULTS['negative_prompt'])

    return {
        "10": {
            "class_type": "WanVideoModelLoader",
            "inputs": {
                "model": "Wan2.2-TI2V-5B-Q4_K_M.gguf",
                "base_precision": "fp16",
                "quantization": "disabled",
                "load_device": "main_device"
            }
        },
        "11": {
            "class_type": "LoadWanVideoT5TextEncoder",
            "inputs": {
                "model_name": "umt5-xxl-enc-fp8_e4m3fn.safetensors",
                "precision": "bf16"
            }
        },
        "12": {
            "class_type": "WanVideoVAELoader",
            "inputs": {
                "model_name": "Wan2.2_VAE.safetensors",
                "precision": "fp16"
            }
        },
        "14": {
            "class_type": "LoadImage",
            "inputs": {
                "image": image_filename
            }
        },
        "15": {
            "class_type": "WanVideoEncode",
            "inputs": {
                "vae": ["12", 0],
                "image": ["14", 0],
                "enable_vae_tiling": True,
                "tile_x": 256,
                "tile_y": 256,
                "tile_stride_x": 192,
                "tile_stride_y": 192
            }
        },
        "20": {
            "class_type": "WanVideoTextEncode",
            "inputs": {
                "t5": ["11", 0],
                "positive_prompt": prompt,
                "negative_prompt": negative
            }
        },
        "25": {
            "class_type": "WanVideoEmptyEmbeds",
            "inputs": {
                "width": width,
                "height": height,
                "num_frames": num_frames,
                "extra_latents": ["15", 0]
            }
        },
        "30": {
            "class_type": "WanVideoSampler",
            "inputs": {
                "model": ["10", 0],
                "text_embeds": ["20", 0],
                "image_embeds": ["25", 0],
                "steps": steps,
                "cfg": cfg,
                "shift": shift,
                "seed": seed,
                "scheduler": "euler",
                "riflex_freq_index": 0,
                "force_offload": True
            }
        },
        "40": {
            "class_type": "WanVideoDecode",
            "inputs": {
                "vae": ["12", 0],
                "samples": ["30", 0],
                "enable_vae_tiling": True,
                "tile_x": 256,
                "tile_y": 256,
                "tile_stride_x": 192,
                "tile_stride_y": 192
            }
        },
        "50": {
            "class_type": "VHS_VideoCombine",
            "inputs": {
                "images": ["40", 0],
                "frame_rate": frame_rate,
                "loop_count": 0,
                "filename_prefix": "wan22_i2v",
                "format": "video/h264-mp4",
                "pingpong": False,
                "save_output": True
            }
        }
    }


def wait_for_comfyui(timeout=120):
    """Wait for ComfyUI to be ready"""
    start = time.time()
    while time.time() - start < timeout:
        try:
            r = requests.get(f'{COMFY_API_URL}/system_stats', timeout=5)
            if r.status_code == 200:
                print(f"[HANDLER] ComfyUI ready after {int(time.time()-start)}s")
                return True
        except:
            pass
        time.sleep(2)
    return False


def get_video_files(output_path, start_time):
    """Scan output folder for video files created after start_time"""
    video_extensions = ['.mp4', '.webm', '.mov', '.avi', '.mkv', '.gif']
    videos = []

    for ext in video_extensions:
        pattern = os.path.join(output_path, f'*{ext}')
        for filepath in glob.glob(pattern):
            try:
                if os.path.getmtime(filepath) > start_time:
                    videos.append(filepath)
            except:
                pass

    # Also check subdirectories
    for ext in video_extensions:
        pattern = os.path.join(output_path, '**', f'*{ext}')
        for filepath in glob.glob(pattern, recursive=True):
            try:
                if os.path.getmtime(filepath) > start_time:
                    if filepath not in videos:
                        videos.append(filepath)
            except:
                pass

    return sorted(videos, key=lambda x: os.path.getmtime(x))


def upload_video(filepath, job_id):
    """Return video as base64"""
    try:
        with open(filepath, 'rb') as f:
            video_data = f.read()

        # Check size limit (15MB to be safe)
        if len(video_data) > 15 * 1024 * 1024:
            return {
                'type': 'error',
                'filename': os.path.basename(filepath),
                'data': f'Video too large ({len(video_data)/1024/1024:.1f}MB)'
            }

        return {
            'type': 'base64',
            'filename': os.path.basename(filepath),
            'data': base64.b64encode(video_data).decode('utf-8')
        }
    except Exception as e:
        return {'type': 'error', 'filename': os.path.basename(filepath), 'data': str(e)}


def handler(event):
    """Main handler function"""
    job_id = event.get('id', 'unknown')
    job_input = event.get('input', {})

    print(f"[HANDLER] Job {job_id} started")

    # Record start time for video detection
    start_time = time.time()

    # Check for workflow or simplified API
    workflow = job_input.get('workflow')
    images = job_input.get('images', [])
    image_filename = None

    if not workflow:
        # Simplified API mode
        prompt = job_input.get('prompt')
        if not prompt:
            return {'error': 'No workflow or prompt provided', 'status': 'FAILED'}

        image_b64 = job_input.get('image')

        if image_b64:
            # I2V mode - save image first
            image_filename = f'input_{job_id}.png'
            try:
                img_bytes = base64.b64decode(image_b64)
                img_path = f'/comfyui/input/{image_filename}'
                os.makedirs(os.path.dirname(img_path), exist_ok=True)
                with open(img_path, 'wb') as f:
                    f.write(img_bytes)
                print(f"[HANDLER] Saved input image: {img_path}")
            except Exception as e:
                return {'error': f'Failed to save input image: {e}', 'status': 'FAILED'}

            workflow = build_i2v_workflow(job_input, image_filename)
            print(f"[HANDLER] Built I2V workflow")
        else:
            # T2V mode
            workflow = build_t2v_workflow(job_input)
            print(f"[HANDLER] Built T2V workflow")

    # Wait for ComfyUI to be ready
    if not wait_for_comfyui(timeout=120):
        return {'error': 'ComfyUI not ready after 120s', 'status': 'FAILED'}

    # Save input images
    for img in images:
        name = img.get('name', 'INPUT_IMAGE')
        img_data = img.get('image', '')
        if img_data:
            try:
                img_bytes = base64.b64decode(img_data)
                img_path = f'/comfyui/input/{name}.png'
                os.makedirs(os.path.dirname(img_path), exist_ok=True)
                with open(img_path, 'wb') as f:
                    f.write(img_bytes)
                print(f"[HANDLER] Saved: {img_path}")
            except Exception as e:
                print(f"[HANDLER] Error saving image: {e}")

    # Queue workflow via ComfyUI API
    try:
        response = requests.post(
            f'{COMFY_API_URL}/prompt',
            json={'prompt': workflow},
            timeout=30
        )
        if response.status_code != 200:
            return {
                'error': f'Failed to queue workflow: {response.text}',
                'status': 'FAILED'
            }
        prompt_id = response.json().get('prompt_id')
        print(f"[HANDLER] Queued: {prompt_id}")
    except Exception as e:
        return {'error': f'Failed to connect to ComfyUI: {e}', 'status': 'FAILED'}

    # Wait for completion
    max_wait = 600
    waited = 0
    completed = False

    while waited < max_wait:
        time.sleep(5)
        waited += 5

        try:
            hist = requests.get(
                f'{COMFY_API_URL}/history/{prompt_id}',
                timeout=30
            ).json()

            if prompt_id in hist:
                status_info = hist[prompt_id].get('status', {})
                status_str = status_info.get('status_str', '')

                if status_str == 'error':
                    messages = status_info.get('messages', [])
                    error_msg = str(messages) if messages else 'Unknown error'
                    return {'error': error_msg, 'status': 'FAILED'}

                if hist[prompt_id].get('outputs'):
                    completed = True
                    print(f"[HANDLER] Completed in {waited}s")
                    break
        except Exception as e:
            print(f"[HANDLER] Error checking status: {e}")

        if waited % 30 == 0:
            print(f"[HANDLER] Waiting... ({waited}s)")

    if not completed:
        return {'error': f'Timeout after {max_wait}s', 'status': 'FAILED'}

    # Wait for file system
    time.sleep(2)

    # Get video files
    videos = get_video_files(COMFY_OUTPUT_PATH, start_time)
    print(f"[HANDLER] Found {len(videos)} video(s)")

    # Process videos
    video_outputs = []
    for video_path in videos:
        video_output = upload_video(video_path, job_id)
        video_outputs.append(video_output)
        print(f"[HANDLER] Processed: {video_path}")

    if not video_outputs:
        return {
            'error': 'Workflow completed but no video found',
            'status': 'FAILED',
            'details': f'Searched in {COMFY_OUTPUT_PATH}'
        }

    output = {
        'status': 'success',
        'images': [],
        'videos': video_outputs
    }

    # Add first video as 'video' for backward compatibility
    if video_outputs and video_outputs[0].get('type') == 'base64':
        output['video'] = video_outputs[0].get('data')

    return output


# RunPod serverless entry point
runpod.serverless.start({'handler': handler})
