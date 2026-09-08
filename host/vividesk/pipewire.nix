{ ... }: {

  services.pipewire.extraConfig.pipewire = {
    "99-monitor-split" = {
      "context.modules" = [
        {
          name = "libpipewire-module-loopback";
          args = {
            node.description = "Monitor Links (Mono)";
            capture.props = {
              node.name = "split_left_sink";
              media.class = "Audio/Sink";
              audio.position = [
                "FL"
                "FR"
              ];
            };
            playback.props = {
              node.name = "split_left_playback";
              audio.position = [
                "FL"
                "FR"
              ];
              target.object = "alsa_output.pci-0000_08_00.1.hdmi-stereo";
              channelmix.upmix = true;
              channelmix.mono-mix-out = true;
            };
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            node.description = "Monitor Rechts (Mono)";
            capture.props = {
              node.name = "split_right_sink";
              media.class = "Audio/Sink";
              audio.position = [
                "FL"
                "FR"
              ];
            };
            playback.props = {
              node.name = "split_right_playback";
              audio.position = [
                "FL"
                "FR"
              ];
              target.object = "alsa_output.pci-0000_08_00.1.hdmi-stereo-extra1";
              channelmix.upmix = true;
              channelmix.mono-mix-out = true;
            };
          };
        }
      ];
    };
  };
}
