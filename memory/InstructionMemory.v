////////////////////////////////////////////////////////////////////////////////
// File      : instruction_memory.v
// Author(s) : Sayyid Amirreza Sayyid Torabi <sayyidtorabi@gmail.com>
// Date      : 2026-10-8 (last modified)
// Description:
//   
////////////////////////////////////////////////////////////////////////////////
module instructionMemoryModel #(
	parameter MEM_SIZE  = 1024,
	parameter DELAY_A	= 0,
    parameter WORD_PER_LINES_PORT_A = 1,
	parameter DELAY_B  	= 0
) (
    input  wire 	   clk,
    input  wire 	   rst,

	// Port A
	input  wire		   							readRequestA,
    input  wire [31:0] 							addrA,
    output reg  [32*WORD_PER_LINES_PORT_A-1:0]  dataOutA,
	output reg		   							waitRequestA,

	// Port B
	input  wire		   							readRequestB,
    input  wire [31:0] 							addrB,
	input  wire	[ 1:0] 							accessTypeB,
    output reg  [31:0] 							dataOutB,
	output reg		   							waitRequestB
);

	localparam IDLE = 1'b0;
	localparam WAIT = 1'b1;

	generate
		if (DELAY_A == 0) begin : ZERO_DELAY_A
			always @(readRequestA) begin
            	waitRequestA = 1'b0;
        	end
		end else begin : NON_ZERO_DELAY_A
			reg [ 3:0] 	counterA;
			reg			countEnA;
			reg			countClearA;
			wire		carryOutA;
			reg         psA, nsA;
			reg [31:0]  currentAddrA;

			always @(posedge clk, posedge rst) begin
				if (rst) begin
					counterA <= 4'b1111 - DELAY_A;
					currentAddrA <= 32'b0;
				end else if (countClearA) begin
					counterA <= 4'b1111 - DELAY_A;
					currentAddrA <= addrA;
				end else if (countEnA) begin
					counterA <= counterA + 1'b1;
				end
			end
			assign carryOutA = &counterA;
	
    		always @(posedge clk, posedge rst) begin
        		if (rst)  
					psA <= IDLE;
        		else      
					psA <= nsA;
    		end
    
    		always @(*) begin
		 		nsA = IDLE;
        		case (psA)
            		IDLE: nsA = readRequestA ? WAIT : IDLE;
					WAIT: begin
						if (carryOutA)
							nsA = IDLE;
						else if (!readRequestA)
							nsA = IDLE;
						else if (addrA != currentAddrA)
							nsA = IDLE;
						else
							nsA = WAIT;
					end
        		endcase
    		end

    		always @(*) begin
				waitRequestA = 1'b0;
				countClearA  = 1'b0;
				countEnA	 = 1'b0;
        		case (psA)
            		IDLE: begin
						countClearA  = 1'b1;
						waitRequestA = 1'b1;
					end
            		WAIT: begin  
						countEnA     = 1'b1;
						waitRequestA = carryOutA ? 1'b0 : 1'b1;
					end
        		endcase
    		end
	    end
	endgenerate

	generate
		if (DELAY_B == 0) begin : ZERO_DELAY_B
			always @(readRequestB) begin
            	waitRequestB = 1'b0;
        	end
		end else begin : NON_ZERO_DELAY_B
			reg [ 3:0] 	counterB;
			reg			countEnB;
			reg			countClearB;
			wire		carryOutB;
			reg         psB, nsB;
			reg [31:0]  currentAddrB;

			always @(posedge clk, posedge rst) begin
				if (rst) begin
					counterB <= 4'b1111 - DELAY_B;
					currentAddrB <= 32'b0;
				end else if (countClearB) begin
					counterB <= 4'b1111 - DELAY_B;
					currentAddrB <= addrB;
				end else if (countEnB) begin
					counterB <= counterB + 1'b1;
				end
			end
			assign carryOutB = &counterB;
	
    		always @(posedge clk, posedge rst) begin
        		if (rst)  
					psB <= IDLE;
        		else      
					psB <= nsB;
    		end
    
    		always @(*) begin
		 		nsB = IDLE;
        		case (psB)
            		IDLE: nsB = readRequestB ? WAIT : IDLE;
					WAIT: begin
						if (carryOutB)
							nsB = IDLE;
						else if (!readRequestB)
							nsB = IDLE;
						else if (addrB != currentAddrB)
							nsB = IDLE;
						else
							nsB = WAIT;
					end
        		endcase
    		end

    		always @(*) begin
				waitRequestB = 1'b0;
				countClearB  = 1'b0;
				countEnB	 = 1'b0;
        		case (psB)
            		IDLE: begin
						countClearB  = 1'b1;
						waitRequestB = 1'b1;
					end
            		WAIT: begin  
						countEnB     = 1'b1;
						waitRequestB = carryOutB ? 1'b0 : 1'b1;
					end
        		endcase
    		end
	    end
	endgenerate

	localparam BYTE 			= 2'b00;
	localparam HALFWORD 		= 2'b01;
	localparam WORD 			= 2'b10;
    
	reg [7:0] memory [0:MEM_SIZE-1];
	
	integer i;
	initial begin
		for (i = 0; i < MEM_SIZE; i = i + 1)
			memory[i] = 8'b0;
		$readmemb("instructions.txt", memory);
	end

	integer w;
	always @(*) begin
		dataOutA = 32'b0;
		if (!waitRequestA) begin
        	for (w = 0; w < WORD_PER_LINES_PORT_A; w = w + 1) begin
            	dataOutA[w*32 +: 32] = {memory[addrA + w*4 + 3], memory[addrA + w*4 + 2],
                                    	memory[addrA + w*4 + 1], memory[addrA + w*4 + 0]};
        	end
		end
	end

	always @(readRequestB, addrB, accessTypeB, waitRequestB) begin
		dataOutB = 32'b0;
		if (!waitRequestB) begin
			case (accessTypeB)
				BYTE : begin
					dataOutB = {24'b0, memory[addrB]};
				end
				HALFWORD : begin
					dataOutB = {16'b0, memory[addrB + 1], memory[addrB]};
				end
				WORD : begin
					dataOutB = {memory[addrB + 3], memory[addrB + 2], memory[addrB + 1], memory[addrB]};
				end
			endcase
		end
	end

endmodule