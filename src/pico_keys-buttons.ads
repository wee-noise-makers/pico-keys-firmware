with RP.Timer;

package Pico_Keys.Buttons is

   procedure Scan (Now : RP.Timer.Time);

   function Pressed (ID : Button_ID) return Boolean;
   function Falling (ID : Button_ID) return Boolean;
   function Rising (ID : Button_ID) return Boolean;
   function Repeat (ID : Button_ID) return Boolean;
   function Long_Press (ID : Button_ID) return Boolean;
   function Double_Press (ID : Button_ID) return Boolean;

   procedure Reset_Dbl_Long;
   --  Reset the double and long press counters. Use this procedure to avoid
   --  triggering long presses or double presses when switching between modes.

end Pico_Keys.Buttons;
