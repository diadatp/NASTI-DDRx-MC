/**
 * This module is responsible for mapping a NASTI address to SDRAM addressing.
 */

// `include "enums.svh"

module address_mapper #(
    C_NASTI_ADDR_WIDTH = 40,
    C_NASTI_DATA_WIDTH = 64,
    C_CS_WIDTH         = 1 ,
    C_DQ_WIDTH         = 64,
    C_ROW_WIDTH        = 16,
    C_BANK_WIDTH       = 3
) (
    input  row_widths                   r_width   ,
    input  col_widths                   c_width   ,
    input                               bor       , // bank or rank at msb
    //
    input      [C_NASTI_ADDR_WIDTH-1:0] nasti_addr,
    output     [        C_CS_WIDTH-1:0] rank      ,
    output reg [      C_BANK_WIDTH-1:0] bank      ,
    output reg [       C_ROW_WIDTH-1:0] row       ,
    output reg [                  11:0] column
);

    initial begin
        // TODO fix in later revision
        assert(C_NASTI_DATA_WIDTH >= C_DQ_WIDTH) else $fatal(1, "[mc] NASTI data width is too small.");
    end

    localparam OFFSET_BITS = $clog2(C_DQ_WIDTH/8);

    int i;

    always_comb begin : proc_column
        column[9:0] = nasti_addr[OFFSET_BITS +: 10];
        unique case (c_width)
            c9  : column[11:10] = {1'b0, 1'b0};
            c10 : column[11:10] = {1'b0, nasti_addr[10 + OFFSET_BITS]};
            c11 : column[11:10] = {nasti_addr[11 + OFFSET_BITS], nasti_addr[10 + OFFSET_BITS]};
        endcase
    end

    localparam SS_WIDTH = C_ROW_WIDTH+C_BANK_WIDTH+C_CS_WIDTH;

    logic [SS_WIDTH-1:0] second_stage;

    always_comb begin : proc_second_stage
        unique case (c_width)
            c9  : second_stage = nasti_addr[(10 + OFFSET_BITS) +: SS_WIDTH];
            c10 : second_stage = nasti_addr[(11 + OFFSET_BITS) +: SS_WIDTH];
            c11 : second_stage = nasti_addr[(12 + OFFSET_BITS) +: SS_WIDTH];
        endcase
    end

    always_comb begin : proc_row
        row[11:0] = second_stage[11:0];
        unique case (r_width)
            r11 : row[C_ROW_WIDTH-1:12] = 4'b0000;
            r12 : row[C_ROW_WIDTH-1:12] = {3'b000, second_stage[12]};
            r13 : row[C_ROW_WIDTH-1:12] = {2'b0, second_stage[13:12]};
            r14 : row[C_ROW_WIDTH-1:12] = {1'b0, second_stage[14:12]};
            r15 : row[C_ROW_WIDTH-1:12] = second_stage[15:12];
        endcase
    end

    always_comb begin : proc_bank
        for(i = 0; i < C_BANK_WIDTH; i++) begin
            unique case (r_width)
                r11 : bank[i] = second_stage[i + 12];
                r12 : bank[i] = second_stage[i + 13];
                r13 : bank[i] = second_stage[i + 14];
                r14 : bank[i] = second_stage[i + 15];
                r15 : bank[i] = second_stage[i + 16];
            endcase
        end
    end

endmodule // address_mapper
