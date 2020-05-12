module top_vgatest_640x480_pixeltest
(
  input clk_25mhz,
  input [6:0] btn,
  output [7:0] led,
  output [3:0] gpdi_dp, gpdi_dn,
  output wifi_gpio0
);
    parameter C_ddr = 1'b1; // 0:SDR 1:DDR

    // wifi_gpio0=1 keeps board from rebooting
    // hold btn0 to let ESP32 take control over the board
    assign wifi_gpio0 = btn[0];

    // clock generator
    wire clk_250MHz, clk_125MHz, clk_25MHz, clk_locked;
    clk_25_250_125_25
    clock_instance
    (
      .clkin(clk_25mhz),
      .clkout0(clk_250MHz),
      .clkout1(clk_125MHz),
      .clkout2(clk_25MHz),
      .locked(clk_locked)
    );
    
    // shift clock choice SDR/DDR
    wire clk_pixel, clk_shift;
    assign clk_pixel = clk_25MHz;
    generate
      if(C_ddr == 1'b1)
        assign clk_shift = clk_125MHz;
      else
        assign clk_shift = clk_250MHz;
    endgenerate

    // LED blinky
    localparam counter_width = 28;
    wire [7:0] countblink;
    blink
    #(
      .bits(counter_width)
    )
    blink_instance
    (
      .clk(clk_pixel),
      .led(countblink)
    );
    assign led[0] = btn[1];
    assign led[1] = countblink[4];
    assign led[7:2] = 0;
    // assign led[7:1] = countblink[7:1];


    parameter C_shift_clock_initial = 10'b0000011111;
    parameter C_shift_r_initial     = 10'b1100110011; //2
    parameter C_shift_g_initial     = 10'b0011001100; //1
    parameter C_shift_b_initial     = 10'b0101010101; //0
    reg [9:0] shift_clock = C_shift_clock_initial;
    reg [9:0] shift_r = C_shift_r_initial;
    reg [9:0] shift_g = C_shift_g_initial;
    reg [9:0] shift_b = C_shift_b_initial;
    wire [1:0] tmds[3:0];
    always @(posedge clk_shift) begin
        shift_clock <= {shift_clock[1:0], shift_clock[9:2]};
        shift_r     <= {shift_r[1:0],     shift_r[9:2]};
        shift_g     <= {shift_g[1:0],     shift_g[9:2]};
        shift_b     <= {shift_b[1:0],     shift_b[9:2]};
    end

    assign tmds[0] = shift_b[9:7];
    assign tmds[1] = shift_g[9:7];
    assign tmds[2] = shift_r[9:7];
    assign tmds[3] = shift_clock[9:7];





    // output TMDS SDR/DDR data to fake differential lanes
    fake_differential
    #(
      .C_ddr(C_ddr)
    )
    fake_differential_instance
    (
      .clk_shift(clk_shift),
      .in_clock(tmds[3]),
      .in_red(tmds[2]),
      .in_green(tmds[1]),
      .in_blue(tmds[0]),
      .out_p(gpdi_dp),
      .out_n(gpdi_dn)
    );

endmodule
