/**
 @file
 @brief converter without ram in white
 @version 1.0
 @author Arco van Geest <arco@appeltaart.mine.nu>
 @copyright 2020 Arco van Geest <arco@appeltaart.mine.nu> All right reserved.

  This is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this file.  If not, see <http://www.gnu.org/licenses/>.

 @date       20200718 Initial version
 
 @details  
	try to convert the signal without the use of ram. This would make it possible to run on a MAX II
 
*/
module dmd_hub75_direct(

input [127:0] rowdata,
input [4:0] address,
input enable,
input clk,

output hub75_r0,	
output hub75_r1,
output hub75_g0,
output hub75_g1,
output hub75_b0,
output hub75_b1,
output hub75_a,
output hub75_b,
output hub75_c,
output hub75_d,

output hub75_lat,
output hub75_oe,
output hub75_clk
);

// ###############################################
// Parameters
// ###############################################

parameter CLOCK_PER_SECOND=50_000_000;
parameter PIXELS=128;
//parameter PIXELS=8;
parameter LINES=16;
//parameter LINELEN=PIXELS+16; //1952/4
parameter LINELEN=128+128; //1952/4


// ###############################################
// registers
// ###############################################


reg[3:0] color_r[0:3];
reg[3:0] color_g[0:3];
reg[3:0] color_b[0:3];

reg [15:0] enabletime[4];

reg [127:0] show_data;
reg [4:0] show_address;


reg [31:0] counter;
reg[127:0] divcounter=0;
reg[7:0] pixelcounter=8'b0;
reg[15:0] dmdcounter=16'b0;
wire pixelclock;

//reg [5:0] lineplane=6'b0;   // 5432.10 line.plane active on display
//reg [5:0] lineplaneactive=6'b0; // 5432.10 line.plane at unlatched input
reg [1:0] plane=2'b0;
//reg [3:0] lineactive=4'b0;


reg [1:0] planeload=2'b0;
reg [3:0] lineload=4'b0;


//wire nextaddractive;
wire nextplane;
//wire nextaddrin;


//wire oe;
wire lat;
wire lineend;


// ###############################################
// initial
// ###############################################
initial begin


end



// 50MHZ is too high for dmd
always @(posedge clk) begin
	divcounter <= divcounter + 1'b1;
end


//always @(posedge o_hub75_oe ) begin
	//planeactive = planeload;
	//lineactive = lineload;

//end

always @( posedge enable) begin
show_address<=address;
show_data <= rowdata;
end

// 50MHz is teveel
assign pixelclock = divcounter[1];
 
//########################################
always @(posedge pixelclock) begin
  counter = counter + 1'b1;
  
  dmdcounter <= dmdcounter + counter[0];
  pixelcounter <= pixelcounter + counter[0] ;
  //if ( pixelcounter > PIXELS-1) pixelcounter <= PIXELS-1;

	if ( lineend ) 
	begin
		dmdcounter<=0;
		pixelcounter<=0;
		counter<=0;
		plane <= plane +1;
	end
end







//always @(posedge nextplane  ) begin
//	plane <= plane +1;
// end




// ########################################
// ram fill
// ########################################


//assign inputwriteclock = divcounter[0] & 	memory_pulse ;
//assign inputwriteclock = memory_pulse ;
 

//assign wr_en_ht=inputwriteenableht;
//assign wr_en_lt=inputwriteenablelt;
//assign wr_en_hb=inputwriteenablehb;
//assign wr_en_lb=inputwriteenablelb;



// ########################################
// outputs
// ########################################





//assign lat=(dmdcounter == PIXELS+1) ;

assign hub75_lat=(dmdcounter == LINELEN-2) ;

//assign o_hub75_lat=(dmdcounter == ( dmdcounter == enabletime[ plane ] +1 )) ;

//assign nextaddractive=(dmdcounter == enabletime[ 3 ] +2) ;
//assign nextplane=(dmdcounter == enabletime[ 3 ] +4) ;
//assign nextaddrin=(dmdcounter == enabletime[ 3 ] +6) ;
//assign ramread=(dmdcounter == enabletime[ 3 ] +8) ;


////assign nextaddractive=(dmdcounter == LINELEN-6) ;
//assign nextplane=(dmdcounter == LINELEN-4) ;
//assign nextaddrin=(dmdcounter == LINELEN-2) ;
//assign ramread=(dmdcounter == enabletime[ 3 ] ) ;


//assign ramclk=(counter[0] & (dmdcounter > enabletime[ 3 ] ) ) ;
//assign ramaddr=lineload;

//assign lineend=(dmdcounter == LINELEN) ;
assign lineend=(dmdcounter == LINELEN) ;


// ~oe is blanking
assign hub75_oe=~( dmdcounter >128 );

// pixel clock naar display
//assign o_hub75_clk = ( ~counter[0]& (dmdcounter < PIXELS )) ;
assign hub75_clk = ( ~counter[0]& (dmdcounter < PIXELS )) ;

// line to show
assign { hub75_d,hub75_c,hub75_b,hub75_a}=show_address[3:0];

/*
assign hub75_r0=show_data[ pixelcounter ]& (show_address<16);
assign hub75_g0=show_data[ pixelcounter ]& (show_address<16);
assign hub75_b0=show_data[ pixelcounter ]& (show_address<16);

assign hub75_r1=show_data[ pixelcounter ]& (show_address>15);
assign hub75_g1=show_data[ pixelcounter ]& (show_address>15);
assign hub75_b1=show_data[ pixelcounter ]& (show_address>15);
*/

assign hub75_r0=rowdata[ pixelcounter ]& (address<16);
assign hub75_g0=rowdata[ pixelcounter ]& (address<16);
assign hub75_b0=rowdata[ pixelcounter ]& (address<16);

assign hub75_r1=rowdata[ pixelcounter ]& (address>15);
assign hub75_g1=rowdata[ pixelcounter ]& (address>15);
assign hub75_b1=rowdata[ pixelcounter ]& (address>15);



















endmodule


module dmd_hub75_direct_tb();
reg [127:0] dmddata=128'b10011100110011110011000100001110001000101110000000000111110111110011110111110000001000000000001000000000000010110000000000000101;
reg [4:0] dmdaddr=7;
reg enable;


reg clock;
wire a,b,c,d,r0,r1,g0,g1,b0,b1,lat,oe,dclk;

initial begin
clock=0;
enable=0;
#5 enable=1;
#200 $finish;
end

always begin 
  #5  clock =  ! clock;
end

mono_hub75_direct display1(

.rowdata(dmddata),
.address(dmdaddr),
//.rowdata(128'b10011100110011110011000100001110001000101110000000000111110111110011110111110000001000000000001000000000000010110000000000000101),/
//.address(5'b00100),

.enable(enable),
.clk(clock),

.hub75_r0(r0),	
.hub75_r1(r1),
.hub75_g0(g0),
.hub75_g1(g1),
.hub75_b0(b0),
.hub75_b1(b1),
.hub75_a(a),
.hub75_b(b),
.hub75_c(c),
.hub75_d(d),

.hub75_lat(lat),
.hub75_oe(oe),
.hub75_clk(dclk)
);


endmodule
