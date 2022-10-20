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

  parameter       SAMPLING_PERIOD = 49; // clock cycles

  parameter       LANE_0_ENABLE = 1;
  parameter       LANE_1_ENABLE = 1;
  parameter       LANE_2_ENABLE = 1;
  parameter       LANE_3_ENABLE = 1;
  parameter       LANE_4_ENABLE = 1;
  parameter       LANE_5_ENABLE = 1;
  parameter       LANE_6_ENABLE = 1;
  parameter       LANE_7_ENABLE = 1;
  parameter       IF_TYPE = 1;
  parameter       EXTERNAL_CLK = 0;
  parameter       OVERSAMPLING = 0;

  reg         [31:0]      rx_db_i[0:7];
  wire        [23:0]      rx_db_i_24[0:7];
  reg         [ 4:0]      db_i_index = 23;
  reg         [ 3:0]      ring_buffer_index = 0;

  reg         [ 3:0]      ch_index_lane_0 = 0;
  reg         [ 3:0]      ch_index_lane_1 = 1;
  reg         [ 3:0]      ch_index_lane_2 = 2;
  reg         [ 3:0]      ch_index_lane_3 = 3;
  reg         [ 3:0]      ch_index_lane_4 = 4;
  reg         [ 3:0]      ch_index_lane_5 = 5;
  reg         [ 3:0]      ch_index_lane_6 = 6;
  reg         [ 3:0]      ch_index_lane_7 = 7;
  reg         [ 7:0]      db_i_shift = 0;

  reg                     external_clk = 'd0;

  reg                     rx_busy = 0;
  reg                     rx_busy_d = 0;
  reg                     cnvs = 0;
  reg                     cnvs_d = 0;
  reg                     busy_oversamp = 0;
  reg                     action = 'd0;


  wire                    scki;

  wire                    adc_valid;
  wire        [31:0]      adc_data_0;
  wire        [31:0]      adc_data_1;
  wire        [31:0]      adc_data_2;
  wire        [31:0]      adc_data_3;
  wire        [31:0]      adc_data_4;
  wire        [31:0]      adc_data_5;
  wire        [31:0]      adc_data_6;
  wire        [31:0]      adc_data_7;

  // internal registers

  reg                     clk = 1'b0;
  reg                     resetn = 1'b0;
  reg     [31:0]          up_rdata = 32'b0;


  // clocks

  always #1 clk = ~clk;

  initial begin
      #40
      resetn <= 1'b1;
      #100
      action <= 1;
      rx_db_i[0] <= 'h80000;
      rx_db_i[1] <= 'h80001;
      rx_db_i[2] <= 'h80002;
      rx_db_i[3] <= 'h80003;
      rx_db_i[4] <= 'h80004;
      rx_db_i[5] <= 'h80005;
      rx_db_i[6] <= 'h80006;
      rx_db_i[7] <= 'h80007;
      #6000
      $finish;
  end

  generate
    if (EXTERNAL_CLK == 1'b1) begin
      always #1 external_clk = ~external_clk;
    end
  endgenerate

  reg [7:0] conv_counter = 'd0;
  reg [7:0] oversampling_counter = 'd0;
  reg [7:0] busy_counter = 'd0;

  reg       scki_d = 'd0;
  reg       incr_data = 'd0;

  if (OVERSAMPLING == 0) begin
    assign rx_db_i_24[0] = {rx_db_i[0][19:0], 4'd0};
    assign rx_db_i_24[1] = {rx_db_i[1][19:0], 4'd1};
    assign rx_db_i_24[2] = {rx_db_i[2][19:0], 4'd2};
    assign rx_db_i_24[3] = {rx_db_i[3][19:0], 4'd3};
    assign rx_db_i_24[4] = {rx_db_i[4][19:0], 4'd4};
    assign rx_db_i_24[5] = {rx_db_i[5][19:0], 4'd5};
    assign rx_db_i_24[6] = {rx_db_i[6][19:0], 4'd6};
    assign rx_db_i_24[7] = {rx_db_i[7][19:0], 4'd7};
    assign rx_db_i_24[8] = 'h2CEC;
  end else begin
    assign rx_db_i_24[0] = rx_db_i[0][23:0];
    assign rx_db_i_24[1] = rx_db_i[1][23:0];
    assign rx_db_i_24[2] = rx_db_i[2][23:0];
    assign rx_db_i_24[3] = rx_db_i[3][23:0];
    assign rx_db_i_24[4] = rx_db_i[4][23:0];
    assign rx_db_i_24[5] = rx_db_i[5][23:0];
    assign rx_db_i_24[6] = rx_db_i[6][23:0];
    assign rx_db_i_24[7] = rx_db_i[7][23:0];
    assign rx_db_i_24[8] = 'h2CEC;
  end

  always @(posedge clk) begin
    if (action == 1'b0) begin
      conv_counter <= 'd0;
    end else begin
      scki_d <= scki;
      if (adc_valid && adc_data_0 == rx_db_i[0]) begin
        rx_db_i[0] <= rx_db_i[0] + 1;
        rx_db_i[1] <= rx_db_i[1] + 1;
        rx_db_i[2] <= rx_db_i[2] + 1;
        rx_db_i[3] <= rx_db_i[3] + 1;
        rx_db_i[4] <= rx_db_i[4] + 1;
        rx_db_i[5] <= rx_db_i[5] + 1;
        rx_db_i[6] <= rx_db_i[6] + 1;
        rx_db_i[7] <= rx_db_i[7] + 1;
      end else begin
        rx_db_i[0] <= rx_db_i[0];
        rx_db_i[1] <= rx_db_i[1];
        rx_db_i[2] <= rx_db_i[2];
        rx_db_i[3] <= rx_db_i[3];
        rx_db_i[4] <= rx_db_i[4];
        rx_db_i[5] <= rx_db_i[5];
        rx_db_i[6] <= rx_db_i[6];
        rx_db_i[7] <= rx_db_i[7];
      end

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

      cnvs_d <= cnvs;
      rx_busy_d <= rx_busy;

      if (conv_counter == 'd4) begin
        cnvs <= 1'b1;
      end else begin
        cnvs <= 1'b0;
      end

      if (~cnvs_d & cnvs && rx_busy == 1'b0 || busy_oversamp == 1) begin
        busy_counter <= 'd0;
        rx_busy <= 1'b1;
      end else if (busy_counter == 'd4) begin
        busy_counter <= 'd0;
        rx_busy <= busy_oversamp;
      end else if (rx_busy == 1'b1) begin
        busy_counter <= busy_counter +1;
        rx_busy <= 1'b1;
      end

      if (OVERSAMPLING == 1) begin
        if (oversampling_counter == 'd4) begin
          oversampling_counter <= 'd0;
          busy_oversamp <= 1'b0;
        end else if (~cnvs & cnvs_d && oversampling_counter < 'd4 && rx_busy == 1'b1) begin
          oversampling_counter <= oversampling_counter +1;
          busy_oversamp <= 1'b1;
        end
      end

      if (conv_counter < SAMPLING_PERIOD) begin
        conv_counter <= conv_counter +1;
      end else begin
        conv_counter <= 'd0;
      end
    end
  end

  axi_ltc235x #(
    .LVDS_CMOS_N (1'b0),
    .LANE_0_ENABLE (LANE_0_ENABLE),
    .LANE_1_ENABLE (LANE_1_ENABLE),
    .LANE_2_ENABLE (LANE_2_ENABLE),
    .LANE_3_ENABLE (LANE_3_ENABLE),
    .LANE_4_ENABLE (LANE_4_ENABLE),
    .LANE_5_ENABLE (LANE_5_ENABLE),
    .LANE_6_ENABLE (LANE_6_ENABLE),
    .LANE_7_ENABLE (LANE_7_ENABLE),
    .OVERSMP_ENABLE (OVERSAMPLING),
    .EXTERNAL_CLK (1'b0))
  i_ltc235x (
    .lane_0 (db_i_shift[0]),
    .lane_1 (db_i_shift[1]),
    .lane_2 (db_i_shift[2]),
    .lane_3 (db_i_shift[3]),
    .lane_4 (db_i_shift[4]),
    .lane_5 (db_i_shift[5]),
    .lane_6 (db_i_shift[6]),
    .lane_7 (db_i_shift[7]),
    .scki (scki),
    .scko (scki_d),
    .external_clk (external_clk),
    .busy (rx_busy),
    .cnvs (cnvs),
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
    .s_axi_aresetn   (resetn),
    .s_axi_awvalid   ('d0),
    .s_axi_awaddr    ('d0),
    .s_axi_awprot    ('d0),
    .s_axi_awready   (   ),
    .s_axi_wvalid    ('d0),
    .s_axi_wdata     ('d0),
    .s_axi_wstrb     ('d0),
    .s_axi_wready    (   ),
    .s_axi_bvalid    (   ),
    .s_axi_bresp     (   ),
    .s_axi_bready    ('d0),
    .s_axi_arvalid   ('d0),
    .s_axi_araddr    ('d0),
    .s_axi_arprot    ('d0),
    .s_axi_arready   (   ),
    .s_axi_rvalid    (   ),
    .s_axi_rresp     (   ),
    .s_axi_rdata     (   ),
    .s_axi_rready    ('d0));

endmodule
