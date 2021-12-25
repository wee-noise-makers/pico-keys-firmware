
with System;

with RP.Clock;
with RP.GPIO;
with RP.DMA;
with RP.Device;

package body Pico_Keys is

   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer) is
   begin
      loop
         null;
      end loop;
   end Last_Chance_Handler;

begin
   RP.Clock.Initialize (XOSC_Frequency);
   RP.Clock.Enable (RP.Clock.PERI);
   RP.Device.Timer.Enable;
   RP.GPIO.Enable;
   RP.DMA.Enable;

   --  Asm ("cpsie i",
   --       Volatile => True);

end Pico_Keys;
