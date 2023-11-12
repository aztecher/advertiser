package main

import (
	"fmt"

	"github.com/aztecher/advertiser/pkg/cni/plugin"
	"github.com/containernetworking/cni/pkg/skel"
	"github.com/containernetworking/cni/pkg/version"
)

func main() {
	p := plugin.NewPlugin()
	about := fmt.Sprintf("%s CNI plugin %s", p.Name, p.Version)
	skel.PluginMain(p.CmdAdd, p.CmdCheck, p.CmdDel, version.All, about)
}
