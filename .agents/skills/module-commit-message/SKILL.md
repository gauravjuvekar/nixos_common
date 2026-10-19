---
name: module-commit-message
description: Write commit messages for this repository using a module prefix in place of Conventional Commits type and scope. Use when drafting a commit message or making an authorized commit.
---

Use the repository's module-based variant of Conventional Commits:

```text
<module>[!]: <short imperative summary>

[optional body explaining why and any relevant behavior changes]

[optional footers]
```

- Inspect the relevant diff and recent commit subjects. For an actual commit, describe the staged changes; when only drafting, use the changes requested by the user.
- Replace the entire conventional type/scope prefix with the affected module. For example, use `niri: use perceptual brightness scaling`, not `feat(niri): ...` or `niri(feat): ...`.
- Derive the module from the changed configuration, usually the nearest meaningful module directory under `src/common/` or `src/modules/`. Examples include `ai`, `niri`, `ssh`, and `mdadm`. Use the host name for host-specific changes, as existing `rpi:` commits do. For repository infrastructure, use a concise descriptive component such as `skills` or `flake`.
- Use one prefix for a cohesive change. If several modules support one change, choose the primary component or a clear shared component. Do not create additional commits solely to satisfy the prefix convention.
- Keep the summary concise, imperative, and without a trailing period. Use the body for motivation or details that do not fit the subject.
- Preserve Conventional Commits breaking-change notation when applicable: `<module>!: <summary>` and a `BREAKING CHANGE: <explanation>` footer. Include other footers only when relevant.

Writing a message does not authorize staging, committing, or pushing. When only a message is requested, return the proposed message.
