package main

import (
	"context"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/RyRose/smouth-os/tools/go/qemu"
)

var (
	cpu           = flag.String("cpu", "", "Guest architecture to run with.")
	output        = flag.String("output", "", "Method of displaying output from QEMU.")
	kernel        = flag.String("kernel", "", "Path to the kernel to boot.")
	workspaceFile = flag.String("workspace_file", "", "File containing path to the root directory containing source code.")
	logSerial = flag.Bool("log_serial", true, "Log to serial port instead of directly writing to stdout.")
)

func workspace() string {
	if *workspaceFile == "" {
		return ""
	}
	workspaceStr, err := ioutil.ReadFile(*workspaceFile)
	if err != nil {
		log.Printf("Could not read workspace file %v: %v", *workspaceFile, err)
		return ""
	}
	return strings.TrimSpace(string(workspaceStr))
}

func run(ctx context.Context, vm qemu.VM) error {
	switch *output {
	case "monitor":
		return vm.Monitor(ctx)
	case "serial":
		_, err := vm.Serial(ctx)
		return err
	case "gdb":
		return vm.GDB(ctx)
	}
	return fmt.Errorf("unknown output method: %v", *output)
}

func main() {
	flag.Parse()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	c := make(chan os.Signal)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		cancel()
	}()

	vm := qemu.VM{
		CPU:       *cpu,
		Kernel:    *kernel,
		Workspace: workspace(),
		NoLogSerial: !*logSerial,
	}

	if err := run(ctx, vm); err != nil {
		log.Fatalf("QEMU execution failed: %v", err)
	}
}
