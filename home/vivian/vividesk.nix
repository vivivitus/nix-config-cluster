{
  imports = [
    ../common/global
    ../common/features/gui
    ../common/features/work
    ../common/features/social
    ../common/features/virtualisation/virt-manager.nix
    ../common/features/cli/ssh/rothstrasse.nix
  ];

  home.stateVersion = "24.05";

  programs.ssh.settings."github.com".IdentityFile = "/home/vivian/.ssh/vivian@vividesk";

  xdg.configFile."pipewire/pipewire.conf.d/99-hdmi-subdevices.conf".text = ''
    context.objects = [
      {
        factory = adapter
        args = {
          factory.name   = api.alsa.pcm.sink
          node.name      = "hdmi_monitor_left"
          node.description = "Monitor Links"
          media.class    = Audio/Sink
          api.alsa.path  = "hw:0,3"
          audio.position = [ FL FR ]
        }
      }
      {
        factory = adapter
        args = {
          factory.name   = api.alsa.pcm.sink
          node.name      = "hdmi_monitor_right"
          node.description = "Monitor Rechts"
          api.alsa.path  = "hw:0,7"
          audio.position = [ FL FR ]
        }
      }
    ]

    context.modules = [
      {
        name = libpipewire-module-combine-stream
        args = {
          combine.mode = "sink"
          node.name = "split_master_sink"
          node.description = "Beide Monitore"
          combine.latency-compensate = true
          audio.position = [ "FL" "FR" ]
          stream.properties = {
            node.passive = true
          }
          outputs = [
            "hdmi_monitor_left"
            "hdmi_monitor_right"
          ]
        }
      }
    ]
  '';

  xdg.configFile."wireplumber/wireplumber.conf.d/51-disable-navi-hdmi.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            device.name = "alsa_card.pci-0000_08_00.1"
          }
        ]
        actions = {
          update-props = {
            device.disabled = true
          }
        }
      }
    ]
  '';
}
