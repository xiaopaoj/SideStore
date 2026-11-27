# SideStore with Watch and OS Recovery

Independent, AI-assisted experimental build of SideStore develop with Watch installation,
refresh and OS recovery changes from Fairway. This is not an official SideStore release.

The Build Watch-enabled SideStore IPA action publishes the pinned adapted source here,
runs the existing recovery, native Watch and signing tests, and builds an unsigned IPA.
Download the successful run artifact for the IPA, corresponding source, BUILD.json and checksums.
Install using your own Apple account; no account credentials are used in CI.

Modified dependencies are vendored here. Original upstream workflows are retained under
`.github/upstream-workflows` as inactive reference. Source revisions are in
`WatchBuild/source-pins.json`. See NOTICE-WATCH.md and README.upstream.md for attribution,
licenses and verification limits. Successful CI does not prove device migration, data
preservation or reliable automatic Watch renewal.
