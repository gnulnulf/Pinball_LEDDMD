/**
 @file
 @brief Oneshot 
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
	In the other dmd to rgb designs a 74LS123 is used to clean the signal.
	I don't know if we need this.
 
*/

// oneshot
module oneshot(
	input clk,
	input reset,
	input pulse_in,
	output reg pulse_out

);

parameter CLKCOUNT=4;

reg [7:0] clkcounter=0;

wire reset_pulse = ( clkcounter == CLKCOUNT ) | reset;

always @( posedge reset_pulse, posedge pulse_in ) begin
	if ( reset_pulse ) begin
		pulse_out <= 0;
	end else begin 
		pulse_out <= 1;
	end
end

always @ (posedge clk, posedge reset_pulse) begin
	if ( reset_pulse ) begin
		clkcounter <= 0;
	end else begin
		clkcounter <= clkcounter + pulse_out;
	end
end

endmodule //oneshot


