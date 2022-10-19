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

module axi_ltc235x_cmos_tb ();
  parameter NUM_CHANNELS = 8;	// 8 for 2358, 4 for 2357, 2 for 2353
  parameter DATA_WIDTH = 18;	// 18 or 16
  parameter ACTIVE_LANE = 8'b0001_0000;
  parameter SOFTSPAN_NEXT = 24'hf0_f0f0;

  reg                   resetn = 0;
  reg                   clk = 0;
  reg       [ 7:0]      adc_enable = 'h80;//'hff;

  // physical interface

  wire                  scki;
  wire                  db_o;
  reg                   scko = 1;
  reg                   rx_busy = 0;

  // FIFO interface

  wire      [ 2:0]      adc_ch0_id;
  wire      [ 2:0]      adc_ch1_id;
  wire      [ 2:0]      adc_ch2_id;
  wire      [ 2:0]      adc_ch3_id;
  wire      [ 2:0]      adc_ch4_id;
  wire      [ 2:0]      adc_ch5_id;
  wire      [ 2:0]      adc_ch6_id;
  wire      [ 2:0]      adc_ch7_id;
  wire      [31:0]      adc_data_0;
  wire      [31:0]      adc_data_1;
  wire      [31:0]      adc_data_2;
  wire      [31:0]      adc_data_3;
  wire      [31:0]      adc_data_4;
  wire      [31:0]      adc_data_5;
  wire      [31:0]      adc_data_6;
  wire      [31:0]      adc_data_7;
  wire      [ 2:0]      adc_softspan_0;
  wire      [ 2:0]      adc_softspan_0;
  wire      [ 2:0]      adc_softspan_2;
  wire      [ 2:0]      adc_softspan_3;
  wire      [ 2:0]      adc_softspan_4;
  wire      [ 2:0]      adc_softspan_5;
  wire      [ 2:0]      adc_softspan_6;
  wire      [ 2:0]      adc_softspan_7;
  wire                  adc_valid;

	// other registers
  reg       [31:0]      rx_db_i[0:7];
  wire      [23:0]      rx_db_i_24[0:7];
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

  // wires

  wire      [ 2:0]      softspan_next_s;

  axi_ltc235x_cmos #(
    .NUM_CHANNELS (NUM_CHANNELS),
    .DATA_WIDTH (DATA_WIDTH),
    .ACTIVE_LANE (ACTIVE_LANE),
    .SOFTSPAN_NEXT (SOFTSPAN_NEXT)
  ) i_ltc235x_cmos (
    .rst (!resetn),
    .clk (clk),
    .adc_enable (adc_enable),

    .scki (scki),
    .db_o (db_o),
    .scko (scko),
    .db_i (db_i_shift),
    .busy (rx_busy),

    .adc_ch0_id (adc_ch0_id),
    .adc_ch1_id (adc_ch1_id),
    .adc_ch2_id (adc_ch2_id),
    .adc_ch3_id (adc_ch3_id),
    .adc_ch4_id (adc_ch4_id),
    .adc_ch5_id (adc_ch5_id),
    .adc_ch6_id (adc_ch6_id),
    .adc_ch7_id (adc_ch7_id),

    .adc_data_0 (adc_data_0),
    .adc_data_1 (adc_data_1),
    .adc_data_2 (adc_data_2),
    .adc_data_3 (adc_data_3),
    .adc_data_4 (adc_data_4),
    .adc_data_5 (adc_data_5),
    .adc_data_6 (adc_data_6),
    .adc_data_7 (adc_data_7),

    .adc_softspan_0 (adc_softspan_0),
    .adc_softspan_1 (adc_softspan_1),
    .adc_softspan_2 (adc_softspan_2),
    .adc_softspan_3 (adc_softspan_3),
    .adc_softspan_4 (adc_softspan_4),
    .adc_softspan_5 (adc_softspan_5),
    .adc_softspan_6 (adc_softspan_6),
    .adc_softspan_7 (adc_softspan_7),

    .adc_valid (adc_valid)
  );

  always #1 clk = ~clk;

  initial begin
    #40
    resetn <= 1'b1;
    #100
    action <= 1;
    // 18-bit data
    rx_db_i[0] <= 'h8000;
    rx_db_i[1] <= 'h8001;
    rx_db_i[2] <= 'h8002;
    rx_db_i[3] <= 'h8003;
    rx_db_i[4] <= 'h8004;
    rx_db_i[5] <= 'h8005;
    rx_db_i[6] <= 'h8006;
    rx_db_i[7] <= 'h8007;
    #6000
    $finish;	
  end

  // {18-bit data, channel id, softspan}
  assign rx_db_i_24[0] = {rx_db_i[0][17:0], 3'd0, 3'd7};
  assign rx_db_i_24[1] = {rx_db_i[1][17:0], 3'd1, 3'd6};
  assign rx_db_i_24[2] = {rx_db_i[2][17:0], 3'd2, 3'd5};
  assign rx_db_i_24[3] = {rx_db_i[3][17:0], 3'd3, 3'd4};
  assign rx_db_i_24[4] = {rx_db_i[4][17:0], 3'd4, 3'd3};
  assign rx_db_i_24[5] = {rx_db_i[5][17:0], 3'd5, 3'd2};
  assign rx_db_i_24[6] = {rx_db_i[6][17:0], 3'd6, 3'd1};
  assign rx_db_i_24[7] = {rx_db_i[7][17:0], 3'd7, 3'd0};

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
    if (action == 1'b1) begin
      action_d <= action;
      scki_d <= scki;

      // update rx_db_i for next conversion
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
      if (!scki && scki_d) begin
        softspan_next <= {softspan_next[22:0], db_o};
      end
    end
  end

  generate
    genvar i;
    for (i = 0, i < 24; i = i + 3) begin : softspan_next_lane
      assign softspan_next_s = softspan_next[(2+i):i];
    end
  endgenerate

endmodule
