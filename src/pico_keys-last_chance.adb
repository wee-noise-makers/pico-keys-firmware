with Pico_Keys.LEDs;
with RP.Device;

package body Pico_Keys.Last_Chance is

   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer) is
      pragma Unreferenced (Msg, Line);
   begin
      LEDs.Clear;

      for Id in Button_ID loop
        LEDs.Set_Hue (Id     => Id,
                      H      => LEDs.Red);
      end loop;

      loop
         LEDs.Update;
         RP.Device.Timer.Delay_Milliseconds (1);
      end loop;
   end Last_Chance_Handler;

end Pico_Keys.Last_Chance;
