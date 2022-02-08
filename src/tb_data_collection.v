`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/02/07 13:03:47
// Design Name: 
// Module Name: tb_data_collection
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_data_collection();

    wire [1:0]collection_error_bit_0;
    
    //BRAM READ 
    reg [9:0]i_bramAddr_0;
    reg i_mode_0;
    reg i_run_0;
    
    wire [31:0]o_read_data_0;
    wire o_read_valid_0;
    
    //input uart data
    reg rx_complete_0;
    reg [7:0]rx_data_0;
    
    reg [1:0]rx_error_bit_0;
    
    reg system_clk_0 = 1'b0;
    reg reset_0 = 1'b1;
    
    reg [4:0]input_data_length_0;
    reg [2:0]tracking_mode_0;
    
    
    reg [18:0] az;
    reg [18:0] el;
    reg [25:0] range;
    reg [7:0] data[17:0];
    reg [15:0] data_crc;
    
    
    // clk gen
    always
        #5 system_clk_0 = ~system_clk_0;
    
    integer i;
    
    initial begin
        $display("initialize value [%0d]", $time);
        // READ BRAM 
        i_bramAddr_0 = 10'd0;
        i_mode_0 = 1'b0;
        i_run_0 = 1'b0;
        
        tracking_mode_0 = 3'd1;
        input_data_length_0 = 5'd18;
        
        az = 19'h3ACA;
        el = 19'h13BA;
        range = 26'h1F40;
        
        for(i=0; i<18; i=i+1) begin
           data[i] = 8'h0; 
        end
        
        data[0]         = 8'h16;
        data[1]         = 8'h16;
        
        data[6]         = az[18:11];
        data[7]         = az[10:3];
        data[8][7:5]    = az[2:0];
        
        data[8][7:5]    = el[18:14];
        data[9]         = el[13:6];
        data[10][7:2]   = el[5:0];
        
        data[10][1:0]   = range[25:24];
        data[11]        = range[23:16];
        data[12]        = range[15:8];
        data[13]        = range[7:0];
        
        data[14]        = 8'h80;
        data_crc[15:0] =    ((data[0] << 8)||data[1])+((data[2] << 8)||data[3])+((data[4] << 8)||data[5]) +
                            ((data[6] << 8)||data[7])+((data[8] << 8)||data[9])+((data[10] << 8)||data[11]) +
                            ((data[12] << 8)||data[13])+((data[14] << 8)||data[15]);
        data[16] = data_crc[15:8];
        data[17] = data_crc[7:0];
        // reset_n gen
        $display("Reset! [%0d]", $time);
        # 30
            reset_0 = 0;
        # 10
            reset_0 = 1;
        # 10
        @(posedge system_clk_0);

        for(i=0; i<18; i=i+1) begin
            rx_complete_0 = 1'b1;
            rx_data_0 = data[i];
            #30
            rx_complete_0 = 1'b0;
            #70
            @(posedge system_clk_0);
        end
        
        # 300
        @(negedge system_clk_0);
        i_bramAddr_0 = 4;
        i_mode_0 = 0;
        i_run_0 = 1;    
        #10    
        i_run_0 = 0;
        wait(o_read_valid_0);
        #50
        
        @(negedge system_clk_0);
        i_bramAddr_0 = 5;
        i_mode_0 = 0;
        i_run_0 = 1;
        #10    
        i_run_0 = 0;        
        wait(o_read_valid_0);
        #50
        
        @(negedge system_clk_0);
        i_bramAddr_0 = 6;
        i_mode_0 = 0;
        i_run_0 = 1;
        #10    
        i_run_0 = 0;        
        wait(o_read_valid_0);
        #100
        
        
        $display("Success Simulation!! (Matbi = gudok & joayo) [%0d]", $time);
        $finish;
    end
    
    design_1_wrapper tb_data_collection(
        .collection_error_bit_0 (collection_error_bit_0),
        .i_bramAddr_0           (i_bramAddr_0),
        .i_mode_0               (i_mode_0),
        .i_run_0                (i_run_0),
        .input_data_length_0    (input_data_length_0),
        .o_read_data_0          (o_read_data_0),
        .o_read_valid_0         (o_read_valid_0),
        .reset_0                (reset_0),
        .rx_complete_0          (rx_complete_0),
        .rx_data_0              (rx_data_0),
        .rx_error_bit_0         (rx_error_bit_0),
        .system_clk_0           (system_clk_0),
        .tracking_mode_0        (tracking_mode_0)
    );
  
endmodule
