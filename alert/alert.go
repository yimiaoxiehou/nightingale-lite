package alert

import (
	"context"
	"fmt"

	"nightingale-lite/alert/aconf"
	"nightingale-lite/alert/astats"
	"nightingale-lite/alert/dispatch"
	"nightingale-lite/alert/eval"
	"nightingale-lite/alert/naming"
	"nightingale-lite/alert/process"
	"nightingale-lite/alert/queue"
	"nightingale-lite/alert/record"
	"nightingale-lite/alert/router"
	"nightingale-lite/alert/sender"
	"nightingale-lite/conf"
	"nightingale-lite/dumper"
	"nightingale-lite/memsto"
	"nightingale-lite/models"
	"nightingale-lite/pkg/ctx"
	"nightingale-lite/pkg/httpx"
	"nightingale-lite/pkg/logx"
	"nightingale-lite/prom"
	"nightingale-lite/pushgw/pconf"
	"nightingale-lite/pushgw/writer"
)

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

	syncStats := memsto.NewSyncStats()
	alertStats := astats.NewSyncStats()

	targetCache := memsto.NewTargetCache(ctx, syncStats, nil)
	busiGroupCache := memsto.NewBusiGroupCache(ctx, syncStats)
	alertMuteCache := memsto.NewAlertMuteCache(ctx, syncStats)
	alertRuleCache := memsto.NewAlertRuleCache(ctx, syncStats)
	notifyConfigCache := memsto.NewNotifyConfigCache(ctx)
	dsCache := memsto.NewDatasourceCache(ctx, syncStats)
	userCache := memsto.NewUserCache(ctx, syncStats)
	userGroupCache := memsto.NewUserGroupCache(ctx, syncStats)

	promClients := prom.NewPromClient(ctx, config.Alert.Heartbeat)

	externalProcessors := process.NewExternalProcessors()

	Start(config.Alert, config.Pushgw, syncStats, alertStats, externalProcessors, targetCache, busiGroupCache, alertMuteCache, alertRuleCache, notifyConfigCache, dsCache, ctx, promClients, userCache, userGroupCache)

	r := httpx.GinEngine(config.Global.RunMode, config.HTTP)
	rt := router.New(config.HTTP, config.Alert, alertMuteCache, targetCache, busiGroupCache, alertStats, ctx, externalProcessors)
	rt.Config(r)
	dumper.ConfigRouter(r)

	httpClean := httpx.Init(config.HTTP, r)

	return func() {
		logxClean()
		httpClean()
	}, nil
}

func Start(alertc aconf.Alert, pushgwc pconf.Pushgw, syncStats *memsto.Stats, alertStats *astats.Stats, externalProcessors *process.ExternalProcessorsType, targetCache *memsto.TargetCacheType, busiGroupCache *memsto.BusiGroupCacheType,
	alertMuteCache *memsto.AlertMuteCacheType, alertRuleCache *memsto.AlertRuleCacheType, notifyConfigCache *memsto.NotifyConfigCacheType, datasourceCache *memsto.DatasourceCacheType, ctx *ctx.Context, promClients *prom.PromClientMap, userCache *memsto.UserCacheType, userGroupCache *memsto.UserGroupCacheType) {
	alertSubscribeCache := memsto.NewAlertSubscribeCache(ctx, syncStats)
	recordingRuleCache := memsto.NewRecordingRuleCache(ctx, syncStats)

	go models.InitNotifyConfig(ctx, alertc.Alerting.TemplatesDir)

	naming := naming.NewNaming(ctx, alertc.Heartbeat)

	writers := writer.NewWriters(pushgwc)
	record.NewScheduler(alertc, recordingRuleCache, promClients, writers, alertStats)

	eval.NewScheduler(alertc, externalProcessors, alertRuleCache, targetCache, busiGroupCache, alertMuteCache, datasourceCache, promClients, naming, ctx, alertStats)

	dp := dispatch.NewDispatch(alertRuleCache, userCache, userGroupCache, alertSubscribeCache, targetCache, notifyConfigCache, alertc.Alerting, ctx)
	consumer := dispatch.NewConsumer(alertc.Alerting, ctx, dp)

	go dp.ReloadTpls()
	go consumer.LoopConsume()

	go queue.ReportQueueSize(alertStats)
	go sender.StartEmailSender(notifyConfigCache.GetSMTP()) // todo
}
