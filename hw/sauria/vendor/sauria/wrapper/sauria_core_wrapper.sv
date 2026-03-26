// --------------------
//      INCLUDES
// --------------------

`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "common_cells/registers.svh"

// --------------------
// MODULE DECLARATION
// --------------------

module sauria_core_wrapper #(
    parameter CFG_AXI_DATA_WIDTH    = 32,       // Configuration AXI4-Lite Slave data width
    parameter CFG_AXI_ADDR_WIDTH    = 32,       // Configuration AXI4-Lite Slave address width
    parameter DATA_AXI_DATA_WIDTH   = 32,       // Data AXI4 Slave data width
    parameter DATA_AXI_ADDR_WIDTH   = 32,       // Data AXI4 Slave address width
    parameter DATA_AXI_ID_WIDTH      = 2,       // Data AXI4 Slave ID width
    
    localparam  BYTE = 8,
    localparam  CFG_AXI_BYTE_NUM = CFG_AXI_DATA_WIDTH/BYTE,
    localparam  DATA_AXI_BYTE_NUM = DATA_AXI_DATA_WIDTH/BYTE,
    parameter type reg_req_t = logic,
    parameter type reg_rsp_t = logic,
    parameter type obi_req_t = logic,
    parameter type obi_resp_t = logic
)(
  input  logic     clk_i,
  input  logic     rst_ni,

  // Configuration Interface
  input  reg_req_t reg_req_i,
  output reg_rsp_t reg_rsp_o,

  // SRAMs Interface
  input  obi_req_t sram_req_i,
  output obi_resp_t sram_resp_o,

  output logic      sauria_doneintr_o          // Completion interrupt
);

  /*import cgra_pkg::*;
  import obi_pkg::*;
  import reg_pkg::*;*/


// ------------------------------------------------------------
// Signals
// ------------------------------------------------------------

// AXI4 Lite Interfaces
AXI_LITE #(
  .AXI_ADDR_WIDTH (CFG_AXI_ADDR_WIDTH),
  .AXI_DATA_WIDTH (CFG_AXI_DATA_WIDTH)
)   sauria_cfg_port_mst(), sauria_cfg_port_slv();

// AXI4 Interface
AXI_BUS #(
  .AXI_ADDR_WIDTH (DATA_AXI_ADDR_WIDTH),
  .AXI_DATA_WIDTH (DATA_AXI_DATA_WIDTH),
  .AXI_ID_WIDTH   (DATA_AXI_ID_WIDTH+1),
  .AXI_USER_WIDTH (1) // Unused, but 0 can cause compilation errors
)   sauria_mem_port();


// ------------------------------------------------------------
// Modules instantiation
// ------------------------------------------------------------

//Bridge obi to axi
core2axi #(
    .AXI4_ADDRESS_WIDTH (DATA_AXI_ADDR_WIDTH),
    .AXI4_RDATA_WIDTH   (DATA_AXI_DATA_WIDTH),
    .AXI4_WDATA_WIDTH   (DATA_AXI_DATA_WIDTH),
    .AXI4_ID_WIDTH      (DATA_AXI_ID_WIDTH+1),
    .AXI4_USER_WIDTH    (1), // Unused, but 0 can cause compilation errors
) obi_to_axi_i(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    // obi
    .data_req_i(sram_req_i.req),
    .data_gnt_o(sram_resp_o.gnt),
    .data_rvalid_o(sram_resp_o.rvalid),
    .data_addr_i(sram_req_i.addr),
    .data_we_i(sram_req_i.we),
    .data_be_i(sram_req_i.be),
    .data_rdata_o(sram_resp_o.rdata),
    .data_wdata_i(sram_req_i.wdata),

    // ---------------------------------------------------------
    // AXI TARG Port Declarations ------------------------------
    // ---------------------------------------------------------
    //AXI write address bus -------------- // USED// -----------
    .aw_id_o(sauria_mem_port.aw_id),
    .aw_addr_o(sauria_mem_port.aw_addr),
    .aw_len_o(sauria_mem_port.aw_len),
    .aw_size_o(sauria_mem_port.aw_size),
    .aw_burst_o(sauria_mem_port.aw_burst),
    .aw_lock_o(sauria_mem_port.aw_lock),
    .aw_cache_o(sauria_mem_port.aw_cache),
    .aw_prot_o(sauria_mem_port.aw_prot),
    .aw_region_o(sauria_mem_port.aw_region),
    .aw_user_o(sauria_mem_port.aw_user),
    .aw_qos_o(sauria_mem_port.aw_qos),
    .aw_valid_o(sauria_mem_port.aw_valid),
    .aw_ready_i(sauria_mem_port.aw_ready),
    // ---------------------------------------------------------

    //AXI write data bus -------------- // USED// --------------
    .w_data_o(sauria_mem_port.w_data),
    .w_strb_o(sauria_mem_port.w_strb),
    .w_last_o(sauria_mem_port.w_last),
    .w_user_o(sauria_mem_port.w_user),
    .w_valid_o(sauria_mem_port.w_valid),
    .w_ready_i(sauria_mem_port.w_ready),

    // ---------------------------------------------------------

    //AXI write response bus -------------- // USED// ----------
    .b_id_i(sauria_mem_port.b_id),
    .b_resp_i(sauria_mem_port.b_resp),
    .b_valid_i(sauria_mem_port.b_valid),
    .b_user_i(sauria_mem_port.b_user),
    .b_ready_o(sauria_mem_port.b_ready),

    // ---------------------------------------------------------

    //AXI read address bus -------------------------------------
    .ar_id_o(sauria_mem_port.ar_id),
    .ar_addr_o(sauria_mem_port.ar_addr),
    .ar_len_o(sauria_mem_port.ar_len),
    .ar_size_o(sauria_mem_port.ar_size),
    .ar_burst_o(sauria_mem_port.ar_burst),
    .ar_lock_o(sauria_mem_port.ar_lock),
    .ar_cache_o(sauria_mem_port.ar_cache),
    .ar_prot_o(sauria_mem_port.ar_prot),
    .ar_region_o(sauria_mem_port.ar_region),
    .ar_user_o(sauria_mem_port.ar_user),
    .ar_qos_o(sauria_mem_port.ar_qos),
    .ar_valid_o(sauria_mem_port.ar_valid),
    .ar_ready_i(sauria_mem_port.ar_ready),

    // ---------------------------------------------------------

    //AXI read data bus ----------------------------------------
    .r_id_i(sauria_mem_port.r_id),
    .r_data_i(sauria_mem_port.r_data),
    .r_resp_i(sauria_mem_port.r_resp),
    .r_last_i(sauria_mem_port.r_last),
    .r_user_i(sauria_mem_port.r_user),
    .r_valid_i(sauria_mem_port.r_valid),
    .r_ready_o(sauria_mem_port.r_ready)
    // ---------------------------------------------------------
  );

//Bridge reg to axi_lite
reg_to_axi_lite_intf #(
  .ADDR_WIDTH(CFG_AXI_ADDR_WIDTH),
  .DATA_WIDTH(CFG_AXI_DATA_WIDTH),
  .reg_req_t(reg_req_t), //.reg_req_t(reg_pkg::reg_req_t),
  .reg_rsp_t(reg_rsp_t)  //.reg_rsp_t(reg_pkg::reg_rsp_t)
) reg_to_axi_lite_i(
  .clk_i(clk_i),
  .rst_ni(rst_ni),

  .reg_req_i(reg_req_i),
  .reg_rsp_o(reg_rsp_o),

  .axi_o(sauria_cfg_port_mst)
);

`AXI_LITE_ASSIGN(sauria_cfg_port_slv, sauria_cfg_port_mst)

// SAURIA Core
sauria_core #(
    .CFG_AXI_DATA_WIDTH             (CFG_AXI_DATA_WIDTH),
    .CFG_AXI_ADDR_WIDTH             (CFG_AXI_ADDR_WIDTH),
    .DATA_AXI_DATA_WIDTH            (DATA_AXI_DATA_WIDTH),
    .DATA_AXI_ADDR_WIDTH            (DATA_AXI_ADDR_WIDTH),
    .DATA_AXI_ID_WIDTH              (DATA_AXI_ID_WIDTH+1)
) sauria_core_i(
    .i_clk      (clk_i),
    .i_rstn     (rst_ni),

    .cfg_slv    (sauria_cfg_port_slv),
    .mem_slv    (sauria_mem_port),

    .o_doneintr (sauria_doneintr_o)
);



endmodule

