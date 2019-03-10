// package genh generates a header file template rooted at the WORKSPACE file.
package main

import (
	"errors"
	"io/ioutil"
	"os"
	"strings"
	"text/template"
)

const (
	buildTemplate = `#ifndef {{.Path}}_H
#define {{.Path}}_H
#endif  //  {{.Path}}_H
`
)

type data struct {
	Path string
}

func currentDirectory() string {
	dir, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	return dir
}

func hasWorkspace(path string) bool {
	files, err := ioutil.ReadDir(path)
	if err != nil {
		panic(err)
	}
	for _, file := range files {
		if file.Name() == "WORKSPACE" {
			return true
		}
	}
	return false
}

func findPath(name string) (string, error) {
	currentDir := currentDirectory()
	parts := strings.Split(currentDir, "/")
	other := []string{strings.ToUpper(name)}
	for i := len(parts) - 1; i > 0; i-- {
		if hasWorkspace(strings.Join(parts, "/")) {
			return strings.Join(other, "_"), nil
		}
		other = append([]string{strings.ToUpper(parts[i])}, other...)
		parts = parts[:i]
	}
	return "", errors.New("path with WORKSPACE not found")
}

func main() {
	if len(os.Args) != 2 {
		panic("name of header file not given")
	}
	templ := template.Must(template.New("genbuild").Parse(buildTemplate))

	name := os.Args[1]
	p, err := findPath(name)
	if err != nil {
		panic(err)
	}
	d := data{p}
	if err := templ.Execute(os.Stdout, d); err != nil {
		panic(err)
	}
}
