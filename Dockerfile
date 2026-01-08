# 1. Use the standard x86 devel image
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS build

RUN apt-get update && apt-get install -y \
    cmake \
    ccache \
    build-essential \
    libcurl4-openssl-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the llama.cpp repository
COPY llama.cpp/ .

# Correct CUDA stub location
RUN ln -s \
  /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so \
  /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so.1

ENV CUDAFLAGS="--use_fast_math"

# 2. Build with x86-specific CUDA architectures (e.g., 86 for RTX 30, 89 for RTX 40)
RUN rm -rf build && \
    cmake -B build \
    -DGGML_CUDA=ON \
    -DGGML_CUDA_F16=ON \
    -DGGML_SHARED_LIBS=ON \
    -DLLAMA_CURL=ON \
    -DLLAMA_FATAL_WARNINGS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CUDA_ARCHITECTURES="80;86;89;90;90a" \
    -DCMAKE_LIBRARY_PATH=/usr/local/cuda/targets/x86_64-linux/lib/stubs \
#    -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath-link=/usr/local/cuda/targets/x86_64-linux/lib/stubs" \
#    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-shlib-undefined" \
    . && \
    cmake --build build --config Release -j $(nproc)

# 3. Final Runtime Stage
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y \
    libcurl4 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the server AND the backend libraries (libggml-cuda.so, etc.)
COPY --from=build /app/build/bin/llama-server /app/
COPY --from=build /app/build/bin/*.so* /app/

RUN mkdir /models

# 4. Simplified paths (No more /compat needed for standard x86)
ENV LD_LIBRARY_PATH=/app:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

EXPOSE 8033
ENTRYPOINT ["/app/llama-server"]
