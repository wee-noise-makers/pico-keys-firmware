with Ada.Unchecked_Conversion;

package body Pico_Keys.MIDI.Input is

   Max_MIDI_Data_Len : constant := 3;

   type MIDI_Decoder_State is (Wait_For_Status,
                               Msg_Data);

   type MIDI_Data_Array is new HAL.UInt8_Array (1 .. Max_MIDI_Data_Len);

   type MIDI_Decoder is tagged record
      State : MIDI_Decoder_State := Wait_For_Status;
      Count : Natural := 0;
      Data  : MIDI_Data_Array;
      Index : Positive := 1;
   end record;

   ----------
   -- Push --
   ----------

   procedure Push (This : in out MIDI_Decoder;  Data : HAL.UInt8) is

      function Is_Status return Boolean
      is ((Data and 2#1000_0000#) /= 0);

      ---------------
      -- Msg_Ready --
      ---------------

      procedure Msg_Ready is
         function To_MIDI_Message
         is new Ada.Unchecked_Conversion (MIDI_Data_Array,
                                          Message);
      begin
         Pico_Keys.MIDI.Push_To_Input_Queue (To_MIDI_Message (This.Data));
      end Msg_Ready;

      ---------------
      -- Start_Msg --
      ---------------

      procedure Start_Msg (Expected_Len : Positive) is
      begin
         This.Data (1) := Data;
         This.Index := 2;

         if Expected_Len /= 1 then
            This.Count := Expected_Len - 1;
            This.State := Msg_Data;
         else
            Msg_Ready;
         end if;
      end Start_Msg;

   begin
      case This.State is
         when Wait_For_Status =>
            if Is_Status then
               case Data and 2#1111_0000# is
                  when 16#80# | 16#90# | 16#A0# | 16#B0# | 16#E0# =>
                     --  Channel message with two data bytes
                     Start_Msg (Expected_Len => 3);

                  when 16#C0# | 16#D0# => null;
                     --  Channel message with one data byte
                     Start_Msg (Expected_Len => 2);

                  when 16#F0# => --  System message
                     case Data is
                        when 16#F0# | 16#F7#=>
                           -- Ignore SysEx start and stop
                           null;

                        when 16#F2# =>
                           --  Sys message with two data bytes
                           Start_Msg (Expected_Len => 3);

                        when 16#F3# | 16#F5# =>
                           --  Sys message with one data byte
                           Start_Msg (Expected_Len => 2);

                        when 16#F6# | 16#F8# | 16#FA# |
                             16#FB# | 16#FC# | 16#FE# | 16#FF# =>
                           --  Sys message without data byte
                           Start_Msg (Expected_Len => 1);

                        when others =>
                           --  Unknown/unsupported sys message
                           null;
                     end case;

                  when others =>
                     --  Unknown/unsupported message
                     null;
               end case;
            end if;

         when Msg_Data =>

            if Is_Status or else This.Count = 0 then
               --  There is an issue with the current message, ignore it
               This.State := Wait_For_Status;

            else
               This.Data (This.Index) := Data;
               This.Count := This.Count - 1;
               This.Index := This.Index + 1;

               if This.Count = 0 then

                  Msg_Ready;
                  This.State := Wait_For_Status;
               end if;
            end if;
      end case;
   end Push;

   Decoder : MIDI_Decoder;

   --------------
   -- Received --
   --------------

   procedure Received (Data : HAL.UInt8) is
   begin
      Decoder.Push (Data);
   end Received;

end Pico_Keys.MIDI.Input;
