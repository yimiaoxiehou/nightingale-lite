package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/toolkits/pkg/runner"
	"nightingale-lite/center"
	"nightingale-lite/pkg/osx"
)

var (
	configDir = flag.String("configs", osx.GetEnv("N9E_CONFIGS", "etc"), "Specify configuration directory.(env:N9E_CONFIGS)")
)
//go:generate echo "build front"
//go:generate $GOPATH/bin/statik -src=./pub -dest=./front
//go:generate go fmt .
func main() {
	flag.Parse()

	printEnv()

	cleanFunc, err := center.Initialize(*configDir, "")
	if err != nil {
		log.Fatalln("failed to initialize:", err)
	}

	code := 1
	sc := make(chan os.Signal, 1)
	signal.Notify(sc, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

EXIT:
	for {
		sig := <-sc
		fmt.Println("received signal:", sig.String())
		switch sig {
		case syscall.SIGQUIT, syscall.SIGTERM, syscall.SIGINT:
			code = 0
			break EXIT
		case syscall.SIGHUP:
			// reload configuration?
		default:
			break EXIT
		}
	}

	cleanFunc()
	fmt.Println("process exited")
	os.Exit(code)
}

func printEnv() {
	runner.Init()
	fmt.Println("runner.cwd:", runner.Cwd)
	fmt.Println("runner.hostname:", runner.Hostname)
	fmt.Println("runner.fd_limits:", runner.FdLimits())
	fmt.Println("runner.vm_limits:", runner.VMLimits())
}
