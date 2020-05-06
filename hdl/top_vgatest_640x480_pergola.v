module top_vgatest_640x480_pergola
(
  input clk_16mhz,
  input btn,
  output [7:0] led,
  output [3:0] gpdi_dp, gpdi_dn,
  output [3:0] debug,
  // output wifi_gpio0
);
    parameter C_ddr = 1'b1; // 0:SDR 1:DDR

    // wifi_gpio0=1 keeps board from rebooting
    // hold btn0 to let ESP32 take control over the board
    // assign wifi_gpio0 = btn[0];

    // clock generator
    wire clk_100MHz, clk100_locked;
    clk_16_100
    clock25_instance
    (
      .clkin(clk_16mhz),
      .clkout0(clk_100MHz),
      .locked(clk100_locked)
    );
    reg [1:0] clk_25MHz_r;
    wire clk_25MHz = clk_25MHz_r[1] & clk100_locked;
    always @(posedge clk_100MHz) begin
      clk_25MHz_r <= clk_25MHz_r + 1;
    end

    assign debug[0] = clk_16mhz;
    assign debug[1] = clk_25MHz;
//    assign debug[2] = clk_100MHz;
    assign debug[2] = clk_125MHz;
    assign debug[3] = clk_250MHz;

    wire clk_250MHz, clk_125MHz, clk_locked;
    clk_25_250_125
    clock_instance
    (
      .clkin(clk_25MHz),
      .clkout0(clk_250MHz),
      .clkout1(clk_125MHz),
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
    assign led[0] = btn[0];
    assign led[7:1] = countblink[7:1];

    // VGA signal generator
    wire [7:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, vga_blank;
    vga
    vga_instance
    (
      .clk_pixel(clk_pixel),
      .test_picture(1'b1), // enable test picture generation
      .vga_r(vga_r),
      .vga_g(vga_g),
      .vga_b(vga_b),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_blank(vga_blank)
    );

    // VGA to digital video converter
    wire [1:0] tmds[3:0];
    vga2dvid
    #(
      .C_ddr(C_ddr)
    )
    vga2dvid_instance
    (
      .clk_pixel(clk_pixel),
      .clk_shift(clk_shift),
      .in_red(vga_r),
      .in_green(vga_g),
      .in_blue(vga_b),
      .in_hsync(vga_hsync),
      .in_vsync(vga_vsync),
      .in_blank(vga_blank),
      .out_clock(tmds[3]),
      .out_red(tmds[2]),
      .out_green(tmds[1]),
      .out_blue(tmds[0])
    );

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