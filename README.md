# affinitizeProcess

## I. DESCRIPTION:

PowerShell script to assign specific cores to a process

Copyright (c) 2018 Frostbyte <frostbytegr@gmail.com>

## II. USAGE:

* Direct: <PATH_TO>\affinitizeProcess.ps1 -exec "<EXECUTABLE_NAME>" -cores "<COMMA_DELIMITED_CORE_INDEXES>"
  - example #1: C:\affinitizeProcess.ps1 -exec "notepad" -cores "0,2,4,6"
  - example #2: C:\affinitizeProcess.ps1 -exec "notepad" -cores "all"
NOTE: Requires elevated privileges to work.

* Elevated Shortcut: PowerShell -Command "Start-Process -Verb RunAs PowerShell" "'-ExecutionPolicy Bypass -NoProfile -File <PATH_TO>\affinitizeProcess.ps1 -exec <EXECUTABLE_NAME> -cores <COMMA_DELIMITED_CORE_INDEXES>'"
  - example #1: PowerShell -Command "Start-Process -Verb RunAs PowerShell" "'-ExecutionPolicy Bypass -NoProfile -File C:\affinitizeProcess.ps1 -exec notepad -cores 0,2,4,6'"
  - example #2: PowerShell -Command "Start-Process -Verb RunAs PowerShell" "'-ExecutionPolicy Bypass -NoProfile -File C:\affinitizeProcess.ps1 -exec notepad -cores all'"

NOTE: When supplying the executable name (to either usage method) you must omit the file extension.
