package pushgw

import (
	"context"
	"fmt"

	"nightingale-lite/conf"
	"nightingale-lite/memsto"
	"nightingale-lite/pkg/ctx"
	"nightingale-lite/pkg/httpx"
	"nightingale-lite/pkg/logx"
	"nightingale-lite/pushgw/idents"
	"nightingale-lite/pushgw/router"
	"nightingale-lite/pushgw/writer"
)

type PushgwProvider struct {
	Ident  *idents.Set
	Router *router.Router
}

func Initialize(configDir string, cryptoKey string) (func(), error) {
	config, err := conf.InitConfig(configDir, cryptoKey)
	if err != nil {
		return nil, fmt.Errorf("failed to init config: %v", err)
	}

	logxClean, err := logx.Init(config.Log)
	if err != nil {
		return nil, err
	}

	ctx := ctx.NewContext(context.Background(), nil, false, config.CenterApi)

	idents := idents.New(ctx)

	stats := memsto.NewSyncStats()

	busiGroupCache := memsto.NewBusiGroupCache(ctx, stats)
	targetCache := memsto.NewTargetCache(ctx, stats)

	writers := writer.NewWriters(config.Pushgw)

	r := httpx.GinEngine(config.Global.RunMode, config.HTTP)
	rt := router.New(config.HTTP, config.Pushgw, targetCache, busiGroupCache, idents, writers, ctx)
	rt.Config(r)

	httpClean := httpx.Init(config.HTTP, r)

	return func() {
		logxClean()
		httpClean()
	}, nil
}
