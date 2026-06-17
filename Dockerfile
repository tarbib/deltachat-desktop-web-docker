FROM rust:alpine AS certgen

RUN apk update && apk add build-base \
    && cargo install rustls-cert-gen \
    && rustls-cert-gen -o /opt/deltachat-certificate

FROM node:alpine

EXPOSE 3000

VOLUME /opt/deltachat-desktop/packages/target-browser/data

WORKDIR /opt/deltachat-desktop

# Replaced the curl script with 'npm install -g pnpm'
RUN apk update && apk add git curl \
    && npm install -g pnpm \
    && git clone https://github.com/deltachat/deltachat-desktop /opt/deltachat-desktop

WORKDIR /opt/deltachat-desktop/packages/target-browser

COPY --from=certgen /opt/deltachat-certificate/ /opt/deltachat-certificate/

RUN sed -i "s|'wss://localhost:3000/ws/dc'|\`wss://\${window.location.host}/ws/dc\`|g" runtime-browser/runtime.ts \
    && sed -i "s|'wss://localhost:3000/ws/backend'|\`wss://\${window.location.host}/ws/backend\`|g" runtime-browser/runtime.ts \
    && pnpm install \
    && pnpm build

CMD ["pnpm", "run", "start"]