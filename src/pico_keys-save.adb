with System;
with System.Storage_Elements; use System.Storage_Elements;

with RP.Flash;

package body Pico_Keys.Save is

   Data_Page_Size        : constant Natural :=
     ((Save_State'Object_Size / 8) / RP.Flash.Page_Size) + 1;
   Data_Sector_Size      : constant Natural :=
     ((Save_State'Object_Size / 8) / RP.Flash.Sector_Size) + 1;

   -------------------
   -- Save_To_Flash --
   -------------------

   procedure Save_To_Flash is
      use RP.Flash;

      Offset : constant Flash_Offset := To_Flash_Offset (Flash_State'Address);
   begin
      RAM_State.Valid := True;

      Erase (Offset,
             Data_Sector_Size * RP.Flash.Sector_Size);

      Program (Offset, RAM_State'Address,
               Data_Page_Size * RP.Flash.Page_Size);
   end Save_To_Flash;

   ---------------------
   -- Load_From_Flash --
   ---------------------

   procedure Load_From_Flash is
   begin
      if Flash_State.Valid then
         declare
            Src : Storage_Array (1 .. Save_State'Object_Size / 8)
              with Address => Flash_State'Address;
            Dst : Storage_Array (1 .. Save_State'Object_Size / 8)
              with Address => RAM_State'Address;
         begin
            Dst := Src;
            --  RAM_State := Flash_State;
         end;
      end if;
   end Load_From_Flash;

end Pico_Keys.Save;
