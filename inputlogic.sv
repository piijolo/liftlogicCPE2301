`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/17/2026 08:31:28 AM
// Design Name: 
// Module Name: inputlogic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module input_controller(
    input logic clk,
    input logic reset,
    
    //internal elevator controls
    input logic [1:0] IF_sw, 
    input logic BT_center,
    
    //outside elevator controls
    input logic [3:0] OF_sw,
    input logic BT_up,
    input logic BT_down,
    
    //other controls
    input logic emergency_sw,
    input logic BT_hold,
    input logic BT_reset,
    
    output logic [1:0] cabin_floor,
    output logic       cabin_request_pulse,
    output logic [3:0] hall_up_pulse,
    output logic [3:0] hall_down_pulse, 
    
    output logic emergency_active,
    output logic hold_active,
    output logic reset_pulse
    );
    
    // Previous button values for rising-edge detection
    logic center_prev, up_prev, down_prev, reset_prev;

    always_ff @(posedge clk) begin
        if (reset) begin
            center_prev <= 1'b0;
            up_prev     <= 1'b0;
            down_prev   <= 1'b0;
            reset_prev  <= 1'b0;
        end
        else begin
            center_prev <= BT_center;
            up_prev     <= BT_up;
            down_prev   <= BT_down;
            reset_prev  <= BT_reset;
        end
    end

    // One-clock pulse when each button is newly pressed
    assign cabin_request_pulse = BT_center & ~center_prev;
    assign reset_pulse         = BT_reset  & ~reset_prev;

    // Internal floor chosen by the two switches
    assign cabin_floor = IF_sw;

    // Emergency and hold are level-based controls
    assign emergency_active = emergency_sw;
    assign hold_active      = BT_hold;

    // Invalid hall calls are blocked:
    // Floor 4 cannot request UP
    // Floor 1 cannot request DOWN
    always_comb begin
        hall_up_pulse   = 4'b0000;
        hall_down_pulse = 4'b0000;

        if (BT_up & ~up_prev)
            hall_up_pulse = OF_sw & 4'b0111;

        if (BT_down & ~down_prev)
            hall_down_pulse = OF_sw & 4'b1110;
    end
endmodule

// output of request_manager should be sent to the FSM.
module request_manager (
    input  logic       clk,
    input  logic       rst,
    input  logic       reset_pulse,

    // From input_controller
    input  logic [1:0] cabin_floor,
    input  logic       cabin_request_pulse,
    input  logic [3:0] hall_up_pulse,
    input  logic [3:0] hall_down_pulse,

    // From main FSM
    input  logic       service_valid,
    input  logic [1:0] service_floor,
    input  logic       clear_cabin_request,
    input  logic       clear_up_request,
    input  logic       clear_down_request,

    // Stored requests sent to FSM/display logic
    output logic [3:0] cabin_pending,
    output logic [3:0] hall_up_pending,
    output logic [3:0] hall_down_pending,
    output logic       any_request
);

    logic [3:0] cabin_next;
    logic [3:0] up_next;
    logic [3:0] down_next;

    always_comb begin
        // By default, retain stored requests
        cabin_next = cabin_pending;
        up_next    = hall_up_pending;
        down_next  = hall_down_pending;

        // Clear only requests the FSM says were served
        if (service_valid) begin
            if (clear_cabin_request)
                cabin_next[service_floor] = 1'b0;

            if (clear_up_request)
                up_next[service_floor] = 1'b0;

            if (clear_down_request)
                down_next[service_floor] = 1'b0;
        end

        // New requests have priority, so one cannot be lost
        if (cabin_request_pulse)
            cabin_next[cabin_floor] = 1'b1;

        up_next   = up_next   | hall_up_pulse;
        down_next = down_next | hall_down_pulse;
    end

    always_ff @(posedge clk) begin
        if (rst || reset_pulse) begin
            cabin_pending   <= 4'b0000;
            hall_up_pending <= 4'b0000;
            hall_down_pending <= 4'b0000;
        end
        else begin
            cabin_pending   <= cabin_next;
            hall_up_pending <= up_next;
            hall_down_pending <= down_next;
        end
    end

    assign any_request =
        |cabin_pending |
        |hall_up_pending |
        |hall_down_pending;

endmodule
