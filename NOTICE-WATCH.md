# Watch-enabled SideStore adaptation

This independent, AI-assisted adaptation combines official SideStore develop
`4f3d18d98c5fbee72c80f787ceb2e8e09ded60a6` with Watch and OS recovery changes
from [9andmoai/Fairway](https://github.com/9andmoai/Fairway), branch
`sidestore-os-recovery-20261125`, commit `5fbb18175e69255c117b16ed0bca7bc59e209d89`.
It is not an official SideStore release and implies no endorsement by Apple,
SideStore, or the Fairway author.

All dependency sources used for the modified native and signing code are vendored
here rather than referenced as dirty local Git submodules. Their original license
files and notices are preserved. Fairway's original overlays and newly added code
are AGPL-3.0-or-later; see LICENSE-WATCH-OVERLAYS and the corresponding published
Fairway source. Unmodified third-party code retains its own license and notices.
The frozen Fairway signing fixture corresponds to Fairway source
`ad565069f56d6b8e645a6581eb829b0363aa1cbf`; see WatchBuild/fixtures/README.md.

WatchBuild/source-pins.json records all original input commits. The GitHub Actions
artifact includes the exact source snapshot for the built IPA, with its commit
and checksums. CI tests use synthetic signing identities, not a user's Apple
account. Device migration, preservation of app data, scheduled Watch renewal and
operation after the old provisioning profile expires still require user testing.

This repository is for the owner's experimental builds. No upstream contribution
or maintainer interaction is implied. AI assistance has been used for local
integration, build automation and documentation.

