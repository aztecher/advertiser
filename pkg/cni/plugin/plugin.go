package plugin

import (
	"github.com/aztecher/advertiser/pkg/version"
	"github.com/containernetworking/cni/pkg/skel"
	"github.com/containernetworking/cni/pkg/types"
	current "github.com/containernetworking/cni/pkg/types/100"

	log "github.com/k8snetworkplumbingwg/cni-log"
)

const (
	CNIPluginName = "advertiser"
)

type Plugin struct {
	Name    string
	Version string
}

func NewPlugin() *Plugin {
	return &Plugin{
		Name:    CNIPluginName,
		Version: version.GetVersionString(),
	}
}

func (p *Plugin) CmdAdd(args *skel.CmdArgs) error {
	return types.PrintResult(&current.Result{}, "0.4.0")
}

func (p *Plugin) CmdDel(args *skel.CmdArgs) error {
	log.Infof("DEL operation was called on %s", p.Name)
	return nil
}

func (p *Plugin) CmdCheck(args *skel.CmdArgs) error {
	log.Infof("CHECK operation was called on %s", p.Name)
	return nil
}
