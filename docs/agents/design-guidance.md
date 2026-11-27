# Design guidance workflow

The repository carries project-scoped Impeccable guidance in
`.github/skills/impeccable/`; it is available to the active Copilot
environment. The guidance is project-local and does not replace or overwrite
user-level configuration.

## Load project context

Keep the repository root as the working directory and run:

```powershell
.github\skills\impeccable\scripts\impeccable.cmd context
```

The context command loads `PRODUCT.md` and any later design context. It has been
verified to run on Windows and to resolve this repository as the project root.
When a design task does not need a full new-world flow, read the task's
applicable Impeccable command reference, then load
`.github\skills\impeccable\reference\craft-floor.md` immediately before editing
UI files.

## Dashboard work

Treat the `analyst dashboard` as an Operate surface: prioritize scanability,
learner task completion, explicit local-lab status, and the existing domain
vocabulary. Before design work, load the project context and use the relevant
playbook, such as `shape`, `audit`, `polish`, or `new-work`.

Do not run an alternate design approach if project-scoped guidance becomes
unavailable. Stop and request approval before substituting it.

Machine-local settings belong in `.impeccable/config.local.json`, which is not
tracked. Repository-wide project settings belong in the `.github/skills`
installation and can be committed with the project.
