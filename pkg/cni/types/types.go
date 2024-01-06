package types

import (
	"encoding/json"
	"fmt"
)

type ConfLoader interface {
	// LoadConf loads CNI configuration from JSON data
	LoadConf(bytes []byte) (*NetConf, error)
}

type NetConf struct {
}

type confLoader struct{}

func NewConfLoader() ConfLoader {
	return &confLoader{}
}

func (cl *confLoader) LoadConf(bytes []byte) (*NetConf, error) {
	var conf NetConf
	if err := json.Unmarshal(bytes, &conf); err != nil {
		return nil, fmt.Errorf("failed to unmarshal configurations. %w", err)
	}
	// TODO
	return &conf, nil
}
