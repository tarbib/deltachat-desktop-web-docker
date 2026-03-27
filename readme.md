# delta.chat desktop in docker container

rough info / example on how to run delta.chat desktop within docker as a web app

## dire warnings

- the delta code is pre-alpha status
- there are many caveats, see the delta chat docs before attempting to run the desktop app as a web app within docker
- WARNING: You must put this container behind a reverse proxy (like Cosmos Cloud, Traefik, or Nginx) to access it securely over the internet.

*Note: The previous requirements for manual certificate generation, manual `.env` file mounting, and static `base_url.patch` modifications have been fully automated in this repository!*

## links

- https://github.com/deltachat/deltachat-desktop/tree/main
- https://github.com/deltachat/deltachat-desktop/tree/main/packages/target-browser

## Quick Start (Docker Compose)

The easiest way to run this project is using Docker Compose. The configuration below will automatically build the web app with dynamic host detection, generate the required self-signed certificates, and provision a secure password.

1. Create a `docker-compose.yml` file with the following contents:

\`\`\`yaml
services:
  deltachat:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: deltachat-web
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      # CHANGE THIS: Set your secure web login password here
      - WEB_PASSWORD=your_secure_password_here
    volumes:
      # Uses a Docker managed named volume instead of a bind mount
      - deltachat_data:/opt/deltachat-desktop/packages/target-browser/data
    
    # 1. Writes the env variable to the required .env file
    # 2. Makes sure the certificate folder exists in the volume
    # 3. Copies the certificates safely
    # 4. Starts the app
    command: >
      sh -c "echo \"WEB_PASSWORD=$$WEB_PASSWORD\" > .env &&
             mkdir -p data/certificate && 
             cp -rn /opt/deltachat-certificate/* data/certificate/ && 
             pnpm run start"

volumes:
  deltachat_data:
\`\`\`

2. Build and start the container:
\`\`\`shell
docker compose up -d --build
\`\`\`

3. Check the logs to ensure it started successfully:
\`\`\`shell
docker compose logs -f
\`\`\`

## Reverse Proxy Requirements (Crucial)

Because Delta Chat has strict internal security rules, the application runs on **HTTPS using a self-signed certificate** generated during the build process. 

If you are using a reverse proxy (like Cosmos Cloud, Nginx Proxy Manager, or Traefik) to provide a valid Let's Encrypt certificate to the outside world, you **must** configure your proxy with the following settings:

1. **Accept Insecure / Self-Signed Backend Certs:** You must tell your proxy to ignore certificate warnings when communicating with the Delta Chat container (e.g., "Disable Strict SSL" or "Insecure Skip Verify").
2. **Enable WebSockets:** Delta Chat requires WebSockets (`wss://`) for real-time messaging. Ensure your proxy routes WebSocket traffic correctly.
3. **Target URL:** Route your proxy to `https://<your-server-ip>:3000` (NOTE the HTTPS).

## docker labels for self-hosting with traefik

note: you likely want to setup basic auth via traffic too

If you are using Traefik, you can add these labels to your `docker-compose.yml` (under a `labels:` block inside the `deltachat` service):

\`\`\`yaml
    - "diun.enable=false"
    - "traefik.enable=true"
    - "traefik.http.routers.deltachat-desktop-user-1.tls"
    - "traefik.http.routers.deltachat-desktop-user-1.tls.certresolver=letsencrypt"
    - "traefik.http.routers.deltachat-desktop-user-1_insecure.entrypoints=web"
    - "traefik.http.routers.deltachat-desktop-user-1_insecure.rule=Host(\`deltachat-desktop-user-1.domain.tld\`)"
    - "traefik.http.routers.deltachat-desktop-user-1_insecure.middlewares=redirect@file"
    - "traefik.http.routers.deltachat-desktop-user-1.entrypoints=web-secure"
    - "traefik.http.routers.deltachat-desktop-user-1.rule=Host(\`deltachat-desktop-user-1.domain.tld\`)"
    - "traefik.http.services.deltachat-desktop-user-1.loadbalancer.server.port=3000"
    - "traefik.http.services.deltachat-desktop-user-1.loadbalancer.server.scheme=https"
\`\`\`

*(Note: Ensure you update `deltachat-desktop-user-1.domain.tld` to your actual domain).*

## Licensing

Unless otherwise stated all source code is licensed under the [Apache 2 License](LICENSE-APACHE-2.0.txt).

Unless otherwise stated the non source code contents of this repository are licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](LICENSE-CC-Attribution-NonCommercial-ShareAlike-4.0-International.txt).