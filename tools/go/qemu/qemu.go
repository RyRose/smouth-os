package qemu

import (
	"bufio"
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

type VM struct {
	CPU, Kernel, Workspace string
}

func (v *VM) qemu() string {
	return fmt.Sprintf("qemu-system-%s", v.CPU)
}

func (v *VM) Monitor(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, v.qemu(), "-kernel", v.Kernel, "-monitor", "stdio")
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func (v *VM) Serial(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, v.qemu(), "-kernel", v.Kernel, "-nographic", "--no-reboot")
	cmdReader, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}

	scanner := bufio.NewScanner(cmdReader)
	go func() {
		scanner.Scan()
		// Handle the first line with SeaBIOS differently since it outputs bytes that mess up the
		// terminal.
		log.Print(scanner.Text()[strings.Index(scanner.Text(), "SeaBIOS"):])
		for scanner.Scan() {
			log.Print(strings.TrimSpace(scanner.Text()))
		}
	}()
	return cmd.Run()
}

func (v *VM) GDB(ctx context.Context) error {
	qemu := exec.CommandContext(ctx, v.qemu(), "-kernel", v.Kernel, "-S", "-s")
	if err := qemu.Start(); err != nil {
		return err
	}
	defer qemu.Wait()
	defer qemu.Process.Kill()
	gdb := exec.CommandContext(ctx, "sudo", "gdb",
		"-d", v.Workspace,
		"-ex", fmt.Sprintf("file %s", v.Kernel),
		"-ex", "target remote :1234",
		"-ex", "layout split",
	)
	gdb.Stdin = os.Stdin
	gdb.Stdout = os.Stdout
	gdb.Stderr = os.Stderr
	return gdb.Run()
}
