FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN CGO_ENABLED=0 go build -o /order-api .

FROM alpine:3.20
RUN adduser -D -H appuser
USER appuser
COPY --from=build /order-api /order-api
EXPOSE 8080
ENTRYPOINT ["/order-api"]
