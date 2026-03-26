/*
 * Copyright 2025 PoliTo
 * Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
 * SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 * Author: Tommaso Terzano <tommaso.terzano@polito.it> 
 *                         <tommaso.terzano@gmail.com>
 *  
 * Info: Bridge between interface-based AXI protocol and structure based AXI protocol.
 */

module axi_intfc_bridge #(
  // In channel
  parameter type axi_in_resp_t    = logic,
  parameter type axi_in_req_t     = logic,
  parameter type axi_in_aw_chan_t = logic,
  parameter type axi_in_w_chan_t  = logic,
  parameter type axi_in_b_chan_t  = logic,
  parameter type axi_in_ar_chan_t = logic,
  parameter type axi_in_r_chan_t  = logic,

  parameter int unsigned AxiAddrWidth     = 48,
  parameter int unsigned AxiDataWidth     = 64,
  parameter int unsigned AxiUserWidth     = 10,
  parameter int unsigned AxiInIdWidth     = 6,
  parameter int unsigned LogDepth         = 3,
  parameter int unsigned CdcSyncStages    = 2,

  // AXI Slave
  parameter int unsigned AsyncAxiInAwWidth = (2**LogDepth)*
                                              axi_pkg::aw_width(AxiAddrWidth,
                                                                AxiInIdWidth,
                                                                AxiUserWidth),
  parameter int unsigned AsyncAxiInWWidth  = (2**LogDepth)*
                                              axi_pkg::w_width(AxiDataWidth,
                                                               AxiUserWidth),
  parameter int unsigned AsyncAxiInBWidth  = (2**LogDepth)*
                                              axi_pkg::b_width(AxiInIdWidth,
                                                               AxiUserWidth),
  parameter int unsigned AsyncAxiInArWidth = (2**LogDepth)*
                                              axi_pkg::ar_width(AxiAddrWidth,
                                                                AxiInIdWidth,
                                                                AxiUserWidth),
  parameter int unsigned AsyncAxiInRWidth  = (2**LogDepth)*
                                              axi_pkg::r_width(AxiDataWidth,
                                                               AxiInIdWidth,
                                                               AxiUserWidth)
)(
  /* To the interface side: the interface is master-side, because the bridge is connecting the input requests
   * from the struct side (CHESHIRE) to the interface side.
   */
  AXI_BUS.Master axi_o,

  input logic clk_i,
  input logic pwr_on_rst_ni,

  // AXI Slave port
  input  logic [AsyncAxiInArWidth-1:0] async_axi_in_ar_data_i,
  input  logic [LogDepth:0]            async_axi_in_ar_wptr_i,
  output logic [LogDepth:0]            async_axi_in_ar_rptr_o,
  input  logic [AsyncAxiInAwWidth-1:0] async_axi_in_aw_data_i,
  input  logic [LogDepth:0]            async_axi_in_aw_wptr_i,
  output logic [LogDepth:0]            async_axi_in_aw_rptr_o,
  output logic [AsyncAxiInBWidth-1:0]  async_axi_in_b_data_o,
  output logic [LogDepth:0]            async_axi_in_b_wptr_o,
  input  logic [LogDepth:0]            async_axi_in_b_rptr_i,
  output logic [AsyncAxiInRWidth-1:0]  async_axi_in_r_data_o,
  output logic [LogDepth:0]            async_axi_in_r_wptr_o,
  input  logic [LogDepth:0]            async_axi_in_r_rptr_i,
  input  logic [AsyncAxiInWWidth-1:0]  async_axi_in_w_data_i,
  input  logic [LogDepth:0]            async_axi_in_w_wptr_i,
  output logic [LogDepth:0]            async_axi_in_w_rptr_o
);

  `include "axi/typedef.svh"
  `include "axi/assign.svh"

  axi_in_req_t axi_to_sauria_req;
  axi_in_resp_t axi_to_sauria_resp;
  
  // Assign from interface => local_req
  `AXI_ASSIGN_FROM_REQ(axi_o, axi_to_sauria_req)

  // Assign local_rsp => interface
  `AXI_ASSIGN_TO_RESP(axi_to_sauria_resp, axi_o) 

  axi_cdc_dst #(
    .LogDepth   ( LogDepth          ),
    .SyncStages ( CdcSyncStages     ),
    .aw_chan_t  ( axi_in_aw_chan_t  ),
    .w_chan_t   ( axi_in_w_chan_t   ),
    .b_chan_t   ( axi_in_b_chan_t   ),
    .ar_chan_t  ( axi_in_ar_chan_t  ),
    .r_chan_t   ( axi_in_r_chan_t   ),
    .axi_req_t  ( axi_in_req_t      ),
    .axi_resp_t ( axi_in_resp_t     )
  ) i_sauria_cdc_dst (
    // Asynchronous slave port
    .async_data_slave_aw_data_i ( async_axi_in_aw_data_i ),
    .async_data_slave_aw_wptr_i ( async_axi_in_aw_wptr_i ),
    .async_data_slave_aw_rptr_o ( async_axi_in_aw_rptr_o ),
    .async_data_slave_w_data_i  ( async_axi_in_w_data_i  ),
    .async_data_slave_w_wptr_i  ( async_axi_in_w_wptr_i  ),
    .async_data_slave_w_rptr_o  ( async_axi_in_w_rptr_o  ),
    .async_data_slave_b_data_o  ( async_axi_in_b_data_o  ),
    .async_data_slave_b_wptr_o  ( async_axi_in_b_wptr_o  ),
    .async_data_slave_b_rptr_i  ( async_axi_in_b_rptr_i  ),
    .async_data_slave_ar_data_i ( async_axi_in_ar_data_i ),
    .async_data_slave_ar_wptr_i ( async_axi_in_ar_wptr_i ),
    .async_data_slave_ar_rptr_o ( async_axi_in_ar_rptr_o ),
    .async_data_slave_r_data_o  ( async_axi_in_r_data_o  ),
    .async_data_slave_r_wptr_o  ( async_axi_in_r_wptr_o  ),
    .async_data_slave_r_rptr_i  ( async_axi_in_r_rptr_i  ),
    // Synchronous master port
    .dst_clk_i                  ( clk_i                  ),
    .dst_rst_ni                 ( pwr_on_rst_ni          ),
    .dst_req_o                  ( axi_to_sauria_req     ),
    .dst_resp_i                 ( axi_to_sauria_resp    )
  );


endmodule