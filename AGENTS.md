# Ship

- Validate with `nix flake check path:.`.
- Commit and push to `origin/main`.
- Deploy: each host builds Homelab main against the latest Dotfiles main. Each command exits 0 once that host runs it (add `-o StrictHostKeyChecking=accept-new` on first contact):
  ```
  ssh deploy@sharbox              # Sharbox
  ssh deploy@hotbox               # Hotbox
  ssh deploy@sharbox sharchy      # relayed; fails if the workstation is asleep
  ssh deploy@sharbox turbogadget
  ```
- Orbs join the tailnet via `.agents/resume`.
