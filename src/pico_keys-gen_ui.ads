with RP.Timer;

package Pico_Keys.Gen_UI is

   procedure Process_Keys (Now         :        RP.Timer.Time;
                           Current_Gen : in out Gen_Id);
   --  Buttons.Scan and LEDs.Clear should be already done before entring this
   --  procedure.

end Pico_Keys.Gen_UI;
