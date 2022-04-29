with System;
with System.Storage_Elements; use System.Storage_Elements;

package body Pico_Keys.Save is

   Data_Page_Size        : constant Natural :=
     ((Save_State'Object_Size / 8) / RP.Flash.Page_Size) + 1;
   Data_Sector_Size      : constant Natural :=
     ((Save_State'Object_Size / 8) / RP.Flash.Sector_Size) + 1;

   Last_Loaded : Any_Save_Slot := Any_Save_Slot'First;

   -------------------
   -- Save_To_Flash --
   -------------------

   procedure Save_To_Flash (Slot : Valid_Save_Slot) is
      use RP.Flash;

      Offset : constant Flash_Offset :=
        To_Flash_Offset (Flash_State_Data (Slot)'Address);
   begin
      RAM_State.Valid := True;

      Erase (Offset,
             Data_Sector_Size * RP.Flash.Sector_Size);

      Program (Offset, RAM_State'Address,
               Data_Page_Size * RP.Flash.Page_Size);

      Last_Loaded := Slot;
   end Save_To_Flash;

   ---------------------
   -- Load_From_Flash --
   ---------------------

   procedure Load_From_Flash (Slot : Valid_Save_Slot) is
      Flash_State : Save_State
        with Import, Address => Flash_State_Data (Slot)'Address;
   begin
      if Flash_State.Valid then
         declare
            Src : Storage_Array (1 .. Save_State'Object_Size / 8)
              with Address => Flash_State'Address;
            Dst : Storage_Array (1 .. Save_State'Object_Size / 8)
              with Address => RAM_State'Address;
         begin
            --  RAM_State := Flash_State;
            Dst := Src;

            Pico_Keys.Synth_UI.Update_All_Parameters;

            Last_Loaded := Slot;
         end;
      end if;
   end Load_From_Flash;

   ----------------------
   -- Load_First_Valid --
   ----------------------

   procedure Load_First_Valid is
   begin
      for Slot in Valid_Save_Slot loop
         declare
            Flash_State : Save_State
              with Import, Address => Flash_State_Data (Slot)'Address;
         begin
            if Flash_State.Valid then
               Load_From_Flash (Slot);
               return;
            end if;
         end;
      end loop;
   end Load_First_Valid;

   ---------------
   -- Last_Load --
   ---------------

   function Last_Load return Any_Save_Slot
   is (Last_Loaded);

end Pico_Keys.Save;
