with MIDI.Decoder.Queue;

package body Pico_Keys.MIDI.Input is

   --------------
   -- Received --
   --------------

   procedure Received (Data : HAL.UInt8) is
   begin
      Standard.MIDI.Decoder.Queue.Push (Decoder_Queue, Data);
   end Received;

end Pico_Keys.MIDI.Input;
