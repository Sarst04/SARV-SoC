////////////////////////////////////////////////////////////////////////////////
// File       : SARV_SoC_pkgConfig.sv
// Author(s)  : Sayyid Amirreza Sayyid Torabi <sayyidtorabi@gmail.com>
// Created    : 2026-09-13
// Description:
//
// Revisions:
//   2026-09-13 - Initial release (Sayyid Amirreza Sayyid Torabi)
////////////////////////////////////////////////////////////////////////////////
package SARV_SoC_pkgConfig;

	// Memory Map
    localparam INSTRUCTION_MEMORY_BASE_ADDR 	= 32'h0000_0000;
    localparam INSTRUCTION_MEMORY_END_ADDR  	= INSTRUCTION_MEMORY_BASE_ADDR + 32'hFFFF;

    localparam DATA_MEMORY_BASE_ADDR        	= 32'h8000_0000;
    localparam DATA_MEMORY_END_ADDR         	= DATA_MEMORY_BASE_ADDR + 32'hFFFF;

    localparam ACLINT_BASE_ADDR             	= 32'hfff4_0000;
    localparam ACLINT_END_ADDR              	= ACLINT_BASE_ADDR + 32'hBFFF;

	localparam UART_BASE_ADDR					= 32'h1000_0000;
	localparam UART_END_ADDR					= UART_BASE_ADDR + 32'hFF;

	localparam GPIO_BASE_ADDR					= 32'h1001_0000;
	localparam GPIO_END_ADDR					= GPIO_BASE_ADDR + 32'hFF;	

	localparam PLIC_BASE_ADDR					= 32'h0C00_0000;
	localparam PLIC_END_ADDR					= PLIC_BASE_ADDR + 32'h20_7FFF;
    
    // Cache Parameters
    localparam INSTRUCTION_CACHE_LINES_COUNT    = 256;
    localparam INSTRUCTION_CACHE_WORD_PER_LINE  = 4;
    localparam INSTRUCTION_CACHE_WAY_COUNT      = 4;

    localparam DATA_CACHE_LINES_COUNT           = 256;
    localparam DATA_CACHE_WORD_PER_LINE  		= 4;
    localparam DATA_CACHE_WAY_COUNT             = 4;

	localparam BYPASS_DATA_CACHE				= 0;
	localparam BYPASS_INSTRUCTION_CACHE			= 0;

	// Memory Model Delay
	localparam DELAY_INST_MEM					= 1;
	localparam DELAY_DATA_MEM					= 1;

endpackage