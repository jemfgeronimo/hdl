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

module axi_ltc235x_cmos #(
	parameter NUM_CHANNELS = 8,	// 8 for 2358, 4 for 2357, 2 for 2353
	parameter DATA_WIDTH = 18,	// 18 or 16
  parameter ACTIVE_LANE = 8'b1111_1111,
	parameter SOFTSPAN
) (

  input                   rst,
  input                   clk,
  input				[ 7:0]			adc_enable,
	input				[23:0]			softspan,

  // physical interface

  output                  scki,
  output                  db_o,
  input                   scko,
  input       [ 7:0]      db_i,
  input                   busy,

  // FIFO interface

  output      [ 2:0]      adc_ch0_id,
  output      [ 2:0]      adc_ch1_id,
  output      [ 2:0]      adc_ch2_id,
  output      [ 2:0]      adc_ch3_id,
  output      [ 2:0]      adc_ch4_id,
  output      [ 2:0]      adc_ch5_id,
  output      [ 2:0]      adc_ch6_id,
  output      [ 2:0]      adc_ch7_id,
  output      [31:0]      adc_data_0,
  output      [31:0]      adc_data_1,
  output      [31:0]      adc_data_2,
  output      [31:0]      adc_data_3,
  output      [31:0]      adc_data_4,
  output      [31:0]      adc_data_5,
  output      [31:0]      adc_data_6,
  output      [31:0]      adc_data_7,
  output reg              adc_valid
);

  localparam NEG_EDGE = 1;	// unused
  localparam DW = 24;				// packet size
	localparam BW = DW - 1;

  // internal registers

  reg         [BW:0]  adc_lane_0;
  reg         [BW:0]  adc_lane_1;
  reg         [BW:0]  adc_lane_2;
  reg         [BW:0]  adc_lane_3;
  reg         [BW:0]  adc_lane_4;
  reg         [BW:0]  adc_lane_5;
  reg         [BW:0]  adc_lane_6;
  reg         [BW:0]  adc_lane_7;

  reg         [ 4:0]  data_counter = 5'h0;
  reg         [ 4:0]  scki_counter = 5'h0;
  reg         [ 4:0]  data_packets = 5'h0;	// unused
  reg         [ 4:0]  req_packets = 5'h0;		// unused

  reg                 scki_i;
  reg                 scki_d;
  reg                 scko_d;

  reg         [BW:0]  adc_data_store[7:0];
  reg         [BW:0]  adc_data_init[7:0];
  reg                 adc_valid_init;
  reg                 adc_valid_init_d;

  reg         [ 7:0]  ch_capture;
  reg         [ 7:0]  ch_captured;

  reg         [ 4:0]  adc_ch0_shift;
  reg         [ 4:0]  adc_ch1_shift;
  reg         [ 4:0]  adc_ch2_shift;
  reg         [ 4:0]  adc_ch3_shift;
  reg         [ 4:0]  adc_ch4_shift;
  reg         [ 4:0]  adc_ch5_shift;
  reg         [ 4:0]  adc_ch6_shift;
  reg         [ 4:0]  adc_ch7_shift;

  reg         [ 4:0]  adc_ch0_shift_d;
  reg         [ 4:0]  adc_ch1_shift_d;
  reg         [ 4:0]  adc_ch2_shift_d;
  reg         [ 4:0]  adc_ch3_shift_d;
  reg         [ 4:0]  adc_ch4_shift_d;
  reg         [ 4:0]  adc_ch5_shift_d;
  reg         [ 4:0]  adc_ch6_shift_d;
  reg         [ 4:0]  adc_ch7_shift_d;

  reg         [ 2:0]  lane_0_data = 'd0;
  reg         [ 2:0]  lane_1_data = 'd0;
  reg         [ 2:0]  lane_2_data = 'd0;
  reg         [ 2:0]  lane_3_data = 'd0;
  reg         [ 2:0]  lane_4_data = 'd0;
  reg         [ 2:0]  lane_5_data = 'd0;
  reg         [ 2:0]  lane_6_data = 'd0;
  reg         [ 2:0]  lane_7_data = 'd0;
  reg         [ 7:0]  ch_data_lock = 'hff;

  reg                 busy_m1;
  reg                 busy_m2;
  reg                 busy_m3;

  // internal wires

  wire        [31:0]  adc_data_s[7:0];
  wire        [ 2:0]  adc_ch_id_s[7:0];

  wire                start_transfer_s;
  wire                aquire_data;
  wire                scki_cnt_rst;

  // instantiations

  
  always @(posedge clk) begin
    scko_d <= scko;
  end

  always @(posedge clk) begin
    if (rst == 1'b1) begin
      busy_m1 <= 1'b0;
      busy_m2 <= 1'b0;
    end else begin
      busy_m1 <= busy;
      busy_m2 <= busy_m1;
      busy_m3 <= busy_m2;
    end
  end

  assign start_transfer_s = busy_m3 & ~busy_m2;

  // reading clock logic
  always @(posedge clk) begin
    if (rst) begin
      scki_counter <= 5'h0;
      scki_i <= 1'b1;
      scki_d <=  1'b0;
    end else begin
      scki_d <= scki_i;
      if (aquire_data == 1'b0) begin
        scki_counter <= 5'h0;
        scki_i <= 1'b1;
      end else if (scki_cnt_rst & (scki_d & ~scki_i)) begin // end of a capture
        scki_counter <= 5'h1;
        scki_i <= 1'b1;
      end else if (scki_i == 1'b0) begin
        scki_counter <= scki_counter + 1;
        scki_i <= 1'b1;
      end else begin
        scki_counter <= scki_counter;
        scki_i <= ~scki_i;
      end
    end
  end

  assign scki_cnt_rst = (scki_counter == DW) ? 1'b1 : 1'b0;
  assign scki = scki_i | ~aquire_data;

  /*
  The device sends each channel data on one of the 8 lines.
  Data is stored in the device in a ring buffer. After the first packet is read
  and no new conversion is requested if the reading process is restarted,
  the new data on the lines will be from the next index from the ring buffer.
  e.g For second read process without a conversion start
  line 0 = channel 1, line 1 = channel 2, line 2 = channel 3; so on and so forth.

  The ring buffer contains the crc data on the 8(last position.)
  e.g for a 4'th reading cycle:
  line 0 = ch 3
  line 1 = ch 4
  line 2 = ch 5
  line 3 = ch 6
  line 4 = ch 7
  line 5 = crc
  line 6 = ch 0
  line 7 = ch 1

  Because there is no rule for a specific number of lanes to be enabled at a given time
  the interface can handle every combination of enabled lanes with enabled channels.
  The valid signal will only be asserted after all enabled channels are stored,
  including the crc data(if crc_is enabled)
  This means that the user must adjust the sampling frequency based on the
  interface clock frequency and the maximum position/index
  difference +1 of a channel data (or crc) and the first enabled lane that will
  pass that channels data(or crc), maximum difference is 9(e.g line 0 to crc data).
  e.g. If only lanes 1 and 2(0 to 7) are enabled,
    1. The user wants to capture the 6'th(0 to 7) channel, 5 reading cycles are required.
    2. The user wants to capture channel 0, 8 reading cycles are required.
  */

  always @(posedge clk) begin
    if (start_transfer_s) begin
      lane_0_data <= 4'd0;
      lane_1_data <= 4'd1;
      lane_2_data <= 4'd2;
      lane_3_data <= 4'd3;
      lane_4_data <= 4'd4;
      lane_5_data <= 4'd5;
      lane_6_data <= 4'd6;
      lane_7_data <= 4'd7;
      ch_data_lock <= 8'd0;
    end else if (aquire_data == 1'b1 && (scki_cnt_rst & (~scki_d & scki_i))) begin
      lane_0_data <= lane_0_data[3] == 1'b1 ? 4'd0 : lane_0_data + 1;
      lane_1_data <= lane_1_data[3] == 1'b1 ? 4'd0 : lane_1_data + 1;
      lane_2_data <= lane_2_data[3] == 1'b1 ? 4'd0 : lane_2_data + 1;
      lane_3_data <= lane_3_data[3] == 1'b1 ? 4'd0 : lane_3_data + 1;
      lane_4_data <= lane_4_data[3] == 1'b1 ? 4'd0 : lane_4_data + 1;
      lane_5_data <= lane_5_data[3] == 1'b1 ? 4'd0 : lane_5_data + 1;
      lane_6_data <= lane_6_data[3] == 1'b1 ? 4'd0 : lane_6_data + 1;
      lane_7_data <= lane_7_data[3] == 1'b1 ? 4'd0 : lane_7_data + 1;
      ch_data_lock[lane_0_data[3:0]] <= ACTIVE_LANE[0] ? 1'b1 : ch_data_lock[lane_0_data[2:0]];
      ch_data_lock[lane_1_data[3:0]] <= ACTIVE_LANE[1] ? 1'b1 : ch_data_lock[lane_1_data[2:0]];
      ch_data_lock[lane_2_data[3:0]] <= ACTIVE_LANE[2] ? 1'b1 : ch_data_lock[lane_2_data[2:0]];
      ch_data_lock[lane_3_data[3:0]] <= ACTIVE_LANE[3] ? 1'b1 : ch_data_lock[lane_3_data[2:0]];
      ch_data_lock[lane_4_data[3:0]] <= ACTIVE_LANE[4] ? 1'b1 : ch_data_lock[lane_4_data[2:0]];
      ch_data_lock[lane_5_data[3:0]] <= ACTIVE_LANE[5] ? 1'b1 : ch_data_lock[lane_5_data[2:0]];
      ch_data_lock[lane_6_data[3:0]] <= ACTIVE_LANE[6] ? 1'b1 : ch_data_lock[lane_6_data[2:0]];
      ch_data_lock[lane_7_data[3:0]] <= ACTIVE_LANE[7] ? 1'b1 : ch_data_lock[lane_7_data[2:0]];
    end else begin
      lane_0_data <= lane_0_data;
      lane_1_data <= lane_1_data;
      lane_2_data <= lane_2_data;
      lane_3_data <= lane_3_data;
      lane_4_data <= lane_4_data;
      lane_5_data <= lane_5_data;
      lane_6_data <= lane_6_data;
      lane_7_data <= lane_7_data;
      ch_data_lock <= ch_data_lock;
    end
  end

  assign aquire_data = ~((ch_data_lock[0] | ~adc_enable[0]) &
                         (ch_data_lock[1] | ~adc_enable[1]) &
                         (ch_data_lock[2] | ~adc_enable[2]) &
                         (ch_data_lock[3] | ~adc_enable[3]) &
                         (ch_data_lock[4] | ~adc_enable[4]) &
                         (ch_data_lock[5] | ~adc_enable[5]) &
                         (ch_data_lock[6] | ~adc_enable[6]) &
                         (ch_data_lock[7] | ~adc_enable[7]));

  // capture data
  always @(scko) begin
    adc_lane_0 <= {adc_lane_0[BW-1:0], db_i[0]};
    adc_lane_1 <= {adc_lane_1[BW-1:0], db_i[1]};
    adc_lane_2 <= {adc_lane_2[BW-1:0], db_i[2]};
    adc_lane_3 <= {adc_lane_3[BW-1:0], db_i[3]};
    adc_lane_4 <= {adc_lane_4[BW-1:0], db_i[4]};
    adc_lane_5 <= {adc_lane_5[BW-1:0], db_i[5]};
    adc_lane_6 <= {adc_lane_6[BW-1:0], db_i[6]};
    adc_lane_7 <= {adc_lane_7[BW-1:0], db_i[7]};
  end

  always @(posedge clk) begin
    if (rst == 1'b1) begin
      adc_valid_init <= 1'b0;
    end else begin
      if (data_counter == DW && adc_valid_init == 1'b0) begin
        adc_valid_init <= 1'b1;
      end else begin
        adc_valid_init <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (rst == 1'b1 || adc_valid == 1'b1) begin
      adc_valid <= 1'b0;
      adc_valid_init_d <= 1'b0;
      ch_capture <= 9'd0;
      ch_captured <= 9'd0;
    end else begin
      ch_capture <= ch_data_lock;
      ch_captured <= ch_capture;
      adc_valid_init_d <= adc_valid_init;
      adc_valid <= adc_valid_init_d &
                     (ch_captured[0] | ~adc_enable[0]) &
                     (ch_captured[1] | ~adc_enable[1]) &
                     (ch_captured[2] | ~adc_enable[2]) &
                     (ch_captured[3] | ~adc_enable[3]) &
                     (ch_captured[4] | ~adc_enable[4]) &
                     (ch_captured[5] | ~adc_enable[5]) &
                     (ch_captured[6] | ~adc_enable[6]) &
                     (ch_captured[7] | ~adc_enable[7]);
    end
  end

  always @(posedge clk) begin
    if (rst == 1'b1 || adc_valid == 1'b1) begin
      adc_ch0_shift <= 4'd0;
      adc_ch1_shift <= 4'd0;
      adc_ch2_shift <= 4'd0;
      adc_ch3_shift <= 4'd0;
      adc_ch4_shift <= 4'd0;
      adc_ch5_shift <= 4'd0;
      adc_ch6_shift <= 4'd0;
      adc_ch7_shift <= 4'd0;
      adc_ch0_shift_d <= 4'd0;
      adc_ch1_shift_d <= 4'd0;
      adc_ch2_shift_d <= 4'd0;
      adc_ch3_shift_d <= 4'd0;
      adc_ch4_shift_d <= 4'd0;
      adc_ch5_shift_d <= 4'd0;
      adc_ch6_shift_d <= 4'd0;
      adc_ch7_shift_d <= 4'd0;
    end else begin
      adc_ch0_shift <= {ACTIVE_LANE[0],lane_0_data};
      adc_ch1_shift <= {ACTIVE_LANE[1],lane_1_data};
      adc_ch2_shift <= {ACTIVE_LANE[2],lane_2_data};
      adc_ch3_shift <= {ACTIVE_LANE[3],lane_3_data};
      adc_ch4_shift <= {ACTIVE_LANE[4],lane_4_data};
      adc_ch5_shift <= {ACTIVE_LANE[5],lane_5_data};
      adc_ch6_shift <= {ACTIVE_LANE[6],lane_6_data};
      adc_ch7_shift <= {ACTIVE_LANE[7],lane_7_data};
      adc_ch0_shift_d <= adc_ch0_shift;
      adc_ch1_shift_d <= adc_ch1_shift;
      adc_ch2_shift_d <= adc_ch2_shift;
      adc_ch3_shift_d <= adc_ch3_shift;
      adc_ch4_shift_d <= adc_ch4_shift;
      adc_ch5_shift_d <= adc_ch5_shift;
      adc_ch6_shift_d <= adc_ch6_shift;
      adc_ch7_shift_d <= adc_ch7_shift;
    end
  end

  always @(posedge clk) begin
    if (rst == 1'b1) begin
      adc_data_init[0] <= 'h0;
      adc_data_init[1] <= 'h0;
      adc_data_init[2] <= 'h0;
      adc_data_init[3] <= 'h0;
      adc_data_init[4] <= 'h0;
      adc_data_init[5] <= 'h0;
      adc_data_init[6] <= 'h0;
      adc_data_init[7] <= 'h0;
      data_counter <= 'h0;
    end else begin
      data_counter <= scki_counter;
      if (data_counter == DW) begin
        adc_data_init[0] <= adc_lane_0;
        adc_data_init[1] <= adc_lane_1;
        adc_data_init[2] <= adc_lane_2;
        adc_data_init[3] <= adc_lane_3;
        adc_data_init[4] <= adc_lane_4;
        adc_data_init[5] <= adc_lane_5;
        adc_data_init[6] <= adc_lane_6;
        adc_data_init[7] <= adc_lane_7;
      end else begin
        adc_data_init[0] <= adc_data_init[0];
        adc_data_init[1] <= adc_data_init[1];
        adc_data_init[2] <= adc_data_init[2];
        adc_data_init[3] <= adc_data_init[3];
        adc_data_init[4] <= adc_data_init[4];
        adc_data_init[5] <= adc_data_init[5];
        adc_data_init[6] <= adc_data_init[6];
        adc_data_init[7] <= adc_data_init[7];
      end
    end
  end

  always @(posedge clk) begin
    if (rst == 1'b1) begin
      adc_data_store[0] <= 'd0;
      adc_data_store[1] <= 'd0;
      adc_data_store[2] <= 'd0;
      adc_data_store[3] <= 'd0;
      adc_data_store[4] <= 'd0;
      adc_data_store[5] <= 'd0;
      adc_data_store[6] <= 'd0;
      adc_data_store[7] <= 'd0;
    end else begin
      if (!adc_valid_init_d & adc_valid_init) begin
        if (adc_ch0_shift_d[4] == 1'b1) begin
          adc_data_store[adc_ch0_shift_d[2:0]] <= adc_data_init[0];
        end
        if (adc_ch1_shift_d[4] == 1'b1) begin
          adc_data_store[adc_ch1_shift_d[2:0]] <= adc_data_init[1];
        end
        if (adc_ch2_shift_d[4] == 1'b1) begin
          adc_data_store[adc_ch2_shift_d[2:0]] <= adc_data_init[2];
        end
        if (adc_ch3_shift_d[4] == 1'b1) begin
          adc_data_store[adc_ch3_shift_d[2:0]] <= adc_data_init[3];
        end
        if (adc_ch4_shift_d[4] == 1'b1) begin
          adc_data_store[adc_ch4_shift_d[2:0]] <= adc_data_init[4];
        end
        if (adc_ch5_shift_d[4] == 1'b1) begin
          adc_data_store[adc_ch5_shift_d[2:0]] <= adc_data_init[5];
        end
        if (adc_ch6_shift_d[4] == 1'b1) begin
          adc_data_store[adc_ch6_shift_d[2:0]] <= adc_data_init[6];
        end
        if (adc_ch7_shift_d[4] == 1'b1) begin
          adc_data_store[adc_ch7_shift_d[2:0]] <= adc_data_init[7];
        end
      end
    end
  end

  genvar i;
  generate

    for (i=0; i < 8; i=i+1) begin: format
      if (PACKET_FORMAT == 0) begin
        assign adc_data_s[i] = {{12{adc_data_store[i][19]}}, adc_data_store[i]};
        assign adc_ch_id_s[i] = 3'd0;
      end else if (PACKET_FORMAT == 1) begin
        if (OVERSMP_ENABLE == 0) begin
          assign adc_data_s[i] = {{12{adc_data_store[i][23]}}, adc_data_store[i][23:4]};
          assign adc_ch_id_s[i] = adc_data_store[i][2:0];
        end else if (OVERSMP_ENABLE == 1) begin
          assign adc_data_s[i] = {{8{adc_data_store[i][23]}}, adc_data_store[i][23:0]};
          assign adc_ch_id_s[i] = 3'd0;
        end
      end else begin
        if (OVERSMP_ENABLE == 0) begin
          assign adc_data_s[i] = {{12{adc_data_store[i][31]}}, adc_data_store[i][31:12]};
          assign adc_ch_id_s[i] = adc_data_store[i][10:7];
        end else if (OVERSMP_ENABLE == 1) begin
          assign adc_data_s[i] = {{8{adc_data_store[i][31]}}, adc_data_store[i][31:8]};
          assign adc_ch_id_s[i] = adc_data_store[i][6:4];
        end
      end
    end


  endgenerate

  assign adc_data_0 = adc_data_s[0];
  assign adc_data_1 = adc_data_s[1];
  assign adc_data_2 = adc_data_s[2];
  assign adc_data_3 = adc_data_s[3];
  assign adc_data_4 = adc_data_s[4];
  assign adc_data_5 = adc_data_s[5];
  assign adc_data_6 = adc_data_s[6];
  assign adc_data_7 = adc_data_s[7];

  assign adc_ch0_id = adc_ch_id_s[0];
  assign adc_ch1_id = adc_ch_id_s[1];
  assign adc_ch2_id = adc_ch_id_s[2];
  assign adc_ch3_id = adc_ch_id_s[3];
  assign adc_ch4_id = adc_ch_id_s[4];
  assign adc_ch5_id = adc_ch_id_s[5];
  assign adc_ch6_id = adc_ch_id_s[6];
  assign adc_ch7_id = adc_ch_id_s[7];

	// db_o (TODO)

endmodule

