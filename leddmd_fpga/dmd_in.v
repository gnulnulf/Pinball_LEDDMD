/**
 @file
 @brief Input for 128x32 displays like Vishay APD-128G032
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

 @details  Input from WPC DMD 
*/

//
// module dmd_in
// 
module dmd_in(
	//inputs
	input dmd_dotdata,
	input dmd_latch,
	input dmd_dotclk,
	input	dmd_enable,

	input dmd_rowclock,
	input dmd_firstrow,

	//outputs
	output [127:0] dmd_data_out,
	output [4:0] dmd_addr_out,
	output dmd_enable_out,
	output dmd_latch_out
	);

	reg [127:0] dmd_data=0;
	reg [127:0] data_in=0;
	reg [4:0] addr_in=0;

	reg [127:0] dmd_tmp=0;
	reg dmd_latch_reg;

	// line address
	always @(posedge dmd_rowclock ) begin
		addr_in<=addr_in+1;
		if ( dmd_firstrow ) addr_in<=0;
	end

	// pixe input
	always @(posedge dmd_dotclk ) begin
		// right shift in
		//data_in={data_in[127-1:0],dmd_dotdata};
		// left shift in
		data_in<={dmd_dotdata,data_in[127:1]};
	end

	// latch data to output
	always @(posedge dmd_latch) begin
		dmd_data<=data_in;
		#1 dmd_latch_reg=1;
		#1 dmd_latch_reg=0;
	end

	assign dmd_enable_out=dmd_enable;
	assign dmd_latch_out=dmd_latch_reg;
	assign dmd_addr_out=addr_in;
	assign dmd_data_out=dmd_data;

endmodule // dmd_in


//
// testbench dmd_in
// 

module dmd_in_tb();

	reg dotdata,latch,dotclk,enable,rowclk,firstrow;
	reg [127:0] inputpixels;
	reg [7:0] i;


	wire [127:0] dmddata;
	wire [4:0] dmdaddr;
	wire enableout;
	wire latchout;

	initial begin
		dotdata=0;
		latch=0;
		dotclk=0;
		enable=0;
		rowclk=0;
		firstrow=0;
		inputpixels = 128'b1010_0101_0101_0101_1010_0101_1010_0000_0000_1010_1110_1000_1000_1110_0000_0000_0000_0000_0010_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001;

		#1 rowclk=1;
		#1 rowclk=0;

		for (i=0; i<128; i=i+1) begin
			dotclk=0;
			dotdata = inputpixels[ i ];
			#1 dotclk=1;
			#1;
		end
		#1 enable = 0;
		#1 rowclk=1;
		#4 rowclk=0;
		#4 latch=1;
		#1 latch=0;
		#1 enable=1;

		#50 $finish;


	end //initial

	dmd_in dmdtest(
	.dmd_dotdata(dotdata),
	.dmd_latch(latch),
	.dmd_dotclk(dotclk),
	.dmd_enable(enable),

	.dmd_rowclock(rowclk),
	.dmd_firstrow(firstrow),

	.dmd_data_out(dmddata),
	.dmd_addr_out(dmdaddr),
	.dmd_enable_out(enableout),
	.dmd_latch_out(latchout)
	);

endmodule	//dmd_in_tb
