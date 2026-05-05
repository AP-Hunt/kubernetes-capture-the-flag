FROM golang:1.24-alpine AS build
WORKDIR /src
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o /collector main.go

FROM scratch
COPY --from=build /collector /collector
USER 65534
ENTRYPOINT ["/collector"]
