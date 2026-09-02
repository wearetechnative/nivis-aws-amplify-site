# nivis-aws-amplify-site

A GitHub-connected AWS Amplify Hosting site as a
**[nivis](https://github.com/nivis-project/nivis) module**: Amplify app +
production branch + custom-domain association + build service role, with
redirect rules and an optional same-origin form proxy. Successor of the
OpenTofu-era `brunordias/amplify-app` usage. First deployed for technative.eu
v2026.

## Usage

```nix
# flake input:
#   amplifySite.url = "git+ssh://git@github.com/wearetechnative/nivis-aws-amplify-site";

site = amplifySite.nivisModules.default {
  nivis = nivis.lib;
  # namePrefix = "";        # set when instantiating twice in one domain
  cfg = {
    appName = "myorg-prod-website";
    region = "eu-central-1";              # for the regional Amplify principal
    repository = "https://github.com/myorg/my-hugo-site";
    branch = "main";
    domain = "example.org";
    subDomains = [ { prefix = ""; } { prefix = "www"; } ];
    githubTokenParam = "/myorg/github_token";   # SSM SecureString (see below)
    preRules = [                          # evaluated first (host rules etc.)
      { source = "https://www.example.org"; status = "301"; target = "https://example.org"; }
    ];
    redirects = import ./redirects.nix;   # bulk path redirects, evaluated last
    # formProxy = {                       # optional same-origin form proxy
    #   pathPrefix = "/sendform";         # -> 200-rewrite /sendform/<*> to the API
    #   apiEndpointRef = form.apiEndpointRef;   # from nivis-aws-form-action
    # };
    buildSpec = ''...'';                  # optional amplify.yml content
    tags = { ManagedBy = "nivis"; };
  };
};

# then in your domain's toIR:
#   resources = site.resources ++ ...;
#   dataSources = site.dataSources ++ ...;
#   outputs = site.outputs // ...;
```

## Module conventions (nivis bean `nixform2-l2hx`)

- **`namePrefix`** namespaces all resource names; default `""` keeps canonical
  names (`site`, `main`, `root`, `amplify_service`, `github_token`).
- The module references provider id **`"aws"`** — the consumer supplies the
  provider and the state backend.

## Prerequisites & operational gotchas (learned in production)

- **The AWS Amplify GitHub App** (e.g. `aws-amplify-eu-central-1`) MUST be
  installed on the GitHub org and granted the site repo — builds fetch sources
  through the App. Without it, builds fail right after "Build environment
  configured" with the **misleading** error `Unable to assume specified IAM
  Role` (aws-amplify/amplify-hosting#4035). Install via
  `https://github.com/apps/aws-amplify-<region>/installations/new`.
- **GitHub token** at `cfg.githubTokenParam` (SSM SecureString): officially
  Amplify supports classic PATs (`ghp_…`) only; a fine-grained PAT sufficed for
  provisioning (webhook) in practice. The token value lands in nivis state —
  keep the state bucket encrypted.
- **`iam_service_role_arn` is a one-way door**: unsetting it forces a full app
  replace, so the module always creates/attaches the service role
  (`AdministratorAccess-Amplify`; scope down if desired).
- **Domain mechanics**: Amplify auto-writes Route53 records + ACM validation
  in-account (same-account hosted zone) — no manual DNS. A domain/subdomain can
  be associated with only ONE Amplify app; moving a domain between apps means
  deleting the old association first (~minutes of switchover).
- **Redirect order**: `preRules` → `formProxy` rewrite → `redirects`, evaluated
  top-down, first match wins. Amplify accepted 100+ rules in practice.
