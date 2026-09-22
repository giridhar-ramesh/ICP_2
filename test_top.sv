import tb_pkg::*;
//------------------------------------------------------------------------------------------------
// Section 0
// We will use the Randomizer to generate random constrained stimuli.
//------------------------------------------------------------------------------------------------
class RANDOMIZER;
    // Task 2: Modify this class so that we can randomize 
   randc opcode op;
    rand logic[7:0] operand_1;
    rand logic[7:0] operand_2;
	constraint no_div_by_zero {
        	if (op inside {DIV, MOD}) operand_2 != 0;
    	}
	constraint no_add_overflow {
        	if (op == ADD) operand_1 + operand_2 <= 255;
    	}
		constraint no_mul_overflow {
        	if (op == MUL) operand_1 * operand_2 <= 255;
    	}
		constraint no_sub_underflow {
        	if (op == SUB) operand_1  >= operand_2;
    	}


endclass

module simple_alu_tb;

    //------------------------------------------------------------------------------
    // Section 1
    // TB internal signals
    //------------------------------------------------------------------------------    
    logic           tb_clock;
    logic           tb_reset_n;
    logic           tb_start_bit;
    logic [7:0]    tb_operand_1;
    logic [7:0]    tb_operand_2;
    logic [7:0]    tb_result;
    logic [7:0]     tb_max_count;
    opcode          tb_opcode;
    

    //------------------------------------------------------------------------------
    // Section 2
    // Initialize signals
    //------------------------------------------------------------------------------    
    initial begin
        tb_clock = 0;
        tb_reset_n = 0;
        tb_start_bit = 0;
        tb_operand_1 = 0;
        tb_operand_2 = 0;
        tb_max_count = 0;
    end

    //------------------------------------------------------------------------------
    // Section 3
    // Instantiation of mysterybox DUT (Design Under Test)(The thing we want to look at :)
    //------------------------------------------------------------------------------
    simple_alu DUT (
        .clock(tb_clock),
        .reset_n(tb_reset_n),
        .start(tb_start_bit),
        .a(tb_operand_1),
        .b(tb_operand_2),
        .c(tb_result),
        .mode_select(tb_opcode)
    );
    RANDOMIZER randy = new();
    //------------------------------------------------------------------------------
    // Section 4
    // Clock generator.
    //------------------------------------------------------------------------------
    initial begin
        forever begin
            tb_clock = #5ns ~tb_clock;
        end
    end

    //------------------------------------------------------------------------------
    // Section 5
    // Task to generate Reset simulus
    //------------------------------------------------------------------------------
    task automatic reset(int delay, int length);
        $display("%0t reset():            Starting delay=%0d length=%0d",$time(), delay, length);
        //Repeat doing nothing for the clock delay
        repeat(delay) @(posedge tb_clock);

        tb_reset_n <= 0;
        $display("%0t reset():            Reset activated",$time());
        // Min 1 clock that reset bit is active. Use a do while loop for that!
        do begin
            @(posedge tb_clock);
        end while (--length > 0);
        tb_reset_n <= 1;
        $display("%0t reset():            Reset released",$time());
    endtask


    //------------------------------------------------------------------------------
    // Section 6
    // Task to generate start bit simulus
    //------------------------------------------------------------------------------
    task automatic start_bit(int delay, int length);
        $display("%0t start_bit():        Starting delay=%0d length=%0d",$time(), delay, length);
        // Min 1 clock synchronize start bit 
        do begin
            @(posedge tb_clock);
        end while (--delay > 0);
        tb_start_bit <= 1;
        $display("%0t start_bit():        Start bit activated ",$time());
        // Min 1 clock that start bit is active
        do begin
            @(posedge tb_clock);
        end while (--length > 0);
        tb_start_bit <= 0;
        $display("%0t start_bit():        Start bit released ",$time());
    endtask

    //------------------------------------------------------------------------------
    // Section 7
    // Task to simplify generation of signals.
    //------------------------------------------------------------------------------
    task automatic do_math(int a,int b,opcode code);
        if(randy.randomize())
            $display("Randomization done! :D");
        else 
           $error("Failed to randomize :(");
        $display("%0t do_math:   Opcode:%0s     First number=%0d Second Value=%0d",$time(),code.name(), a, b);
        @(posedge tb_clock);
        tb_start_bit <= 1;
        tb_operand_1 <= a;
        tb_operand_2 <= b;
        tb_opcode<= code;
        @(posedge tb_clock);
        tb_operand_1 <= '1;
        tb_operand_2 <= '1;
	tb_opcode<= ADD;	//for safer side checking
        tb_start_bit <= 0;
    endtask

    //------------------------------------------------------------------------------
    // Section 8
    // Functional coverage definitions. Expand on this!!!
    //------------------------------------------------------------------------------
    
    covergroup basic_fcov @(negedge tb_clock);
        reset:coverpoint tb_reset_n{
            bins reset = { 0 };
            bins run=    { 1 };
        }
    //Task 3: Expand our coverage...
    	op: coverpoint tb_opcode {
   		 bins add = {ADD};
   		 bins sub = {SUB};
   		 bins mul = {MUL};
   		 bins div = {DIV};
   		 bins mod = {MOD};
	}

	a: coverpoint tb_operand_1 {
 	   bins zero    = {0};
 	   bins max     = {255};
  	   bins low     = {[1:84]};
 	   bins mid     = {[85:169]};
      	   bins high    = {[170:254]};
	}
	b: coverpoint tb_operand_2 {
 	   bins zero    = {0};
 	   bins max     = {255};
  	   bins low     = {[1:84]};
 	   bins mid     = {[85:169]};
      	   bins high    = {[170:254]};
	}

	c: coverpoint tb_result {
 	   bins zero    = {0};
 	   bins max     = {255};
  	   bins low     = {[1:84]};
 	   bins mid     = {[85:169]};
      	   bins high    = {[170:254]};
	}

	x_op_a: cross op, a;
    	x_op_b: cross op, b;
    	x_op_c: cross op, c;


    //Task 5: Add some crosses aswell to get some granularity going!
    endgroup: basic_fcov

    basic_fcov coverage_instance;



    //------------------------------------------------------------------------------
    // Section 9
    // Task 4: Now change your test case , and the number of times you run it so that your input stim
    //Here we will start our meat and potatoes of the test.
    //------------------------------------------------------------------------------
    task test_case();
        reset(.delay(0), .length(2));

      //  repeat(2)
      //  do_math(1,2,ADD);
  	  do_math(255, 255, ADD);
	  do_math(0, 120, ADD);       //added after 96% fo the complete cover point
  	  do_math(255, 0,   SUB);
 	  do_math(200, 10,   SUB);	
  	  do_math(0, 255, MUL);
  	  do_math(15, 12, MUL);
  	  do_math(220, 30, DIV);


	repeat(50) begin
	randy.randomize();
	do_math(randy.operand_1,randy.operand_2,randy.op);
	end

        reset(.delay(10), .length(2));
        // Task 1: The DUT is causing this assertion to be hit...
        assert (tb_result == 0) 
            $display ("Output reset");
        else
            $error("Reset doesn't clear output!");
            
        

    endtask

    //------------------------------------------------------------------------------
    // Section 10
    // Start test case from time 0
    //------------------------------------------------------------------------------
    initial begin
        // Here we can call our tests. Start by initializing our coverage!
        coverage_instance = new();
        
        //Uncomment this to try randomizing internal randomizable variables.
        //if(randy.randomize())
        //    $display("Randomization done! :D");
        //else 
        //    $error("Failed to randomize :(");
        $display("*****************************************************");
        $display("Starting Tests");
        $display("*****************************************************");
        test_case();
        $display("*****************************************************");
        $display("Tests Finished!");
        $display("*****************************************************");

        $stop;
    end

endmodule
