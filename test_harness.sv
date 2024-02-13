/*

i_har_* -> Signals from the PS to the test harness PL
o_har_* -> Signals from the test harness PL to the PS
o_cim_* -> Signals from the test harness to the CIM (connected to the external pins on the FPGA) -> These are the inputs to the CIm from the test harness
i_cim_* -> Signals from the CIM to the test harness (connected to the external pins on the FPGA) -> These are the outputs of the CIM into the test harness
*/
module test_harness#(
    parameter NUM_STACKS = 8, 
    parameter STAGE_1_NUM_INPUTS = 8,//should be power of 2
    parameter STAGE_1_BIT_WIDTH = 8,
    parameter SRAM_THROUGHPUT = 1, //cycles/bit - should be power of 2
    parameter STAGE_4_BIT_WIDTH = 4,
    parameter SIZE_ACT_ARRAY = 1,
    parameter STAGE_1_MAX_SHIFT_AMT = STAGE_1_NUM_INPUTS-1,
    parameter STAGE_1_MUX_2_NUM_INPUTS = STAGE_1_NUM_INPUTS+1,
    parameter STAGE_1_OUT_BIT_WIDTH = STAGE_1_BIT_WIDTH+STAGE_1_MAX_SHIFT_AMT+$clog2(STAGE_1_NUM_INPUTS),
    parameter STAGE_1_OUT_BIT_WIDTH_NECESSARY = STAGE_1_BIT_WIDTH, //For signed representation
    parameter STAGE_3_OUT_BIT_WIDTH = STAGE_1_OUT_BIT_WIDTH_NECESSARY+ $clog2(STAGE_1_NUM_INPUTS),
   parameter counter_bit_width = $clog2(SRAM_THROUGHPUT)+$clog2(STAGE_1_NUM_INPUTS),
   parameter STAGE_4_OUT_BIT_WIDTH = STAGE_3_OUT_BIT_WIDTH+STAGE_4_BIT_WIDTH
)(
    //-- PS to the test harness
    input logic i_har_clk,
    input logic i_har_reset,
    input logic i_har_wrEn_queue,
    input logic [STAGE_4_BIT_WIDTH-1:0] i_har_wrData_queue,
    input logic i_har_DISABLE_STAGE_1,
    input logic i_har_DISABLE_STAGE_4,
    input logic i_har_wrEn_act_array,

    // From the PS we write the data to the test harness in the normal way and then we serialize it and send it to the CIM via scan chain 
    input logic [NUM_STACKS-1:0][SIZE_ACT_ARRAY-1:0][STAGE_1_BIT_WIDTH-1:0] i_har_wrData_act,
    input logic [NUM_STACKS-1:0][STAGE_1_BIT_WIDTH-1:0] i_har_input_wt,

    input logic i_har_SRAM_flop_en_in,//Chicken bit
    input logic i_har_flop_1_en_in,//Chicken bit
    input logic i_har_flop_3_en_in,//Chicken bit
    input logic i_har_queue_en_in,//Chicken bit for stage 2
    input logic [$clog2(STAGE_1_BIT_WIDTH)-1:0] i_har_wrPtr_d_in, //Chicken bit
    input logic i_har_in,//Chicken bit for safety reasons
    input logic i_har_wrPtr_over_in, //Chicken bit
    input logic i_har_DISABLE_STAGE_2,//Chicken bit
    input logic i_har_DISABLE_STAGE_3,//Chicken bit
    input logic i_har_chicken_bit,

    input logic i_har_scan_enable,
    input logic i_har_update_clk,
    // from the harness to the PS we deserialize the serial output from the CIM, and write it to the shared registers
    
    // add all the output signals from the CIM that you scan chainedinto it
    // for now we have the o_deserialized_scan_out_data  
    output logic [128:0] o_har_deserialized_scan_out_data,


    //-- o_cim_ --- These are the inputs to the CIM from the test harness (outputs here). These are connected to physical pins in the FPGA configured as output
    output logic o_cim_clk_pad,//
    output logic o_cim_reset_pad,//
    output logic o_cim_wrEn_queue_pad,//
    output logic [STAGE_4_BIT_WIDTH-1:0] o_cim_wrData_queue_pad,//
    output logic o_cim_DISABLE_STAGE_1_pad,//
    output logic o_cim_DISABLE_STAGE_4_pad,//
    output logic o_cim_wrEn_act_array_pad, //
    output logic o_cim_SRAM_flop_en_in_pad, //Chicken bit
    output logic o_cim_flop_1_en_in_pad, //Chicken bit
    output logic o_cim_flop_3_en_in_pad, //Chicekn bit
    output logic o_cim_queue_en_in_pad, //Chicken bit for stage 2
    output logic [$clog2(STAGE_1_BIT_WIDTH)-1:0] o_cim_wrPtr_d_in_pad, //Chicken bit
    output logic o_cim_in_pad, //
    output logic o_cim_wrPtr_over_in_pad,// /
    output logic o_cim_DISABLE_STAGE_2_pad,//
    output logic o_cim_DISABLE_STAGE_3_pad,//

    output logic o_cim_scan_in_pad,

    output logic o_cim_se_pad,//
    output logic o_cim_update_clk_pad,//
    output logic o_cim_scan_clk_pad,//

    //-- i_cim_ --- These are the outputs of the CIM into the test harness (inputs here). These are connected to physical pins in the FPGA configured as input
    input logic [2:0] i_cim_stage_4_o_pad,
    input logic i_cim_scan_out_pad

);
// We use the same Clock and Reset Domain for the test harness and the CIM , to avoid complexities 
assign o_cim_clk_pad = i_har_clk;
assign o_cim_reset_pad = i_har_reset;
assign o_cim_wrEn_queue_pad = i_har_wrEn_queue;
assign o_cim_wrData_queue_pad = i_har_wrData_queue;
assign o_cim_DISABLE_STAGE_1_pad = i_har_DISABLE_STAGE_1;
assign o_cim_DISABLE_STAGE_4_pad = i_har_DISABLE_STAGE_4;
assign o_cim_wrEn_act_array_pad = i_har_wrEn_act_array;
assign o_cim_SRAM_flop_en_in_pad = i_har_SRAM_flop_en_in;
assign o_cim_flop_1_en_in_pad = i_har_flop_1_en_in;
assign o_cim_flop_3_en_in_pad = i_har_flop_3_en_in;
assign o_cim_queue_en_in_pad = i_har_queue_en_in;
assign o_cim_wrPtr_d_in_pad = i_har_wrPtr_d_in;
assign o_cim_in_pad = i_har_in;
assign o_cim_wrPtr_over_in_pad = i_har_wrPtr_over_in;
assign o_cim_DISABLE_STAGE_2_pad = i_har_DISABLE_STAGE_2;
assign o_cim_DISABLE_STAGE_3_pad = i_har_DISABLE_STAGE_3;

