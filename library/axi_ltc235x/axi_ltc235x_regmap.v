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

module axi_ltc235x_regmap #(
	parameter SOFTSPAN_NEXT = 24'hff_ffff
) (

  output      [23:0]  softspan_next,

  // bus interface

  input               up_rstn,
  input               up_clk,
  input               up_wreq,
  input       [13:0]  up_waddr,
  input       [31:0]  up_wdata,
  output              up_wack,
  input               up_rreq,
  input       [13:0]  up_raddr,
  output      [31:0]  up_rdata,
  output              up_rack
);

  // internal registers

  reg         [23:0]  softspan_next_int = SOFTSPAN_NEXT;
  reg                 up_wack_int;
  reg         [31:0]  up_rdata_int;
  reg                 up_rack_int;

  // local parameter

  localparam  SOFTSPAN_ADDR = 14'h50;
  localparam  AXI_LTC235X_ID_ADDR = SOFTSPAN_ADDR + 1;
  localparam  AXI_LTC235X_ID = 32'h17512358;

  // processor read interface

  assign up_wack = up_wack_int;
  assign up_rdata = up_rdata_int;
  assign up_rack = up_rack_int;

  always @(posedge up_clk) begin
    if (up_rstn == 0) begin
      up_rack_int <= 'd0;
      up_rdata_int <= 'd0;
    end else begin
      up_rack_int <= up_rreq;
      if (up_rreq == 1'b1) begin
        case (up_raddr)
          SOFTSPAN_ADDR: up_rdata_int <= {8'b0, softspan_next};
          AXI_LTC235X_ID_ADDR: up_rdata_int <= AXI_LTC235X_ID;
          default: up_rdata_int <= 0;
        endcase
      end else begin
        up_rdata_int <= 32'd0;
      end
    end
  end

  // processor write interface

  assign softspan_next = softspan_next_int;

  always @(posedge up_clk) begin
    if (up_rstn == 0) begin
      up_wack_int <= 'd0;
      softspan_next_int <= SOFTSPAN_NEXT;
    end else begin
      up_wack_int <= up_wreq;
      if ((up_wreq == 1'b1) && (up_waddr == SOFTSPAN_ADDR)) begin
        softspan_next_int <= up_wdata;
      end
    end
  end

endmodule