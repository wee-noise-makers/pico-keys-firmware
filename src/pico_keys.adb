with RP.GPIO;
with RP.Device;

package body Pico_Keys is

   procedure ISR_Invalid;
   pragma Export (ASM, ISR_Invalid, "isr_invalid");

   procedure ISR_Hardfault;
   pragma Export (ASM, ISR_Hardfault, "isr_hardfault");

   procedure ISR_Nmi;
   pragma Export (ASM, ISR_Nmi, "isr_nmi");

   procedure ISR_Invalid is
   begin
      raise Program_Error;
   end ISR_Invalid;

   procedure ISR_Hardfault is
   begin
      raise Program_Error;
   end ISR_Hardfault;

   procedure ISR_Nmi is
   begin
      raise Program_Error;
   end ISR_Nmi;

begin
   RP.Clock.Initialize (XOSC_Frequency);
   RP.Clock.Enable (RP.Clock.PERI);
   RP.Device.Timer.Enable;
   RP.GPIO.Enable;
   RP.DMA.Enable;
   RP.Device.PIO_0.Enable;

   --  Asm ("cpsie i",
   --       Volatile => True);

end Pico_Keys;
