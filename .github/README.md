# Local verification

Hosted CI was removed for Studio #469. Native checks run on the Mac with a
reserved iPhone simulator. The project is `BarPath.xcodeproj`; its shared
scheme is `BarPath`.

After reserving the device and a task-owned DerivedData directory:

```sh
: "${SCEO_SIM_UDID:?Reserve a simulator first}"
: "${QA_DERIVED_DATA:?Use a task-owned directory}"
xcodebuild -project BarPath.xcodeproj -scheme BarPath \
  -destination "platform=iOS Simulator,id=$SCEO_SIM_UDID" \
  -derivedDataPath "$QA_DERIVED_DATA" \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  CODE_SIGNING_ALLOWED=NO build-for-testing
xcodebuild -project BarPath.xcodeproj -scheme BarPath \
  -destination "platform=iOS Simulator,id=$SCEO_SIM_UDID" \
  -derivedDataPath "$QA_DERIVED_DATA" \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  CODE_SIGNING_ALLOWED=NO test-without-building
```

No build or native test was run by this workflow-only change. Local CI
registration remains a separate operation.
