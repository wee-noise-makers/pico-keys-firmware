with System;

with HAL;

with MIDI;

package Pico_Keys.Synth_Plugin is

   procedure Start;
   --  Load a plug-in from flash and start it (on the second core)

   function Get_CRC return HAL.UInt32;
   --  Return the CRC of loaded plug-in, or zero if no plug-in was loaded

   procedure Audio_Handler (Buffer       : out System.Address;
                            Sample_Count : out HAL.UInt32);
   --  Audio callback to exchange buffer with the plug-in

   procedure Send (M : MIDI.Message);
   --  Send a MIDI message to the plug-in

private

   function RAM_Offset (Addr : System.Address) return HAL.UInt24;
   function Address (Offset : HAL.UInt24) return System.Address;
   function Sample_Count (Len : Natural) return HAL.UInt4;

   type Data_Kind is (Out_Buffer, In_Buffer, MIDI_Msg)
     with Size => 4;

   for Data_Kind use (Out_Buffer => 1,
                      In_Buffer  => 2,
                      MIDI_Msg   => 3);

   type Data (Kind : Data_Kind := Data_Kind'First) is record
      case Kind is
         when In_Buffer | Out_Buffer =>
            Size   : HAL.UInt4;
            Offset : HAL.UInt24;

         when MIDI_Msg =>
            Msg : MIDI.Message;
      end case;
   end record
     with Size => 32;

   for Data use record
      Kind   at 0 range 0 .. 3;
      Size   at 0 range 4 .. 7;
      Offset at 0 range 8 .. 31;
      Msg    at 0 range 8 .. 31;
   end record;

   procedure Push (D : Data);
   function Pop (D : out Data) return Boolean;

end Pico_Keys.Synth_Plugin;
