with System;

package Pico_Keys.Last_Chance is

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer);
   pragma Export (C, Last_Chance_Handler, "__gnat_last_chance_handler");

end Pico_Keys.Last_Chance;
