### 项目说明

该项目基于 nightinagle（夜莺）进行轻量化所得，使用 sqlite 替代 mysql， 使用 ledis 替代 redis 做到只依赖 prometheus （本想将 prometheus 也集成但能力不足）


### 如何编译
```bash
# 安装 statik
go install github.com/rakyll/statik@latest

# 复制前端编译成果
cp /node/fe/pub  /app/pub

go clean

# 执行 go generate 会调用 statik 集成前端
go generate -x cmd/center/main.go
# 编译
go build -ldflags "-linkmode external -extldflags '-static'"  -tags musl -o nightingale-lite cmd/center/main.go
```
项目使用了 statik 将前端静态文件打包以及加入路由。

### 如何运行
```bash
./nightingale-lite -c ../etc/config.toml 
```

### 如何配置
参考 `etc/config.toml`