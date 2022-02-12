with RP.PIO; use RP.PIO;
with RP.Device;

package Pico_Keys.PIO is

   -- PIO 0 --

   WS2812_PIO    : PIO_Device renames RP.Device.PIO_0;
   WS2812_SM     : constant PIO_SM := 2;
   WS2812_Offset : constant PIO_Address := 0;

end Pico_Keys.PIO;
