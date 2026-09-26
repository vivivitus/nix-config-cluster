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

  # 1. Native PipeWire-Kombination der beiden HDMI-Subdevices
  xdg.configFile."pipewire/pipewire.conf.d/99-hdmi-subdevices.conf".text = ''
    context.objects = [
      {
        factory = adapter
        args = {
          factory.name   = api.alsa.pcm.sink
          node.name      = "hdmi_monitor_left"
          node.description = "Monitor Links (HDMI 0)"
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
          node.description = "Monitor Rechts (HDMI 1)"
          media.class    = Audio/Sink
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
          node.description = "Beide Monitore (Kombiniert)"
          combine.latency-compensate = true
          combine.props = {
            audio.position = [ FL FR ]
            media.class = "Audio/Sink"
          }
          stream.props = {
            stream.dont-remix = true
          }
          stream.rules = [
            {
              matches = [
                { node.name = "hdmi_monitor_left" }
                { node.name = "hdmi_monitor_right" }
              ]
              actions = {
                create-stream = {}
              }
            }
          ]
        }
      }
    ]
  '';

  # 2. Automatische AMD-Grafikkarte in WirePlumber deaktivieren
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
