`define TRUE 1'b1
`define FALSE 1'b0

module xillydemo(input CLK_P, CLK_N, reset
  ,input  PCIE_PERST_B_LS
  ,input  PCIE_REFCLK_N, PCIE_REFCLK_P
  ,input [3:0] PCIE_RX_N, PCIE_RX_P
  ,output [3:0] PCIE_TX_N, PCIE_TX_P
  ,output [7:0] GPIO_LED);

  //Xillybus signals
  wire 	bus_clk, quiesce;
   // Wires related to /dev/xillybus_mem_8
   wire       user_r_mem_8_rden;
   wire       user_r_mem_8_empty;
   reg [7:0]  user_r_mem_8_data;
   wire       user_r_mem_8_eof;
   wire       user_r_mem_8_open;
   wire       user_w_mem_8_wren;
   wire       user_w_mem_8_full;
   wire [7:0] user_w_mem_8_data;
   wire       user_w_mem_8_open;
   wire [4:0] user_mem_8_addr;
   wire       user_mem_8_addr_update;

   // Wires related to /dev/xillybus_read_32
   wire       user_r_read_32_rden;
   wire       user_r_read_32_empty;
   wire [31:0] user_r_read_32_data;
   wire        user_r_read_32_eof;
   wire        user_r_read_32_open;

   // Wires related to /dev/xillybus_read_8
   wire        user_r_read_8_rden;
   wire        user_r_read_8_empty;
   wire [7:0]  user_r_read_8_data;
   wire        user_r_read_8_eof;
   wire        user_r_read_8_open;

   // Wires related to /dev/xillybus_write_32
   wire        user_w_write_32_wren;
   wire        user_w_write_32_full;
   wire [31:0] user_w_write_32_data;
   wire        user_w_write_32_open;

   // Wires related to /dev/xillybus_write_8
   wire        user_w_write_8_wren;
   wire        user_w_write_8_full;
   wire [7:0]  user_w_write_8_data;
   wire        user_w_write_8_open;

  reg pc_msg32_ack; // Command from the PC to FPGA
  wire[31:0] pc_msg32;
  wire pc_msg32_empty;
  reg send_data;
  reg[11:0] top_pixel, bottom_pixel;
  wire xb_rd_fifo_full;
  reg[3:0] n_msg;
  
  //IBUFGDS dsClkBuf(.O(clk), .I(CLK_P), .IB(CLK_N));
  
   xillybus xillybus_ins (
			  // Ports related to /dev/xillybus_mem_8
			  // FPGA to CPU signals:
			  .user_r_mem_8_rden(user_r_mem_8_rden),
			  .user_r_mem_8_empty(user_r_mem_8_empty),
			  .user_r_mem_8_data(user_r_mem_8_data),
			  .user_r_mem_8_eof(user_r_mem_8_eof),
			  .user_r_mem_8_open(user_r_mem_8_open),

			  // CPU to FPGA signals:
			  .user_w_mem_8_wren(user_w_mem_8_wren),
			  .user_w_mem_8_full(user_w_mem_8_full),
			  .user_w_mem_8_data(user_w_mem_8_data),
			  .user_w_mem_8_open(user_w_mem_8_open),

			  // Address signals:
			  .user_mem_8_addr(user_mem_8_addr),
			  .user_mem_8_addr_update(user_mem_8_addr_update),


			  // Ports related to /dev/xillybus_read_32
			  // FPGA to CPU signals:
			  .user_r_read_32_rden(user_r_read_32_rden),
			  .user_r_read_32_empty(user_r_read_32_empty),
			  .user_r_read_32_data(user_r_read_32_data),
			  .user_r_read_32_eof(user_r_read_32_eof),
			  .user_r_read_32_open(user_r_read_32_open),

			  // Ports related to /dev/xillybus_write_32
			  // CPU to FPGA signals:
			  .user_w_write_32_wren(user_w_write_32_wren),
			  .user_w_write_32_full(user_w_write_32_full),
			  .user_w_write_32_data(user_w_write_32_data),
			  .user_w_write_32_open(user_w_write_32_open),

			  // Ports related to /dev/xillybus_read_8
			  // FPGA to CPU signals:
			  .user_r_read_8_rden(user_r_read_8_rden),
			  .user_r_read_8_empty(user_r_read_8_empty),
			  .user_r_read_8_data(user_r_read_8_data),
			  .user_r_read_8_eof(user_r_read_8_eof),
			  .user_r_read_8_open(user_r_read_8_open),

			  // Ports related to /dev/xillybus_write_8
			  // CPU to FPGA signals:
			  .user_w_write_8_wren(user_w_write_8_wren),
			  .user_w_write_8_full(user_w_write_8_full),
			  .user_w_write_8_data(user_w_write_8_data),
			  .user_w_write_8_open(user_w_write_8_open),

			  // Signals to top level
			  .PCIE_PERST_B_LS(PCIE_PERST_B_LS),
			  .PCIE_REFCLK_N(PCIE_REFCLK_N), .PCIE_REFCLK_P(PCIE_REFCLK_P),
			  .PCIE_RX_N(PCIE_RX_N), .PCIE_RX_P(PCIE_RX_P),
			  .GPIO_LED(GPIO_LED[3:0]),
			  .PCIE_TX_N(PCIE_TX_N), .PCIE_TX_P(PCIE_TX_P),
			  .bus_clk(bus_clk), .quiesce(quiesce));

  xb_wr_fifo xb_wr_fifo(.rst(reset), .clk(bus_clk)//.wr_clk(bus_clk), .rd_clk(clk)
    , .din(user_w_write_32_data), .wr_en(user_w_write_32_wren)
    , .rd_en(pc_msg32_ack), .dout(pc_msg32)
    , .full(user_w_write_32_full), .empty(pc_msg32_empty));
