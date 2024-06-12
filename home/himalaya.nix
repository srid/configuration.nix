let
  # https://pimalaya.org/himalaya/cli/latest/configuration/icloud-mail.html
  iCloudMailSettings = {
    imap = {
      host = "imap.mail.me.com";
      port = 993;
    };
    smtp = {
      host = "smtp.mail.me.com";
      port = 587;
      tls.useStartTls = true;
    };
  };
in
{
  home.shellAliases = {
    H = "himalaya";
    Hr = "himalaya message read";
    Hd = "himalaya message delete";
    Hs = "himalaya account sync";
  };

  programs.himalaya = {
    enable = true;
  };

  accounts.email.accounts = {
    "srid@srid.ca" = iCloudMailSettings // {
      primary = true;
      realName = "Sridhar Ratnakumar";
      address = "happyandharmless@icloud.com";
      aliases = [ "srid@srid.ca" ];
      userName = "happyandharmless";
      passwordCommand = "op read op://Personal/iCloud-Apple/himalaya";
      himalaya = {
        enable = true;
        # Don't forget to run `himalaya account sync` first!
        settings.sync = {
          enable = true;
        };
      };
    };
  };
}
