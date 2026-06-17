# Delta Chat Desktop in Docker

A complete guide and configuration to run the Delta Chat desktop application within a Docker container as a web app.

## ⚠️ Important Warnings

* **Pre-Alpha Status:** The Delta Chat web-app code is currently in pre-alpha status.
* **Caveats Apply:** There are many limitations. Please see the [Delta Chat browser docs](https://github.com/deltachat/deltachat-desktop/tree/main/packages/target-browser) before relying on this setup.
* **Reverse Proxy Required:** You **must** put this container behind a reverse proxy (like Cosmos Cloud, Traefik, or Nginx) to access it securely over the internet.

> **Note:** The previous requirements for manual certificate generation, manual `.env` file mounting, and static `base_url.patch` modifications have been fully automated in this repository!

---

## 🔗 Useful Links

* [Delta Chat Desktop Source Code](https://github.com/deltachat/deltachat-desktop/tree/main)
* [Delta Chat Target Browser Source Code](https://github.com/deltachat/deltachat-desktop/tree/main/packages/target-browser)

---

## 🚀 Quick Start (Docker Compose)

The easiest way to run this project is using Docker Compose. The configuration below uses the automated, pre-built image from the GitHub Container Registry. It will dynamically handle host detection, generate required self-signed certificates, and provision your secure password.

### 1. Create `docker-compose.yml`

Create a file named `docker-compose.yml` with the following contents:

```yaml
services:
  deltachat:
    # Pulls the pre-built image automatically
    image: ghcr.io/tarbib/deltachat-desktop-web-docker:latest
    
    # To build from source locally, comment out the 'image' line above 
    # and uncomment the 'build' block below:
    # build:
    #   context: .
    #   dockerfile: Dockerfile
    
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
```

### 2. Start the Application
Pull the image and start the container in detached mode:
```shell
docker compose pull
docker compose up -d
```

### 3. Verify the Logs
Check the logs to ensure the service started successfully:
```shell
docker compose logs -f
```

---

## 🛡️ Reverse Proxy Requirements (Crucial)

Because Delta Chat has strict internal security rules, the application runs on **HTTPS using a self-signed certificate** generated during the container's startup process. 

If you are using a reverse proxy (like Cosmos Cloud, Nginx Proxy Manager, or Traefik) to provide a valid Let's Encrypt certificate to the outside world, you **must** configure your proxy with the following settings:

1. **Accept Insecure / Self-Signed Backend Certs:** You must tell your proxy to ignore certificate warnings when communicating with the Delta Chat container (e.g., enable "Disable Strict SSL" or "Insecure Skip Verify").
2. **Enable WebSockets:** Delta Chat requires WebSockets (`wss://`) for real-time messaging. Ensure your proxy routes WebSocket traffic correctly.
3. **Target URL:** Route your proxy to `https://<your-server-ip>:3000` (**Note:** You must use `https`, not `http`).

---

## 🚦 Traefik Configuration (Self-Hosting)

If you are using Traefik as your reverse proxy, you can dynamically configure it by adding these labels to your `docker-compose.yml` (under a `labels:` block inside the `deltachat` service). 

*Note: You will likely want to set up basic auth via Traefik as well for added security.*

```yaml
    labels:
      - "diun.enable=false"
      - "traefik.enable=true"
      - "traefik.http.routers.deltachat-desktop-user-1.tls"
      - "traefik.http.routers.deltachat-desktop-user-1.tls.certresolver=letsencrypt"
      - "traefik.http.routers.deltachat-desktop-user-1_insecure.entrypoints=web"
      - "traefik.http.routers.deltachat-desktop-user-1_insecure.rule=Host(`deltachat-desktop-user-1.domain.tld`)"
      - "traefik.http.routers.deltachat-desktop-user-1_insecure.middlewares=redirect@file"
      - "traefik.http.routers.deltachat-desktop-user-1.entrypoints=web-secure"
      - "traefik.http.routers.deltachat-desktop-user-1.rule=Host(`deltachat-desktop-user-1.domain.tld`)"
      - "traefik.http.services.deltachat-desktop-user-1.loadbalancer.server.port=3000"
      - "traefik.http.services.deltachat-desktop-user-1.loadbalancer.server.scheme=https"
```

**(Ensure you update `deltachat-desktop-user-1.domain.tld` to your actual domain).**

---

## 📄 Licensing

Unless otherwise stated, all source code is licensed under the [Apache 2 License](LICENSE-APACHE-2.0.txt).

Unless otherwise stated, the non-source code contents of this repository are licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](LICENSE-CC-Attribution-NonCommercial-ShareAlike-4.0-International.txt).
