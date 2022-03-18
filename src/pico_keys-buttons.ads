with RP.Timer;

package Pico_Keys.Buttons is

   procedure Scan (Now : RP.Timer.Time);

   function Pressed (ID : Button_ID) return Boolean;
   function Falling (ID : Button_ID) return Boolean;
   function Rising (ID : Button_ID) return Boolean;
   function Repeat (ID : Button_ID) return Boolean;

end Pico_Keys.Buttons;
