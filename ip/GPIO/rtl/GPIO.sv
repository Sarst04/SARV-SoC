////////////////////////////////////////////////////////////////////////////////
// File       : GPIO.sv
// Author(s)  : Sayyid Amirreza Sayyid Torabi <sayyidtorabi@gmail.com>
// Created    : 2026-09-07
// Description:
//
// Revisions:
//   2026-09-07 - Initial release (Sayyid Amirreza Sayyid Torabi)
////////////////////////////////////////////////////////////////////////////////

module GPIO #(
	parameter int	GPIO_IN_NUM = 8,
	parameter int	GPIO_OUT_NUM = 8
	
)(
	input  wire							clk,
	input  wire							rst,

	input  wire	 [GPIO_IN_NUM  - 1:0]  	GPIO_In,
	output logic [GPIO_OUT_NUM - 1:0] 	GPIO_Out,

    // Bus Side
    input  wire         readRequest,
    input  wire         writeRequest,

    input  wire  [31:0] address,
    input  wire  [31:0] dataIn,
    output logic [31:0] dataOut,

    // Interrupt
    output wire  		irq

);
    localparam logic [3:0] ADDR_GPIO_OUT  = 4'h0;
    localparam logic [3:0] ADDR_GPIO_IN   = 4'h4;
    localparam logic [3:0] ADDR_STATUS    = 4'h8;
    localparam logic [3:0] ADDR_CONTROL   = 4'hC;


	logic [GPIO_IN_NUM - 1:0] statusReg;
	logic [GPIO_IN_NUM - 1:0] controlReg;

	logic [GPIO_IN_NUM - 1:0] gpioInReg;
	logic [GPIO_IN_NUM - 1:0] gpioInRegPre;


	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			gpioInReg 		<= '0;
			gpioInRegPre	<= '0;
		end else begin
			gpioInReg 		<= GPIO_In;
			gpioInRegPre	<= gpioInReg;
		end 
	end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            statusReg <= '0;
        end else if (writeRequest && (address[3:0] == ADDR_STATUS)) begin
            statusReg <= '0;
        end else begin
			statusReg <= statusReg | ((gpioInReg ^ gpioInRegPre));
        end
    end


	assign irq = |(statusReg & controlReg);

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			controlReg <= '0;
			GPIO_Out   <= '0;
		end else begin
			if (writeRequest) begin
				unique0 case (address[3:0])
					ADDR_GPIO_OUT: begin
						GPIO_Out <= dataIn[GPIO_OUT_NUM - 1:0];
					end
					ADDR_CONTROL: begin
						controlReg <= dataIn[GPIO_IN_NUM - 1:0];
					end
				endcase
			end
		end
	end
	always_comb begin
		dataOut = 32'b0;
		if (readRequest) begin
			unique0 case (address[3:0])
				ADDR_GPIO_IN: begin
					dataOut 	= {'0, gpioInReg};
				end
				ADDR_STATUS: begin
					dataOut 	= {'0, statusReg};
				end
				ADDR_CONTROL: begin
					dataOut 	= {'0, controlReg};
				end
			endcase
		end
	end



endmodule