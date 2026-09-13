`timescale 1ns/1ns

module tb;


	localparam bit FAKE_UART = 1'b1;

	
	localparam int GPIO_IN_NUM = 8;
	localparam int GPIO_OUT_NUM = 8;

    localparam int BAUD_RATE     	= 960_000;
    localparam int BIT_TIME_NS    	= 1_000_000_000 / BAUD_RATE;
    localparam int FIRST_SAMPLE_NS 	= (BIT_TIME_NS * 5) / 4; 

    logic clk;
    logic rst;

	logic [GPIO_IN_NUM - 1:0]  gpioIn = '0;
	wire  [GPIO_OUT_NUM - 1:0] gpioOut;

	logic uartRX = 1'b1;
	wire  uartTX;



    SARV_SoC #(
		.GPIO_IN_NUM(GPIO_IN_NUM),
		.GPIO_OUT_NUM(GPIO_OUT_NUM)
	) SoC (
        .clk(clk),
        .rst(rst),
		
		.uartRX(uartRX),
		.uartTX(uartTX),
		
		.GPIO_In(gpioIn),
		.GPIO_Out(gpioOut)
    );
	

    initial begin
        clk = 1'b0;
        forever begin
            #1 clk = ~clk;
        end
    end

	initial begin
		#200;
		sendFrame("HI");
			
	end


    initial begin
        rst = 1'b1;
        #20 rst = 1'b0;
		#4_000;
		//gpioIn = 8'h2;
        #4_000;
        //$stop;
        #400_000;
        //$stop;
        #900_000;
        $stop;
        #100_000_000;
        $stop;
    end

	task sendFrame(input byte frame[]);
    	for (int i = 0; i < frame.size(); i++) begin
        	uartSendByte(frame[i]);
    	end
    	uartSendByte(8'h0D); // Enter '\r'
	endtask

	task uartSendByte(input [7:0] data);
		logic rx_parity;
		begin
			uartRX = 1'b0;
			#BIT_TIME_NS;

			rx_parity = ^ data;
			
			for (int i = 0; i < 8 ; i++) begin
				uartRX = data[i];
				#BIT_TIME_NS;
			end

			uartRX = rx_parity;
			#BIT_TIME_NS;

			uartRX = 1'b1;
			#BIT_TIME_NS;
		end
	endtask
    
	if (FAKE_UART == 1'b0) begin

    	initial begin
        	fork
            	uartTX_monitor();
        	join
    	end

 	   task uartTX_monitor;
    	    logic [7:0] tx_char;
			logic		tx_parity;

			begin
    	    	forever begin
            
					@(negedge uartTX);
			
					#FIRST_SAMPLE_NS; 
			
					for (int i = 0; i < 8; i = i + 1) begin
	            		tx_char[i] = uartTX;
    	    	   		#BIT_TIME_NS;
    	    		end
	            	tx_parity = uartTX;
    	    	   	#BIT_TIME_NS;
					$write("%c", tx_char);
					$fflush();
            	end
        	end
    	endtask
	end else begin
    
		`define UART_ADDR 32'h1000_0000
		always @(posedge clk) begin
    		if (SoC.CoreSubsystem.dMemWriteReq && SoC.CoreSubsystem.dMemAddress == `UART_ADDR) begin
        		$write("%c", SoC.CoreSubsystem.dMemDataOut);
    		end
		end

	end

    always @(posedge clk) begin
        if (SoC.instructionMem.dataOutA === 32'bx) begin
            $display("x data");
            $stop;
        end
    end    

    // Simulation end detection
    `define SIMEND_ADDR 32'h2000_0000
    always @(posedge clk) begin
        if (SoC.CoreSubsystem.dMemWriteReq && SoC.CoreSubsystem.dMemAddress == `SIMEND_ADDR) begin
            $write("\n Simulation Ended by Writing in End Address\n");
            $stop;
        end
    end    
endmodule
