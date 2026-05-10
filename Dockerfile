# ============================================================
# Kangaroo - Pollard's Kangaroo ECDLP Solver
# Bitcoin Puzzle Hunter - Docker Image
# ============================================================
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ── Dependencies ────────────────────────────────────────────
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

# ── Python packages for Telegram bot ────────────────────────
RUN pip3 install requests python-telegram-bot==13.15

# ── Clone & Build Kangaroo ───────────────────────────────────
WORKDIR /opt
RUN git clone https://github.com/JeanLucPons/Kangaroo.git
WORKDIR /opt/Kangaroo

# Build with CUDA GPU support (sm_86 = RTX 30xx/A100, adjust if needed)
RUN sed -i 's|/usr/local/cuda-8.0|/usr/local/cuda|g' Makefile && \
    sed -i 's|/usr/bin/g++-4.8|/usr/bin/g++|g' Makefile && \
    make gpu=1 ccap=86 CXXFLAGS="-DWITHGPU" -j$(nproc)

# ── Work directory ───────────────────────────────────────────
WORKDIR /workspace
RUN mkdir -p /workspace/results /workspace/logs

# ── Copy scripts ─────────────────────────────────────────────
COPY start.sh /workspace/start.sh
COPY notify.py /workspace/notify.py
RUN chmod +x /workspace/start.sh

# ── Entrypoint ───────────────────────────────────────────────
ENTRYPOINT ["/workspace/start.sh"]
