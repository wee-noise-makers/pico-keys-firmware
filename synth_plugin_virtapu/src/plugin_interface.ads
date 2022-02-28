with HAL;
with System;

with MIDI;

package Plugin_Interface is

   function RAM_Offset (Addr : System.Address) return HAL.UInt24;
   function Address (Offset : HAL.UInt24) return System.Address;
   function Sample_Count (Len : Natural) return HAL.UInt4;

   type Data_Kind is (Out_Buffer, In_Buffer, MIDI_Msg)
     with Size => 4;

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
   function Pop_Blocking return Data;

   -- Raw FIFO access --

   function RX_Ready return Boolean;
   function TX_Ready return Boolean;

   procedure Push_Blocking (V : HAL.UInt32);
   function Pop_Blocking return HAL.UInt32;

   function Try_Push (V : HAL.UInt32) return Boolean;
   function Try_Pop (V : out HAL.UInt32) return Boolean;

   procedure Drain;

end Plugin_Interface;
