package memsto

import (
	"log"
	"math"
	"sync"
	"time"

	"github.com/pkg/errors"
	"github.com/toolkits/pkg/logger"
	"nightingale-lite/dumper"
	"nightingale-lite/models"
	"nightingale-lite/pkg/ctx"
)

// 1. append note to alert_event
// 2. append tags to series
type TargetCacheType struct {
	statTotal       int64
	statLastUpdated int64
	ctx             *ctx.Context
	stats           *Stats

	sync.RWMutex
	targets map[string]*models.Target // key: ident
}

func NewTargetCache(ctx *ctx.Context, stats *Stats) *TargetCacheType {
	tc := &TargetCacheType{
		statTotal:       -1,
		statLastUpdated: -1,
		ctx:             ctx,
		stats:           stats,
		targets:         make(map[string]*models.Target),
	}

	tc.SyncTargets()
	return tc
}

func (tc *TargetCacheType) Reset() {
	tc.Lock()
	defer tc.Unlock()

	tc.statTotal = -1
	tc.statLastUpdated = -1
	tc.targets = make(map[string]*models.Target)
}

func (tc *TargetCacheType) StatChanged(total, lastUpdated int64) bool {
	if tc.statTotal == total && tc.statLastUpdated == lastUpdated {
		return false
	}

	return true
}

func (tc *TargetCacheType) Set(m map[string]*models.Target, total, lastUpdated int64) {
	tc.Lock()
	tc.targets = m
	tc.Unlock()

	// only one goroutine used, so no need lock
	tc.statTotal = total
	tc.statLastUpdated = lastUpdated
}

func (tc *TargetCacheType) Get(ident string) (*models.Target, bool) {
	tc.RLock()
	defer tc.RUnlock()
	val, has := tc.targets[ident]
	return val, has
}

func (tc *TargetCacheType) GetOffsetHost(targets []*models.Target, now, offset int64) map[string]int64 {
	tc.RLock()
	defer tc.RUnlock()
	hostOffset := make(map[string]int64)
	for _, target := range targets {
		target, exists := tc.targets[target.Ident]
		if !exists {
			continue
		}

		if target.CpuNum <= 0 {
			// means this target is not collect by categraf, do not check offset
			continue
		}

		if now-target.UpdateAt > 120 {
			// means this target is not a active host, do not check offset
			continue
		}

		if int64(math.Abs(float64(target.Offset))) > offset {
			hostOffset[target.Ident] = target.Offset
		}
	}

	return hostOffset
}

func (tc *TargetCacheType) SyncTargets() {
	err := tc.syncTargets()
	if err != nil {
		log.Fatalln("failed to sync targets:", err)
	}

	go tc.loopSyncTargets()
}

func (tc *TargetCacheType) loopSyncTargets() {
	duration := time.Duration(9000) * time.Millisecond
	for {
		time.Sleep(duration)
		if err := tc.syncTargets(); err != nil {
			logger.Warning("failed to sync targets:", err)
		}
	}
}

func (tc *TargetCacheType) syncTargets() error {
	start := time.Now()

	stat, err := models.TargetStatistics(tc.ctx)
	if err != nil {
		dumper.PutSyncRecord("targets", start.Unix(), -1, -1, "failed to query statistics: "+err.Error())
		return errors.WithMessage(err, "failed to call TargetStatistics")
	}

	if !tc.StatChanged(stat.Total, stat.LastUpdated) {
		tc.stats.GaugeCronDuration.WithLabelValues("sync_targets").Set(0)
		tc.stats.GaugeSyncNumber.WithLabelValues("sync_targets").Set(0)
		dumper.PutSyncRecord("targets", start.Unix(), -1, -1, "not changed")
		return nil
	}

	lst, err := models.TargetGetsAll(tc.ctx)
	if err != nil {
		dumper.PutSyncRecord("targets", start.Unix(), -1, -1, "failed to query records: "+err.Error())
		return errors.WithMessage(err, "failed to call TargetGetsAll")
	}

	m := make(map[string]*models.Target)
	if tc.ctx.IsCenter {
		metaMap := tc.GetHostMetas(lst)
		for i := 0; i < len(lst); i++ {
			if meta, ok := metaMap[lst[i].Ident]; ok {
				lst[i].FillMeta(meta)
			}
		}
	}

	for i := 0; i < len(lst); i++ {
		m[lst[i].Ident] = lst[i]
	}

	tc.Set(m, stat.Total, stat.LastUpdated)

	ms := time.Since(start).Milliseconds()
	tc.stats.GaugeCronDuration.WithLabelValues("sync_targets").Set(float64(ms))
	tc.stats.GaugeSyncNumber.WithLabelValues("sync_targets").Set(float64(len(lst)))
	logger.Infof("timer: sync targets done, cost: %dms, number: %d", ms, len(lst))
	dumper.PutSyncRecord("targets", start.Unix(), ms, len(lst), "success")

	return nil
}

func (tc *TargetCacheType) GetHostMetas(targets []*models.Target) map[string]*models.HostMeta {
	return make(map[string]*models.HostMeta)
}
