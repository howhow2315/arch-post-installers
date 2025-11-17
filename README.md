## arch-post-installers

Post `archinstall` installers

----

Goals:
Each script should work compeletely independently of the others (disincluding requiring ./base.sh)
Each script should only elevate PER COMMAND (via. _run_as_root)
Each script should be SAFE to run multiple times (aka checking for reruns)

----

This repository is fully licensed under the MIT License (see `LICENSE`).
