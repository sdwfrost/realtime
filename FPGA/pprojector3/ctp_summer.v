module CameraTraceRowSummer//Sums the camera trace projection through 1 FSP row
#(parameter SIMULATION=1, DELAY=1, FP_SIZE=32, SMALL_FP_SIZE=24
          , CAM_ROW_SIZE=12, CAM_COL_SIZE=12
          , N_CAM=2, FSP_WIDTH=6, FSP_ROW=2'd1)
(input CLK, RESET, init, ctrace_valid, sum_ack, xof
, input[CAM_ROW_SIZE-1:0] config_row, ctrace_row
, input[CAM_COL_SIZE-1:0] config_col, ctrace_col
, input[FP_SIZE-1:0] config_initial, grn_ctrace, red_ctrace
     , grn_fsp0, grn_fsp1, grn_fsp2, grn_fsp3, grn_fsp4, grn_fsp5
     , red_fsp0, red_fsp1, red_fsp2, red_fsp3, red_fsp4, red_fsp5
, output available, done, output reg[FP_SIZE-1:0] grn_result, red_result);
`include "function.v"
  genvar geni, genj, genk;
  integer i, j, k;
  reg [CAM_ROW_SIZE-1:0] me_row;
  reg [CAM_COL_SIZE-1:0] me_col;
  reg [FP_SIZE-1:0] me_initial, me_ctrace[N_CAM-1:0][FSP_WIDTH-1:0];
  reg [SMALL_FP_SIZE-1:0] me_fsp[N_CAM-1:0][FSP_WIDTH-1:0];
`ifdef DELAY_INPUTS
  reg [FP_SIZE-1:0] ctrace_d[N_CAM-1:0];
  reg [SMALL_FP_SIZE-1:0] fsp_d[N_CAM-1:0][FSP_WIDTH-1:0];
  reg ctrace_valid_d, 
  reg[log2(FSP_WIDTH)-1:0] fsp_row;
  reg [CAM_ROW_SIZE-1:0] me_ctrace_row;
  reg signed [CAM_COL_SIZE:0] fsp_col;//signed, so an extra bit
`endif
  wire[FP_SIZE-1:0] ctraceXfsp[N_CAM-1:0][FSP_WIDTH-1:0]
                  , partial_sum1[N_CAM-1:0][(2**(log2(FSP_WIDTH)-1))-1:0]
                  , partial_sum2[N_CAM-1:0][(2**(log2(FSP_WIDTH)-2))-1:0]
                  , sum[N_CAM-1:0];
  wire[FSP_WIDTH-1:0] ctraceXfsp_rdy[N_CAM-1:0];
  wire[(2**(log2(FSP_WIDTH)-1))-1:0] partial_sum1_rdy[N_CAM-1:0];
  wire[(2**(log2(FSP_WIDTH)-2))-1:0] partial_sum2_rdy[N_CAM-1:0];
  wire[N_CAM-1:0] sum_rdy;
  wire[log2(FSP_WIDTH)-1:0] n_recv, fsp_row;

  reg start_calc;
  reg[log2(FSP_WIDTH)-1:0] n_recv;

  localparam ERROR = 0, FREE = 1, COLLECTING = 2, FINISHING = 3, DONE = 4
           , N_STATE = 5;
  reg [log2(N_STATE)-1:0] state;
  assign done = state == DONE;
  assign availabe = state == FREE;
  
  generate
    for(geni=0; geni<N_CAM; geni=geni+1) begin
      for(genj=0; genj<FSP_WIDTH; genj=genj+1)
        fmult ctraceXfsp_module(.clk(CLK), .sclr(RESET)
          , .operation_nd(start_calc), .a(me_ctrace[geni][genj])
          , .b({me_fsp[geni][genj], {(FP_SIZE-SMALL_FP_SIZE){`FALSE}}})
          , .result(ctraceXfsp[geni][genj]), .rdy(ctraceXfsp_rdy[geni][genj]));

      //This cascading arrangement of 1st stage adders is specific to
      //FSP_WIDTH=6
      for(genj=0; genj<FSP_WIDTH/2; genj=genj+1)
        fadd partial_add_1(.clk(CLK), .sclr(RESET)
          , .operation_nd(ctraceXfsp_rdy[geni][genj*2])
          , .a(ctraceXfsp[geni][2*genj]), .b(ctraceXfsp[geni][2*genj])
          , .result(partial_sum1[geni][genj])
          , .rdy(partial_sum1_rdy[geni][genj]));
      fadd just_delay_initial(.clk(CLK), .sclr(RESET)
          , .operation_nd(ctraceXfsp_rdy[geni][0]), .a(me_initial), .b(0)
          , .result(partial_sum1[geni][3]), .rdy(partial_sum1_rdy[geni][3]));

      //2nd stage
      for(genj=0; genj<2**(log2(FSP_WIDTH)-2); genj=genj+1)
        fadd partial_add_2(.clk(CLK), .sclr(RESET)
          , .operation_nd(partial_sum1_rdy[geni][genj*2])
          , .a(partial_sum1[geni][2*genj]), .b(partial_sum1[geni][2*genj+1])
          , .result(partial_sum2[geni][genj])
          , .rdy(partial_sum2_rdy[geni][genj]));

      fadd partial_add_module1(.clk(CLK), .sclr(RESET)
          , .operation_nd(partial_sum2_rdy[geni][0])
          , .a(partial_sum2[geni][0]), .b(partial_sum2[geni][1])
          , .result(sum[geni]), .rdy(sum_rdy[geni]));
    end//for(N_CAM)
  endgenerate

  wire[CAM_ROW_SIZE-1:0] me_ctrace_row;
  assign me_ctrace_row = ctrace_row + FSP_ROW;//Note: instantiation param

  wire signed[CAM_COL_SIZE:0] fsp_col;//signed, so an extra bit
  assign fsp_col = me_col - ctrace_col;//signed arithmetic

  always @(posedge CLK) begin
    start_calc <= #DELAY `FALSE;

