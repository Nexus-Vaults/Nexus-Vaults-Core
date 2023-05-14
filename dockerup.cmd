docker build . -t nexus-vaults-core
docker compose up -d
docker compose exec dev bash