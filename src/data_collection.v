`timescale 1 ns / 1 ps

module data_collection(
        input wire          system_clk,
        input wire          reset,
        input wire [2:0]    tracking_mode,
        input wire [4:0]    input_data_length,
        input wire          rx_complete,
        input wire [1:0]    rx_error_bit,
        input wire [7:0]    rx_data,
        output wire [1:0]   collection_error_bit,
        input wire          bram_write_idle,
        output wire         bram_write_run,
        output wire         bram_mode,
        output wire [9:0]   bram_addr,
        output wire [31:0]  bram_data
    );
    
    localparam  SAVE_IDLE       = 0,
                DATA_HEADER     = 1,
                SAVE_DATA       = 2,
                CHECK_CRC       = 3,
                DATA_SPLIT      = 4,
                BRAM_DATA_SAVE  = 5,
                RX_READ_END     = 6;
                
                
    localparam  SAVE_DATA_SUCCESS		= 0,
                HEADER_MISMATCH			= 1,
				UNKNOWN_TRACKING_MODE	= 2,
                CHECKSUM_ERROR			= 3;
                
    localparam  TRACKING_MODE_NONE      = 0,
                TRACKING_MODE_MCC       = 1,
                TRACKING_MODE_RADAR     = 2,
                TRACKING_MODE_MCR       = 3,
                TRACKING_MODE_PROGRAM   = 4;
                
                
    localparam  BRAM_ADDR_MCC_AZ            = 4,
                BRAM_ADDR_MCC_EL            = 5,
                BRAM_ADDR_MCC_RANGE         = 6,
                BRAM_ADDR_RADAR_NORTH       = 7,
                BRAM_ADDR_RADAR_EAST        = 8,
                BRAM_ADDR_RADAR_UP          = 9,
                BRAM_ADDR_MCR_AZ            = 10,
                BRAM_ADDR_MCR_EL            = 11,
                BRAM_ADDR_PRE_PROGRAM_AZ    = 12,
                BRAM_ADDR_PRE_PROGRAM_EL    = 13,
                BRAM_ADDR_POSITION_AZ       = 14,
                BRAM_ADDR_POSITION_EL       = 15;
                
    reg [7:0] received_data;
    reg [7:0] rx_data_buffer[27:0];
    
    reg [2:0] save_state = SAVE_IDLE;
    reg [1:0] data_collection_error_bit = SAVE_DATA_SUCCESS;
    
    reg [31:0] split_data_1;
    reg [31:0] split_data_2;
    reg [31:0] split_data_3;
    reg tracking_flag;
    reg [4:0] save_data_count;

    
    always @(posedge system_clk) begin
        if(reset == 1'b0) begin
            save_data_count <= 0;
            save_state <= SAVE_IDLE;
            tracking_flag <= 0;
        end else begin
            case(save_state)
                SAVE_IDLE: begin
                    if(rx_complete == 1'b1)begin
                        received_data <=  rx_data;
                        if(save_data_count <= 1) begin
							tracking_flag <= 0;
                            save_state <= DATA_HEADER;
                        end else begin
                            save_state <= SAVE_DATA;
                        end                        
                    end else begin
                        save_state <= SAVE_IDLE;
                    end
                end
                
                DATA_HEADER: begin
					if(tracking_mode == TRACKING_MODE_MCC) begin
					   if(received_data == 8'h16) begin
                            rx_data_buffer[save_data_count] <= received_data;
                            save_data_count <= save_data_count + 1'b1;
                        end else begin
                            save_data_count <= 0;
                            data_collection_error_bit <= HEADER_MISMATCH;
                        end
					end else if(tracking_mode == TRACKING_MODE_RADAR) begin
					   if(save_data_count == 0) begin
					       if(received_data == 8'h55) begin
                                rx_data_buffer[save_data_count] <= received_data;
                                save_data_count <= save_data_count + 1'b1;
                            end else begin
                                save_data_count <= 0;
                                data_collection_error_bit <= HEADER_MISMATCH;
                            end
					   end else if(save_data_count == 1) begin
					       if(received_data == 8'hAA) begin
                                rx_data_buffer[save_data_count] <= received_data;
                                save_data_count <= save_data_count + 1'b1;
                            end else begin
                                save_data_count <= 0;
                                data_collection_error_bit <= HEADER_MISMATCH;
                            end
					   end else begin
					       save_data_count <= 0;
					       data_collection_error_bit <= HEADER_MISMATCH;
					   end
                    end else if(tracking_mode == TRACKING_MODE_MCR) begin
                    
                    end else if(tracking_mode == TRACKING_MODE_PROGRAM) begin
                    
                    end else if(tracking_mode == TRACKING_MODE_NONE) begin
                        
					end else begin
					   data_collection_error_bit <= UNKNOWN_TRACKING_MODE;
					end
                    save_state <= RX_READ_END;                
                end
                
                SAVE_DATA: begin
                    rx_data_buffer[save_data_count] <= received_data;
                    if(save_data_count == input_data_length-1) begin
                        save_data_count <= 0;
                        save_state <= CHECK_CRC;
                    end else begin
                        save_data_count <= save_data_count + 1'b1;
                        save_state <= RX_READ_END;
                    end
                end
                
                CHECK_CRC: begin
                    save_state <= DATA_SPLIT;
//                    data_collection_error_bit <= CHECKSUM_ERROR;
                end
                
                DATA_SPLIT: begin
                    if(tracking_mode == TRACKING_MODE_MCC) begin
                        split_data_1[2:0]   <= rx_data_buffer[8][7:5];
                        split_data_1[10:3]  <= rx_data_buffer[7];
                        split_data_1[18:11] <= rx_data_buffer[6];
                        if(rx_data_buffer[6][7:7] == 1)begin
                            split_data_1[31:19] <= 13'b0;
                        end else begin
                            split_data_1[31:19] <= 13'b0;
                        end
                        
                        split_data_2[5:0]   <= rx_data_buffer[10][7:2];
                        split_data_2[13:6]  <= rx_data_buffer[9];
                        split_data_2[18:14] <= rx_data_buffer[8][4:0];                        
                        if(rx_data_buffer[8][4:4] == 1)begin
                            split_data_2[31:19] <= 13'b0;
                        end else begin
                            split_data_2[31:19] <= 13'b0;
                        end
                        
                        split_data_3[7:0]   <= rx_data_buffer[13];
                        split_data_3[15:8]  <= rx_data_buffer[12];
                        split_data_3[23:16] <= rx_data_buffer[11];
                        split_data_3[25:24] <= rx_data_buffer[10][1:0];
                        if(rx_data_buffer[10][1:1] == 1)begin
                            split_data_3[31:26] <= 6'b0;
                        end else begin
                            split_data_3[31:26] <= 6'b0;
                        end
                    
                        tracking_flag <= rx_data_buffer[14][7:7];
                    end else if(tracking_mode == TRACKING_MODE_RADAR) begin
                    end else if(tracking_mode == TRACKING_MODE_MCR) begin
                    end else if(tracking_mode == TRACKING_MODE_PROGRAM) begin
                    end else if(tracking_mode == TRACKING_MODE_NONE) begin
                    end
                    save_state <= BRAM_DATA_SAVE;
                end
                
                BRAM_DATA_SAVE: begin
                    save_state <= SAVE_IDLE;
                    data_collection_error_bit <= SAVE_DATA_SUCCESS;
                end
                
                RX_READ_END: begin
                    if(rx_complete == 1'b0) begin
                        save_state <= SAVE_IDLE;
                    end else begin
                        save_state <= RX_READ_END;
                    end                    
                end
            endcase
        end
    end
    
    assign collection_error_bit = data_collection_error_bit;
    
    
    
    localparam  BRAM_SAVE_IDLE      = 0,
                BRAM_WRITE_START    = 1,
                BRAM_WRITE_DATA1    = 2,
                BRAM_WRITE_DATA2    = 3,
                BRAM_WRITE_DATA3    = 4,
                BRAM_WRITE_DONE     = 5;
              
    reg [2:0] bram_write_state      = BRAM_SAVE_IDLE;
    reg bram_write_run_enable       = 1'h0;
    reg [1:0] bram_write_data_count = 2'h0;
    reg [31:0] reg_bram_data        = 32'h0;
    reg [9:0] reg_bram_addr         = 9'h0;
    reg [2:0] bram_write_done_count = 3'h0;
    reg reg_bram_mode               = 1'b0;
    
    always @(posedge system_clk) begin
        if(reset == 1'b0) begin
            bram_write_state = BRAM_SAVE_IDLE;            
			bram_write_data_count <= 2'h0;
			bram_write_done_count <= 3'h0;
			bram_write_run_enable <= 1'b0;
            reg_bram_mode <= 1'b0;
        end else begin
            case(bram_write_state)
                BRAM_SAVE_IDLE: begin
                    if(save_state == BRAM_DATA_SAVE)begin
                        bram_write_state <= BRAM_WRITE_START;
                        bram_write_data_count <= 2'h0;
                        bram_write_done_count <= 3'h0;
                        reg_bram_mode <= 1'b1;
                    end else begin
                        reg_bram_mode <= 1'b0;
                    end
                end
                
                BRAM_WRITE_START: begin
                    bram_write_run_enable = 1'b1;
                    if(bram_write_data_count == 2'd0) begin
                        bram_write_state <= BRAM_WRITE_DATA1;
                    end else if(bram_write_data_count == 2'd1) begin
                        bram_write_state <= BRAM_WRITE_DATA2;
                    end else if(bram_write_data_count == 2'd2) begin
                        bram_write_state <= BRAM_WRITE_DATA3;
                    end else begin
                        bram_write_state <= BRAM_SAVE_IDLE;
                    end
                    bram_write_data_count <= bram_write_data_count + 2'b1;
                end                
                
                BRAM_WRITE_DATA1: begin
                    bram_write_run_enable = 1'b0;
                    reg_bram_data <= split_data_1;
                    bram_write_state <= BRAM_WRITE_DONE;
                    if(tracking_mode == TRACKING_MODE_MCC) begin
                        reg_bram_addr <= BRAM_ADDR_MCC_AZ;
                    end else if(tracking_mode == TRACKING_MODE_RADAR) begin
                        reg_bram_addr <= BRAM_ADDR_RADAR_NORTH;
                    end else if(tracking_mode == TRACKING_MODE_MCR) begin
                        reg_bram_addr <= BRAM_ADDR_MCR_AZ;
                    end else if(tracking_mode == TRACKING_MODE_PROGRAM) begin
                        reg_bram_addr <= BRAM_ADDR_PRE_PROGRAM_AZ;
                    end else if(tracking_mode == TRACKING_MODE_NONE) begin
                        reg_bram_addr <= BRAM_ADDR_POSITION_AZ;
                    end else begin
                        bram_write_state <= BRAM_SAVE_IDLE;
                    end
                end
                
                BRAM_WRITE_DATA2: begin
                    bram_write_run_enable = 1'b0;
                    reg_bram_data <= split_data_2;
                    bram_write_state <= BRAM_WRITE_DONE;
                    if(tracking_mode == TRACKING_MODE_MCC) begin
                        reg_bram_addr <= BRAM_ADDR_MCC_EL;
                    end else if(tracking_mode == TRACKING_MODE_RADAR) begin
                        reg_bram_addr <= BRAM_ADDR_RADAR_EAST;
                    end else if(tracking_mode == TRACKING_MODE_MCR) begin
                        reg_bram_addr <= BRAM_ADDR_MCR_EL;
                    end else if(tracking_mode == TRACKING_MODE_PROGRAM) begin
                        reg_bram_addr <= BRAM_ADDR_PRE_PROGRAM_EL;
                    end else if(tracking_mode == TRACKING_MODE_NONE) begin      
                        reg_bram_addr <= BRAM_ADDR_POSITION_EL;              
                    end else begin
                        bram_write_state <= BRAM_SAVE_IDLE;
                    end
                end
                
                BRAM_WRITE_DATA3: begin
                    bram_write_run_enable = 1'b0;
                    reg_bram_data <= split_data_3;
                    bram_write_state <= BRAM_WRITE_DONE;
                    if(tracking_mode == TRACKING_MODE_MCC) begin
                        reg_bram_addr <= BRAM_ADDR_MCC_RANGE;
                    end else if(tracking_mode == TRACKING_MODE_RADAR) begin
                        reg_bram_addr <= BRAM_ADDR_RADAR_UP;                   
                    end else begin
                        bram_write_state <= BRAM_SAVE_IDLE;
                    end
                end
                
                BRAM_WRITE_DONE: begin
                    if(bram_write_idle == 1'b1) begin
                        if(bram_write_data_count == 3'd2) begin
                            if(tracking_mode == TRACKING_MODE_MCC || tracking_mode == TRACKING_MODE_RADAR) begin
                                bram_write_state <= BRAM_WRITE_START;
                            end else begin
                                bram_write_state <= BRAM_SAVE_IDLE;
                            end
                        end else if(bram_write_data_count == 3'd3) begin
                            bram_write_state <= BRAM_SAVE_IDLE;
                        end else begin
                            bram_write_state <= BRAM_WRITE_START;
                        end
                    end else begin
                        if(bram_write_done_count == 3'd7) begin 
                            bram_write_state <= BRAM_SAVE_IDLE;
                            bram_write_done_count <= 0;
                        end else begin
                            bram_write_state <= BRAM_WRITE_DONE;
                            bram_write_done_count <= bram_write_done_count + 1'b1;
                        end
                    end
                end
            endcase
        end
    end
    
    assign bram_write_run   = bram_write_run_enable;
    assign bram_data        = reg_bram_data;
    assign bram_addr        = reg_bram_addr;
    assign bram_mode        = reg_bram_mode;
endmodule
