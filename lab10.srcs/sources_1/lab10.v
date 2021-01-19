`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE,
    
      // 1602 LCD Module Interface
  	output LCD_RS,
  	output LCD_RW,
  	output LCD_E,
  	output [3:0] LCD_D
    );

//Declare debounce variables
wire [3:0] btn_level;
wire [3:0] btn_pressed;
reg  [3:0] prev_btn_level;

// declare SRAM control signals
wire [16:0] sram_addr;
wire [16:0] sram_cloud_addr;
wire [16:0] sram_cloud2_addr;
wire [16:0] sram_pika1_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire [11:0] data_out_cloud;
wire [11:0] data_out_cloud2;
wire [11:0] data_out_pika1;
wire [11:0] data_out_ball;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel




wire [31:0] P1score, P2score;
reg p1_increase, p2_increase;
reg [127:0] row_A = "P1 0000:0000 P2 ";
reg [127:0] row_B = "Fuck you Dlab...";

//SCORE
reg [7:0] pika1sc, pika2sc;
reg [17:0] score1_addr[0:11];
reg [17:0] score2_addr[0:11];
reg  [17:0] pixel_addr_sc1;
reg  [17:0] pixel_addr_sc2;
localparam SCORE_W = 28;
localparam SCORE_H = 28;
localparam SCORE_VPOS = 20;
localparam SCORE1_HPOS = 100;
localparam SCORE2_HPOS = 600;
wire score1_region,score2_region;
wire [16:0] sram_sc1_addr;
wire [16:0] sram_sc2_addr;
wire [11:0] data_out_sc2;
wire [11:0] data_out_sc1;

//

// Application-specific VGA signals
reg  [17:0] pixel_addr;
reg  [17:0] pixel_addr_cloud;
reg  [17:0] pixel_addr_cloud2;
reg  [17:0] pixel_addr_pika1;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the cloud1 images
localparam CLOUD_VPOS   = 20; 
localparam CLOUD_W      = 32; 
localparam CLOUD_H      = 16; 
reg [31:0] cloud_clock;
wire cloud_region;
wire [9:0] cloud_pos;
reg [17:0] cloud_addr;

// Set parameters for the cloud1 images
localparam CLOUD2_VPOS   = 40; 
localparam CLOUD2_W      = 32; 
localparam CLOUD2_H      = 16; 
reg [31:0] cloud2_clock;
wire cloud2_region;
wire [9:0] cloud2_pos;
reg [17:0] cloud2_addr;

//Set parameters for the pika1 inages
localparam PIKA1_W      = 47; 
localparam PIKA1_H      = 50; 
reg [31:0] pika1_clock_X;
reg [31:0] pika1_clock_Y;
reg [31:0] pika1_clock_anima;
wire pika1_region;
wire [9:0] pika1_pos_X;
wire [9:0] pika1_pos_Y;
reg [17:0] pika1_addr[0:7];
reg jump;
reg jumpdown;
reg [31:0] jump_clock;

//2P data
localparam pika2y = 167;
//wire        sram_we_pika2, sram_en_pika2;
reg  [31:0] pika2x_clock,pika2_clock;
wire [9:0] pika2x;
wire        pika2_region,pika2_ball_region;
reg [7:0] pika2_stop_pos;
initial begin

 pika2x_clock[31:20] = 70;
end


initial begin
    cloud_addr = 0;                   // Address for cloud
    cloud2_addr = 0;                   // Address for cloud 2
    pika1_addr[0] = 0;                // Address for pika1 image #1
    pika1_addr[1] = PIKA1_W*PIKA1_H  ; // Address for pika1 image #2
    pika1_addr[2] = PIKA1_W*PIKA1_H*2; // Address for pika1 image #3
    pika1_addr[3] = PIKA1_W*PIKA1_H*3; // Address for pika1 image #4
    pika1_addr[4] = PIKA1_W*PIKA1_H*4; // Address for pika1 image #5
    pika1_addr[5] = PIKA1_W*PIKA1_H*5; // Address for pika1 image #6
    pika1_addr[6] = PIKA1_W*PIKA1_H*6; // Address for pika1 image #7
    pika1_addr[7] = PIKA1_W*PIKA1_H*7; // Address for pika1 image #8
end



initial begin
    score1_addr[0] = 0;                // Address for pika1 image #1
    score1_addr[1] = SCORE_W*SCORE_H  ; // Address for pika1 image #2
    score1_addr[2] = SCORE_W*SCORE_H*2; // Address for pika1 image #3
    score1_addr[3] = SCORE_W*SCORE_H*3; // Address for pika1 image #4
    score1_addr[4] = SCORE_W*SCORE_H*4; // Address for pika1 image #5
    score1_addr[5] = SCORE_W*SCORE_H*5; // Address for pika1 image #6
    score1_addr[6] = SCORE_W*SCORE_H*6; // Address for pika1 image #7
    score1_addr[7] = SCORE_W*SCORE_H*7; // Address for pika1 image #8
    score1_addr[8] = SCORE_W*SCORE_H*8; // Address for pika1 image #8
    score1_addr[9] = SCORE_W*SCORE_H*9; // Address for pika1 image #8
    score1_addr[10] = SCORE_W*SCORE_H*10; // Address for WINWIN

    score2_addr[0] = 0;                // Address for pika1 image #1
    score2_addr[1] = SCORE_W*SCORE_H  ; // Address for pika1 image #2
    score2_addr[2] = SCORE_W*SCORE_H*2; // Address for pika1 image #3
    score2_addr[3] = SCORE_W*SCORE_H*3; // Address for pika1 image #4
    score2_addr[4] = SCORE_W*SCORE_H*4; // Address for pika1 image #5
    score2_addr[5] = SCORE_W*SCORE_H*5; // Address for pika1 image #6
    score2_addr[6] = SCORE_W*SCORE_H*6; // Address for pika1 image #7
    score2_addr[7] = SCORE_W*SCORE_H*7; // Address for pika1 image #8
    score2_addr[8] = SCORE_W*SCORE_H*8; // Address for pika1 image #8
    score2_addr[9] = SCORE_W*SCORE_H*9; // Address for pika1 image #8
    score2_addr[10] = SCORE_W*SCORE_H*10; // Address for WINWIN
      
end
//debounce
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

debounce btn_db2(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level[2])
);

debounce btn_db3(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level[3])
);

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

BCD_counter P1BCD_counter(
	.clk(clk),
	.rst(~reset_n),
	.increase(p1_increase),
	.result(P1score)
);

BCD_counter P2BCD_counter(
	.clk(clk),
	.rst(~reset_n),
	.increase(p2_increase),
	.result(P2score)
);
//---------------------------------------from hereeeeeeeeeeeee-------------------------------
wire        ball_region;
wire [16:0] sram_addr_ball;
reg  [17:0] pixel_addr_ball;

reg [2:0] kill;
reg     right,up;// if the ball is going right(up) or not
reg     touched, touched_reg, touched_net,touched_p1,touched_p2;
wire    ball_change;
reg  [32:0] ball_clock;
wire [32:0] ball_reg_clock;
localparam BALL_W = 20; // ball width
localparam BALL_H = 20; // ball height

reg [9:0] BALL_HPOS  ; // Horizontal location of the ball in the court image.
reg [8:0] BALL_VPOS   ; // Vertical location of the ball in the court image.
//reg a_x;
reg [4:0]a_y;
//reg [17:0] ball_addr[0:3];   // Address array for up to 8 ball images.
reg start;
reg b;//for sram_we
//---------------------------------------done hereeeeeeeeeeeee-------------------------------

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);
assign usr_led = {up,right,kill};

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

sram_ball #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BALL_W*BALL_H))
  ramball (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_ball), .data_i(data_in), .data_o(data_out_ball));
          
sram_cloud #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(CLOUD_W*CLOUD_H))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_cloud_addr), .data_i(data_in), .data_o(data_out_cloud));

sram_cloud #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(CLOUD_W*CLOUD_H))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_cloud2_addr), .data_i(data_in), .data_o(data_out_cloud2));          
sram_pika1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(PIKA1_W*PIKA1_H*8))
  ram3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_pika1_addr), .data_i(data_in), .data_o(data_out_pika1));
sramscore #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(SCORE_W*SCORE_H*11))
  ramsc1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_sc1_addr), .data_i(data_in), .data_o(data_out_sc1));          
sramscore #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(SCORE_W*SCORE_H*11))
  ramsc2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_sc2_addr), .data_i(data_in), .data_o(data_out_sc2));
assign sram_we = b; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign sram_addr_ball = pixel_addr_ball;
assign sram_cloud_addr = pixel_addr_cloud;
assign sram_cloud2_addr = pixel_addr_cloud2;
assign sram_pika1_addr = pixel_addr_pika1;
assign sram_sc2_addr = pixel_addr_sc2;
assign sram_sc1_addr = pixel_addr_sc1;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  	if (~reset_n)begin
  		row_A <= "P2 0000:0000 P1 ";
		row_B <= "Fuck you Dlab...";
	end
  	else begin
  		row_A <= {"P2 ", P2score, ":", P1score, " P1 "};
  		row_B <= "Fuck you Dlab...";
  	end
end
// End of the LCD display function
// ------------------------------------------------------------------------
always @(posedge clk) begin
  	if (~reset_n)begin
  		p1_increase <= 0;
		p2_increase <= 0;
	end
  	else begin
  		if(touched == 1 && touched_reg == 0 && BALL_HPOS > 320)
  			p1_increase <= 1;
  		else if(touched && touched_reg == 0 && BALL_HPOS < 320)
  			p2_increase <= 1;
  		else begin
  			p1_increase <= 0;
			p2_increase <= 0;
  		end
  	end
end




//Debounce----------------------------------------------------------------
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = btn_level&(~prev_btn_level);
//------------------------------------------------------------------------


//cloud control---------------------------------------------------------
// cloud image is 32x16
assign cloud_region =
           (pixel_y >= (CLOUD_VPOS<<1) && pixel_y < (CLOUD_VPOS+CLOUD_H)<<1 &&
           (pixel_x + 63) >= cloud_pos && pixel_x < cloud_pos + 1);
           
assign cloud_pos = cloud_clock[31:20];

always @(posedge clk) begin
  if (~reset_n || cloud_clock[31:21] > VBUF_W + CLOUD_W+100)
    cloud_clock <= 0;
  else
    cloud_clock <= cloud_clock + 1;
end

always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr_cloud <= 0;
  else if (cloud_region)
    pixel_addr_cloud <= cloud_addr +
                  ((pixel_y>>1)-CLOUD_VPOS)*CLOUD_W +
                  ((pixel_x +(CLOUD_W*2-1)-cloud_pos)>>1);
  else
    pixel_addr_cloud <= 0;
end
//-----------------------------------------------------------------------------------------------


//cloud2 control---------------------------------------------------------
// cloud2 image is 32x16
assign cloud2_region =
           pixel_y >= (CLOUD2_VPOS<<1) && pixel_y < (CLOUD2_VPOS+CLOUD2_H)<<1 &&
           (pixel_x + 63) >= cloud2_pos && pixel_x < cloud2_pos + 1;
           
assign cloud2_pos = cloud2_clock[31:20];

always @(posedge clk) begin
  if (~reset_n || cloud2_clock[31:21] > VBUF_W + CLOUD2_W)
    cloud2_clock <= 0;
  else
    cloud2_clock <= cloud2_clock + 2;
end

always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr_cloud2 <= 0;
  
  else if (cloud2_region)
    pixel_addr_cloud2 <= cloud2_addr +
                  ((pixel_y>>1)-CLOUD2_VPOS)*CLOUD2_W +
                  ((pixel_x +(CLOUD2_W*2-1)-cloud2_pos)>>1);
  else
    pixel_addr_cloud2 <= 0;
end
//-----------------------------------------------------------------------------------------------

//pika1 control---------------------------------------------------------------------------------
// pika1 image is 47x50
assign pika1_region =
           ((pixel_y + 99) >= pika1_clock_Y[31:20] && pixel_y < pika1_clock_Y[31:20] + 1)&&
           ((pixel_x + 93) >= pika1_clock_X[31:20] && pixel_x < pika1_clock_X[31:20] + 1);

assign pika1_pos_X = pika1_clock_X[31:20];
assign pika1_pos_Y = pika1_clock_Y[31:20];

//Move left or right
always @(posedge clk) begin
  if (~reset_n || pika1_clock_X[31:21] < 210)
    pika1_clock_X <= {11'd210,21'h0};
  else if( pika1_clock_X[31:21] > VBUF_W)
    pika1_clock_X <= {11'd320,21'h0};
  else if(usr_btn[0] && ~jump)
    pika1_clock_X <=  pika1_clock_X + 3;
  else if(usr_btn[0] && jump)
    pika1_clock_X <=  pika1_clock_X + 1;
  else if(usr_btn[2] && ~jump)
    pika1_clock_X <=  pika1_clock_X - 3;
  else if(usr_btn[2] && jump)
    pika1_clock_X <=  pika1_clock_X - 1;
end
//Jump 控制什麼時候往上跳跟掉下來
always @(posedge clk) begin
    if(~reset_n || jump_clock==32'd110000000) begin
        jump <= 0;
        jumpdown <=0;
    end else if (btn_pressed[1]) begin
        jump <= 1; 
    end else if (jump && jump_clock == 32'd55000000) begin
        jumpdown <=1;
    end
end
//Jump 控制跳的時間長短
always @(posedge clk) begin
    if(~reset_n || ~jump )
        jump_clock <= 0;
    else
        jump_clock <= jump_clock + 1;

end
//Jump 控制皮卡丘上下動 跳到最高時會滯空一下
always @(posedge clk) begin
  if (~reset_n || pika1_clock_Y[31:21] > 215)
    pika1_clock_Y <= {11'd215,21'h0};
  else if(jumpdown && jump_clock < 32'd65000000)
    pika1_clock_Y <=  pika1_clock_Y + 1;
  else if(jumpdown)
    pika1_clock_Y <=  pika1_clock_Y + 4;
  else if(jump && jump_clock < 32'd45000000)
    pika1_clock_Y <=  pika1_clock_Y - 4;
  else if(jump)
    pika1_clock_Y <=  pika1_clock_Y - 1;
  
end
// Control the Animation 沒有左右跑的時候皮卡丘會站著不動
always @(posedge clk) begin
    if(~reset_n ||( ~usr_btn[0] && ~usr_btn[2]))
        pika1_clock_anima <= 0;
    else
        pika1_clock_anima <= pika1_clock_anima + 1;
end

always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr_pika1 <= 0;
  else if (pika1_region && jump)
    pixel_addr_pika1 <= pika1_addr[1] +
                  ((pixel_y +(PIKA1_H*2-1)-pika1_pos_Y)>>1)*PIKA1_W +
                  ((pixel_x +(PIKA1_W*2-1)-pika1_pos_X)>>1);
  else if (pika1_region)
    pixel_addr_pika1 <= pika1_addr[pika1_clock_anima[25:23]] +
                  ((pixel_y +(PIKA1_H*2-1)-pika1_pos_Y)>>1)*PIKA1_W +
                  ((pixel_x +(PIKA1_W*2-1)-pika1_pos_X)>>1);
  else if(pika2_region)
    pixel_addr_pika1 <=  pika1_addr[pika2_clock[25:23]] +
    			  ((pixel_y>>1)-pika2y)*PIKA1_W + PIKA1_W -
                  ((pixel_x +(PIKA1_W*2-1)-pika2x)>>1);
end
//-----------------------------------------------------------------------------------------------

///2P CODE-----------------------------------------------------------------------------------------------------

           
assign pika2x = pika2x_clock[31:18];
always @(posedge clk)begin
	if(~reset_n)begin
		pika2_stop_pos<=0;
		pika2x_clock[31:20] <= 100;
		pika2_clock<=0;
	end
	else begin
		if(BALL_HPOS<320)begin
    		if (pika2x < 320 && BALL_HPOS>pika2x)
    			pika2x_clock <= pika2x_clock + 1;
    		else if(pika2x >  90 && BALL_HPOS<pika2x)
    			pika2x_clock <= pika2x_clock - 1;
  			else begin
  				pika2x_clock <= pika2x_clock;
  			end
   		pika2_clock <= pika2_clock+1;
		end
	end
 	
end

assign pika2_region =
			pixel_y >= (pika2y<<1) && pixel_y < (pika2y+PIKA1_H)<<1 &&
           (pixel_x + 2*PIKA1_W-1) >= pika2x && pixel_x < pika2x + 1;

// ------------------------------------------------------------------------
assign ball_reg_clock=ball_clock-1;
//assign ball_change=(ball_reg_clock[28]!=ball_clock[28]);

always @(posedge clk) begin//單純拿來當clk
  if (~reset_n ||ball_clock[31]==1)
    ball_clock <= 0;
  else
    ball_clock <= ball_clock + 1;
end

always@(posedge clk) begin
	touched_reg <= touched;
end

always @(posedge clk) begin
  if (~reset_n ) begin
    pika2sc <= 0;
    pika1sc <= 0;
  end
  else begin
  	if(touched == 1 && touched_reg == 0) begin
  		if(BALL_HPOS > 320 && pika1sc < 8'd10)
             pika1sc <= pika1sc + 1;
    	else if(BALL_HPOS < 340 && pika2sc < 8'd10)
             pika2sc <= pika2sc + 1;
  	end
  end
end

always @(posedge clk) begin
  if(!reset_n) begin
    BALL_HPOS   = 320;
    BALL_VPOS   = 120; 
    up=1;
    right=0;
    a_y =18;
    touched = 0;
    touched_p1 = 0;
    touched_p2=0;
    kill=1;
    start=0;
  end
  else if(touched)begin
  	BALL_HPOS   <= 320;
    BALL_VPOS   <= 120; 
    up<=1;
    if(BALL_HPOS <320)
    	right<=1;
    else
    	right<=0;
    a_y <=18;
    touched <= 0;
    touched_p1 <= 0;
    touched_p2<=0;
    kill<=1;
    start<=0;
  end
  else if(pika1sc == 10 || pika2sc == 10) begin
  	BALL_HPOS   <= 330;
  	BALL_VPOS   <= 100;
  end
  else begin 
    
    if(usr_btn[3] && touched_p1) begin//&&pika1_pos_Y<170)//不在地上)
        	kill <= 4;             //調速度
        	if(jump)
        		up <= 0;
        end

    if(kill!=1&&(touched_p2||touched||BALL_HPOS<=40||BALL_HPOS>636))
        	kill <= 1;    
        
    //xpos處理 剩彈牆,彈網
    //if(touched_p2) start=1;
    if(BALL_VPOS==200) begin//碰到地板 要改成碰到結束遊戲
        touched<=1;                                             
        up<=1;               //加皮卡丘後要刪掉
    end
    else
        touched<=0;
        
    if(BALL_VPOS==120&&BALL_HPOS>320&&BALL_HPOS<360) begin//碰到網子上面
        touched_net<=1;                                                         
        up<=1;               //加皮卡丘後要刪掉
    end
    else
        touched_net<=0;
     /*碰到player設定*/
     if(ball_region&&pika1_region&&data_out_ball!=12'h0f0&&data_out_pika1!=12'h0f0) begin
                right<=0;
                touched_p1<=1;
                up<=1;
     end
     else
        touched_p1<=0;
            
     if(ball_region&&pika2_region&data_out_ball!=12'h0f0)begin 
        right<=1;
        touched_p2<=1;
        up<=1;
     end
     else
        touched_p2<=0;
        
    //if(start) begin
    if(ball_reg_clock[18]!=ball_clock[18]) begin
        if(touched_p1) right<=0;
        else if(touched_p2) right<=1;
        else
        if(right) begin  //一開始直線往下,然後碰到皮卡丘再往右or左開始
            BALL_HPOS <= BALL_HPOS+kill;
            if(BALL_HPOS>=640) right<=0;//牆壁
            if(BALL_HPOS>=316&&BALL_HPOS<=320&&BALL_VPOS>120) right<=0;//網子
        end
        else begin
            BALL_HPOS <= BALL_HPOS-kill;
            if(BALL_HPOS<=40) right<=1;//牆壁
            if(BALL_HPOS>=320+40&&BALL_HPOS<=324+40&&BALL_VPOS>120) right<=1;//網子
        end
    end
    //end
    //y_pos處理
    if(ball_reg_clock[a_y]!=ball_clock[a_y]) begin
        if(up) begin
            BALL_VPOS <= BALL_VPOS-1;//a_y from0~128
        end
        else begin
            BALL_VPOS <= BALL_VPOS+1;//a_y from128~0
        end
    end
	if(touched || touched_p1 || touched_p2)a_y <=18;
    if(touched_net)a_y <=20-1;
    else if(BALL_VPOS == 20) a_y <=21;
    else if(ball_reg_clock[23]!=ball_clock[23]) begin
            if(up) begin
                a_y <=a_y+1;
                if(a_y==23) up<=0;
            end
            else begin
                if(a_y>19)a_y <=a_y-1;
            end
    end
  end
end


assign ball_region =
           pixel_y >= (BALL_VPOS<<1) && pixel_y < (BALL_VPOS+BALL_H)<<1 &&
           (pixel_x + 2*BALL_W-1) >= BALL_HPOS && pixel_x < BALL_HPOS + 1;
 
assign score1_region =
           pixel_y >= (SCORE_VPOS<<1) && pixel_y < (SCORE_VPOS+SCORE_H)<<1 &&
           (pixel_x + 2*SCORE_W-1) >= SCORE1_HPOS && pixel_x < SCORE1_HPOS + 1;   
assign score2_region =
           pixel_y >= (SCORE_VPOS<<1) && pixel_y < (SCORE_VPOS+SCORE_H)<<1 &&
           (pixel_x + 2*SCORE_W-1) >= SCORE2_HPOS && pixel_x < SCORE2_HPOS + 1;           

      
always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr <= 0;
    pixel_addr_ball<=0;
    pixel_addr_sc1<=0;
    pixel_addr_sc2<=0;
  end
  else begin
    if(ball_region)//ball_addr[ball_clock[26:24]] +//還不用動圖
        pixel_addr_ball <=  ((pixel_y>>1)-BALL_VPOS)*BALL_W +
                      ((pixel_x +(BALL_W*2-1)-BALL_HPOS)>>1);
    if(score2_region)
         pixel_addr_sc2 <=  score2_addr[pika2sc]+((pixel_y>>1)-SCORE_VPOS)*SCORE_W +
                      ((pixel_x +(SCORE_W*2-1)-SCORE2_HPOS)>>1);
    if(score1_region)
         pixel_addr_sc1 <= score1_addr[pika1sc]+ ((pixel_y>>1)-SCORE_VPOS)*SCORE_W +
                      ((pixel_x +(SCORE_W*2-1)-SCORE1_HPOS)>>1);
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
  end
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if(score1_region&&data_out_sc1!=12'h0f0 ) //score1
    rgb_next = data_out_sc1;
  else if(score2_region&&data_out_sc2!=12'h0f0 ) //score2
    rgb_next = data_out_sc2;
  else if(ball_region&&data_out_ball!=12'h0f0 && kill!=1)
    rgb_next = data_out_ball+12'h300;
  else if(ball_region&&data_out_ball!=12'h0f0 )
    rgb_next = data_out_ball;
  else if(pika1_region&&data_out_pika1!=12'h0f0)
    rgb_next = data_out_pika1;
  else if(pika2_region&&data_out_pika1!=12'h0f0)
    rgb_next = data_out_pika1;
  else if(cloud_region&&data_out_cloud!=12'h0f0)
    rgb_next = data_out_cloud;
  else if(cloud2_region&&data_out_cloud2!=12'h0f0)
    rgb_next = data_out_cloud2;
  else
    rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
