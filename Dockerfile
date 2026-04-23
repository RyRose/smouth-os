# Stage 1: build the environment using Nix.
FROM nixos/nix:latest@sha256:e2fe74e96e965653c7b8f16ac64d1e56581c63c84d7fa07fb0692fd055cd06b0 AS builder

COPY . /tmp/build
WORKDIR /tmp/build

RUN nix \
    --extra-experimental-features "nix-command flakes" \
    --option filter-syscalls false \
    build

# Collect the full Nix store closure — every path our package needs and
# nothing more.
RUN mkdir /tmp/nix-store-closure
RUN cp -R $(nix-store -qR result/) /tmp/nix-store-closure

# Stage 2: minimal final image.
# debian:bookworm-slim provides /bin/sh so the image can be used as a CI
# container; all actual tooling comes from the Nix store closure.
FROM debian:bookworm-slim@sha256:f9c6a2fd2ddbc23e336b6257a5245e31f996953ef06cd13a59fa0a1df2d5c252

COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /tmp/build/result /env

ENV PATH=/env/bin:$PATH

WORKDIR /workspace
