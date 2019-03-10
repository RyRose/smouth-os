// package genbuild generates a //kernel BUILD file.
package main

import (
	"os"
	"text/template"
)

const (
	buildTemplate = `load("//kernel:templates.bzl", "kernel_library")
`
)

func main() {
	templ := template.Must(template.New("genbuild").Parse(buildTemplate))
	if err := templ.Execute(os.Stdout, nil); err != nil {
		panic(err)
	}
}
