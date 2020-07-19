/**
 @file
 @brief Signal generator for 128x32 RGB LED display
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
 
 @details  This code generates a test signal for HUB75 displays.
   Shows a color raster.
 
*/

#define DATAPORT PORTA
#define AR0 PA0 //22 
#define AR1 PA1 //23
#define AG0 PA2 //24
#define AG1 PA3 //25 
#define AB0 PA4 //26
#define AB1 PA5 //27

#define CTRLPORT PORTC

#define AA PC0  //37
#define AB PC1  //36
#define AC PC2  //35
#define AD PC3  //34

#define OE PC4  //33
#define LAT PC5 //32 
#define CLK PC6 //31 
#define PLANES 2
void setup() {
// set ports to output
pinMode(22, OUTPUT);
pinMode(23, OUTPUT);
pinMode(24, OUTPUT);
pinMode(25, OUTPUT);
pinMode(26, OUTPUT);
pinMode(27, OUTPUT);

pinMode(31, OUTPUT);
pinMode(32, OUTPUT);
pinMode(33, OUTPUT);
pinMode(34, OUTPUT);
pinMode(35, OUTPUT);
pinMode(36, OUTPUT);
pinMode(37, OUTPUT);

DATAPORT = 0;
CTRLPORT=(1<<OE);

for (int x=0; x<128;x++) {
CTRLPORT &= ~(1<<CLK);
DATAPORT = 0;
CTRLPORT |= (1<<CLK);
DATAPORT = 0;
} //x

CTRLPORT |= (1<<LAT);
//delayMicroseconds(2);
CTRLPORT &= ~(1<<LAT);
}

void loop() {



// lines
for (int y=0;y<16;y++){
//planes (inside y to avoid ghosting?)
for (int p=0;p<PLANES+1;p++){

//output enable
CTRLPORT &= ~(1<<OE);

//display enable in too slow?
//for ( int wait = 0;wait<((y<<1)+1);wait++) {
// __asm__("nop\n\t"); 
//}
//CTRLPORT |= (1<<OE);

//pixels
for (int x=0; x<128;x++) {
CTRLPORT &= ~(1<<CLK) ;
int z = (x>>p);
int w = (z>>2);
//DATAPORT = (z&1) | ((z>>PLANES-1)&10) | (z>>(PLANES*2-2)&100)     ; // B1.G1.R1.B0.G0.R0.
int r1= (z&1)  | ((z>>PLANES-1)&0x2)| ((z>>(PLANES*2-2))&4);
int r2= (w&1);//  | ((w>>PLANES-1)&0x2)| ((w>>(PLANES*2-2))&4);

//int r2= ((w>>1)&1) |( (w>>PLANES-1+3 )&2) | ((z>>(PLANES*2-2+3))&4) ;  
//int r2=  ((z>>((PLANES*2)-2+1))&0x7) ;  


//DATAPORT = (z&1)     ; // B1.G1.R1.B0.G0.R0.
//DATAPORT |=  ((z>>PLANES-1)&2)     ; // B1.G1.R1.B0.G0.R0.
//DATAPORT |=  ((z>>(PLANES*2-2))&4)     ; // B1.G1.R1.B0.G0.R0.
//DATAPORT &=0x7;
DATAPORT = r1<<3 | r2;

//DATAPORT = (z&1) | z>>(PLANES-1)&10   ; // B1.G1.R1.B0.G0.R0.
//DATAPORT = ((y&0xf)>>(x&0xf))&1;

CTRLPORT |= (1<<CLK);

//DATAPORT = 0;

// stop output after N pixels (dimming)
//if ( x> ((y)+1)<<p) { 
if ( x> (1<<p)) { 
CTRLPORT |= (1<<OE);
}
} //x

// row address
CTRLPORT =  (CTRLPORT & 0xf0) | (y&0xf);

// latch data in
CTRLPORT |= (1<<LAT);
CTRLPORT &= ~(1<<LAT);



}//p
}//y
}//loop
