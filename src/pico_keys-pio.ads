with RP.PIO; use RP.PIO;
with RP.Device;
with RP.DMA;

with Pico_Keys.WS2812_PIO_ASM; use Pico_Keys.WS2812_PIO_ASM;

package Pico_Keys.PIO is

   -- PIO 0 --

   WS2812_PIO    : PIO_Device renames RP.Device.PIO_0;
   WS2812_SM     : constant PIO_SM := 2;
   WS2812_Offset : constant PIO_Address :=
     PIO_Address'Last - Ws2812_Program_Instructions'Length + 1;
   WS2812_DMA_Trigger : constant RP.DMA.DMA_Request_Trigger := RP.DMA.PIO0_TX2;

end Pico_Keys.PIO;
