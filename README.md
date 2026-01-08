# llamacpp-cuda-amd64-docker
This repository helps you build your own llama.cpp Docker image with CUDA support for AMD64 architectures. 
Looking for ARM64 / NVIDIA DGX? Then, head to [llamacpp-cuda-arm64-docker](https://github.com/cslev/llamacpp-cuda-arm64-docker).


## Prerequisites

To compile this Docker image, you need a fully working NVIDIA AMD64-based Linux system with all drivers installed, including CUDA. 
This means you should already be able to run llama.cpp or any AI workload efficiently on your system by offloading most of the processing to the GPU.

## Check Your System

Verify your system is properly configured by running these commands. If you see some output, you are good to go.
```
$ nvcc --version
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2025 NVIDIA Corporation
Built on Fri_Nov__7_07:24:07_PM_PST_2025
Cuda compilation tools, release 13.1, V13.1.80
Build cuda_13.1.r13.1/compiler.36836380_0

$ nvidia-smi 
Wed Dec 31 01:42:54 2025       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.95.05              Driver Version: 580.95.05      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GB10                    On  |   0000000F:01:00.0 Off |                  N/A |
| N/A   39C    P8              3W /  N/A  | Not Supported          |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```
---

# Clone Repository (with Submodule)

Clone this repository with the `llama.cpp` submodule:
```
$ git clone --recurse-submodules https://github.com/cslev/llamacpp-cuda-arm64-docker.git
```

If you cloned without the submodule, initialize it manually:
```
$ cd llamacpp-cuda-arm64-docker
$ git submodule update --init --recursive
```


# Docker Image
The image file is quite universal supporting the following GPU architectures:
- 80: A100 (Ampere Datacenter)
- 86: RTX 30-series (3080, 3090) & A6000
- 89: RTX 40-series (4080, 4090) & L40
- 90: H100 & H200 (Hopper Datacenter)

The numbers in the front represent the numbers how `lamacpp` can refer to the architectures. 
If you want to optimize for your architecture and make a smaller image, put only the relevant number in the `DCMAKE_CUDA_ARCHITECTURES` setting in the `Dockerfile.` and build it for yourself, alternatively, you can use the prebuilt image.

So, you have two options: pull the prebuilt image or build it yourself.

## Option 1: Pull Prebuilt Image (Recommended)

Pull the prebuilt image from Docker Hub:
```
$ sudo docker pull cslev/llamacpp-cuda-amd64:latest
```

## Option 2: Build From Source

Build the multi-stage Docker image locally. This process may take 20-30 minutes, similar to the native compilation time.
```
$ sudo docker build -t cslev/llamacpp-cuda-amd64:latest .
```


# Download Models

Create a Python environment and install the `huggingface-hub` library to download models. In this example, we'll use a small vision model to test both text generation and image understanding capabilities.

## Install Python Virtual Environment
```
$ python3 -m venv .venv
$ source .venv/bin/activate
$ pip install -U "huggingface_hub"
```

First, download the model (GGUF) file:
```
$ hf download ggml-org/Qwen2.5-VL-3B-Instruct-GGUF Qwen2.5-VL-3B-Instruct-Q8_0.gguf --local-dir ./models/
```

Then, download the mmproj file for image input:
```
$ hf download ggml-org/Qwen2.5-VL-3B-Instruct-GGUF   mmproj-Qwen2.5-VL-3B-Instruct-Q8_0.gguf --local-dir ./models/
```

# Configure models.ini

Edit the `models.ini` configuration file to register your downloaded models. This file maps each model to its associated files (including vision projectors for multimodal models).
```
$ nano models/models.ini
```
Then, modify and add new entries as per your requirements. Here, we just set up the model we just downloaded.
```
# Settings for Qwen2.5-VL
[Qwen2.5-VL-3B-instruct]
model = /models/Qwen2.5-VL-3B-Instruct-Q8_0.gguf
mmproj = /models/mmproj-Qwen2.5-VL-3B-Instruct-Q8_0.gguf
```

# Deploy

Use the provided `docker-compose.yml` file to deploy the llama.cpp container:
```
$ sudo docker-compose up
```

Once the stack is running, navigate to http://localhost:3000. You should see a fully-fledged llama.cpp instance with CUDA support running on your ARM64 system within an isolated Docker container.

<p align="center">
  <img src="assets/llamacpp_running.png" alt="llama.cpp running with CUDA">
</p>