assign o_cim_se_pad = i_har_scan_enable;   
assign o_cim_update_clk_pad = i_har_update_clk;
assign o_cim_scan_clk_pad = i_har_clk;  // scan clk same as the harness clk


// LOGIC to serialize data and send it to the scan in of the CIM

// I think write data act and input weights are scan chained. Depending on the design change that
logic [(NUM_STACKS*SIZE_ACT_ARRAY*STAGE_1_BIT_WIDTH)+(NUM_STACKS*STAGE_1_BIT_WIDTH)]parallel_scan_in_data = {i_har_wrData_act,i_har_input_wt};
logic serialized_scan_in_data = 0;
// Serialize and the send the inputs from the harness to the CIM scan chain
always_ff@(posedge i_har_clk or posedge i_har_reset)
begin 
    if(i_har_scan_enable) begin 
        serialized_scan_in_data <= parallel_scan_in_data[0];
        parallel_scan_in_data <= parallel_scan_in_data>>1;
    end else begin 
        serialized_scan_in_data <= 0;
    end
end
assign o_cim_scan_in_pad = serialized_scan_in_data;


//LOGIC to deserialize the scan out from the CIM and write it to the shared registers
logic [128:0] deserialized_scan_out_data = '0; //regsiter to hold the deserialized data
logic serial_scan_out_data;
always_ff@(posedge i_har_clk or posedge i_har_reset)
begin
    if(i_har_scan_enable) begin 
            deserialized_scan_out_data[0] <= i_cim_scan_out_pad;
            deserialized_scan_out_data <= deserialized_scan_out_data << 1;
    end else begin 
        deserialized_scan_out_data <= 0;
    end
end 
assign o_har_deserialized_scan_out_data = deserialized_scan_out_data;

endmodule