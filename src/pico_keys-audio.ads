with HAL;
with System;

package Pico_Keys.Audio is

   type Audio_Handler is access procedure (Buffer       : out System.Address;
                                           Sample_Count : out HAL.UInt32);

   procedure Set_Handler (Handler : Audio_Handler);

end Pico_Keys.Audio;
