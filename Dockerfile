# ============================================================
# Kangaroo - Pollard's Kangaroo ECDLP Solver
# Bitcoin Puzzle Hunter - Docker Image
# ============================================================
FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# تحديد مسار CUDA للـ PATH
ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# — Dependencies ————————————————————————
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    g++ \
    libgmp-dev \
    python3 \
    python3-pip \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# — Python packages ————————————————————
RUN pip3 install requests

# — Clone Kangaroo (بدون بناء - يُبنى في startup script) ——
WORKDIR /opt
RUN git clone https://github.com/JeanLucPons/Kangaroo.git
WORKDIR /opt/Kangaroo

# تحضير الـ Makefile فقط بدون بناء
RUN sed -i 's|/usr/local/cuda-8.0|/usr/local/cuda|g' Makefile && \
    sed -i 's|/usr/bin/g++-4.8|/usr/bin/g++|g' Makefile

# — Work directory ————————————————————
WORKDIR /workspace
RUN mkdir -p /workspace/results /workspace/logs

# — Entrypoint ————————————————————————
CMD ["/bin/bash", "-c", "tail -f /dev/null"]
