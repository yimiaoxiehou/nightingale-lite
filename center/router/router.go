package router

import (
	"embed"
	"fmt"
	"github.com/ledisdb/ledisdb/ledis"
	"github.com/rakyll/statik/fs"
	"github.com/toolkits/pkg/logger"
	"net/http"
	"path"
	"runtime"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toolkits/pkg/runner"
	"nightingale-lite/center/cconf"
	"nightingale-lite/center/cstats"
	_ "nightingale-lite/front/statik"
	"nightingale-lite/memsto"
	"nightingale-lite/pkg/aop"
	"nightingale-lite/pkg/ctx"
	"nightingale-lite/pkg/httpx"
	"nightingale-lite/prom"
	"nightingale-lite/pushgw/idents"
)

type Router struct {
	HTTP              httpx.Config
	Center            cconf.Center
	Operations        cconf.Operation
	DatasourceCache   *memsto.DatasourceCacheType
	NotifyConfigCache *memsto.NotifyConfigCacheType
	PromClients       *prom.PromClientMap
	Redis             *ledis.DB
	IdentSet          *idents.Set
	Ctx               *ctx.Context
}

func New(httpConfig httpx.Config, center cconf.Center, operations cconf.Operation, ds *memsto.DatasourceCacheType, ncc *memsto.NotifyConfigCacheType,
	pc *prom.PromClientMap, ctx *ctx.Context) *Router {
	return &Router{
		HTTP:              httpConfig,
		Center:            center,
		Operations:        operations,
		DatasourceCache:   ds,
		NotifyConfigCache: ncc,
		PromClients:       pc,
		Ctx:               ctx,
	}
}

func stat() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()

		code := fmt.Sprintf("%d", c.Writer.Status())
		method := c.Request.Method
		labels := []string{cstats.Service, code, c.FullPath(), method}

		cstats.RequestCounter.WithLabelValues(labels...).Inc()
		cstats.RequestDuration.WithLabelValues(labels...).Observe(float64(time.Since(start).Seconds()))
	}
}

func languageDetector(i18NHeaderKey string) gin.HandlerFunc {
	headerKey := i18NHeaderKey
	return func(c *gin.Context) {
		if headerKey != "" {
			lang := c.GetHeader(headerKey)
			if lang != "" {
				if strings.HasPrefix(lang, "zh") {
					c.Request.Header.Set("X-Language", "zh")
				} else if strings.HasPrefix(lang, "en") {
					c.Request.Header.Set("X-Language", "en")
				} else {
					c.Request.Header.Set("X-Language", lang)
				}
			} else {
				c.Request.Header.Set("X-Language", "en")
			}
		}
		c.Next()
	}
}

func (rt *Router) configNoRoute(r *gin.Engine, fs *http.FileSystem) {
	r.NoRoute(func(c *gin.Context) {
		arr := strings.Split(c.Request.URL.Path, ".")
		suffix := arr[len(arr)-1]

		switch suffix {
		case "png", "jpeg", "jpg", "svg", "ico", "gif", "css", "js", "html", "htm", "gz", "zip", "map":
			if !rt.Center.UseFileAssets {
				c.FileFromFS(c.Request.URL.Path, *fs)
			} else {
				cwdarr := []string{"/"}
				if runtime.GOOS == "windows" {
					cwdarr[0] = ""
				}
				cwdarr = append(cwdarr, strings.Split(runner.Cwd, "/")...)
				cwdarr = append(cwdarr, "pub")
				cwdarr = append(cwdarr, strings.Split(c.Request.URL.Path, "/")...)
				c.File(path.Join(cwdarr...))
			}
		default:
			if !rt.Center.UseFileAssets {
				c.FileFromFS("/", *fs)
			} else {
				cwdarr := []string{"/"}
				if runtime.GOOS == "windows" {
					cwdarr[0] = ""
				}
				cwdarr = append(cwdarr, strings.Split(runner.Cwd, "/")...)
				cwdarr = append(cwdarr, "pub")
				cwdarr = append(cwdarr, "index.html")
				c.File(path.Join(cwdarr...))
			}
		}
	})
}

var f embed.FS

