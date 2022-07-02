// Package qemu_test runs the provided kernel binary using QEMU and verifies a magic string is produced in its output.
package qemu_test

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"regexp"
	"syscall"
	"testing"

	"github.com/RyRose/smouth-os/tools/go/qemu"
)

var (
	cpu    = flag.String("cpu", "", "Guest architecture to run with.")
	kernel = flag.String("kernel", "", "Path to the kernel to boot.")
	subTestName = flag.String("sub_test_name", "", "Name of the sub-test to launch.")
)

type logWriter struct {
	t *testing.T
}

func (l *logWriter) Write(p []byte) (n int, err error) {
	l.t.Log(string(p))
	return len(p), nil
}

func TestRun(t *testing.T) {
    t.Run(*subTestName, testRun)
}

func testRun(t *testing.T) {
	flag.Parse()
	log.SetOutput(&logWriter{t})

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	c := make(chan os.Signal)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		cancel()
	}()

	vm := qemu.VM{
		CPU:    *cpu,
		Kernel: filepath.Base(*kernel),
	}

	out, err := vm.Serial(ctx)
	if err != nil {
		t.Fatalf("%#v.Serial(%v) = _, %v; want successful execution of QEMU", vm, ctx, err)
	}

	re := regexp.MustCompile("<ktest>[^{]*(.*)[^}]*</ktest>")
	parts := re.FindAllSubmatch(out, -1)
	for _, arr := range parts {
		data := make(map[string]interface{})
		if err := json.Unmarshal(arr[1], &data); err != nil {
			t.Errorf("json.Unmarshal(%s, %v) = %v; want valid JSON between ktest tags", arr[1], data, err)
			continue
		}
		t.Errorf("%s:%s: %s = %q; want %q", data["file"], data["line"], data["expr"], data["got"], data["want"])
	}

	magic := "<<KERNEL TEST COMPLETE>>"
	if !bytes.Contains(out, []byte(magic)) {
		t.Errorf("!bytes.Contain(<serial port output>, %q); want serial port output containing magic string", magic)
	}

}
