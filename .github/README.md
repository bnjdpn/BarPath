# Local verification

Studio config/ci.json runs `.github/check-local` at the PR SHA through
`bin/studio-ci bnjdpn/BarPath <sha>`. Reserve an iPhone simulator first and
pass SCEO_SIM_UDID through the environment. The script builds the app and
tests, then runs the tests using its own temporary DerivedData directory.

The hosted cache and artifact upload are omitted because the local CI keeps
its log and runs on the Mac. They are not validation gates.
No native check was executed during Studio #469 corrections because the
simulator is reserved by #431. Tech must obtain studio/ci success before merge.
