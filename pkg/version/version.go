package version

import "fmt"

var (
	// values bellow are set via ldflags passed to go build command
	version       = ""
	commit        = ""
	date          = ""
	gitTreeState  = ""
	releaseStatus = ""
)

func GetVersionString() string {
	return fmt.Sprintf("%s(%s%s), commit:%s, date:%s", version, gitTreeState, releaseStatus, commit, date)
}
