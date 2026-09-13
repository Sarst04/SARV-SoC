////////////////////////////////////////////////////////////////////////////////
// File      : dataMemoryModel.v
// Author(s) : Sayyid Amirreza Sayyid Torabi <sayyidtorabi@gmail.com>
// Date      : 2026-10-8 (last modified)
// Description: 
//
////////////////////////////////////////////////////////////////////////////////
module dataMemoryModel #(
    parameter MEM_SIZE            = 1024,
    parameter DELAY               = 0,
    parameter WORD_PER_LINES_PORT = 1
) (
    input wire                          clk,
    input wire                          rst,
    
    input wire                          readRequest,
    input wire                          writeRequest,
    input wire [1:0]                    accessType,
    input wire                          chipSelect,
    output reg                          waitRequest,

    input wire [31:0]                   address,
    input wire [32*WORD_PER_LINES_PORT-1:0] dataIn,
    output reg [32*WORD_PER_LINES_PORT-1:0] dataOut
);

    localparam IDLE = 1'b0;
    localparam WAIT = 1'b1;

    generate
        if (DELAY == 0) begin : ZERO_DELAY
            always @(readRequest, writeRequest, chipSelect) begin
                waitRequest = 1'b0;
            end
        end else begin : NON_ZERO_DELAY
            reg [3:0]   counter;
            reg         countEn;
            reg         countClear;
            wire        carryOut;
            reg         ps, ns;
            reg [31:0]  currentAddr;

            always @(posedge clk, posedge rst) begin
                if (rst) begin
                    counter     <= 4'b1111 - DELAY;
                    currentAddr <= 32'b0;
                end else if (countClear) begin
                    counter     <= 4'b1111 - DELAY;
                    currentAddr <= address;
                end else if (countEn) begin
                    if ((readRequest || writeRequest) && chipSelect && (address != currentAddr)) begin
                        counter     <= 4'b1111 - DELAY;
                        currentAddr <= address;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
            end
            assign carryOut = &counter;
    
            always @(posedge clk, posedge rst) begin
                if (rst)  
                    ps <= IDLE;
                else      
                    ps <= ns;
            end
    
            always @(*) begin
                ns = IDLE;
                case (ps)
                    IDLE: ns = ((readRequest | writeRequest) & chipSelect) ? WAIT : IDLE;
                    WAIT: ns = carryOut ? IDLE : WAIT;
                endcase
            end

            always @(*) begin
                waitRequest = 1'b0;
                countClear  = 1'b0;
                countEn     = 1'b0;
                case (ps)
                    IDLE: begin
                        countClear  = 1'b1;
                        waitRequest = ((readRequest | writeRequest) & chipSelect);
                    end
                    WAIT: begin  
                        countEn     = 1'b1;
                        waitRequest = carryOut ? 1'b0 : 1'b1;
                    end
                endcase
            end
        end
    endgenerate

    localparam BYTE      = 2'b00;
    localparam HALFWORD  = 2'b01;
    localparam WORD      = 2'b10;
    
    reg [7:0] memory [0:MEM_SIZE-1];
    
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1)
            memory[i] = 8'b0;
    end

    generate
        if (WORD_PER_LINES_PORT > 1) begin : MULTI_WORD_PORT
            integer w;
            
            always @(*) begin
                dataOut = {(32 * WORD_PER_LINES_PORT){1'b0}};
                if (!waitRequest && readRequest && chipSelect) begin
                    for (w = 0; w < WORD_PER_LINES_PORT; w = w + 1) begin
                        dataOut[w*32 +: 32] = {memory[address + w*4 + 3], 
                                               memory[address + w*4 + 2],
                                               memory[address + w*4 + 1], 
                                               memory[address + w*4 + 0]};
                    end
                end
            end

            always @(posedge clk, posedge rst) begin
                if (rst) begin
                    for (i = 0; i < MEM_SIZE; i = i + 1)
                        memory[i] = 8'b0;
                end else begin
                    if (writeRequest & chipSelect) begin
                        for (w = 0; w < WORD_PER_LINES_PORT; w = w + 1) begin
                            memory[address + w*4    ] = dataIn[w*32 +: 8];
                            memory[address + w*4 + 1] = dataIn[w*32 + 8 +: 8];
                            memory[address + w*4 + 2] = dataIn[w*32 + 16 +: 8];
                            memory[address + w*4 + 3] = dataIn[w*32 + 24 +: 8];
                        end
                    end
                end
            end
            
        end else begin : SINGLE_WORD_PORT
            always @(*) begin
                dataOut = 32'b0;
                if (!waitRequest && readRequest && chipSelect) begin
                    case (accessType)
                        BYTE : begin
                            dataOut = {24'b0, memory[address]};
                        end
                        HALFWORD : begin
                            dataOut = {16'b0, memory[address + 1], memory[address]};
                        end
                        WORD : begin
                            dataOut = {memory[address + 3], memory[address + 2], memory[address + 1], memory[address]};
                        end
                    endcase
                end
            end
            always @(posedge clk, posedge rst) begin
                if (rst) begin
                    for (i = 0; i < MEM_SIZE; i = i + 1)
                        memory[i] = 8'b0;
                end else begin
                    if (writeRequest & chipSelect) begin
                        case (accessType)
                            BYTE : begin
                                memory[address    ] = dataIn[7:0];
                            end
                            HALFWORD : begin
                                memory[address    ] = dataIn[7:0];
                                memory[address + 1] = dataIn[15:8];
                            end
                            WORD : begin
                                memory[address    ] = dataIn[7:0];
                                memory[address + 1] = dataIn[15:8];
                                memory[address + 2] = dataIn[23:16];
                                memory[address + 3] = dataIn[31:24];
                            end
                        endcase
                    end
                end
            end
        end
    endgenerate

endmodule
