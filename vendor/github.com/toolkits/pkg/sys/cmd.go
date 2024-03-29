package sys

import (
	"bytes"
	"os/exec"
	"strings"
	"time"
)

func CmdOutString(name string, arg ...string) (string, error) {
	bs, err := CmdOutBytes(name, arg...)
	if err != nil {
		return "", err
	}

	return string(bs), nil
}

func CmdOutBytes(name string, arg ...string) ([]byte, error) {
	cmd := exec.Command(name, arg...)
	return cmd.CombinedOutput()
}

func CmdOutTrim(name string, arg ...string) (out string, err error) {
	out, err = CmdOutString(name, arg...)
	if err != nil {
		return
	}

	return strings.TrimSpace(string(out)), nil
}

func CmdRun(name string, arg ...string) error {
	cmd := exec.Command(name, arg...)
	return cmd.Run()
}

// CmdRunT Command run with timeout
func CmdRunT(timeout time.Duration, name string, arg ...string) (output string, err error, istimeout bool) {
	cmd := exec.Command(name, arg...)

	var b bytes.Buffer
	cmd.Stdout = &b
	cmd.Stderr = &b

	err = CmdStart(cmd)
	if err != nil {
		return
	}

	err, istimeout = WrapTimeout(cmd, timeout)
	output = b.String()

	return
}

func WrapTimeout(cmd *exec.Cmd, timeout time.Duration) (error, bool) {
	return CmdWait(cmd, timeout)
}
