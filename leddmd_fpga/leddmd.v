/**
 @file
 @brief Signal converter for 128x32 DMD display to HUB75 128x32 RGB
 @version 1.0
 @author Arco van Geest <arco@appeltaart.mine.nu>
 @copyright 2020 Arco van Geest <arco@appeltaart.mine.nu> All right reserved.

  This is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this file.  If not, see <http://www.gnu.org/licenses/>.

 @date       20200701 Initial version
 
 @details  
	Accepts DMD input and converts it into a HUB75 RGB signal.
	switch1 produces a testscreen without input.
 
*/

`default_nettype none

module leddmd (
// module onboard IO
input i_switch_1,
input i_switch_2,
input clk,
output o_led_138,
output o_led_141,
output o_led_142,
output o_led_143,
output o_led_144,
output o_led_1,
output o_led_2,
output o_led_3,

// dmd inputs
input i_dmd_en, 			//DMDpin1
input i_dmd_rowdata,		//DMDpin3
input i_dmd_rowclock,	//DMDpin5
input i_dmd_collatch,	//DMDpin7
input i_dmd_dotclock,	//DMDpin9
input i_dmd_dotdata,		//DMDpin11


// led matrix output
output o_hub75_r0,	
output o_hub75_r1,
output o_hub75_g0,
output o_hub75_g1,
output o_hub75_b0,
output o_hub75_b1,
output o_hub75_a,
output o_hub75_b,
output o_hub75_c,
output o_hub75_d,

output o_hub75_lat,
output o_hub75_oe,
output o_hub75_clk,

// uart 
input i_uart_rx,
output o_uart_tx,


// DIP40 mc680X input
// WARNING! 6809 != 6802 pinout
input i_dip01,
input i_dip02,
input i_dip03,
input i_dip04,
input i_dip05,
input i_dip06,
input i_dip07,
input i_dip08,
input i_dip09,
input i_dip10,
input i_dip11,
input i_dip12,
input i_dip13,
input i_dip14,
input i_dip15,
input i_dip16,
input i_dip17,
input i_dip18,
input i_dip19,
input i_dip20,
input i_dip21,
input i_dip22,
input i_dip23,
input i_dip24,
input i_dip25,
input i_dip26,
input i_dip27,
input i_dip28,
input i_dip29,
input i_dip30,
input i_dip31,
input i_dip32,
input i_dip33,
input i_dip34,
input i_dip35,
input i_dip36,
input i_dip37,
input i_dip38,
input i_dip39,
input i_dip40

);  

// ###############################################
// Parameters
// ###############################################

parameter CLOCK_PER_SECOND=50_000_000;
parameter PIXELS=128;
//parameter PIXELS=8;
parameter LINES=16;
parameter LINELEN=PIXELS+16; //1952/4
//parameter LINELEN=488; //1952/4



// ###############################################
// registers
// ###############################################

reg [31:0] counter;


reg[127:0] divcounter=0;
reg[7:0] pixelcounter=8'b0;
reg[15:0] dmdcounter=16'b0;

reg myclock;
reg myclk=1'b0;
wire pixelclock;

wire inputclock;

reg[3:0] color_r[0:3];
reg[3:0] color_g[0:3];
reg[3:0] color_b[0:3];

reg [15:0] enabletime[4];

//wire oe;
wire lat;
wire lineend;

// framebuffer high
reg [0:127] framel[31:0];
reg [0:127] frameh[31:0];




reg [127:0] ramtestht=0;
reg [127:0] ramtestlt=0;
reg [127:0] ramtesthb=0;
reg [127:0] ramtestlb=0;


reg [5:0] lineplane=6'b0;   // 5432.10 line.plane active on display
reg [5:0] lineplaneactive=6'b0; // 5432.10 line.plane at unlatched input
reg [1:0] planeactive=2'b0;
reg [3:0] lineactive=4'b0;


reg [1:0] planeload=2'b0;
reg [3:0] lineload=4'b0;


wire nextaddractive;
wire nextaddr;
wire nextaddrin;
wire ramread;

// ====================
// dmd input regs
// ====================

reg [5:0] inputaddr=0;
reg [127:0] inputpixels;
reg [127:0] inputpixelsht;
reg [127:0] inputpixelshb;
reg [127:0] inputpixelslt;
reg [127:0] inputpixelslb;
reg [7:0] inputcounter=0;
reg [31:0] inputlatchcounter=0;
wire  inputwriteclock;

// counters for display enable
reg [31:0] enable_counter=0;
reg [31:0] enable_length=0;

reg inputwriteenableht=1'b0;
reg inputwriteenablehb=1'b0;
reg inputwriteenablelt=1'b0;
reg inputwriteenablelb=1'b0;

wire wr_en_ht;
wire wr_en_lt;
wire wr_en_hb;
wire wr_en_lb;

wire [127:0] dmddata;
wire [4:0] dmdaddr;
reg [4:0] dummyaddr=5;
wire  dmdenable;
wire  dmdlatch;


// RAM to dmd logic
wire [3:0] ramaddr;
wire ramclk;
//reg ramenable=1'b1;
reg dummy=1'b1;

wire [127:0] framehtdata;
wire [127:0] framehbdata;
wire [127:0] frameltdata;
wire [127:0] framelbdata;

reg [127:0] dmddata_latched;





// ###############################################
// initial
// ###############################################
initial begin
color_r[0]=0;
color_g[0]=0;
color_b[0]=0;

// color is inverted 8 bit0....1 bit
/*
color_r[2]=4'hc;
color_g[2]=4'h8;
color_b[2]=4'h0;

color_r[1]=4'h6;
color_g[1]=4'h4;
color_b[1]=4'h0;

color_r[3]=4'hf;
color_g[3]=4'h4;
color_b[3]=4'h4;
*/


color_r[2'b01]=4'hc;
color_g[2'b01]=4'h8;
color_b[2'b01]=4'h0;

color_r[2'b10]=4'he;
color_g[2'b10]=4'h4;
color_b[2'b10]=4'h0;


color_r[2'b11]=4'hf;
color_g[2'b11]=4'h4;
color_b[2'b11]=4'h0;




//enabletime[0]=100;  //show bit 0 in nr.dmdcounter
//enabletime[1]=200;  //show bit 1 in nr.dmdcounter
//enabletime[2]=300; //show bit 2 in nr.dmdcounter
//enabletime[3]=400; //show bit 3 in nr.dmdcounter


//enabletime[0]=50;  //show bit 0 in nr.dmdcounter
//enabletime[1]=100;  //show bit 1 in nr.dmdcounter
//enabletime[2]=200; //show bit 2 in nr.dmdcounter
//enabletime[3]=400; //show bit 3 in nr.dmdcounter


//enabletime[0]=(LINELEN-8)/8;  //show bit 0 in nr.dmdcounter
//enabletime[1]=(LINELEN-8)/4;  //show bit 1 in nr.dmdcounter
//enabletime[2]=(LINELEN-8)/2; //show bit 2 in nr.dmdcounter
//enabletime[3]=(LINELEN-8); //show bit 3 in nr.dmdcounter

enabletime[0]=(LINELEN-8)/12;  //show bit 0 in nr.dmdcounter
enabletime[1]=(LINELEN-8)/8;  //show bit 1 in nr.dmdcounter
enabletime[2]=(LINELEN-8)/4; //show bit 2 in nr.dmdcounter
enabletime[3]=(LINELEN-8); //show bit 3 in nr.dmdcounter




// max 488 -16
//*/
 /*
//enabletime[0]=2;  //show bit 0 in nr.dmdcounter
//enabletime[1]=4;  //show bit 1 in nr.dmdcounter
//enabletime[2]=8; //show bit 2 in nr.dmdcounter
//enabletime[3]=16; //show bit 3 in nr.dmdcounter

color_r[1]=8'hff;
color_g[1]=8'hff;
color_b[1]=8'hff;

color_r[2]=8'hff;
color_g[2]=8'hff;
color_b[2]=8'hff;

color_r[3]=8'hff;
color_g[3]=8'hff;
color_b[3]=8'hff;
*/


//inputpixelsht = 128'b1000_0000_0001_1111_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;



inputpixels = 128'b1010_0101_0101_0101_1010_0101_1010_0000_0000_1010_1110_1000_1000_1110_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;

//$display("Loading rom.");
//$readmemh("framel.mem", framel);



frameh[0]  = 128'b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110001111111111111111111111111111111;
frameh[1]  = 128'b10000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000100000000000010110000000000000011;
frameh[2]  = 128'b10011100110011110011000100001110001000101110000000000111110111110011110111110000001000000000001000000000000010110000000000000101;
frameh[3]  = 128'b10011110110011000011000100001001001101101001000000000001000100000100000001000000010000000000001100000000000010110000000000001001;
frameh[4]  = 128'b10011011110011110001100100001000101010101000100000000001000111000011100001000000100000000000010000000000000010110000000000010001;
frameh[5]  = 128'b10011000110011000001101000001001001000101001000000000001000100000000010001000001000000000000010100000000000010110000000000100001;
frameh[6]  = 128'b10011000110011000000110000001110001000101110000000000001000111110111100001000010000000000000011000000000000010110000000001000001;
frameh[7]  = 128'b10000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000011100000000000010110000000010000001;
frameh[8]  = 128'b10000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000100000000000000010110000000100000001;
frameh[9]  = 128'b10000000000111111000000000000000000000000000000000000000000000000000000000010000000000000000100100000000000010110000001000000101;
frameh[10] = 128'b10000000000100111000000000000000000010101110100010000100000000000000000000100000000000000000101000000000000010110000010000000101;
frameh[11] = 128'b10000000000100111000000000000000000010101000100010001010000000000000000001000000000000000000101100000000000010110000100000000101;
frameh[12] = 128'b10000000000100111000000000000000000011101100100010001010000000000000000010000000000000000000110000000000000010110001000000000101;
frameh[13] = 128'b10000000000111111000000000000000000010101000100010001010000000000000000100000000000000000000110100000000000010110010000000000101;
frameh[14] = 128'b10000000000000000000000000000000000010101110111011100100000000000000001000000000000000000000111000000000000010110100001000100101;
frameh[15] = 128'b10000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000111100000000000010111000001000100101;
frameh[16] = 128'b10000000000000000000000000000000000000000000000000000000000000000000100000000000000000000001000000000000000010110000000101000101;
frameh[17] = 128'b10000000000000000000000000000000000000000000000000000000000000000001000000000000000000000001000100000000000010100000000101000101;
frameh[18] = 128'b10000000000000000000000000000000000011100111111101110000000000000010000000000000000000000001001000000000000010100000000101000101;
frameh[19] = 128'b10000000000000000000000000000000000010010110110101001000000000000100000000000000000000000001001100000000000010100000000101000101;
frameh[20] = 128'b10000000000000000000000000000000000010010110110101001000000000001000000000000000000000000001010000000000000010100000000101000101;
frameh[21] = 128'b10000000000000000000000000000000000010010110110101001000000000010000000000000000000000000001010100000000000010100000001010000101;
frameh[22] = 128'b10000000000000000000000000000000000011100110000101110000000000100000000000000000000000000001011000000000000010100000001010000101;
frameh[23] = 128'b10000000000000000000000000000000000000000000000000000000000001000000000000000000000000000001011100000000000010100000000000000101;
frameh[24] = 128'b10000000000000000000000000000000000000000000000000000000000010000000000000000000000000000001100000000000000000000000000000000101;
frameh[25] = 128'b10000000111111110000000000000000000000000000000000000000000100000000000000000000000000000001100100000000000001011111111111110101;
frameh[26] = 128'b10000000111111110000000000000000000000000000000000000000001000000000000000000000000000000001101000000000000010101111111111110101;
frameh[27] = 128'b10000000111111110000000000000000000000000000000000000000010000000000000000000000000000000001101100000000000001011111111111110101;
frameh[28] = 128'b10000000111111110000000000000000000000000000000000000000100000000000000000000000000000000001110000000000000010101111111111110101;
frameh[29] = 128'b10000000000000000000000000000000000000000000000000000001000000000000000000000000000000000001110100000000000001011111111111110101;
frameh[30] = 128'b10000000000000000000000000000000000000000000000000000010000000000000000000000000000000000001111000000000000000000000000000000101;
frameh[31] = 128'b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111100001111101111111111111111111111111111111;
                  
framel[0]  = 128'b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110001111111111111111111111111111111;
framel[1]  = 128'b10000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000100000000000001110000000000000011;
framel[2]  = 128'b10011100110011110011000100001110001000101110000000000111110111110011110111110000001000000000001000000000000001110000000000000101;
framel[3]  = 128'b10011110110011000011000100001001001101101001000000000001000100000100000001000000010000000000001100000000000001110000000000001001;
framel[4]  = 128'b10011011110011110001100100001000101010101000100000000001000111000011100001000000100000000000010000000000000001110000000000010001;
framel[5]  = 128'b10011000110011000001101000001001001000101001000000000001000100000000010001000001000000000000010100000000000001110000000000100001;
framel[6]  = 128'b10011000110011000000110000001110001000101110000000000001000111110111100001000010000000000000011000000000000001110000000001000001;
framel[7]  = 128'b10000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000011100000000000001110000000010000001;
framel[8]  = 128'b10000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000100000000000000001110000000100000001;
framel[9]  = 128'b10000000000111111000000000000000000000000000000000000000000000000000000000010000000000000000100100000000000001110000001000000101;
framel[10] = 128'b10000000000100111000000000000000000010101110100010000100000000000000000000100000000000000000101000000000000001110000010000000101;
framel[11] = 128'b10000000000100111000000000000000000010101000100010001010000000000000000001000000000000000000101100000000000001110000100000000101;
framel[12] = 128'b10000000000100111000000000000000000011101100100010001010000000000000000010000000000000000000110000000000000001110001000000000101;
framel[13] = 128'b10000000000111111000000000000000000010101000100010001010000000000000000100000000000000000000110100000000000001110010000000000101;
framel[14] = 128'b10000000000000000000000000000000000010101110111011100100000000000000001000000000000000000000111000000000000001110100001000100101;
framel[15] = 128'b10000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000111100000000000001111000001000100101;
framel[16] = 128'b10000000000000000000000000000000000000000000000000000000000000000000100000000000000000000001000000000000000001110000000000000001;
framel[17] = 128'b10000000000000000000000000000000000000000000000000000000000000000001000000000000000000000001000100000000000001100000000000000001;
framel[18] = 128'b10000000000000000000000000000000000011100111111101110000000000000010000000000000000000000001001000000000000001100000000000000001;
framel[19] = 128'b10000000000000000000000000000000000010010110110101001000000000000100000000000000000000000001001100000000000001100000000000000001;
framel[20] = 128'b10000000000000000000000000000000000010010110110101001000000000001000000000000000000000000001010000000000000001100000000000000001;
framel[21] = 128'b10000000000000000000000000000000000010010110110101001000000000010000000000000000000000000001010100000000000001100000000000000001;
framel[22] = 128'b10000000000000000000000000000000000011100110000101110000000000100000000000000000000000000001011000000000000001100000000000000001;
framel[23] = 128'b10000000000000000000000000000000000000000000000000000000000001000000000000000000000000000001011100000000000001100000000000000001;
framel[24] = 128'b10000000000000000000000000000000000000000000000000000000000010000000000000000000000000000001100000000000000000000000000000000001;
framel[25] = 128'b10001111000011110000000000000000000000000000000000000000000100000000000000000000000000000001100100000101111110100000010111110001;
framel[26] = 128'b10001111000011110000000000000000000000000000000000000000001000000000000000000000000000000001101000001010111101010000101011110001;
framel[27] = 128'b10001111000011110000000000000000000000000000000000000000010000000000000000000000000000000001101100000101111110100000010111110001;
framel[28] = 128'b10001111000011110000000000000000000000000000000000000000100000000000000000000000000000000001110000001010111101010000101011110001;
framel[29] = 128'b10000000000000000000000000000000000000000000000000000001000000000000000000000000000000000001110100000101111110100000010111110001;
framel[30] = 128'b10000000000000000000000000000000000000000000000000000010000000000000000000000000000000000001111000000000000000000000000000000001;
framel[31] = 128'b11111111111111111111111111111111111111111111111111111111111111111111111111111111111111100001111101111111111111111111111111111111;

end // initial begin

/* // ram fill
always @(posedge inputclock) begin
if ( dummy) begin
inputcounter <= inputcounter +1;

if (inputcounter==0 ) begin
	inputaddr <= inputaddr+1;
end

if (inputcounter==1) begin
	inputpixelsht <= frameh[{1'b0,inputaddr[3:0]}];
	inputpixelslt <= frameh[{1'b0,inputaddr[3:0]}];
	inputpixelshb <= frameh[{1'b0,inputaddr[3:0]}];
	inputpixelslb <= frameh[{1'b0,inputaddr[3:0]}];
end

if (inputcounter==3) begin
	inputwriteenableht<=1'b1;
	inputwriteenablehb<=1'b1;
	inputwriteenablelt<=1'b1;
	inputwriteenablelb<=1'b1;
end else begin

	inputwriteenableht<=1'b0;
	inputwriteenablehb<=1'b0;
	inputwriteenablelt<=1'b0;
	inputwriteenablelb<=1'b0;
end
if (inputcounter > 4) inputcounter<=0;

if (inputaddr==15) dummy<=1'b0;
end //dummy

end

assign inputwriteclock = ~inputclock;
*/ // ram fill



assign o_led_138 = i_dmd_en;
assign o_led_141 = i_dmd_collatch;
assign o_led_142 = i_dmd_dotclock;
assign o_led_143 = i_dmd_dotdata;


// maybe not needed
// cleanup clock input signal
//wire  dot_clk_wait;
//wire dot_wait_in = ~ dot_clk_clean;
//oneshot #(.CLKCOUNT(2)) waitdot(
//	.clk(clk),
//	.reset(0),
//	.pulse_in(i_dmd_dotclock),
//	.pulse_out(dot_clk_wait),
//);


//wire dot_clk_clean;
//wire cleaned_input = i_dmd_dotclock & ~dot_clk_wait;
//oneshot #(.CLKCOUNT(4)) cleandot(
//	.clk(clk),
//	.reset(0),
//	.pulse_in(cleaned_input ),
//	.pulse_out(dot_clk_clean),
//);

//wire row_clk_clean;
//oneshot #(.CLKCOUNT(50)) cleanrow(
//	.clk(clk),
//	.reset(0),
//	.pulse_in(i_dmd_rowclock),
//	.pulse_out(row_clk_clean),
//);




dmd_in dmd_in(
// input
.dmd_enable(i_dmd_en),
.dmd_dotdata(i_dmd_dotdata),
.dmd_latch(i_dmd_collatch),
//.dmd_dotclk(dot_clk_clean),
.dmd_dotclk(i_dmd_dotclock),
//.dmd_rowclock(row_clk_clean),
.dmd_rowclock(i_dmd_rowclock),
.dmd_firstrow(i_dmd_rowdata),


//output
.dmd_data_out(dmddata),
.dmd_addr_out(dmdaddr),
.dmd_enable_out(dmdenable),
.dmd_latch_out(dmdlatch)

);


//always @( posedge clk ) begin


//end
always @(posedge dmdlatch) begin
//dmddata_latched<=dmddata;
dmddata_latched=frameh[dmdaddr];
end


reg memory_pulse_start;
wire memory_pulse;
oneshot #(.CLKCOUNT(5)) memory_pulse_shot(
	.clk(clk),
	.reset(0),
	.pulse_in(memory_pulse_start),
	.pulse_out(memory_pulse)
);

always @( posedge dmdenable) begin
end


always @( dmdenable, memory_pulse) begin
dummyaddr<= dmdaddr;
if ( dmdenable ) begin
	inputwriteenableht<=1'b0;
	inputwriteenablehb<=1'b0;
	inputwriteenablelt<=1'b0;
	inputwriteenablelb<=1'b0;
	memory_pulse_start <=0;
	end else begin

if ( ~dmdenable )  begin
	memory_pulse_start <=1;
if (dmdaddr<16) begin
//	inputpixelsht <= dmddata;
//	inputpixelslt <= dmddata;
	inputwriteenableht<=1'b1;
	inputwriteenablelt<=1'b1;
	inputwriteenablehb<=1'b0;
	inputwriteenablelb<=1'b0;
	
	end else begin
//	inputpixelshb <= dmddata;
//	inputpixelslb <= dmddata;
	inputwriteenableht<=1'b0;
	inputwriteenablelt<=1'b0;
	inputwriteenablehb<=1'b1;
	inputwriteenablelb<=1'b1;
	end
	end 
	end
end

assign { o_led_144, o_led_1, o_led_2, o_led_3} = dummyaddr; 




//########################################
//input i_dmd_en, 			//DMDpin1
//input i_dmd_rowdata,		//DMDpin3
//input i_dmd_rowclock,	//DMDpin5
//input i_dmd_collatch,	//DMDpin7
//input i_dmd_dotclock,	//DMDpin9
//input i_dmd_dotdata,		//DMDpin11

//reg [5:0] inputaddr=0;
//reg [127:0] inputpixels;
//reg [7:0] inputcounter=0;
//reg [31:0] inputlatchcounter=0;
// /*

/*
always @(negedge i_dmd_rowclock ) begin
	inputaddr <= inputaddr+1;
	if ( i_dmd_rowdata ) inputaddr <= 0;
end

always @(posedge i_dmd_dotclock or posedge i_dmd_collatch) begin
	if ( i_dmd_collatch ) begin
		//frameh[ inputaddr ] = inputpixels;
//		case (inputaddr) 
//		5'b00000: frameh[ 0 ] = inputpixels;
//		5'b00001: frameh[ 1 ] = inputpixels;
		
		
//		default: frameh[32]=0;
//		endcase
	if (inputaddr <16) begin
	inputpixelsht <= inputpixels;
	inputpixelslt <= inputpixels;
	inputwriteenableht<=1'b1;
	inputwriteenablehb<=1'b0;
	inputwriteenablelt<=1'b1;
	inputwriteenablelb<=1'b0;
	
	end else begin
	inputpixelshb <= inputpixels;
	inputpixelslb <= inputpixels;
	inputwriteenableht<=1'b0;
	inputwriteenablehb<=1'b1;
	inputwriteenablelt<=1'b0;
	inputwriteenablelb<=1'b1;
	end
		inputcounter<= 0;
	end
	else
	begin
		inputpixels[inputcounter] = i_dmd_dotdata;
		inputcounter<= inputcounter+1;
	end
end


assign inputwriteclock=clk;

*/

// */
// upper 16 rows HIGHTOP
frameram framehtram( 
	.rdaddress(ramaddr) ,
	.rdclock(ramclk),
	.q( framehtdata ) ,
	
	.data( dmddata ),
	//.data( divcounter ),
	.wraddress(dmdaddr[3:0]),
	.wrclock(inputwriteclock),
	.wren( wr_en_ht)
);
// upper 16 rows LOWTOP
frameram 	frameltram( 
	.rdaddress(ramaddr) ,
	.rdclock(ramclk),
	.q( frameltdata ) ,
	
	.data( dmddata ),
//	.data( divcounter ),
	.wraddress(dmdaddr[3:0]),
	.wrclock(inputwriteclock),
	.wren( wr_en_ht)
);

// lower 16 rows HIGHBOTTOM
frameram framehbram( 
	.rdaddress(ramaddr) ,
	.rdclock(ramclk),
	.q( framehbdata ) ,
	
	.data( dmddata),
	//.data( divcounter ),
	.wraddress(dmdaddr[3:0]),
	.wrclock(inputwriteclock),
	.wren( wr_en_hb)
);

// lower 16 rows LOWBOTTOM
frameram framelbram( 
	.rdaddress(ramaddr) ,
	.rdclock(ramclk),
	.q( framelbdata ) ,
	
	.data( dmddata),
	//.data( divcounter ),
	.wraddress(dmdaddr[3:0]),
	.wrclock(inputwriteclock),
	.wren( wr_en_hb)
);





	
/*module frameram (
	data,
	rdaddress,
	rdclock,
	wraddress,
	wrclock,
	wren,
	q);
*/


// / *
// 50MHZ is too high for dmd
always @(posedge clk) begin
	divcounter <= divcounter + 1'b1;
end


//always @(posedge o_hub75_oe ) begin
	//planeactive = planeload;
	//lineactive = lineload;

//end



//########################################
 always @(posedge nextaddractive  ) begin
	lineplaneactive <= lineplane;
	planeactive <= planeload;
	lineactive <= lineload;

 end
 
always @(posedge nextaddr  ) begin
	lineplane <= lineplane +1;
 end

 always @(posedge nextaddrin  ) begin

	planeload <= lineplane[1:0];
	lineload <= lineplane[5:2];
 end
 
always @(negedge ramclk  ) begin
	
	//planeload = lineplane[1:0];
	// if switch_1 testbeeld
	if ( i_switch_1 ) begin
		ramtestht = framehtdata;
		ramtestlt = frameltdata;
		ramtesthb = framehbdata;
		ramtestlb = framelbdata;
	end else begin
		ramtestht[127:0]=frameh[ {2'b0, lineload } ];
		ramtesthb[127:0]=frameh[ {2'b1, lineload } ];
		ramtestlt[127:0]=framel[ {2'b0, lineload } ];
		ramtestlb[127:0]=framel[ {2'b1, lineload } ];
	end
end
 
 
//########################################
always @(posedge pixelclock) begin
  counter = counter + 1'b1;
  
  dmdcounter <= dmdcounter + counter[0];
  pixelcounter <= pixelcounter + counter[0] ;
  //if ( pixelcounter > PIXELS-1) pixelcounter <= PIXELS-1;

	if ( lineend) 
	begin
		dmdcounter<=0;
		pixelcounter<=0;
		counter<=0;
	end
end

// ########################################
// ram fill
// ########################################


//assign inputwriteclock = divcounter[0] & 	memory_pulse ;
assign inputwriteclock = memory_pulse ;
 

assign wr_en_ht=inputwriteenableht;
assign wr_en_lt=inputwriteenablelt;
assign wr_en_hb=inputwriteenablehb;
assign wr_en_lb=inputwriteenablelb;



// ########################################
// outputs
// ########################################

// 50MHz is teveel
assign pixelclock = divcounter[1];





//assign o_hub75_lat=(dmdcounter == ( dmdcounter == enabletime[ planeactive[1:0] ] +1 )) ;

assign nextaddractive=(dmdcounter == enabletime[ 3 ] +2) ;
assign nextaddr=(dmdcounter == enabletime[ 3 ] +4) ;
assign nextaddrin=(dmdcounter == enabletime[ 3 ] +6) ;
assign ramread=(dmdcounter == enabletime[ 3 ] +8) ;


//assign nextaddractive=(dmdcounter == LINELEN-6) ;
//assign nextaddr=(dmdcounter == LINELEN-4) ;
//assign nextaddrin=(dmdcounter == LINELEN-2) ;
//assign ramread=(dmdcounter == enabletime[ 3 ] ) ;


assign ramclk=(counter[0] & (dmdcounter > enabletime[ 3 ] ) ) ;
assign ramaddr=lineload;

assign lineend=(dmdcounter == LINELEN) ;

// /*
//assign lat=(dmdcounter == PIXELS+1) ;

assign o_hub75_lat=(dmdcounter == LINELEN-2) ;
// ~oe is blanking
assign o_hub75_oe=~( dmdcounter < enabletime[ planeactive ] );

// pixel clock naar display
//assign o_hub75_clk = ( ~counter[0]& (dmdcounter < PIXELS )) ;
assign o_hub75_clk = ( ~counter[0]& (dmdcounter < PIXELS )) ;

// line to show
assign { o_hub75_d,o_hub75_c,o_hub75_b,o_hub75_a}=lineactive;

// color_X[{framel[x],frameh[x]}][plane]



// UPPER DISPLAY
assign o_hub75_r0=color_r[ 
	{ramtestht[ pixelcounter ],ramtestlt[ pixelcounter ]}
][ lineplane[1:0] ]    & (dmdcounter < PIXELS );

assign o_hub75_g0=color_g[ 
	{ramtestht[ pixelcounter ],ramtestlt[ pixelcounter ]}
][ lineplane[1:0] ] & (dmdcounter < PIXELS );

assign o_hub75_b0=color_b[ 
	{ramtestht[ pixelcounter ],ramtestlt[ pixelcounter ]}
][ lineplane[1:0] ] & (dmdcounter < PIXELS );


// LOWER DISPLAY
assign o_hub75_r1=color_r[ 
	{ramtesthb[ pixelcounter ],ramtestlb[ pixelcounter ]}
 ][ lineplane[1:0] ] & (dmdcounter < PIXELS ) ;

assign o_hub75_g1=color_g[ 
	{ramtesthb[ pixelcounter ],ramtestlb[ pixelcounter ]}
 ][ lineplane[1:0] ] & (dmdcounter < PIXELS );

assign o_hub75_b1=color_b[ 
	{ramtesthb[ pixelcounter ],ramtestlb[ pixelcounter ]}
][ lineplane[1:0] ] & (dmdcounter < PIXELS );

//* /

/*
dmd_hub75_direct display1(

.rowdata(dmddata),
.address(dmdaddr),
//.rowdata(128'b10011100110011110011000100001110001000101110000000000111110111110011110111110000001000000000001000000000000010110000000000000101),
//.address(5'b00100),

.enable(dmdenable),
.clk(clk),

.hub75_r0(o_hub75_r0),	
.hub75_r1(o_hub75_r1),
.hub75_g0(o_hub75_g0),
.hub75_g1(o_hub75_g1),
.hub75_b0(o_hub75_b0),
.hub75_b1(o_hub75_b1),
.hub75_a(o_hub75_a),
.hub75_b(o_hub75_b),
.hub75_c(o_hub75_c),
.hub75_d(o_hub75_d),

.hub75_lat(o_hub75_lat),
.hub75_oe(o_hub75_oe),
.hub75_clk(o_hub75_clk)
);
*/




endmodule


