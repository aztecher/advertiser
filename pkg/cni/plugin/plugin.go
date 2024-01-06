package plugin

import (
	"github.com/aztecher/advertiser/pkg/cni/types"
	"github.com/aztecher/advertiser/pkg/version"
	"github.com/containernetworking/cni/pkg/skel"
	cnitypes "github.com/containernetworking/cni/pkg/types"
	current "github.com/containernetworking/cni/pkg/types/100"

	log "github.com/k8snetworkplumbingwg/cni-log"
)

const (
	CNIPluginName = "advertiser"
)

type Plugin struct {
	Name       string
	Version    string
	ConfLoader types.ConfLoader
}

func NewPlugin() *Plugin {
	return &Plugin{
		Name:       CNIPluginName,
		Version:    version.GetVersionString(),
		ConfLoader: types.NewConfLoader(),
	}
}

func (p *Plugin) CmdAdd(args *skel.CmdArgs) error {
	log.Infof("args: %s\n", string(args.StdinData))
	return cnitypes.PrintResult(&current.Result{}, "0.4.0")
}

func (p *Plugin) CmdDel(args *skel.CmdArgs) error {
	log.Infof("DEL operation was called on %s", p.Name)
	return nil
}

func (p *Plugin) CmdCheck(args *skel.CmdArgs) error {
	log.Infof("CHECK operation was called on %s", p.Name)
	return nil
}
