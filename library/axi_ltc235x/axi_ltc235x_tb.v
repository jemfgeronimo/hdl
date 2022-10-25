// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module axi_ltc235x_tb ();
  parameter       LVDS_CMOS_N = 0;
  parameter       LANE_0_ENABLE = 1;
  parameter       LANE_1_ENABLE = 1;
  parameter       LANE_2_ENABLE = 1;
  parameter       LANE_3_ENABLE = 1;
  parameter       LANE_4_ENABLE = 1;
  parameter       LANE_5_ENABLE = 1;
  parameter       LANE_6_ENABLE = 1;
  parameter       LANE_7_ENABLE = 1;

  parameter       NUM_CHANNELS = 8;	            // 8 for 2358, 4 for 2357, 2 for 2353
  parameter       DATA_WIDTH = 18;	            // 18 or 16
  parameter       SOFTSPAN_NEXT = 24'hf0_f0f0; // TODO: make this an input signal
  parameter       EXTERNAL_CLK = 0;

  reg                   resetn = 0;
  reg                   clk = 0;
  reg       [ 7:0]      adc_enable = 'b1111_1111;

  // physical interface

  reg                   external_clk = 'd0;

  wire                  scki;
  reg                   scko = 1;
  reg                   rx_busy = 0;
  wire                  lvds_cmos_n;
  wire                  db_o;

  // FIFO interface

  wire      [31:0]      adc_data_0;
  wire      [31:0]      adc_data_1;
  wire      [31:0]      adc_data_2;
  wire      [31:0]      adc_data_3;
  wire      [31:0]      adc_data_4;
  wire      [31:0]      adc_data_5;
  wire      [31:0]      adc_data_6;
  wire      [31:0]      adc_data_7;
  wire                  adc_valid;

	// other registers
  reg       [31:0]      rx_db_i[0:7];
  wire      [23:0]      rx_db_i_24[0:7];
  reg       [ 2:0]      rx_db_i_ch[0:7];
  reg       [ 2:0]      rx_db_i_softspan[0:7];
  reg       [ 4:0]      db_i_index = 23;
  reg       [ 3:0]      ring_buffer_index = 0;

  reg       [ 2:0]      ch_index_lane_0 = 0;
  reg       [ 2:0]      ch_index_lane_1 = 1;
  reg       [ 2:0]      ch_index_lane_2 = 2;
  reg       [ 2:0]      ch_index_lane_3 = 3;
  reg       [ 2:0]      ch_index_lane_4 = 4;
  reg       [ 2:0]      ch_index_lane_5 = 5;
  reg       [ 2:0]      ch_index_lane_6 = 6;
  reg       [ 2:0]      ch_index_lane_7 = 7;
  reg       [ 7:0]      db_i_shift = 0;

  reg                   rx_busy_d = 0;
  reg       [ 2:0]      busy_counter = 'd0;

  reg                   action = 'd0;
  reg                   action_d = 'd0;

  reg                   scki_d = 0;

  reg       [23:0]      softspan_next = 24'd0;
  reg       [ 4:0]      softspan_counter = 'd0;

  // wires

  wire      [ 2:0]      softspan_next_s [7:0];
  
  genvar                i;

  axi_ltc235x #(
    .LVDS_CMOS_N (LVDS_CMOS_N),
    .LANE_0_ENABLE (LANE_0_ENABLE),
    .LANE_1_ENABLE (LANE_1_ENABLE),
    .LANE_2_ENABLE (LANE_2_ENABLE),
    .LANE_3_ENABLE (LANE_3_ENABLE),
    .LANE_4_ENABLE (LANE_4_ENABLE),
    .LANE_5_ENABLE (LANE_5_ENABLE),
    .LANE_6_ENABLE (LANE_6_ENABLE),
    .LANE_7_ENABLE (LANE_7_ENABLE),
    .NUM_CHANNELS (NUM_CHANNELS),
    .DATA_WIDTH (DATA_WIDTH),
    .SOFTSPAN_NEXT (SOFTSPAN_NEXT),
    .EXTERNAL_CLK (EXTERNAL_CLK)
  ) i_ltc235x (
    .external_clk (external_clk),
    .scki (scki),
    .scko (scko),
    .busy (rx_busy),
    .lvds_cmos_n (lvds_cmos_n),
    .sdi (db_o),
    .lane_0 (db_i_shift[0]),
    .lane_1 (db_i_shift[1]),
    .lane_2 (db_i_shift[2]),
    .lane_3 (db_i_shift[3]),
    .lane_4 (db_i_shift[4]),
    .lane_5 (db_i_shift[5]),
    .lane_6 (db_i_shift[6]),
    .lane_7 (db_i_shift[7]),
    .adc_valid (adc_valid),
    .adc_data_0 (adc_data_0),
    .adc_data_1 (adc_data_1),
    .adc_data_2 (adc_data_2),
    .adc_data_3 (adc_data_3),
    .adc_data_4 (adc_data_4),
    .adc_data_5 (adc_data_5),
    .adc_data_6 (adc_data_6),
    .adc_data_7 (adc_data_7),

    .s_axi_aclk      (clk),
    .s_axi_aresetn  (resetn),
    .s_axi_awvalid  ('d0),
    .s_axi_awaddr   ('d0),
    .s_axi_awprot   ('d0),
    .s_axi_awready  (   ),
    .s_axi_wvalid   ('d0),
    .s_axi_wdata    ('d0),
    .s_axi_wstrb    ('d0),
    .s_axi_wready   (   ),
    .s_axi_bvalid   (   ),
    .s_axi_bresp    (   ),
    .s_axi_bready   ('d0),
    .s_axi_arvalid  ('d0),
    .s_axi_araddr   ('d0),
    .s_axi_arprot   ('d0),
    .s_axi_arready  (   ),
    .s_axi_rvalid   (   ),
    .s_axi_rresp    (   ),
    .s_axi_rdata    (   ),
    .s_axi_rready   ('d0)
  );

  always #1 clk = ~clk;

  initial begin
    #40
    resetn <= 1'b1;
    #100
    action <= 1;
    // 18-bit data
    rx_db_i[0] <= 'h28000; rx_db_i_ch[0] = 0; rx_db_i_softspan[0] = 7;  // 2's complement
    rx_db_i[1] <= 'h28001; rx_db_i_ch[1] = 1; rx_db_i_softspan[1] = 0;  // 0
    rx_db_i[2] <= 'h28002; rx_db_i_ch[2] = 2; rx_db_i_softspan[2] = 6;  // 2's complement
    rx_db_i[3] <= 'h28003; rx_db_i_ch[3] = 3; rx_db_i_softspan[3] = 1;  // straight binary
    rx_db_i[4] <= 'h28004; rx_db_i_ch[4] = 4; rx_db_i_softspan[4] = 5;  // straight binary
    rx_db_i[5] <= 'h28005; rx_db_i_ch[5] = 5; rx_db_i_softspan[5] = 2;  // 2's complement
    rx_db_i[6] <= 'h28006; rx_db_i_ch[6] = 6; rx_db_i_softspan[6] = 4;  // straight binary
    rx_db_i[7] <= 'h28007; rx_db_i_ch[7] = 7; rx_db_i_softspan[7] = 3;  // 2's complement
    #4500
    action <= 0;  softspan_counter <= 'd0;
    #100
    action <= 1;
    #3000
    $finish;	
  end

  // external clock
  generate
    if (EXTERNAL_CLK == 1'b1) begin
      always #1 external_clk = ~external_clk;
    end
  endgenerate

  // {18-bit data, channel id, softspan}
  generate
    for (i = 0; i < 8; i = i + 1) begin
      assign rx_db_i_24[i] = {rx_db_i[i][17:0], rx_db_i_ch[i], rx_db_i_softspan[i]};
    end
  endgenerate

  // scko logic
  always @(posedge clk) begin
    if (!rx_busy && rx_busy_d) begin
      scko <= 1'b0;
    end else if (!scki && scki_d) begin
      scko <= ~scko;
    end
  end

  // simulate transmission of bits from the adc
  always @(posedge clk) begin
    action_d <= action;
    if (action == 1'b1) begin
      scki_d <= scki;

      // update rx_db_i for next conversion
      // update rx_db_i_softspan for next conversion
      if (adc_valid) begin
        rx_db_i[0] <= rx_db_i[0] + 1;
        rx_db_i[1] <= rx_db_i[1] + 1;
        rx_db_i[2] <= rx_db_i[2] + 1;
        rx_db_i[3] <= rx_db_i[3] + 1;
        rx_db_i[4] <= rx_db_i[4] + 1;
        rx_db_i[5] <= rx_db_i[5] + 1;
        rx_db_i[6] <= rx_db_i[6] + 1;
        rx_db_i[7] <= rx_db_i[7] + 1;
        rx_db_i_softspan[0] <= rx_db_i_softspan[0] + 2;
        rx_db_i_softspan[1] <= rx_db_i_softspan[1] + 2;
        rx_db_i_softspan[2] <= rx_db_i_softspan[2] + 2;
        rx_db_i_softspan[3] <= rx_db_i_softspan[3] + 2;
        rx_db_i_softspan[4] <= rx_db_i_softspan[4] + 2;
        rx_db_i_softspan[5] <= rx_db_i_softspan[5] + 2;
        rx_db_i_softspan[6] <= rx_db_i_softspan[6] + 2;
        rx_db_i_softspan[7] <= rx_db_i_softspan[7] + 2;
      end else begin
        rx_db_i[0] <= rx_db_i[0];
        rx_db_i[1] <= rx_db_i[1];
        rx_db_i[2] <= rx_db_i[2];
        rx_db_i[3] <= rx_db_i[3];
        rx_db_i[4] <= rx_db_i[4];
        rx_db_i[5] <= rx_db_i[5];
        rx_db_i[6] <= rx_db_i[6];
        rx_db_i[7] <= rx_db_i[7];
        rx_db_i_softspan[0] <= rx_db_i_softspan[0];
        rx_db_i_softspan[1] <= rx_db_i_softspan[1];
        rx_db_i_softspan[2] <= rx_db_i_softspan[2];
        rx_db_i_softspan[3] <= rx_db_i_softspan[3];
        rx_db_i_softspan[4] <= rx_db_i_softspan[4];
        rx_db_i_softspan[5] <= rx_db_i_softspan[5];
        rx_db_i_softspan[6] <= rx_db_i_softspan[6];
        rx_db_i_softspan[7] <= rx_db_i_softspan[7];
      end

      // on every posedge of scki
      // update index of databits to be sent
      // update index of ring buffer
      // update ch of each lane
      // send 1 bit at a time from the databits
      if (rx_busy_d & !rx_busy) begin
        db_i_index <= 23;
        ring_buffer_index <= 0;

        db_i_shift[0] <= db_i_shift[0];
        db_i_shift[1] <= db_i_shift[1];
        db_i_shift[2] <= db_i_shift[2];
        db_i_shift[3] <= db_i_shift[3];
        db_i_shift[4] <= db_i_shift[4];
        db_i_shift[5] <= db_i_shift[5];
        db_i_shift[6] <= db_i_shift[6];
        db_i_shift[7] <= db_i_shift[7];

        ch_index_lane_0 <= 0;
        ch_index_lane_1 <= 1;
        ch_index_lane_2 <= 2;
        ch_index_lane_3 <= 3;
        ch_index_lane_4 <= 4;
        ch_index_lane_5 <= 5;
        ch_index_lane_6 <= 6;
        ch_index_lane_7 <= 7;
      end else if (~scki & scki_d) begin
        db_i_index <= (db_i_index != 'd0) ? db_i_index - 1 : 23;
        ring_buffer_index <= (db_i_index == 'd0) ? ring_buffer_index +1 : (ring_buffer_index == 8) ? 0 : ring_buffer_index;

        ch_index_lane_0 <= (0 + ring_buffer_index) == 8 ? 0 : (0 + ring_buffer_index) > 8 ? (0 + ring_buffer_index) -8 : 0 + ring_buffer_index;
        ch_index_lane_1 <= (1 + ring_buffer_index) == 8 ? 0 : (1 + ring_buffer_index) > 8 ? (1 + ring_buffer_index) -8 : 1 + ring_buffer_index;
        ch_index_lane_2 <= (2 + ring_buffer_index) == 8 ? 0 : (2 + ring_buffer_index) > 8 ? (2 + ring_buffer_index) -8 : 2 + ring_buffer_index;
        ch_index_lane_3 <= (3 + ring_buffer_index) == 8 ? 0 : (3 + ring_buffer_index) > 8 ? (3 + ring_buffer_index) -8 : 3 + ring_buffer_index;
        ch_index_lane_4 <= (4 + ring_buffer_index) == 8 ? 0 : (4 + ring_buffer_index) > 8 ? (4 + ring_buffer_index) -8 : 4 + ring_buffer_index;
        ch_index_lane_5 <= (5 + ring_buffer_index) == 8 ? 0 : (5 + ring_buffer_index) > 8 ? (5 + ring_buffer_index) -8 : 5 + ring_buffer_index;
        ch_index_lane_6 <= (6 + ring_buffer_index) == 8 ? 0 : (6 + ring_buffer_index) > 8 ? (6 + ring_buffer_index) -8 : 6 + ring_buffer_index;
        ch_index_lane_7 <= (7 + ring_buffer_index) == 8 ? 0 : (7 + ring_buffer_index) > 8 ? (7 + ring_buffer_index) -8 : 7 + ring_buffer_index;

        db_i_shift[0] <= rx_db_i_24[ch_index_lane_0][db_i_index];
        db_i_shift[1] <= rx_db_i_24[ch_index_lane_1][db_i_index];
        db_i_shift[2] <= rx_db_i_24[ch_index_lane_2][db_i_index];
        db_i_shift[3] <= rx_db_i_24[ch_index_lane_3][db_i_index];
        db_i_shift[4] <= rx_db_i_24[ch_index_lane_4][db_i_index];
        db_i_shift[5] <= rx_db_i_24[ch_index_lane_5][db_i_index];
        db_i_shift[6] <= rx_db_i_24[ch_index_lane_6][db_i_index];
        db_i_shift[7] <= rx_db_i_24[ch_index_lane_7][db_i_index];
      end

      // simulate busy signal
      rx_busy_d <= rx_busy;
      if (action && !action_d) begin
        busy_counter <= 'd0;
        rx_busy <= 1'b1;
      end else if (busy_counter == 'd4) begin
        busy_counter <= 'd0;
        rx_busy <= 1'b0;
      end else if (rx_busy == 1'b1) begin
        busy_counter <= busy_counter +1;
        rx_busy <= 1'b1;
      end

      // receive softspan for next conversion
      // every posedge scki
      if (!scki && scki_d && softspan_counter < 24) begin
        softspan_next <= {softspan_next[22:0], db_o};
        softspan_counter <= softspan_counter + 1'b1;
      end
    end
  end

  generate
    for (i = 0; i < 8; i = i + 1) begin
      assign softspan_next_s[i] = softspan_next[(2 + (i*3)) : (i*3)];
    end
  endgenerate

endmodule
