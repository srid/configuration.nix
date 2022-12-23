{ config, pkgs, lib, inputs, modulesPath, flake, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.agenix.nixosModule
      inputs.nix-serve-ng.nixosModules.default
    ];

  boot.initrd.availableKernelModules = [ "nvme" "ahci" "usbhid" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/bede3321-d976-475a-ace3-33c8977a590a";
      fsType = "ext4";
    };

  swapDevices = [ ];

  nix.settings.max-jobs = lib.mkDefault 12;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Use GRUB2 as the boot loader.
  # We don't use systemd-boot because Hetzner uses BIOS legacy boot.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    devices = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
  };

  # The madm RAID was created with a certain hostname, which madm will consider
  # the "home hostname". Changing the system hostname will result in the array
  # being considered "foregin" as opposed to "local", and showing it as
  # '/dev/md/<hostname>:root0' instead of '/dev/md/root0'.

  # This is mdadm's protection against accidentally putting a RAID disk
  # into the wrong machine and corrupting data by accidental sync, see
  # https://bugzilla.redhat.com/show_bug.cgi?id=606481#c14 and onward.
  # We set the HOMEHOST manually go get the short '/dev/md' names,
  # and so that things look and are configured the same on all such
  # machines irrespective of host names.
  # We do not worry about plugging disks into the wrong machine because
  # we will never exchange disks between machines.
  environment.etc."mdadm.conf".text = ''
    HOMEHOST pinch
  '';

  # The RAIDs are assembled in stage1, so we need to make the config
  # available there.
  boot.initrd.services.swraid.mdadmConf = config.environment.etc."mdadm.conf".text;

  # Network (Hetzner uses static IP assignments, and we don't use DHCP here)
  networking.useDHCP = false;
  networking.firewall.checkReversePath = "loose"; # Tailscale recommends this
  networking.interfaces."enp41s0" = {
    ipv4 = {
      addresses = [{
        # Server main IPv4 address
        address = "88.198.33.237";
        prefixLength = 24;
      }];

      routes = [
        # Default IPv4 gateway route
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "88.198.33.225";
        }
      ];
    };

    ipv6 = {
      addresses = [{
        address = "2a01:4f8:a0:305f::1";
        prefixLength = 64;
      }];

      # Default IPv6 route
      routes = [{
        address = "::";
        prefixLength = 0;
        via = "fe80::1";
      }];
    };
  };


  networking = {
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    hostName = "pinch";
  };

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes repl-flake
    '';
  };

  services.netdata.enable = true;

  environment.systemPackages = with pkgs; [
    lsof
    nil
  ];

  services.openssh.permitRootLogin = "prohibit-password";
  services.openssh.enable = true;
  services.tailscale.enable = true;

  age.secrets.cache-priv-key.file = ../../secrets/cache-priv-key.age;
  services.nix-serve = {
    enable = true;
    secretKeyFile = config.age.secrets.cache-priv-key.path;
  };
  services.nginx = {
    enable = true;
    virtualHosts."cache.srid.ca" = {
      forceSSL = true;
      enableACME = true;
      locations."/".extraConfig = ''
        proxy_pass http://localhost:${toString config.services.nix-serve.port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "srid@srid.ca";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${flake.config.people.myself} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "20.03";
}