func (rt *Router) Config(r *gin.Engine) {

	r.Use(stat())
	r.Use(languageDetector(rt.Center.I18NHeaderKey))
	r.Use(aop.Recovery())

	pagesPrefix := "/api/n9e"
	pages := r.Group(pagesPrefix)
	{

		if rt.Center.AnonymousAccess.PromQuerier {
			pages.Any("/proxy/:id/*url", rt.dsProxy)
			pages.POST("/query-range-batch", rt.promBatchQueryRange)
			pages.POST("/query-instant-batch", rt.promBatchQueryInstant)
			pages.GET("/datasource/brief", rt.datasourceBriefs)
		} else {
			pages.Any("/proxy/:id/*url", rt.auth(), rt.dsProxy)
			pages.POST("/query-range-batch", rt.auth(), rt.promBatchQueryRange)
			pages.POST("/query-instant-batch", rt.auth(), rt.promBatchQueryInstant)
			pages.GET("/datasource/brief", rt.auth(), rt.datasourceBriefs)
		}

		pages.GET("/metrics/desc", rt.metricsDescGetFile)
		pages.POST("/metrics/desc", rt.metricsDescGetMap)

		pages.GET("/notify-channels", rt.notifyChannelsGets)
		pages.GET("/contact-keys", rt.contactKeysGets)

		pages.GET("/metric-views", rt.auth(), rt.metricViewGets)
		pages.DELETE("/metric-views", rt.auth(), rt.user(), rt.metricViewDel)
		pages.POST("/metric-views", rt.auth(), rt.user(), rt.metricViewAdd)
		pages.PUT("/metric-views", rt.auth(), rt.user(), rt.metricViewPut)

		pages.GET("/busi-groups", rt.auth(), rt.user(), rt.busiGroupGets)
		pages.POST("/busi-groups", rt.auth(), rt.user(), rt.perm("/busi-groups/add"), rt.busiGroupAdd)
		pages.GET("/busi-groups/alertings", rt.auth(), rt.busiGroupAlertingsGets)
		pages.GET("/busi-group/:id", rt.auth(), rt.user(), rt.bgro(), rt.busiGroupGet)
		pages.PUT("/busi-group/:id", rt.auth(), rt.user(), rt.perm("/busi-groups/put"), rt.bgrw(), rt.busiGroupPut)
		pages.POST("/busi-group/:id/members", rt.auth(), rt.user(), rt.perm("/busi-groups/put"), rt.bgrw(), rt.busiGroupMemberAdd)
		pages.DELETE("/busi-group/:id/members", rt.auth(), rt.user(), rt.perm("/busi-groups/put"), rt.bgrw(), rt.busiGroupMemberDel)
		pages.DELETE("/busi-group/:id", rt.auth(), rt.user(), rt.perm("/busi-groups/del"), rt.bgrw(), rt.busiGroupDel)
		pages.GET("/busi-group/:id/perm/:perm", rt.auth(), rt.user(), rt.checkBusiGroupPerm)

		pages.GET("/builtin-boards", rt.builtinBoardGets)
		pages.GET("/builtin-board/:name", rt.builtinBoardGet)
		pages.GET("/dashboards/builtin/list", rt.builtinBoardGets)
		pages.GET("/builtin-boards-cates", rt.auth(), rt.user(), rt.builtinBoardCateGets)
		pages.POST("/builtin-boards-detail", rt.auth(), rt.user(), rt.builtinBoardDetailGets)
		pages.GET("/integrations/icon/:cate/:name", rt.builtinIcon)

		pages.GET("/busi-group/:id/boards", rt.auth(), rt.user(), rt.perm("/dashboards"), rt.bgro(), rt.boardGets)
		pages.POST("/busi-group/:id/boards", rt.auth(), rt.user(), rt.perm("/dashboards/add"), rt.bgrw(), rt.boardAdd)
		pages.POST("/busi-group/:id/board/:bid/clone", rt.auth(), rt.user(), rt.perm("/dashboards/add"), rt.bgrw(), rt.boardClone)

		pages.GET("/board/:bid", rt.boardGet)
		pages.GET("/board/:bid/pure", rt.boardPureGet)
		pages.PUT("/board/:bid", rt.auth(), rt.user(), rt.perm("/dashboards/put"), rt.boardPut)
		pages.PUT("/board/:bid/configs", rt.auth(), rt.user(), rt.perm("/dashboards/put"), rt.boardPutConfigs)
		pages.PUT("/board/:bid/public", rt.auth(), rt.user(), rt.perm("/dashboards/put"), rt.boardPutPublic)
		pages.DELETE("/boards", rt.auth(), rt.user(), rt.perm("/dashboards/del"), rt.boardDel)

		pages.GET("/share-charts", rt.chartShareGets)
		pages.POST("/share-charts", rt.auth(), rt.chartShareAdd)

		pages.GET("/alert-rules/builtin/alerts-cates", rt.auth(), rt.user(), rt.builtinAlertCateGets)
		pages.GET("/alert-rules/builtin/list", rt.auth(), rt.user(), rt.builtinAlertRules)

		pages.GET("/busi-group/:id/alert-rules", rt.auth(), rt.user(), rt.perm("/alert-rules"), rt.alertRuleGets)
		pages.POST("/busi-group/:id/alert-rules", rt.auth(), rt.user(), rt.perm("/alert-rules/add"), rt.bgrw(), rt.alertRuleAddByFE)
		pages.POST("/busi-group/:id/alert-rules/import", rt.auth(), rt.user(), rt.perm("/alert-rules/add"), rt.bgrw(), rt.alertRuleAddByImport)
		pages.DELETE("/busi-group/:id/alert-rules", rt.auth(), rt.user(), rt.perm("/alert-rules/del"), rt.bgrw(), rt.alertRuleDel)
		pages.PUT("/busi-group/:id/alert-rules/fields", rt.auth(), rt.user(), rt.perm("/alert-rules/put"), rt.bgrw(), rt.alertRulePutFields)
		pages.PUT("/busi-group/:id/alert-rule/:arid", rt.auth(), rt.user(), rt.perm("/alert-rules/put"), rt.alertRulePutByFE)
		pages.GET("/alert-rule/:arid", rt.auth(), rt.user(), rt.perm("/alert-rules"), rt.alertRuleGet)

		pages.GET("/busi-group/:id/recording-rules", rt.auth(), rt.user(), rt.perm("/recording-rules"), rt.recordingRuleGets)
		pages.POST("/busi-group/:id/recording-rules", rt.auth(), rt.user(), rt.perm("/recording-rules/add"), rt.bgrw(), rt.recordingRuleAddByFE)
		pages.DELETE("/busi-group/:id/recording-rules", rt.auth(), rt.user(), rt.perm("/recording-rules/del"), rt.bgrw(), rt.recordingRuleDel)
		pages.PUT("/busi-group/:id/recording-rule/:rrid", rt.auth(), rt.user(), rt.perm("/recording-rules/put"), rt.bgrw(), rt.recordingRulePutByFE)
		pages.GET("/recording-rule/:rrid", rt.auth(), rt.user(), rt.perm("/recording-rules"), rt.recordingRuleGet)
		pages.PUT("/busi-group/:id/recording-rules/fields", rt.auth(), rt.user(), rt.perm("/recording-rules/put"), rt.recordingRulePutFields)

		pages.GET("/busi-group/:id/alert-mutes", rt.auth(), rt.user(), rt.perm("/alert-mutes"), rt.bgro(), rt.alertMuteGetsByBG)
		pages.POST("/busi-group/:id/alert-mutes", rt.auth(), rt.user(), rt.perm("/alert-mutes/add"), rt.bgrw(), rt.alertMuteAdd)
		pages.DELETE("/busi-group/:id/alert-mutes", rt.auth(), rt.user(), rt.perm("/alert-mutes/del"), rt.bgrw(), rt.alertMuteDel)
		pages.PUT("/busi-group/:id/alert-mute/:amid", rt.auth(), rt.user(), rt.perm("/alert-mutes/put"), rt.alertMutePutByFE)
		pages.PUT("/busi-group/:id/alert-mutes/fields", rt.auth(), rt.user(), rt.perm("/alert-mutes/put"), rt.bgrw(), rt.alertMutePutFields)

		pages.GET("/busi-group/:id/alert-subscribes", rt.auth(), rt.user(), rt.perm("/alert-subscribes"), rt.bgro(), rt.alertSubscribeGets)
		pages.GET("/alert-subscribe/:sid", rt.auth(), rt.user(), rt.perm("/alert-subscribes"), rt.alertSubscribeGet)
		pages.POST("/busi-group/:id/alert-subscribes", rt.auth(), rt.user(), rt.perm("/alert-subscribes/add"), rt.bgrw(), rt.alertSubscribeAdd)
		pages.PUT("/busi-group/:id/alert-subscribes", rt.auth(), rt.user(), rt.perm("/alert-subscribes/put"), rt.bgrw(), rt.alertSubscribePut)
		pages.DELETE("/busi-group/:id/alert-subscribes", rt.auth(), rt.user(), rt.perm("/alert-subscribes/del"), rt.bgrw(), rt.alertSubscribeDel)

		if rt.Center.AnonymousAccess.AlertDetail {
			pages.GET("/alert-cur-event/:eid", rt.alertCurEventGet)
			pages.GET("/alert-his-event/:eid", rt.alertHisEventGet)
		} else {
			pages.GET("/alert-cur-event/:eid", rt.auth(), rt.alertCurEventGet)
			pages.GET("/alert-his-event/:eid", rt.auth(), rt.alertHisEventGet)
		}

		// card logic
		pages.GET("/alert-cur-events/list", rt.auth(), rt.alertCurEventsList)
		pages.GET("/alert-cur-events/card", rt.auth(), rt.alertCurEventsCard)
		pages.POST("/alert-cur-events/card/details", rt.auth(), rt.alertCurEventsCardDetails)
		pages.GET("/alert-his-events/list", rt.auth(), rt.alertHisEventsList)
		pages.DELETE("/alert-cur-events", rt.auth(), rt.user(), rt.perm("/alert-cur-events/del"), rt.alertCurEventDel)

		pages.GET("/alert-aggr-views", rt.auth(), rt.alertAggrViewGets)
		pages.DELETE("/alert-aggr-views", rt.auth(), rt.user(), rt.alertAggrViewDel)
		pages.POST("/alert-aggr-views", rt.auth(), rt.user(), rt.alertAggrViewAdd)
		pages.PUT("/alert-aggr-views", rt.auth(), rt.user(), rt.alertAggrViewPut)

		pages.GET("/self/profile", rt.auth(), rt.user(), rt.selfProfileGet)
		pages.PUT("/self/profile", rt.auth(), rt.user(), rt.selfProfilePut)
		pages.PUT("/self/password", rt.auth(), rt.user(), rt.selfPasswordPut)

		pages.GET("/busi-group/:id/task-tpls", rt.auth(), rt.user(), rt.perm("/job-tpls"), rt.bgro(), rt.taskTplGets)
		pages.POST("/busi-group/:id/task-tpls", rt.auth(), rt.user(), rt.perm("/job-tpls/add"), rt.bgrw(), rt.taskTplAdd)
		pages.DELETE("/busi-group/:id/task-tpl/:tid", rt.auth(), rt.user(), rt.perm("/job-tpls/del"), rt.bgrw(), rt.taskTplDel)
		pages.POST("/busi-group/:id/task-tpls/tags", rt.auth(), rt.user(), rt.perm("/job-tpls/put"), rt.bgrw(), rt.taskTplBindTags)
		pages.DELETE("/busi-group/:id/task-tpls/tags", rt.auth(), rt.user(), rt.perm("/job-tpls/put"), rt.bgrw(), rt.taskTplUnbindTags)
		pages.GET("/busi-group/:id/task-tpl/:tid", rt.auth(), rt.user(), rt.perm("/job-tpls"), rt.bgro(), rt.taskTplGet)
		pages.PUT("/busi-group/:id/task-tpl/:tid", rt.auth(), rt.user(), rt.perm("/job-tpls/put"), rt.bgrw(), rt.taskTplPut)

		pages.GET("/busi-group/:id/tasks", rt.auth(), rt.user(), rt.perm("/job-tasks"), rt.bgro(), rt.taskGets)
		pages.POST("/busi-group/:id/tasks", rt.auth(), rt.user(), rt.perm("/job-tasks/add"), rt.bgrw(), rt.taskAdd)
		pages.GET("/busi-group/:id/task/*url", rt.auth(), rt.user(), rt.perm("/job-tasks"), rt.taskProxy)
		pages.PUT("/busi-group/:id/task/*url", rt.auth(), rt.user(), rt.perm("/job-tasks/put"), rt.bgrw(), rt.taskProxy)

		pages.GET("/servers", rt.auth(), rt.admin(), rt.serversGet)
		pages.GET("/server-clusters", rt.auth(), rt.admin(), rt.serverClustersGet)

		pages.POST("/datasource/list", rt.auth(), rt.datasourceList)
		pages.POST("/datasource/plugin/list", rt.auth(), rt.pluginList)
		pages.POST("/datasource/upsert", rt.auth(), rt.admin(), rt.datasourceUpsert)
		pages.POST("/datasource/desc", rt.auth(), rt.admin(), rt.datasourceGet)
		pages.POST("/datasource/status/update", rt.auth(), rt.admin(), rt.datasourceUpdataStatus)
		pages.DELETE("/datasource/", rt.auth(), rt.admin(), rt.datasourceDel)

	}

	if rt.HTTP.APIForService.Enable {
		service := r.Group("/v1/n9e")
		if len(rt.HTTP.APIForService.BasicAuth) > 0 {
			service.Use(gin.BasicAuth(rt.HTTP.APIForService.BasicAuth))
		}
		{
			service.Any("/prometheus/*url", rt.dsProxy)

			service.GET("/user-groups", rt.userGroupGetsByService)
			service.GET("/user-group-members", rt.userGroupMemberGetsByService)

			service.POST("/alert-rules", rt.alertRuleAddByService)
			service.DELETE("/alert-rules", rt.alertRuleDelByService)
			service.PUT("/alert-rule/:arid", rt.alertRulePutByService)
			service.GET("/alert-rule/:arid", rt.alertRuleGet)
			service.GET("/alert-rules", rt.alertRulesGetByService)

			service.GET("/alert-subscribes", rt.alertSubscribeGetsByService)

			service.GET("/busi-groups", rt.busiGroupGetsByService)

			service.GET("/datasources", rt.datasourceGetsByService)
			service.GET("/datasource-ids", rt.getDatasourceIds)
			service.POST("/server-heartbeat", rt.serverHeartbeat)
			service.GET("/servers-active", rt.serversActive)

			service.GET("/recording-rules", rt.recordingRuleGetsByService)

			service.GET("/alert-mutes", rt.alertMuteGets)
			service.POST("/alert-mutes", rt.alertMuteAddByService)
			service.DELETE("/alert-mutes", rt.alertMuteDel)

			service.GET("/alert-cur-events", rt.alertCurEventsList)
			service.GET("/alert-cur-events-get-by-rid", rt.alertCurEventsGetByRid)
			service.GET("/alert-his-events", rt.alertHisEventsList)
			service.GET("/alert-his-event/:eid", rt.alertHisEventGet)

			service.GET("/config/:id", rt.configGet)
			service.GET("/configs", rt.configsGet)
			service.GET("/config", rt.configGetByKey)
			service.PUT("/configs", rt.configsPut)
			service.POST("/configs", rt.configsPost)
			service.DELETE("/configs", rt.configsDel)

			service.POST("/conf-prop/encrypt", rt.confPropEncrypt)
			service.POST("/conf-prop/decrypt", rt.confPropDecrypt)

			service.GET("/statistic", rt.statistic)

			service.POST("/task-record-add", rt.taskRecordAdd)
		}
	}
	if rt.HTTP.APIForAgent.Enable {
		heartbeat := r.Group("/v1/n9e")
		{
			if len(rt.HTTP.APIForAgent.BasicAuth) > 0 {
				heartbeat.Use(gin.BasicAuth(rt.HTTP.APIForAgent.BasicAuth))
			}
			heartbeat.POST("/heartbeat", rt.heartbeat)
		}
	}

	statikFS, err := fs.New()
	if err != nil {
		logger.Errorf("cannot create statik fs: %v", err)
	}

	rt.configNoRoute(r, &statikFS)

}

func Render(c *gin.Context, data, msg interface{}) {
	if msg == nil {
		if data == nil {
			data = struct{}{}
		}
		c.JSON(http.StatusOK, gin.H{"data": data, "error": ""})
	} else {
		c.JSON(http.StatusOK, gin.H{"error": gin.H{"message": msg}})
	}
}

func Dangerous(c *gin.Context, v interface{}, code ...int) {
	if v == nil {
		return
	}

	switch t := v.(type) {
	case string:
		if t != "" {
			c.JSON(http.StatusOK, gin.H{"error": v})
		}
	case error:
		c.JSON(http.StatusOK, gin.H{"error": t.Error()})
	}
}
