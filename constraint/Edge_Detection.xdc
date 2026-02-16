## Clock
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports { clk }]

## Buttons (from blackboard.xdc)
set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]
set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]

## Switches (sw[0..11] are defined in blackboard.xdc)
set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]
set_property -dict { PACKAGE_PIN U20 IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]
set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { sw[4] }]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { sw[5] }]
set_property -dict { PACKAGE_PIN L15 IOSTANDARD LVCMOS33 } [get_ports { sw[6] }]
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS33 } [get_ports { sw[7] }]
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { sw[8] }]
set_property -dict { PACKAGE_PIN T12 IOSTANDARD LVCMOS33 } [get_ports { sw[9] }]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { sw[10] }]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { sw[11] }]

## IMPORTANT:
## Your current blackboard.xdc does NOT define pins for sw[12..15].
## If your top uses sw[15:8] for threshold, you must either:
##  (A) change RTL to use sw[11:4] for threshold, OR
##  (B) tell me where sw[12..15] actually go on your board so we can constrain them.
## For now we intentionally do NOT constrain sw[12..15] to avoid illegal placement.

## HDMI (use TMDS_33 and the known package pins from your placement report)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD TMDS_33 } [get_ports { hdmi_clk_p }]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD TMDS_33 } [get_ports { hdmi_clk_n }]
set_property -dict { PACKAGE_PIN V17 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_p[0] }]
set_property -dict { PACKAGE_PIN V18 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_n[0] }]
set_property -dict { PACKAGE_PIN N17 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_p[1] }]
set_property -dict { PACKAGE_PIN P18 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_n[1] }]
set_property -dict { PACKAGE_PIN N18 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_p[2] }]
set_property -dict { PACKAGE_PIN P19 IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_n[2] }]

## Camera data bus on PMODA pins 0..7 (your numbering scheme)
set_property -dict { PACKAGE_PIN G20 IOSTANDARD LVCMOS33 } [get_ports { cam_d[0] }]
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports { cam_d[1] }]
set_property -dict { PACKAGE_PIN F17 IOSTANDARD LVCMOS33 } [get_ports { cam_d[2] }]
set_property -dict { PACKAGE_PIN F16 IOSTANDARD LVCMOS33 } [get_ports { cam_d[3] }]
set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports { cam_d[4] }]
set_property -dict { PACKAGE_PIN E17 IOSTANDARD LVCMOS33 } [get_ports { cam_d[5] }]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports { cam_d[6] }]
set_property -dict { PACKAGE_PIN E18 IOSTANDARD LVCMOS33 } [get_ports { cam_d[7] }]

## Camera control on PMODB pins 0..7 (your numbering scheme)
## pin0 PCLK, pin1 HREF, pin2 VSYNC, pin3 XCLK, pin4 SIOC, pin5 SIOD, pin6 PWDN, pin7 RESET
set_property -dict { PACKAGE_PIN F20 IOSTANDARD LVCMOS33 } [get_ports { cam_pclk }]
set_property -dict { PACKAGE_PIN F19 IOSTANDARD LVCMOS33 } [get_ports { cam_href }]
set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS33 } [get_ports { cam_vsync }]
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports { cam_xclk }]
set_property -dict { PACKAGE_PIN A20 IOSTANDARD LVCMOS33 } [get_ports { cam_scl }]
set_property -dict { PACKAGE_PIN B19 IOSTANDARD LVCMOS33 } [get_ports { cam_sda }]
set_property -dict { PACKAGE_PIN B20 IOSTANDARD LVCMOS33 } [get_ports { cam_pwdn }]
set_property -dict { PACKAGE_PIN C20 IOSTANDARD LVCMOS33 } [get_ports { cam_reset_n }]

## I2C/SCCB needs a pull-up on SDA if your camera board doesn't already provide it
set_property PULLUP true [get_ports { cam_sda }]
