with Pico_Keys.Save;
with Pico_Keys.MIDI;

with RP.Timer; use RP.Timer;

package body Pico_Keys.MIDI_Clock is

   Current_State : State_Kind := Stopped;
   Current_Step : Step_Count := Step_Count'First;
   Next_Clock_Trig : RP.Timer.Time := RP.Timer.Clock;

   BPM : BPM_Range renames Pico_Keys.Save.RAM_State.BPM;
   Generators : Pico_Keys.Save.Gen_Array
     renames Pico_Keys.Save.RAM_State.Generators;

   ---------------------------
   -- Internal_Clock_Period --
   ---------------------------

   function Internal_Clock_Period return Time is
   begin
      return Time ((Ticks_Per_Second * 60) / (BPM * 24));
   end Internal_Clock_Period;

   -----------
   -- State --
   -----------

   function State return State_Kind is
   begin
      return Current_State;
   end State;

   ----------
   -- Step --
   ----------

   function Step return Step_Count is
   begin
      return Current_Step;
   end Step;

   ------------
   -- Update --
   ------------

   procedure Update (Now : RP.Timer.Time) is
   begin

      case Current_State is
         when Stopped =>
            null; --  Nothing to do...

         when Running_Internal =>

            if Now >= Next_Clock_Trig then
               Next_Clock_Trig := Next_Clock_Trig + Internal_Clock_Period;

               for G of Generators loop
                  G.Signal_Step (BPM, Current_Step, Now);
               end loop;

               Current_Step := Current_Step + 1;
               MIDI.Send_Clock_Tick;
            end if;

         when Running_External =>
            null; --  Nothing to do...
      end case;
   end Update;

   --------------------
   -- Internal_Start --
   --------------------

   procedure Internal_Start is
   begin
      case Current_State is
         when Stopped =>

            Current_State := Running_Internal;
            Next_Clock_Trig := Clock + Internal_Clock_Period;
            Current_Step := Step_Count'First;

            MIDI.Send_Start;

         when Running_Internal =>
            null;

         when Running_External =>
            null;

      end case;
   end Internal_Start;

   -------------------
   -- Internal_Stop --
   -------------------

   procedure Internal_Stop is
   begin
      case Current_State is
         when Stopped =>
            null;

         when Running_Internal =>
            Current_State := Stopped;
            MIDI.Send_Stop;

         when Running_External =>
            null;
      end case;
   end Internal_Stop;

   --------------------
   -- External_Start --
   --------------------

   procedure External_Start is
   begin
      case Current_State is
         when Stopped =>
            Current_State := Running_External;
            Current_Step := Step_Count'First;

            --  Start all internal note generators
            for G of Generators loop
               G.Play;
            end loop;

            --  Propagate the clock start to our MIDI ouput
            MIDI.Send_Start;

         when Running_Internal =>
            null;

         when Running_External =>
            null;
      end case;
   end External_Start;

   -------------------
   -- External_Stop --
   -------------------

   procedure External_Stop is
   begin
      case Current_State is
         when Stopped =>
            null;

         when Running_Internal =>
            null;

         when Running_External =>

            --  Propagate the clock stop to our MIDI ouput
            MIDI.Send_Start;

            Current_State := Stopped;

      end case;
   end External_Stop;

   -------------------
   -- External_Tick --
   -------------------

   procedure External_Tick is
   begin
      case Current_State is
         when Stopped =>
            null; --  ?!? What is going on here?

         when Running_Internal =>
            null;

         when Running_External =>

            for G of Generators loop
               G.Signal_Step (BPM, Current_Step, Clock);
            end loop;

            Current_Step := Current_Step + 1;

            --  Propagate the clock tick to our MIDI ouput
            MIDI.Send_Clock_Tick;

      end case;
   end External_Tick;

end Pico_Keys.MIDI_Clock;
