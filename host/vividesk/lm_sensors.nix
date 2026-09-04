{ pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    lm_sensors
    nvme-cli
    smartmontools
    udisks2
  ];

  environment.etc."sensors.d/asrock-b550.conf".text = ''

    # ====================================================================
    # MAINBOARD: Nuvoton Chip
    # ====================================================================
    chip "nct6792-isa-0290"

        # 1. SPANNUNGEN (Grenzwerte angepasst an die internen ADC-Rohwerte)
        label in0 "Vcore"
            compute in0 @*2, @/2
            set in0_min 0.30
            set in0_max 0.75

        label in2 "AVCC (3.3V)"
            set in2_min 3.13
            set in2_max 3.46

        label in3 "+3.3V"
            set in3_min 3.13
            set in3_max 3.46

        label in7 "3VSB"
            set in7_min 3.13
            set in7_max 3.46

        label in8 "Vbat"
            set in8_min 2.70
            set in8_max 3.40

        label in9 "+1.8V"
            set in9_min 1.62
            set in9_max 1.98

        # +12V (Berechnung: 11.40 / 6.6 = 1.72 und 12.60 / 6.6 = 1.90)
        label in12 "+12.0V"
            compute in12 @*(66/10), @/(66/10)
            set in12_min 1.72
            set in12_max 1.90

        # +5V (Berechnung: 4.75 / 3 = 1.58 und 5.25 / 3 = 1.75)
        label in13 "+5.0V"
            compute in13 @*3, @/3
            set in13_min 1.58
            set in13_max 1.75

        ignore in1
        ignore in4
        ignore in5
        ignore in6
        ignore in10
        ignore in11
        ignore in14

        # 2. LÜFTER
        label fan1 "Top Fan"
            set fan1_min 0
        label fan2 "CPU Fan"
            set fan2_min 200
        label fan3 "Case Fan"
            set fan3_min 0
        ignore fan4
        ignore fan5

        # 3. TEMPERATUREN
        label temp2 "Motherboard"
            set temp2_max 60
            set temp2_max_hyst 55
        label temp3 "CPU Socket"
            set temp3_max 85
            set temp3_max_hyst 80
        label temp13 "CPU Die"
            set temp13_max 90
            set temp13_max_hyst 85

        ignore temp1
        ignore temp4
        ignore temp5
        ignore temp6
        ignore temp7
        ignore temp8
        ignore temp9
        ignore temp10
        ignore temp11
        ignore temp12
        ignore intrusion0
        ignore intrusion1
        ignore beep_enable

    # ====================================================================
    # GRAFIKKARTE: AMD Radeon (Mapping via temp1, temp2, temp3)
    # ====================================================================
    chip "amdgpu-pci-0800"
        label vddgfx "GPU Core"
        label fan1   "GPU Fan"
        label power1 "GPU Power"
        
        # Hier mappen wir die Bezeichnungen auf die internen Sensoren
        label temp1 "GPU Edge"
        label temp2 "GPU Junction"
        label temp3 "GPU VRAM"

    # ====================================================================
    # ZUSATZGERÄTE
    # ====================================================================
    chip "k10temp-pci-00c3"
        label temp1 "CPU Package"
        label temp3 "CPU Core"

    chip "iwlwifi_1-virtual-0"
        label temp1 "Wifi Adapter"
  '';
}
