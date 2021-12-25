package Pico_Keys.Buttons is

   procedure Scan;

   function Pressed (ID : Button_ID) return Boolean;
   function Falling (ID : Button_ID) return Boolean;
   function Raising (ID : Button_ID) return Boolean;
end Pico_Keys.Buttons;
