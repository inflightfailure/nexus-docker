mkdir -p traefik/certs
# shellcheck disable=SC2181,SC2155,SC2086,SC1090,SC2046,SC2164,SC2103,SC3043

openssl req -x509 -nodes -days 3650 \
  -newkey rsa:4096 \
  -keyout traefik/certs/nexus.example.com.key \
  -out traefik/certs/nexus.example.com.crt \
  -subj "/CN=nexus.example.com"

openssl req -x509 -nodes -days 3650 \
  -newkey rsa:4096 \
  -keyout traefik/certs/registry.example.com.key \
  -out traefik/certs/registry.example.com.crt \
  -subj "/CN=registry.example.com"
