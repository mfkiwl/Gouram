module trace_buffer
#(
    parameter BUFFER_WIDTH = 8,
    parameter type trace_output = int
)
(
    // Externally Required Signals

    input logic clk,
    input logic rst_n,
    input bit ready_signal,
    input trace_output trace_element_in,
    input bit data_request,
    
    // Outputs
    
    output bit data_present,
    output bit data_valid,
    output trace_output trace_element_out
);

    (* dont_touch = "yes" *) trace_output buffer [BUFFER_WIDTH-1:0];
    (* dont_touch = "yes" *) bit signed [$clog2(BUFFER_WIDTH):0] front; 
    (* dont_touch = "yes" *) bit signed [$clog2(BUFFER_WIDTH):0] rear;
    integer count;
    
    
    enum bit {
        START = 1'b0,
        OUTPUT_DATA = 1'b1
    } output_state;
   
    always_ff@(posedge clk)
    begin
        if (ready_signal)
        begin
            rear <= (rear + 1) % BUFFER_WIDTH;
            buffer[rear] <= trace_element_in;
            count <= count + 1;
        end
        unique case (output_state)
            START:
            begin
                if (data_valid) data_valid <= 1'b0;
                else if (data_request && !(count == 0))
                begin
                    output_state <= OUTPUT_DATA;
                end
            end
            OUTPUT_DATA:
            begin
                data_valid <= 1'b1;
                trace_element_out <= buffer[front];
                front <= (front + 1) % BUFFER_WIDTH;
                count <= count - 1;
                output_state <= START;
            end
        endcase
        if (!count) data_present <= 1'b0;   
        else data_present <= 1'b1;
        if (!rst_n)
        begin
            initialise_module();
        end 
    end
    
    initial
    begin
        initialise_module();
    end
    
    task initialise_module();
        front <= 0;
        rear <= 0;
        count <= 0;
        buffer <= '{default:0};
        output_state <= START;
        data_valid <= 1'b0;
        data_present <= 1'b0;
    endtask

endmodule
