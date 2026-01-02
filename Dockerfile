# 1. Use the standard x86 devel image
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04 AS build

RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    libcurl4-openssl-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the llama.cpp repository
COPY llama.cpp/ .

# 2. Build with x86-specific CUDA architectures (e.g., 86 for RTX 30, 89 for RTX 40)
RUN rm -rf build && \
    cmake -B build \
    -DGGML_CUDA=ON \
    -DLLAMA_CURL=ON \
    -DCMAKE_CUDA_ARCHITECTURES="80;86;89;90" \ 
    -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-shlib-undefined" \
    . && \
    cmake --build build --config Release -j $(nproc)

# 3. Final Runtime Stage
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y \
    libcurl4 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/build/bin/llama-server /app/llama-server
COPY --from=build /app/build/bin/*.so* /app/
RUN mkdir /models

# 4. Simplified paths (No more /compat needed for standard x86)
ENV LD_LIBRARY_PATH=/app:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

EXPOSE 8033
ENTRYPOINT ["/app/llama-server"]