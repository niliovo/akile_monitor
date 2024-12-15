FROM golang:alpine AS gobuild
WORKDIR /build

RUN apk add git && \
git clone https://github.com/akile-network/akile_monitor && \
cd akile_monitor/client && \
go mod download && \
go mod tidy && \
go mod verify && \
go build

FROM alpine
WORKDIR /app

ENV AUTH_SECRET=${AUTH_SECRET:-auth_secret}
ENV URL=${URL:-ws://localhost:3000/monitor}
ENV NET_NAME=${NET_NAME:-eth0}
ENV NAME=${NAME:-HK-Akile}

COPY --from=gobuild /build/akile_monitor/client/client /app/ak_client

RUN cat <<'EOF' > entrypoint.sh
#!/bin/sh
if [ ! -f "client.json" ]; then
    echo "{
  \"auth_secret\": \"${AUTH_SECRET}\",
  \"url\": \"${URL}\",
  \"net_name\": \"${NET_NAME}\",
  \"name\": \"${NAME}\"
}"> client.json
fi
/app/ak_client
EOF

RUN chmod +x ak_client entrypoint.sh
CMD ["./entrypoint.sh"]
