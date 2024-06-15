# syntax = docker/dockerfile:1.2
# Base image containing all binaries, deployed to ghcr.io/blockworks-foundation/mango-v4:latest
FROM rust:1.69.0-bullseye as base
RUN rustup component add rustfmt
RUN apt-get update && apt-get -y install clang cmake
WORKDIR /app

FROM base as plan
COPY . .

FROM base as build
COPY . .
RUN cargo build --release --bins

FROM debian:bullseye-slim as run
RUN apt-get update && apt-get -y install ca-certificates libc6
ENV NODE_VERSION=16.13.0
RUN apt install -y curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version
COPY --from=build /app/target/release/keeper /usr/local/bin/
COPY --from=build /app/target/release/liquidator /usr/local/bin/
COPY --from=build /app/target/release/settler /usr/local/bin/

COPY --from=build /app/target/release/service-mango-* /usr/local/bin/
COPY --from=build /app/bin/service-mango-pnl/conf/template-config.toml ./pnl-config.toml
COPY --from=build /app/bin/service-mango-fills/conf/template-config.toml ./fills-config.toml
COPY --from=build /app/bin/service-mango-orderbook/conf/template-config.toml ./orderbook-config.toml

COPY --from=build /app/bin/service-mango-pnl/conf/template-config.toml ./pnl-config.toml
COPY --from=build /app/bin/service-mango-fills/conf//template-config.toml ./fills-config.toml
COPY --from=build /app/bin/service-mango-orderbook/conf/template-config.toml ./orderbook-config.toml

RUN adduser --system --group --no-create-home mangouser
USER mangouser
