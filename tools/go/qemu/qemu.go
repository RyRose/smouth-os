package qemu

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
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

func (v *VM) Serial(ctx context.Context) ([]byte, error) {
	cmd := exec.CommandContext(ctx, v.qemu(), "-kernel", v.Kernel, "-nographic", "--no-reboot")

	cmdReader, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	var output bytes.Buffer
	scanner := bufio.NewScanner(cmdReader)
	go func() {
		for scanner.Scan() {
			output.Write(scanner.Bytes())
			output.WriteByte('\n')
			s := fmt.Sprintf("%q", scanner.Text())
			log.Print(s[1 : len(s)-1])
		}
	}()

	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	err = cmd.Run()
	if err != nil {
		err = fmt.Errorf("failed to run QEMU: %w:\n%v", err, stderr.String())
	}
	return output.Bytes(), err
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