/*
  // Q width aspect ratio must be > (85MHz*80bits / 200MHz*32 bit) ~ 1.1
  xb_rd_fifo xb_rd_fifo(.rst(reset), .wr_clk(clk), .rd_clk(bus_clk)
    //, .din({bottom_pixel[1], 4'b0, bottom_pixel[0], 2'b0, cl_state
    //  , top_pixel[1], 4'b0, top_pixel[0], 2'b0, frame_state})
    , .din({pc_msg32[15:8], pc_msg32[15:8] //Counter-intuitively, the
            , pc_msg32[7:0], pc_msg32[7:0] //latter 32 bits go into the
            , pc_msg32[31:24], pc_msg32[31:24] // FIFO first
            , pc_msg32[23:16], pc_msg32[23:16]})
    , .wr_en(send_data)
    , .rd_en(user_r_read_32_rden), .dout(user_r_read_32_data)
    , .full(xb_rd_fifo_full), .empty(user_r_read_32_empty));
*/
  xb_rd_fifo xb_rd_fifo(.rst(reset), .clk(bus_clk)//.wr_clk(clk), .rd_clk(bus_clk)
    , .din(pc_msg32), .wr_en(send_data)
    , .rd_en(user_r_read_32_rden), .dout(user_r_read_32_data)
    , .full(xb_rd_fifo_full), .empty(user_r_read_32_empty));

  assign  user_r_read_32_eof = 0;
  assign  user_r_read_8_eof = 0;

  assign GPIO_LED[7:4] = n_msg;

  always @(posedge reset, posedge bus_clk) begin
    if(reset) begin
      pc_msg32_ack <= 0;
      send_data <= 0;
      top_pixel <= 12'b000000010101;
      bottom_pixel <= 12'b010101000000;
      n_msg <= 0;
    end else begin
      pc_msg32_ack <= `FALSE; //Default value
      send_data <= `FALSE;
      
      if(!pc_msg32_empty && !pc_msg32_ack) begin // a message from PC!
        pc_msg32_ack <= `TRUE;
        send_data <= `TRUE;
        n_msg <= n_msg + 1'b1;
      end
    end
  end//always

endmodule
