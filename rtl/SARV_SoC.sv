////////////////////////////////////////////////////////////////////////////////
// File       : SoC.sv
// Author(s)  : Sayyid Amirreza Sayyid Torabi <sayyidtorabi@gmail.com>
// Created    : 2026-09-13
// Description:
//
// Revisions:
//   2026-09-13 - Initial release (Sayyid Amirreza Sayyid Torabi)
////////////////////////////////////////////////////////////////////////////////
import SARV_SoC_config_pkg::*;
module SARV_SoC#(
	parameter int	GPIO_IN_NUM = 8,
	parameter int	GPIO_OUT_NUM = 8
)
(
    input  wire clk,
    input  wire rst,

	input  wire	uartRX,
	output wire uartTX,

	input  wire	 [GPIO_IN_NUM  - 1:0]  	GPIO_In,
	output logic [GPIO_OUT_NUM - 1:0] 	GPIO_Out
);
	localparam DATA_BUS_WORD_PER_LINE			= DATA_CACHE_WORD_PER_LINE;
	localparam INSTRUCTION_BUS_WORD_PER_LINE	= INSTRUCTION_CACHE_WORD_PER_LINE;
    
    wire        									MTI;
    wire  											MSI;
    wire  											MEI;

    wire                                            iMemReadReq;
    wire [31:0]                                     iMemAddress;
    wire                                            iMemWaitReq;
    wire [32*INSTRUCTION_CACHE_WORD_PER_LINE - 1:0] iMemData;
    
    wire                                            dMemReadReq;
    wire                                            dMemWriteReq;
    wire [1:0]                                      dMemAccessType;
    logic                                           dMemWaitReq;
    wire [31:0]                                     dMemAddress;
    wire [32*DATA_BUS_WORD_PER_LINE - 1:0]        	dMemDataOut;
    logic[32*DATA_BUS_WORD_PER_LINE - 1:0] 			dMemDataIn;


    wire [32*DATA_BUS_WORD_PER_LINE - 1:0] 			dataMemoryReadData;
    wire [31:0] 									aclintReadData;
    wire [31:0] 									instructionMemoryReadData;
	wire [31:0]										uartReadData;
	wire [31:0]										gpioReadData;
	wire [31:0]										plicReadData;
    

    logic dataMemorySelect;
    logic aclintSelect;
    logic instructionMemorySelect;
    logic uartSelect;
    logic gpioSelect;
    logic plicSelect;

	
	wire instMemWaitReq;
	wire dataMemWaitReq;
	wire aclintWaitReq;
	wire uartWaitReq;
	wire gpioWaitReq;
	wire plicWaitReq;

	wire uartIrq;
	wire gpioIrq;


	always_comb begin
    	instructionMemorySelect = 1'b0;
    	dataMemorySelect        = 1'b0;
    	aclintSelect            = 1'b0;
    	uartSelect              = 1'b0;
    	gpioSelect              = 1'b0;
    	plicSelect              = 1'b0;
	
		if ( dMemWriteReq | dMemReadReq) begin
    		case (dMemAddress) inside
        		[INSTRUCTION_MEMORY_BASE_ADDR : INSTRUCTION_MEMORY_END_ADDR] : instructionMemorySelect = 1'b1;
        		[DATA_MEMORY_BASE_ADDR        : DATA_MEMORY_END_ADDR]        : dataMemorySelect        = 1'b1;
        		[ACLINT_BASE_ADDR             : ACLINT_END_ADDR]             : aclintSelect            = 1'b1;
        		[UART_BASE_ADDR               : UART_END_ADDR]               : uartSelect              = 1'b1;
        		[GPIO_BASE_ADDR               : GPIO_END_ADDR]               : gpioSelect              = 1'b1;
        		[PLIC_BASE_ADDR               : PLIC_END_ADDR]               : plicSelect              = 1'b1;
    		endcase
		end
	end
   
    always_comb begin
        case (1'b1)
            dataMemorySelect:        dMemDataIn = dataMemoryReadData;
            instructionMemorySelect: dMemDataIn = {{(32*DATA_BUS_WORD_PER_LINE-32){1'b0}}, instructionMemoryReadData};
            aclintSelect:            dMemDataIn = {{(32*DATA_BUS_WORD_PER_LINE-32){1'b0}}, aclintReadData};
            uartSelect:              dMemDataIn = {{(32*DATA_BUS_WORD_PER_LINE-32){1'b0}}, uartReadData};
            gpioSelect:              dMemDataIn = {{(32*DATA_BUS_WORD_PER_LINE-32){1'b0}}, gpioReadData};
            plicSelect:              dMemDataIn = {{(32*DATA_BUS_WORD_PER_LINE-32){1'b0}}, plicReadData};
            default:                 dMemDataIn = '0;
        endcase
    end

    always_comb begin
        case (1'b1)
            dataMemorySelect:        dMemWaitReq = dataMemWaitReq;
            instructionMemorySelect: dMemWaitReq = instMemWaitReq;
            aclintSelect:            dMemWaitReq = aclintWaitReq;
            uartSelect:              dMemWaitReq = uartWaitReq;
            gpioSelect:              dMemWaitReq = gpioWaitReq;
            plicSelect:              dMemWaitReq = plicWaitReq;
            default:                 dMemWaitReq = 1'b0;
        endcase
    end
	
   
    SARV_CoreSubsystem #(
        .INSTRUCTION_CACHE_LINES_COUNT(INSTRUCTION_CACHE_LINES_COUNT),
        .INSTRUCTION_CACHE_WORD_PER_LINE(INSTRUCTION_CACHE_WORD_PER_LINE),
        .INSTRUCTION_CACHE_WAY_COUNT(INSTRUCTION_CACHE_WAY_COUNT),
		.INSTRUCTION_CACHE_BYPASS(BYPASS_INSTRUCTION_CACHE),
		.DATA_CACHE_WORD_PER_LINE(DATA_CACHE_WORD_PER_LINE),
        .DATA_CACHE_LINES_COUNT(DATA_CACHE_LINES_COUNT),
        .DATA_CACHE_WAY_COUNT(DATA_CACHE_WAY_COUNT),
		.DATA_CACHE_BYPASS(BYPASS_DATA_CACHE),
		.DATA_MEM_BASE_ADDR(DATA_MEMORY_BASE_ADDR),
		.DATA_MEM_END_ADDR(DATA_MEMORY_END_ADDR)
    ) CoreSubsystem (
        .clk(clk),
        .rst(rst),

        .MSI(MSI),
        .MEI(MEI),
        .MTI(MTI),
        
        .iMemReadReq(iMemReadReq),
        .iMemAddress(iMemAddress),
        .iMemWaitReq(iMemWaitReq),
        .iMemData(iMemData),
        
        .dMemReadReq(dMemReadReq),
        .dMemWriteReq(dMemWriteReq),
        .dMemAccessType(dMemAccessType),
        .dMemAddress(dMemAddress),
        .dMemDataOut(dMemDataOut),
        .dMemWaitReq(dMemWaitReq),
        .dMemDataIn(dMemDataIn)
    );
    
    instructionMemoryModel #(
        .MEM_SIZE(INSTRUCTION_MEMORY_END_ADDR - INSTRUCTION_MEMORY_BASE_ADDR),
        .WORD_PER_LINES_PORT_A(INSTRUCTION_CACHE_WORD_PER_LINE),
		.DELAY_A(DELAY_INST_MEM)
    ) instructionMem (
        .clk(clk),
        .rst(rst),
        
        .readRequestA(iMemReadReq),
        .addrA(iMemAddress),
        .dataOutA(iMemData),
        .waitRequestA(iMemWaitReq),
        
        .readRequestB(dMemReadReq & instructionMemorySelect),
        .addrB(dMemAddress - INSTRUCTION_MEMORY_BASE_ADDR),
        .dataOutB(instructionMemoryReadData),
        .accessTypeB(dMemAccessType),
        .waitRequestB(instMemWaitReq)
    );
    

    dataMemoryModel #(
		.MEM_SIZE(DATA_MEMORY_END_ADDR - DATA_MEMORY_BASE_ADDR),
		.WORD_PER_LINES_PORT(DATA_CACHE_WORD_PER_LINE),
		.DELAY(DELAY_DATA_MEM)
		) DataMem (
        .clk(clk),
        .rst(rst),
        .readRequest(dMemReadReq & dataMemorySelect),
        .writeRequest(dMemWriteReq & dataMemorySelect),
        .chipSelect(dataMemorySelect),
        .accessType(dMemAccessType),
        .address(dMemAddress - DATA_MEMORY_BASE_ADDR),
        .dataIn(dMemDataOut),
        .dataOut(dataMemoryReadData),
        .waitRequest(dataMemWaitReq)
    );
    
	assign	aclintWaitReq = 1'b0;
 	ACLINT #(
    .NUM_HARTS(1)
	) aclint(
        .clk(clk),
        .rst(rst),

        .readRequest(dMemReadReq & aclintSelect),
        .writeRequest(dMemWriteReq & aclintSelect),

    	.MTI(MTI),
    	.MSI(MSI),

        .address(dMemAddress - ACLINT_BASE_ADDR),
        .dataIn(dMemDataOut[31:0]),
        .dataOut(aclintReadData)
	);


	assign	plicWaitReq = 1'b0;
	PLIC #(
		.NUM_SOURCES(2),
		.NUM_CONTEXTS(1),
		.PRIORITY_WIDTH(2),
    	.EDGE_MASK('0)
	) plic (
        .clk(clk),
        .rst(rst),

		.irq_o(MEI),

		.irq_i({uartIrq, gpioIrq}),
	
        .readRequest(dMemReadReq & plicSelect),
        .writeRequest(dMemWriteReq & plicSelect),

        .address(dMemAddress - PLIC_BASE_ADDR),
        .dataIn(dMemDataOut[31:0]),
        .dataOut(plicReadData)
	);

 	
	assign	uartWaitReq = 1'b0;
	uart #(
    	.CLK_FREQUENCY(500_000_000),
    	.BAUD_RATE(960_000),
    	.FIFO_DEPTH(8),
		.OVERSAMPLE(16)
	) uart (
        .clk(clk),
        .rst(rst),

    	.RX(uartRX),
    	.TX(uartTX),

        .readRequest(dMemReadReq & uartSelect),
        .writeRequest(dMemWriteReq & uartSelect),


        .address(dMemAddress - UART_BASE_ADDR),
        .dataIn(dMemDataOut[31:0]),
        .dataOut(uartReadData),

    	.irq(uartIrq)
	);

	assign gpioWaitReq = 1'b0;
	GPIO #(
		.GPIO_IN_NUM(GPIO_IN_NUM),
		.GPIO_OUT_NUM(GPIO_OUT_NUM)
	) gpio (
        .clk(clk),
        .rst(rst),

		.GPIO_In(GPIO_In),
		.GPIO_Out(GPIO_Out),

        .readRequest(dMemReadReq & gpioSelect),
        .writeRequest(dMemWriteReq & gpioSelect),

        .address(dMemAddress - GPIO_BASE_ADDR),
        .dataIn(dMemDataOut[31:0]),
        .dataOut(gpioReadData),

    	.irq(gpioIrq)
	);
	
    
endmodule