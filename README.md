## arch-post-installers

Post `archinstall` installers

> [!WARNING]
> This repo is WIP, and nothing from it should be ran!

> [!TIP]
> If for some reason you'd like to run this anyway, please use
> ```sh
> git clone https://github.com/howhow2315/arch-post-installers.git
> ```
> and then run them how youd like.

----

Goals:  
Each script should work compeletely independently of the others (disincluding requiring ./base.sh)  
Each script should only elevate PER COMMAND (via. _run_as_root)  
Each script should be SAFE to run multiple times (aka checking for reruns)  

----

This repository is fully licensed under the MIT License (see `LICENSE`).
