// Package qemu_test runs the provided kernel binary using QEMU and verifies a magic string is produced in its output.
package qemu_test

import (
	"bytes"
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"testing"

	"github.com/RyRose/smouth-os/tools/go/qemu"
)

var (
	cpu    = flag.String("cpu", "", "Guest architecture to run with.")
	kernel = flag.String("kernel", "", "Path to the kernel to boot.")
)

type logWriter struct {
	t *testing.T
}

func (l *logWriter) Write(p []byte) (n int, err error) {
	l.t.Log(string(p))
	return len(p), nil
}

func TestRun(t *testing.T) {
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

	magic := "<<KERNEL TEST COMPLETE>>"
	if !bytes.Contains(out, []byte(magic)) {
		t.Fatalf("Got serial output but did not contain magic string %q", magic)
	}
}
