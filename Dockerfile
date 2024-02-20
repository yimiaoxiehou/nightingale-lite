FROM node:14.15.5-alpine3.13 as front
WORKDIR /node
RUN apk add git
RUN git clone https://github.com/yimiaoxiehou/fe.git
RUN cd fe && npm install && npm run build


FROM golang:1.20 as build
ENV GOPROXY=https://goproxy.cn,direct
WORKDIR /go/release
RUN go install github.com/rakyll/statik@latest
RUN GOPATH=$(go env GOPATH)          
RUN GOPATH=${GOPATH:-/home/runner/go}
ADD . .
COPY --from=front /node/fe/pub  /app/pub
RUN go clean
RUN go generate -x cmd/center/main.go
RUN go build -ldflags "-linkmode external -extldflags '-static'"  -tags musl -o nightingale-lite cmd/center/main.go


FROM scratch  as prod
WORKDIR /app
COPY --from=build /go/release/nightingale-lite  /app
COPY etc /app/etc
EXPOSE 17000
CMD ["/app/nightingale-lite", "-h"]
