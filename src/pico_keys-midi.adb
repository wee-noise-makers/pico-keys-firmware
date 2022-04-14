with Pico_Keys.Synth_Plugin;
with Pico_Keys.MIDI_Clock;

package body Pico_Keys.MIDI is

   --------------------------
   -- Push_To_Serial_Queue --
   --------------------------

   procedure Push_To_Serial_Queue (Msg : Message) is
      use BBqueue;
      use BBqueue.Buffers;

      WG : BBqueue.Buffers.Write_Grant;
   begin
      Grant (MIDI_Serial_Queue, WG, Size => 3);

      if State (WG) = Valid then
         declare
            Addr : constant System.Address := Slice (WG).Addr;
            Dst : Message with Import, Address => Addr;
         begin
            Dst := Msg;
         end;
         Commit (MIDI_Serial_Queue, WG);
      end if;
   end Push_To_Serial_Queue;

   -------------------------
   -- Push_To_Input_Queue --
   -------------------------

   procedure Push_To_Input_Queue (Msg : Message) is
      use BBqueue;

      WG : Write_Grant;
   begin
      Grant (MIDI_Input_Queue, WG, Size => 1);

      if State (WG) = Valid then
         MIDI_Input_Storage (Slice (WG).From) := Msg;
         Commit (MIDI_Input_Queue, WG);
      end if;
   end Push_To_Input_Queue;

   ----------
   -- Send --
   ----------

   procedure Send (M : Message) is
   begin
      Push_To_Serial_Queue (M);
   end Send;

   ------------------
   -- Send_Note_On --
   ------------------

   procedure Send_Note_On (K    : MIDI_Key;
                           Chan : MIDI_Channel)
   is
      Msg : constant Message := (Note_On, Chan, K, MIDI_Data'Last);
   begin
      Send (Msg);
      Pico_Keys.Synth_Plugin.Send (Msg);
   end Send_Note_On;

   -------------------
   -- Send_Note_Off --
   -------------------

   procedure Send_Note_Off (K    : MIDI_Key;
                            Chan : MIDI_Channel)
   is
      Msg : constant Message := (Note_Off, Chan, K, MIDI_Data'Last);
   begin
      Send (Msg);
      Pico_Keys.Synth_Plugin.Send (Msg);
   end Send_Note_Off;

   -------------
   -- Send_CC --
   -------------

   procedure Send_CC (Chan       : MIDI_Channel;
                      Controller : MIDI_Data;
                      Value      : MIDI_Data)
   is
      Msg : constant Message := (Continous_Controller,
                                 Chan,
                                 Controller,
                                 Value);
   begin

      --  CC are only going to the internal synth

      Pico_Keys.Synth_Plugin.Send (Msg);
   end Send_CC;

   ----------------
   -- Send_UInt8 --
   ----------------

   procedure Send_UInt8 (V : UInt8) is
      use BBqueue;
      use BBqueue.Buffers;

      WG : BBqueue.Buffers.Write_Grant;
   begin
      Grant (MIDI_Serial_Queue, WG, Size => 1);

      if State (WG) = Valid then
         declare
            Addr : constant System.Address := Slice (WG).Addr;
            Dst : UInt8 with Import, Address => Addr;
         begin
            Dst := V;
         end;
         Commit (MIDI_Serial_Queue, WG);
      end if;
   end Send_UInt8;

   ---------------------
   -- Send_Clock_Tick --
   ---------------------

   procedure Send_Clock_Tick is
   begin
      Send_UInt8 (2#11111000#);
   end Send_Clock_Tick;

   ----------------
   -- Send_Start --
   ----------------

   procedure Send_Start is
   begin
      Send_UInt8 (2#11111010#);
   end Send_Start;

   ---------------
   -- Send_Stop --
   ---------------

   procedure Send_Stop is
   begin
      Send_UInt8 (2#11111100#);
   end Send_Stop;

   -------------------
   -- Process_Input --
   -------------------

   procedure Process_Input is
      use BBqueue;

      RG : Read_Grant;
   begin
      loop

         BBqueue.Read (MIDI_Input_Queue, RG, Max => 1);

         exit when State (RG) /= Valid;

         declare
            Msg : Message renames MIDI_Input_Storage (Slice (RG).From);
         begin

            case Msg.Kind is

            when Note_Off | Note_On | Aftertouch | Continous_Controller |
                 Patch_Change | Channel_Pressure | Pitch_Bend =>

               Synth_Plugin.Send (Msg);

            when Sys =>
               case Msg.Chan is

                  when 16#A# => --  Start Song
                     MIDI_Clock.External_Start;

                  when 16#C# => --  Stop Song
                     MIDI_Clock.External_Stop;

                  when 16#8# => --  Timming Tick
                     MIDI_Clock.External_Tick;

                  when others =>
                     null; -- Ignore other messages...
               end case;
            end case;
         end;

         BBqueue.Release (MIDI_Input_Queue, RG);

      end loop;
   end Process_Input;

end Pico_Keys.MIDI;
