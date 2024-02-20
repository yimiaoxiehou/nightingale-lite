package router

import (
	"github.com/gin-gonic/gin"
	"github.com/toolkits/pkg/ginx"
	"nightingale-lite/pushgw/idents"
)

func (rt *Router) targetUpdate(c *gin.Context) {
	var f idents.TargetUpdate
	ginx.BindJSON(c, &f)

	ginx.NewRender(c).Message(rt.IdentSet.UpdateTargets(f.Lst, f.Now))
}
