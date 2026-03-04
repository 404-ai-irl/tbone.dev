{...}: {
  disko.devices = {
    disk = {
      main = {
        # Override at deploy time: --disk main /dev/vda
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            bios = {
              type = "EF02";
              size = "1M";
              priority = 1;
            };
            esp = {
              type = "EF00";
              size = "512M";
              priority = 2;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              size = "100%";
              priority = 3;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
