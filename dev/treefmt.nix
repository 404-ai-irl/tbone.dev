{
  projectRootFile = ".git/config";

  programs = {
    nixfmt.enable = true;
    deadnix.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
    prettier.enable = true;
  };

  settings.formatter = {
    deadnix.priority = 1;
    nixfmt.priority = 2;
  };
}
