# Evaluates module.nix against a stub nivis lib and a fixture cfg, and throws
# when the shape of the produced IR changes. Not a test suite: it only proves
# the module still evaluates and still names what the consumer references.
{ lib }:
let
  stubNivis = {
    mkResource =
      r:
      r
      // {
        kind = "resource";
        refAttr = a: "\${${r.provider}.${r.type}.${r.name}.${a}}";
      };
    mkData =
      d:
      d
      // {
        kind = "data";
        refAttr = a: "\${data.${d.provider}.${d.type}.${d.name}.${a}}";
      };
    str = parts: lib.concatStringsSep "" parts;
  };

  site = import ../module.nix {
    nivis = stubNivis;
    cfg = {
      appName = "example-prod-website";
      region = "eu-central-1";
      repository = "https://github.com/example/site";
      branch = "main";
      domain = "example.org";
      subDomains = [
        { prefix = ""; }
        { prefix = "www"; }
      ];
      githubTokenParam = "/example/github_token";
      tags = {
        ManagedBy = "nivis";
      };
    };
  };

  prefixed = import ../module.nix {
    nivis = stubNivis;
    namePrefix = "second";
    cfg = {
      appName = "example-second-website";
      region = "eu-central-1";
      repository = "https://github.com/example/second";
      branch = "main";
      domain = "second.example.org";
      subDomains = [ { prefix = ""; } ];
      githubTokenParam = "/example/github_token";
      tags = { };
    };
  };

  expect = what: cond: if cond then [ ] else [ what ];

  failures =
    expect "resources are the five canonical ones" (
      map (r: r.name) site.resources == [
        "amplify_service"
        "amplify_service"
        "site"
        "main"
        "root"
      ]
    )
    ++ expect "the only data source is the github token" (
      map (d: d.name) site.dataSources == [ "github_token" ]
    )
    ++ expect "outputs cover app id, default domain, association arn and cert record" (
      lib.attrNames site.outputs == [
        "amplify_app_id"
        "amplify_default_domain"
        "domain_association_arn"
        "domain_cert_verification_dns_record"
      ]
    )
    ++ expect "namePrefix namespaces every resource name" (
      map (r: r.name) prefixed.resources == [
        "second_amplify_service"
        "second_amplify_service"
        "second_site"
        "second_main"
        "second_root"
      ]
    );
in
if failures == [ ] then
  "ok"
else
  throw "module.nix changed shape: ${lib.concatStringsSep "; " failures}"
