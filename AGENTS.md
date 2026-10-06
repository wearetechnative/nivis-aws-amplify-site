# nivis-aws-amplify-site

A GitHub-connected AWS Amplify Hosting site as a
[nivis](https://github.com/nivis-project/nivis) module: Amplify app, production
branch, custom-domain association and build service role, with redirect rules
and an optional same-origin form proxy. Successor of the OpenTofu-era
`brunordias/amplify-app` usage, first deployed for technative.eu v2026.

The module is `{ nivis, namePrefix ? "", cfg } -> { resources, dataSources,
outputs }`, exposed as `nivisModules.default` from `flake.nix` and implemented
in `module.nix`. `namePrefix` namespaces all resource names; the default `""`
keeps the canonical names (`site`, `main`, `root`, `amplify_service`,
`github_token`). The module references provider id `"aws"`; the consumer
supplies the provider and the state backend.

See `README.md` for the consumer-facing usage example and the production
gotchas (Amplify GitHub App installation, SSM token, the one-way
`iam_service_role_arn` door, domain mechanics, redirect order).

## Commands

```bash
nix flake check                  # evaluate the module against a fixture
nix develop                      # dev shell
nix fmt                          # format nix sources

openspec list                    # active changes
openspec show <change>           # one change
openspec validate <change>       # validate a proposal

beans list                       # all beans
beans list --ready               # beans ready to start
beans show <id>                  # one bean

./scripts/ship-change.sh <change-name> [subject]   # gate, archive, commit, push
```

## Beans

When I refer to issues like nivis-aws-amplify-site-rn3b checkout the task
in @.beans/nivis-aws-amplify-site-rn3b-*.md

In this project we will use these tasks as epics for making openspec proposals.

WHEN you create a proposal at a link to this task in the proposal.md.
WHEN a bean is used to create an proposal change the status to "in-progress"
WHEN a proposal is archived add the link to the archived proposal in the frontmatter of this task like this:

```
openspec-link: openspec/changes/archive/....
```

You are allowed to update these statuses in the task frontmatter:

- in-progress
- todo
- draft
- completed
- scrapped

When making changes you are allowed to update the date/time in `updated_at` in the task frontmatter

Besides updating status and openspec-link, you are NOT ALLOWED to modify the contents of the task file.
