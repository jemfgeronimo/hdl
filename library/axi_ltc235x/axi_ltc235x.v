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

module axi_ltc235x #(
  parameter NUM_CHANNELS = 8,	// 8 for 2358, 4 for 2357, 2 for 2353
  parameter DATA_WIDTH = 18,	// 18 or 16
  parameter ACTIVE_LANE = 8'b1111_1111,
  parameter SOFTSPAN_NEXT = 24'hff_ffff
) (

  input                   rst,
  input                   clk,
  input       [ 7:0]      adc_enable,

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

  output      [ 2:0]      adc_softspan_0,
  output      [ 2:0]      adc_softspan_1,
  output      [ 2:0]      adc_softspan_2,
  output      [ 2:0]      adc_softspan_3,
  output      [ 2:0]      adc_softspan_4,
  output      [ 2:0]      adc_softspan_5,
  output      [ 2:0]      adc_softspan_6,
  output      [ 2:0]      adc_softspan_7,

  output                  adc_valid,

  // AXI Slave Memory Map

  input                   s_axi_aclk,
  input                   s_axi_aresetn,
  input                   s_axi_awvalid,
  input       [15:0]      s_axi_awaddr,
  input       [ 2:0]      s_axi_awprot,
  output                  s_axi_awready,
  input                   s_axi_wvalid,
  input       [31:0]      s_axi_wdata,
  input       [ 3:0]      s_axi_wstrb,
  output                  s_axi_wready,
  output                  s_axi_bvalid,
  output      [ 1:0]      s_axi_bresp,
  input                   s_axi_bready,
  input                   s_axi_arvalid,
  input       [15:0]      s_axi_araddr,
  input       [ 2:0]      s_axi_arprot,
  output                  s_axi_arready,
  output                  s_axi_rvalid,
  output      [ 1:0]      s_axi_rresp,
  output      [31:0]      s_axi_rdata,
  input                   s_axi_rready
);

  // internal registers

  reg                     up_wack = 1'b0;
  reg                     up_rack = 1'b0;
  reg     [31:0]          up_rdata = 32'b0;
  reg                     up_status_or = 1'b0;

  // internal signals

  wire                    up_clk;
  wire                    up_rstn;
  wire                    up_rreq_s;
  wire    [13:0]          up_raddr_s;
  wire                    up_wreq_s;
  wire    [13:0]          up_waddr_s;

  wire                    adc_clk_s;
  wire                    scko_s;

  wire    [ 7:0]          up_adc_or_s;
  wire    [13:0]          up_addr_s;
  wire    [31:0]          up_wdata_s;
  wire    [31:0]          up_rdata_s[0:8];
  wire    [ 8:0]          up_rack_s;
  wire    [ 8:0]          up_wack_s;

  // read raw, feature
  wire                    rd_req_s;
  wire                    wr_req_s;
  wire    [15:0]          wr_data_s;
  wire    [15:0]          rd_data_s;
  wire                    rd_valid_s;

  wire                    adc_rst_s;

  wire    [ 2:0]          adc_status_header[0:7];
  wire    [ 7:0]          adc_crc_err;
  wire    [ 7:0]          adc_or;

  wire                    adc_crc_enable;

  // defaults

  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;

  axi_ltc235x_cmos #(
    .NUM_CHANNELS (NUM_CHANNELS),
    .DATA_WIDTH (DATA_WIDTH),
    .ACTIVE_LANE (ACTIVE_LANE),
    .SOFTSPAN_NEXT (SOFTSPAN_NEXT)
  ) i_ltc235x_cmos (
    .rst (rst),
    .clk (clk),
    .adc_enable (adc_enable),

    .scki (scki),
    .db_o (db_o),
    .scko (scko),
    .db_i (db_i),
    .busy (busy),

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

  // up bus interface

  up_axi #(
    .AXI_ADDRESS_WIDTH (16)
  ) i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

endmodule

