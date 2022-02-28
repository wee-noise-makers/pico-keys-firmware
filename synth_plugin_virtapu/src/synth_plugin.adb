with HAL; use HAL;
with RP2040_SVD.SIO; use RP2040_SVD.SIO;

with APU_Synth;
with Plugin_Interface;

procedure Synth_Plugin is

   --  TODO: Have a look at what the interpolators can do...

begin
   if SIO_Periph.CPUID /= 1 then
      --  We are not running on core 1...
      raise Program_Error;
   end if;

   loop
      APU_Synth.Handle (Plugin_Interface.Pop_Blocking);
   end loop;
end Synth_Plugin;
