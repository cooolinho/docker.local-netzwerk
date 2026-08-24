FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        cron \
        docker.io \
        mariadb-client \
        postgresql-client \
        zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/docker.local-netzwerk

CMD ["cron", "-f"]
