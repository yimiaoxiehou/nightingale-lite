package center

import (
	"context"
	"fmt"
	"nightingale-lite/center/cconf"
	"nightingale-lite/conf"
	"nightingale-lite/models"
	"nightingale-lite/models/migrate"
	"nightingale-lite/pkg/ctx"
	"nightingale-lite/pkg/httpx"
	"nightingale-lite/pkg/logx"
	"nightingale-lite/prom"
	"nightingale-lite/pushgw/idents"
	"nightingale-lite/pushgw/writer"
	"nightingale-lite/storage"

	centerrt "nightingale-lite/center/router"
	"nightingale-lite/memsto"
	pushgwrt "nightingale-lite/pushgw/router"
)

func Initialize(configDir string, cryptoKey string) (func(), error) {
	config, err := conf.InitConfig(configDir, cryptoKey)
	if err != nil {
		return nil, fmt.Errorf("failed to init config: %v", err)
	}

	cconf.LoadMetricsYaml(configDir, config.Center.MetricsYamlFile)
	cconf.LoadOpsYaml(configDir, config.Center.OpsYamlFile)

	logxClean, err := logx.Init(config.Log)
	if err != nil {
		return nil, err
	}

	db, err := storage.New(config.DB)
	if err != nil {
		return nil, err
	}
	ctx := ctx.NewContext(context.Background(), db, true)
	models.InitRoot(ctx)
	migrate.Migrate(db)

	idents := idents.New(ctx)

	syncStats := memsto.NewSyncStats()

	busiGroupCache := memsto.NewBusiGroupCache(ctx, syncStats)
	targetCache := memsto.NewTargetCache(ctx, syncStats)
	dsCache := memsto.NewDatasourceCache(ctx, syncStats)
	notifyConfigCache := memsto.NewNotifyConfigCache(ctx)

	promClients := prom.NewPromClient(ctx, config.Alert.Heartbeat)
	writers := writer.NewWriters(config.Pushgw)

	httpx.InitRSAConfig(&config.HTTP.RSA)

	centerRouter := centerrt.New(config.HTTP, config.Center, cconf.Operations, dsCache, notifyConfigCache, promClients, ctx)
	pushgwRouter := pushgwrt.New(config.HTTP, config.Pushgw, targetCache, busiGroupCache, idents, writers, ctx)

	r := httpx.GinEngine(config.Global.RunMode, config.HTTP)

	pushgwRouter.Config(r)
	centerRouter.Config(r)

	httpClean := httpx.Init(config.HTTP, r)

	return func() {
		logxClean()
		httpClean()
	}, nil
}
