# Pock. 
#### Switch your favorites apps from your Touch Bar.
![Pock. Preview](https://raw.githubusercontent.com/pigigaldi/Pock/master/Resources/pock-preview.jpg)
### Instructions:
___
Pock. uses **private API** to let custom item stay in Touch Bar's Control Strip.
```
$ git clone http://github.com/pigigaldi/Pock
$ cd Pock/
$ pod install
$ open Pock.xcworkspace
$ echo "Run!"
```

### Usage:
___
Just launch and **BAM**! 
Your dock is in your Touch Bar!

### Utils:
___
`⌥+⌘+P`:  Will set *Pock.* as first item in Control Strip (if any other apps, like iTunes or Spotify, did replace it). This is Global.

### Icon's notification badge
___
In order to access icon's notification badge into Pock, you should [disable SIP](https://developer.apple.com/library/content/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html).

* [Why should disable SIP](https://developer.apple.com/library/content/releasenotes/MacOSX/WhatsNewInOSX/Articles/MacOSX10_11.html)
> `System Integrity Protection is a new security policy that applies to every running process, including privileged code and code that runs out of the sandbox. The policy extends additional protections to components on disk and at run-time, only allowing system binaries to be modified by the system installer and software updates. Code injection and runtime attachments to system binaries are no longer permitted.`

Since there isn't (yet) a simple way to get icon's badge, Pock inject a bundle (`pock_internal.bundle`) into running processes to access `NSApplication`'s `DockTile` and store `badgeLabel` information into a plist file located at `~/Library/Application Support/Pock/`.

This file is then read by Pock main process to show badge over `PockItemView`.

This process occures everytime [`NSWorkspaceDidActivateApplicationNotification`](https://developer.apple.com/documentation/appkit/nsworkspacedidactivateapplicationnotification?language=objc) is posted by Finder.

### TODO:
___
* [???] Put "Launch at login" option in status bar menu;
* [???] Custom hotkey for showing the dock
* [WIP] Add icon's notification badge (better way founded! See [`feature/icon-badge`](https://github.com/pigigaldi/Pock/tree/feature/icon-badge) branch)

### Thank you!
___
* [BrokenSt0rm](https://twitter.com/BrokenSt0rm) 🙅‍♂️
* [SnapKit](https://github.com/SnapKit/SnapKit)
* [Magnet](https://github.com/Clipy/Magnet)
* [touch-baer](https://github.com/a2/touch-baer) - How to put icon in Control Strip
* [ESCapey](https://github.com/brianmichel/ESCapey) - Simulate `esc` button
* [SMJobKit](https://github.com/IngmarStein/SMJobKit) - Easy install PrivilegedHelperTools (a huge thank you!)
* [macSubstrate/mach_inject](https://github.com/wzqcongcong/macSubstrate/) - Inject code into other processes (a huge thank you!)

### Info:
___
**Pock.** is not meant to be a commercial package.

### License:
___
Under MIT license. See LICENSE file for further information.
