with Pico_Keys.Synth_Plugin;
with Pico_Keys.MIDI_Clock;

package body Pico_Keys.MIDI is

   ----------
   -- Send --
   ----------

   procedure Send (M : Message) is
   begin
      Encoder_Queue.Push (M);
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

   ---------------------
   -- Send_Clock_Tick --
   ---------------------

   procedure Send_Clock_Tick is
   begin
      Send ((Sys, Timming_Tick, others => <>));
   end Send_Clock_Tick;

   ----------------
   -- Send_Start --
   ----------------

   procedure Send_Start is
   begin
      Send ((Sys, Start_Song, others => <>));
   end Send_Start;

   -------------------
   -- Send_Continue --
   -------------------

   procedure Send_Continue is
   begin
      Send ((Sys, Continue_Song, others => <>));
   end Send_Continue;

   ---------------
   -- Send_Stop --
   ---------------

   procedure Send_Stop is
   begin
      Send ((Sys, Stop_Song, others => <>));
   end Send_Stop;

   -------------------
   -- Process_Input --
   -------------------

   procedure Process_Input is

      procedure Handle_Message (Msg : Message) is
      begin
         case Msg.Kind is

            when Note_Off | Note_On | Aftertouch | Continous_Controller |
                 Patch_Change | Channel_Pressure | Pitch_Bend =>

               Synth_Plugin.Send (Msg);

            when Sys =>
               case Msg.Cmd is

                  when Start_Song =>
                     MIDI_Clock.External_Start;

                  when Stop_Song =>
                     MIDI_Clock.External_Stop;

                  when Continue_Song =>
                     MIDI_Clock.External_Continue;

                  when Timming_Tick =>
                     MIDI_Clock.External_Tick;

                  when others =>
                     null; -- Ignore other messages...
               end case;
         end case;
      end Handle_Message;

      procedure Flush
      is new Standard.MIDI.Decoder.Queue.Flush (Handle_Message);

   begin
      Flush (Decoder_Queue);
   end Process_Input;

end Pico_Keys.MIDI;
