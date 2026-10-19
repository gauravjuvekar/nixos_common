---
name: validate-nix-config
description: Validate changes in this repository by building the Nix configuration for the current machine. Use after changing Nix configuration or when asked to check a build.
---

Build from the repository root without activating or switching the running configuration.

1. Identify the actual machine and its output key in `flake.nix`. Use `/etc/hostname`, `hostname -f` when available, and the host definitions under `hosts/`. In a jail, the hostname can be `jail`; inspect available host configuration under `/etc/nixos` and the target of `/run/current-system` for evidence instead. Do not guess a host from the username or build every host. If no reliable host identity is exposed, ask for the target machine.
2. Use the machine's full hostname as its `nixosConfigurations` key. Confirm it against the current flake and host files.
3. Build the complete system, including integrated Home Manager configuration:

   ```sh
   nix build --no-link --no-update-lock-file '.#nixosConfigurations."<host-key>".config.system.build.toplevel'
   ```

   Replace `<host-key>` with the actual flake key. If validating a standalone Home Manager installation instead, use its matching `homeConfigurations."<user>@<hostname>".activationPackage` output with the same build flags. Check the current flake for available outputs.
4. Ensure newly created Nix files are included in the flake source: Git-backed flakes omit untracked files. Account for this before interpreting missing-file errors; do not silently stage unrelated changes.
5. Fix failures caused by the changes and rebuild. Report the selected output, command, and result. If dependencies, network access, permissions, or host identification prevent completion, report the blocker and do not claim validation passed. Evaluation or a dry run alone does not count as a successful build.

Do not run `switch`, `boot`, `test`, deployment, or standalone Home Manager activation as part of validation. Do not update `flake.lock` to make validation pass unless the task calls for dependency changes.
