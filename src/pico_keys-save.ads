with MIDI;

with Pico_Keys.Generator_Instances;
with Pico_Keys.Meta_Gen;
with Pico_Keys.Synth_UI;

private with RP.Flash;
private with HAL;

package Pico_Keys.Save is

   type Gen_Array is array (Gen_Id) of Pico_Keys.Meta_Gen.Instance;

   type Save_State is record
      Valid        : Boolean := False;
      BPM          : BPM_Range := 120;
      Base_Note    : MIDI.MIDI_Key := MIDI.C4;
      Generators   : Gen_Array;
      Synth_Params : Synth_UI.All_Synth_Parameters;
   end record;

   RAM_State : Save_State;

   type Any_Save_Slot is range 0 .. 10;
   subtype Valid_Save_Slot is Any_Save_Slot range 1 .. Any_Save_Slot'Last;

   Invalid_Save_Slot : constant Any_Save_Slot := Any_Save_Slot'First;

   procedure Save_To_Flash (Slot : Valid_Save_Slot);
   --  Save the current state to the given slot

   procedure Load_From_Flash (Slot : Valid_Save_Slot);
   --  Load current state from the given slot

   procedure Load_First_Valid;
   --  Load current state from the first valid slot

   function Last_Load return Any_Save_Slot;
   --  Return the last loaded/saved slot

private

   Save_Slot_Byte_Size : constant := RP.Flash.Sector_Size * 7;

   pragma Compile_Time_Error
     ((Save_State'Size / 8) > Save_Slot_Byte_Size, "Save slot too small");

   type Save_Slot_Data is array (1 .. Save_Slot_Byte_Size) of HAL.UInt8
     with Size => Save_Slot_Byte_Size * 8;

   Flash_State_Data : array (Valid_Save_Slot) of Save_Slot_Data
     with Linker_Section => ".save_data",
     Size => Save_Slot_Byte_Size * Valid_Save_Slot'Last * 8;

end Pico_keys.Save;
