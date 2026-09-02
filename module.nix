# nivis-aws-amplify-site — a GitHub-connected AWS Amplify Hosting site as a
# nivis module: app + production branch + custom-domain association + build
# service role, with redirect rules and an optional same-origin form proxy.
#
# Module conventions (nivis has no module scoping yet — see nivis bean
# nixform2-l2hx):
#   - `namePrefix` namespaces every resource name (nivis ids are a flat
#     `provider.type.name` space). The default "" keeps the canonical names.
#   - The module references the provider id "aws"; the consumer supplies it.
#   - The GitHub token is read from SSM at deploy time (cfg.githubTokenParam);
#     it lands in nivis state (unavoidable for Amplify) — keep the state
#     bucket encrypted.
#
# Hard-won operational notes (technative.eu v2026):
#   - The AWS Amplify GitHub App (e.g. aws-amplify-eu-central-1) MUST be
#     installed on the GitHub org and granted the repo — builds fetch sources
#     through the App, and its absence fails builds with the MISLEADING error
#     "Unable to assume specified IAM Role" (aws-amplify/amplify-hosting#4035).
#   - `iam_service_role_arn` is a one-way door: once set, unsetting it forces a
#     full app REPLACE. The module always creates and attaches the role.
#   - Amplify auto-writes the Route53 records + ACM validation in-account when
#     the hosted zone lives in the same AWS account; a domain/subdomain can be
#     associated with only ONE Amplify app at a time.
{
  nivis,
  namePrefix ? "",
  cfg,
}:
let
  inherit (nivis) mkResource mkData;

  n = s: if namePrefix == "" then s else "${namePrefix}_${s}";

  githubToken = mkData {
    provider = "aws";
    type = "aws_ssm_parameter";
    name = n "github_token";
    config = {
      name = cfg.githubTokenParam;
      with_decryption = true;
    };
  };

  serviceRole = mkResource {
    provider = "aws";
    type = "aws_iam_role";
    name = n "amplify_service";
    config = {
      name = "${cfg.appName}-amplify";
      assume_role_policy = builtins.toJSON {
        Version = "2012-10-17";
        Statement = [
          {
            Effect = "Allow";
            Action = "sts:AssumeRole";
            # Both the global and the regional Amplify service principal.
            Principal.Service = [
              "amplify.amazonaws.com"
              "amplify.${cfg.region}.amazonaws.com"
            ];
          }
        ];
      };
      tags = cfg.tags;
    };
  };

  servicePolicy = mkResource {
    provider = "aws";
    type = "aws_iam_role_policy_attachment";
    name = n "amplify_service";
    config = {
      role = serviceRole.refAttr "name";
      policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify";
    };
  };

  # Redirect evaluation is top-down, first match wins:
  # consumer pre-rules (e.g. www -> apex), then the optional form proxy, then
  # the bulk redirect list.
  formProxyRules =
    if cfg.formProxy or null == null then
      [ ]
    else
      [
        {
          source = "${cfg.formProxy.pathPrefix}/<*>";
          status = "200";
          target = nivis.str [
            cfg.formProxy.apiEndpointRef
            "/<*>"
          ];
        }
      ];

  app = mkResource {
    provider = "aws";
    type = "aws_amplify_app";
    name = n "site";
    config = {
      name = cfg.appName;
      repository = cfg.repository;
      access_token = githubToken.refAttr "value";
      iam_service_role_arn = serviceRole.refAttr "arn";
      platform = "WEB";
      enable_branch_auto_build = true;
      environment_variables = cfg.environmentVariables or { };
      custom_rule = (cfg.preRules or [ ]) ++ formProxyRules ++ (cfg.redirects or [ ]);
      tags = cfg.tags;
    }
    // (if cfg.buildSpec or null == null then { } else { build_spec = cfg.buildSpec; });
  };

  branch = mkResource {
    provider = "aws";
    type = "aws_amplify_branch";
    name = n "main";
    config = {
      app_id = app.refAttr "id";
      branch_name = cfg.branch;
      stage = "PRODUCTION";
      enable_auto_build = true;
    };
  };

  domainAssociation = mkResource {
    provider = "aws";
    type = "aws_amplify_domain_association";
    name = n "root";
    config = {
      app_id = app.refAttr "id";
      domain_name = cfg.domain;
      sub_domain = map (s: {
        branch_name = cfg.branch;
        prefix = s.prefix;
      }) cfg.subDomains;
      # Don't block apply on ACM/DNS verification — Amplify provisions in the
      # background and auto-writes Route53 records in-account.
      wait_for_verification = false;
    };
  };
in
{
  resources = [
    serviceRole
    servicePolicy
    app
    branch
    domainAssociation
  ];

  dataSources = [ githubToken ];

  outputs = {
    amplify_app_id = app.refAttr "id";
    amplify_default_domain = app.refAttr "default_domain";
    domain_association_arn = domainAssociation.refAttr "arn";
    domain_cert_verification_dns_record = domainAssociation.refAttr "certificate_verification_dns_record";
  };
}
