{ pkgs, ... }: {

  systemd.services.lm_sensors-init = {
    description = "Initialize lm_sensors boundaries";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.lm_sensors}/bin/sensors -s";
    };
  };

  environment.systemPackages = [ pkgs.lm_sensors ];

  environment.etc."sensors.d/asrock-b450.conf".text = ''

    # ====================================================================
    # MAINBOARD: Nuvoton Chip
    # ====================================================================
    chip "nct6792-isa-*"

      # 1. SPANNUNGEN (Grenzwerte angepasst an die internen ADC-Rohwerte)
      label in0 "VCore"
      compute in0 @*2, @/2
      set in0_max 1.5

      label in2 "AVCC"
      set in2_min 3.3*0.95
      set in2_max 3.3*1.05

      label in3 "+3.3V"
      set in3_min 3.3 * 0.95
      set in3_max 3.3 * 1.05

      label in7 "3VSB"
      set in7_min 3.3 * 0.95
      set in7_max 3.3 * 1.05

      label in8 "VBat"
      set in8_min 3.3 * 0.95
      set in8_max 3.3 * 1.05

      label in9 "+1.8V"
      set in9_min 1.8 * 0.9
      set in9_max 1.8 * 1.1

      label in12 "+12.0V"
      compute in12 @*(66/10), @/(66/10)
      set in12_min 12.0 * 0.95
      set in12_max 12.0 * 1.05

      label in13 "+5.0V"
      compute in13 @*3, @/3
      set in13_min 5.0 * 0.95
      set in13_max 5.0 * 1.05

      # Ignore sensors with input 0V
      ignore in1
      ignore in4
      ignore in5
      ignore in14

      # Unknown voltages are in6, in10, in11
      ignore in6
      ignore in10
      ignore in11

      # 2. LÜFTER
      label fan1 "Top Fan 1"
      set fan1_min 0
      label fan3 "Top Fan 2"
      set fan3_min 0
      label fan2 "CPU Fan"
      set fan2_min 0

      ignore pwm4
      ignore pwm5

      # Zero or not connected
      ignore fan4
      ignore fan5

      # 3. TEMPERATUREN
      label temp3 "Mainboard"
      set temp3_max 55
      set temp3_max_hyst 50

      label temp7 "SMB (Novoton)"
      label temp13 "CPU (Nuvoton)"

      # Values are always zero
      ignore temp8
      ignore temp9
      ignore temp10
      ignore temp11
      ignore temp12

      # Constant negative values
      ignore temp2
      ignore temp6

      # Unknown temperatures
      ignore temp1
      ignore temp4
      ignore temp5

      # 4. WEITERE

      ignore intrusion0
      ignore intrusion1
      ignore beep_enable

      
    # ====================================================================
    # GRAFIKKARTE: AMD Radeon
    # ====================================================================
    chip "amdgpu-pci-*"
      label in0 "GPU Core"
      label fan1 "GPU Fan"
      label power1 "GPU Power"
      label temp1 "GPU Edge"
      label temp2 "GPU Junction"
      label temp3 "GPU VRAM"

    # ====================================================================
    # ZUSATZGERÄTE
    # ====================================================================
    chip "k10temp-pci-*"
      label temp1 "CPU (AMD)"
      label temp2 "CPU Die (Chip)"

    chip "ath12k_hwmon-pci-*"
      label temp1 "Wifi Adapter"

    chip "nvme-pci-*"
      ignore temp1

      label temp2 "NVMe Controller"
      set temp2_min 0.15
      set temp2_max 75.15
      
      label temp3 "NVMe Flash"
      set temp3_min 10.15
      set temp3_max 65.15
  '';
}
