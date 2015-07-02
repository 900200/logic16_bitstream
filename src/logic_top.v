`timescale 1ns / 1ps

module logic_top(
    input CLKIN48,
    input IFCLK,
    output LED,
    output MISO,
    input MOSI,
    input SS,
    input SCLK,
    output [7:0] PORT_B,
    output [7:0] PORT_D,
    output RDY0,
    input CTL0,
    input [15:0] PROBE
);

wire clksel, clkgen_rst;
wire fastclk, normalclk;

assign clkgen_rst = 1'b0;
assign ncd_rst = 1'b0;
assign fcd_rst = 1'b0;

clock_generator clkgen (.U1_CLKIN_IN(CLKIN48), .U1_U2_SELECT_IN(clksel),
                        .U1_RST_IN(clkgen_rst), .U2_RST_IN(clkgen_rst),
			.U1_CLKIN_IBUFG_OUT(normalclk), .U1_U2_CLK_OUT(fastclk),
			.U1_LOCKED_OUT(), .U2_LOCKED_OUT());

wire fifo_reset; // async

wire [15:0] sample_data;  // fast clock domain
wire sample_data_avail;   // - " -

assign fifo_reset = 1'b0;

fifo_generator_v9_3 fifo(.rst(fifo_reset), .wr_clk(fastclk), .rd_clk(IFCLK),
                         .din(sample_data), .wr_en(sample_data_avail),
                         .rd_en(~CTL0), .dout({PORT_D, PORT_B}),
                         .full(), .overflow(),
                         .empty(), .valid(RDY0));

wire acq_enable_ncd, acq_enable_fcd;
wire [7:0] clkdiv_ncd, clkdiv_fcd;

normal_clock_domain ncd(.clk(normalclk), .rst(ncd_rst), .miso(MISO),
			.mosi(MOSI), .ss(SS), .sclk(SCLK), .led_out(LED),
			.acq_enable(acq_enable_ncd),
			.clock_select(clksel), .clock_divisor(clkdiv_ncd));

synchronizer acq_enable_sync (.clk(fastclk),
			      .in(acq_enable_ncd), .out(acq_enable_fcd));

synchronizer #(8) clkdiv_sync (.clk(fastclk),
			       .in(clkdiv_ncd), .out(clkdiv_fcd));

fast_clock_domain fcd(.clk(fastclk), .rst(fcd_rst), .probe(PROBE),
		      .sample_data(sample_data),
		      .sample_data_avail(sample_data_avail),
		      .acq_enable(acq_enable_fcd),
		      .clock_divisor(clkdiv_fcd));

endmodule
