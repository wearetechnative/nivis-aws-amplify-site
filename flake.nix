{
  description = "nivis-aws-amplify-site — GitHub-connected AWS Amplify Hosting site (app + branch + domain + service role) as a nivis module";

  outputs =
    { self, ... }:
    {
      # The nivis module:
      # { nivis, namePrefix ? "", cfg } -> { resources, dataSources, outputs }.
      nivisModules.default = import ./module.nix;
    };
}
