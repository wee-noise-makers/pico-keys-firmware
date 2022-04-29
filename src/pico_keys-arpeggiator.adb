with HAL; use HAL;

package body Pico_Keys.Arpeggiator is

   ----------
   -- Play --
   ----------

   overriding
   procedure Play (This : in out Instance) is
   begin
      Parent (This).Play;
      This.Next_Index := Note_Index'First;
      This.Last_Note := 0;
      This.Current_Oct := 0;
   end Play;

   overriding
   procedure Stop (This : in out Instance) is
   begin
      Parent (This).Stop;
      if This.Note_To_Turn_Off /= 0 then
         This.Note_Off (This.Note_To_Turn_Off);
         This.Note_To_Turn_Off := 0;
      end if;
   end Stop;

   -------------
   -- Falling --
   -------------

   overriding
   procedure Falling (This : in out Instance;
                      K    :        MIDI.MIDI_Key)
   is
   begin
      if not This.Waiting_For_Notes then
         This.Clear;
         This.Waiting_For_Notes := True;
         This.Last_Note := 0;
         This.Current_Oct := 0;
      end if;

      if This.Next_Add /= Note_Index'Last then
         This.Arp_Seq (This.Next_Add) := K;
         This.Next_Add := This.Next_Add + 1;
         This.Notes_In_Arp (K) := True;
      end if;
   end Falling;

   ------------
   -- Rising --
   ------------

   overriding
   procedure Rising (This : in out Instance;
                      K    :        MIDI.MIDI_Key)
   is
   begin
      null;
   end Rising;

   ---------------------
   -- No_Keys_Pressed --
   ---------------------

   overriding
   procedure No_Keys_Pressed (This : in out Instance)
   is
   begin
      This.Waiting_For_Notes := False;
   end No_Keys_Pressed;

   -----------------
   -- Enter_Focus --
   -----------------

   overriding
   procedure Enter_Focus (This : in out Instance)
   is
   begin
      null;
   end Enter_Focus;

   -----------------
   -- Leave_Focus --
   -----------------

   overriding
   procedure Leave_Focus (This : in out Instance)
   is
   begin
      null;
   end Leave_Focus;

   -------------
   -- Trigger --
   -------------

   overriding
   procedure Trigger (This : in out Instance) is
   begin
      if This.Note_To_Turn_Off /= 0 then
         This.Note_Off (This.Note_To_Turn_Off);
         This.Note_To_Turn_Off := 0;
      end if;

      if not This.Playing or else This.Next_Add = Note_Index'First then
         --  Nothing to play
         return;
      end if;


      case This.Current_Mode is
         when Up =>
            loop
               if This.Last_Note = MIDI.MIDI_Key'Last then
                  This.Last_Note := MIDI.MIDI_Key'First;
                  This.Trig_Next_Oct;
               else
                  This.Last_Note := This.Last_Note + 1;
               end if;

               exit when This.Notes_In_Arp (This.Last_Note);
            end loop;

         when Down =>
            loop
               if This.Last_Note = MIDI.MIDI_Key'First then
                  This.Last_Note := MIDI.MIDI_Key'Last;
                  This.Trig_Next_Oct;
               else
                  This.Last_Note := This.Last_Note - 1;
               end if;

               exit when This.Notes_In_Arp (This.Last_Note);
            end loop;

         when Up_N_Down =>
            loop
               if This.Going_Up then
                  if This.Last_Note = MIDI.MIDI_Key'Last then
                     This.Trig_Next_Oct;
                     This.Going_Up := False;
                  else
                     This.Last_Note := This.Last_Note + 1;
                  end if;
               else
                  if This.Last_Note = MIDI.MIDI_Key'First then
                     This.Trig_Next_Oct;
                     This.Going_Up := True;
                  else
                     This.Last_Note := This.Last_Note - 1;
                  end if;
               end if;

               exit when This.Notes_In_Arp (This.Last_Note);
            end loop;

         when Order =>
            if This.Next_Index >= This.Next_Add then
               This.Next_Index := Note_Index'First;
               This.Trig_Next_Oct;
            else
               This.Next_Index := This.Next_Index + 1;
            end if;

            This.Last_Note := This.Arp_Seq (This.Next_Index);
      end case;

      declare
         Int_Key : Integer :=
           Integer (This.Last_Note) + Integer (This.Current_Oct) * 12;

         Int_Key_First : constant Integer := Integer (MIDI.MIDI_Key'First);
         Int_Key_Last : constant Integer := Integer (MIDI.MIDI_Key'Last);
      begin

         if Int_Key not in Int_Key_First .. Int_Key_Last then
            --  Octave shift is outside of key range, go back to original key
            Int_Key := Integer (This.Last_Note);
         end if;

         This.Note_On (MIDI.MIDI_Key (Int_Key));
         This.Note_To_Turn_Off := MIDI.MIDI_Key (Int_Key);
      end;

   end Trigger;

   -------------------
   -- Trig_Next_Oct --
   -------------------

   procedure Trig_Next_Oct (This : in out Instance) is
   begin
      if This.Oct_Rng < 0 then
         if This.Current_Oct > 0 or else This.Current_Oct <= This.Oct_Rng then
            This.Current_Oct := 0;
         else
            This.Current_Oct := This.Current_Oct - 1;
         end if;

      elsif This.Oct_Rng > 0 then
         if This.Current_Oct < 0 or else This.Current_Oct >= This.Oct_Rng then
            This.Current_Oct := 0;
         else
            This.Current_Oct := This.Current_Oct + 1;
         end if;

      else
         This.Current_Oct := 0;
      end if;
   end Trig_Next_Oct;

   -----------
   -- Clear --
   -----------

   overriding
   procedure Clear (This : in out Instance) is
   begin
      This.Next_Index := Note_Index'First;
      This.Next_Add := Note_Index'First;
      This.Notes_In_Arp := (others => False);
   end Clear;

   ------------
   -- In_Arp --
   ------------

   function In_Arp (This : Instance;
                    K    : MIDI.MIDI_Key)
                    return Boolean
   is
   begin
      return This.Notes_In_Arp (K);
   end In_Arp;

   ---------------
   -- Next_Mode --
   ---------------

   procedure Next_Mode (This : in out Instance) is
   begin
      if This.Current_Mode /= Arp_Mode'Last then
         This.Current_Mode := Arp_Mode'Succ (This.Current_Mode);
      else
         This.Current_Mode := Arp_Mode'First;
      end if;
   end Next_Mode;

   ----------
   -- Mode --
   ----------

   function Mode (This : Instance) return Arp_Mode
   is (This.Current_Mode);

   ------------------
   -- Octave_Range --
   ------------------

   function Octave_Range (This : Instance) return Oct_Range
   is (This.Oct_Rng);

   -----------------------
   -- Next_Octave_Range --
   -----------------------

   procedure Next_Octave_Range (This : in out Instance) is
   begin
      if This.Oct_Rng /= Oct_Range'Last then
         This.Oct_Rng := This.Oct_Rng + 1;
      end if;
   end Next_Octave_Range;

   -----------------------
   -- Prev_Octave_Range --
   -----------------------

   procedure Prev_Octave_Range (This : in out Instance) is
   begin
      if This.Oct_Rng /= Oct_Range'First then
         This.Oct_Rng := This.Oct_Rng - 1;
      end if;
   end Prev_Octave_Range;

 end Pico_Keys.Arpeggiator;