`ifdef DELAY_INPUTS
    //Delay the input for better timing
    ctrace_valid_d <= #DELAY ctrace_valid;
    ctrace_d <= #DELAY ctrace;
    fsp_d[0] <= #DELAY fsp0; fsp_d[1] <= #DELAY fsp1; fsp_d[2] <= #DELAY fsp2;
`endif   

    if(RESET) begin
      n_recv <= #DELAY 0;
      state <= #DELAY FREE;
    end else begin
      
      case(state)
        FREE:
          if(init) begin
            me_row <= #DELAY config_row;
            me_col <= #DELAY config_col;
            me_initial <= #DELAY config_initial;
            for(i=0; i<N_CAM; i=i+1) begin
              for(j=0; j<FSP_WIDTH; j=j+1) begin
                me_fsp[i][j] <= #DELAY 0;
                me_ctrace[i][j] <= #DELAY 0;
              end//for(FSP_WIDTH)
            end//for(N_CAM)
            state <= #DELAY COLLECTING;
          end
        COLLECTING:
          if(ctrace_valid) begin//3 cases: before, during, after overlap
            if(me_ctrace_row > me_row
               || (me_ctrace_row == me_row && 0 > fsp_col)) begin//before
              //noop
            end else if(me_ctrace_row == me_row
                        && fsp_col >= 0 && fsp_col < FSP_WIDTH) begin//overlap
              for(i=0; i<N_CAM; i=i+1) me_ctrace[i][n_recv] <= #DELAY ctrace[i];
              me_fsp[n_recv] <= #DELAY fsp[fsp_col];
              n_recv <= #DELAY n_recv + `TRUE;
              
              if(n_recv == FSP_WIDTH-1) begin//all I can save away; HAVE TO finish
                n_recv <= #DELAY 0;
                start_calc <= #DELAY `TRUE;//Kick off the calculation
                state <= #DELAY FINISHING;
              end
            end else begin //after
              n_recv <= #DELAY 0;
              if(n_recv) begin//Received at least 1 projection
                start_calc <= #DELAY `TRUE;//Kick off the calculation
                state <= #DELAY FINISHING;
              end else begin//didn't receive any projection => result = initial
                for(i=0; i<N_CAM; i=i+1) result[i] <= #DELAY me_initial;
                state <= #DELAY DONE;
              end
            end
          end
        FINISHING:
          if(sum_rdy[0]) begin//both virtual cameras move together
            for(i=0; i<N_CAM; i=i+1) begin
              result[i] <= #DELAY sum;//copy it out
              for(j=0; j<FSP_WIDTH; j=j+1) begin//reset storage
                me_fsp[i][j] <= #DELAY 0;
                me_ctrace[i][j] <= #DELAY 0;
              end//for(FSP_WIDTH)
            end//for(N_CAM)
            state <= #DELAY DONE;
          end
        DONE:
          if(sum_ack) state <= #DELAY FREE;

        default: begin//What to do in case of an error?
        end
      endcase
    end
  end
endmodule

//Do I really need this specialization?
module NonOverlappingCameraTraceRowSummer//NOCTPRS
#(parameter SIMULATION=1, DELAY=1, FP_SIZE=32, SMALL_FP_SIZE=24
          , CAM_ROW_SIZE=12, CAM_COL_SIZE=12
          , N_CAM=2, FSP_ROW=2'd1)
(input CLK, RESET, init, ctrace_valid, sum_ack, xof
, input[CAM_ROW_SIZE-1:0] config_row, ctrace_row
, input[CAM_COL_SIZE-1:0] config_col, ctrace_col
, input[FP_SIZE-1:0] config_initial, grn_ctrace, red_ctrace
     , grn_fsp0, grn_fsp1, grn_fsp2, grn_fsp3, grn_fsp4, grn_fsp5
     , red_fsp0, red_fsp1, red_fsp2, red_fsp3, red_fsp4, red_fsp5
, output available, done, output reg[FP_SIZE-1:0] grn_result, red_result);
endmodule
