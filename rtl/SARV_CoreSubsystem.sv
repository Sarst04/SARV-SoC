////////////////////////////////////////////////////////////////////////////////
// File       : SARV_CoreSubsystem.sv
// Author(s)  : Sayyid Amirreza Sayyid Torabi <sayyidtorabi@gmail.com>
// Created    : 2026-08-10
// Description:
//
// Revisions:
//   2026-08-10 - Initial release (Sayyid Amirreza Sayyid Torabi)
////////////////////////////////////////////////////////////////////////////////
module SARV_CoreSubsystem #(
    parameter int INSTRUCTION_CACHE_LINES_COUNT      = 128,
    parameter int INSTRUCTION_CACHE_WORD_PER_LINE    = 4,
    parameter int INSTRUCTION_CACHE_WAY_COUNT        = 4,
	parameter bit INSTRUCTION_CACHE_BYPASS			 = 0,
    
    parameter int DATA_CACHE_LINES_COUNT             = 128,
    parameter int DATA_CACHE_WORD_PER_LINE    		 = 4,
    parameter int DATA_CACHE_WAY_COUNT               = 4,
	parameter bit DATA_CACHE_BYPASS			 		 = 0,
    parameter logic [31:0] DATA_MEM_BASE_ADDR        = 32'h8000_0000,
	parameter logic [31:0] DATA_MEM_END_ADDR		 = 32'h8F00_0000
)(
    input  wire clk,
    input  wire rst,
    
    // IRQ
    input  wire MSI,
    input  wire MEI,
    output wire MTI,
    
    // Instruction Memory
    output wire                                         iMemReadReq,
    output wire [31:0]                                  iMemAddress,
    input  wire                                         iMemWaitReq,
    input  wire [32*INSTRUCTION_CACHE_WORD_PER_LINE - 1:0] iMemData,
    
    // Data Memory
    output wire                                         dMemReadReq,
    output wire                                         dMemWriteReq,
    output wire [1:0]                                   dMemAccessType,
    output wire [31:0]                                  dMemAddress,
    output wire [32*DATA_CACHE_WORD_PER_LINE - 1:0]     dMemDataOut,
    input  wire                                         dMemWaitReq,
    input  wire [32*DATA_CACHE_WORD_PER_LINE - 1:0]     dMemDataIn
);

    wire [31:0] instructionMemoryAddress;
    wire [31:0] instructionMemoryData;
    wire        instructionMemoryWaitRequest;
    wire        instructionMemoryReadRequest;
    wire        instructionMemoryUnalignedAccess;
    
    wire [1:0]  MemoryAccessType;
    wire        MemoryWriteRequest;
    wire        MemoryReadRequest;
    wire [31:0] MemoryAddress;
    wire [31:0] MemoryWriteData;
    wire [31:0] MemoryReadData;
    wire        MemoryWaitRequest;

    SARV_Core Core(
        .clk(clk),
        .rst(rst),

        .MEI(MEI),
        .MTI(MTI),
        .MSI(MSI),

        .instructionMemoryAddress(instructionMemoryAddress),
        .instructionMemoryReadRequest(instructionMemoryReadRequest),
        .instructionMemoryData(instructionMemoryData),
        .instructionMemoryWaitRequest(instructionMemoryWaitRequest),
        .instructionMemoryUnalignedAccess(instructionMemoryUnalignedAccess),

        .memoryAddress(MemoryAddress),
        .memoryWriteData(MemoryWriteData),
        .memoryAccessType(MemoryAccessType),
        .memoryWriteRequest(MemoryWriteRequest),
        .memoryReadRequest(MemoryReadRequest),
        .memoryReadData(MemoryReadData),
        .memoryWaitRequest(MemoryWaitRequest)
    );

    instCache #(
        .CACHE_LINES(INSTRUCTION_CACHE_LINES_COUNT),
        .WORD_PER_LINES(INSTRUCTION_CACHE_WORD_PER_LINE),
        .NUM_WAYS(INSTRUCTION_CACHE_WAY_COUNT),
		.BYPASS_CACHE(INSTRUCTION_CACHE_BYPASS)
    ) instructionCache (
        .clk(clk),
        .rst(rst),
        
        .readReq(instructionMemoryReadRequest),
        .address(instructionMemoryAddress),
        .unalignedAccess(instructionMemoryUnalignedAccess),
        .waitReq(instructionMemoryWaitRequest),
        .dataOut(instructionMemoryData),
        
        .memWaitReq(iMemWaitReq),
        .memData(iMemData),
        .memReadReq(iMemReadReq),
        .memAddress(iMemAddress)
    );

    dataCache #(
        .CACHE_LINES(DATA_CACHE_LINES_COUNT),
        .NUM_WAYS(DATA_CACHE_WAY_COUNT),
		.WORD_PER_LINES(DATA_CACHE_WORD_PER_LINE),
		.BYPASS_CACHE(DATA_CACHE_BYPASS),
		.MEM_BASE(DATA_MEM_BASE_ADDR),
		.MEM_END(DATA_MEM_END_ADDR)
    ) dataCache (
        .clk(clk),
        .rst(rst),
        
        .readReq(MemoryReadRequest),
        .writeReq(MemoryWriteRequest),
        .accessType(MemoryAccessType),
        .waitReq(MemoryWaitRequest),
        .address(MemoryAddress),
        .dataIn(MemoryWriteData),
        .dataOut(MemoryReadData),
        
        .memWaitReq(dMemWaitReq),
        .memReadReq(dMemReadReq),
        .memWriteReq(dMemWriteReq),
        .memAccessType(dMemAccessType),
        .memDataIn(dMemDataIn),
        .memAddress(dMemAddress),
        .memDataOut(dMemDataOut)
    );
endmodule

