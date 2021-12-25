with HAL; use HAL;

package body Pico_Keys.Arpeggiator is

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
      end if;

      if This.Next_Add /= Note_Index'Last then
         This.Arp_Seq (This.Next_Add) := K;
         This.Next_Add := This.Next_Add + 1;
         This.Notes_In_Arp (K) := True;
      end if;
   end Falling;

   -------------
   -- Raising --
   -------------

   overriding
   procedure Raising (This : in out Instance;
                      K    :        MIDI.MIDI_Key)
   is
   begin
      null;
   end Raising;

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
   procedure Trigger (This : in out Instance; Step : Step_Count) is
   begin
      if not This.Do_Trigger (Step) then
         --  No triggering on this step;
         return;
      end if;

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
               else
                  This.Last_Note := This.Last_Note + 1;
               end if;

               exit when This.Notes_In_Arp (This.Last_Note);
            end loop;

         when Down =>
            loop
               if This.Last_Note = MIDI.MIDI_Key'First then
                  This.Last_Note := MIDI.MIDI_Key'Last;
               else
                  This.Last_Note := This.Last_Note - 1;
               end if;

               exit when This.Notes_In_Arp (This.Last_Note);
            end loop;

         when Up_N_Down =>
            loop
               if This.Going_Up then
                  if This.Last_Note = MIDI.MIDI_Key'Last then
                     This.Going_Up := False;
                  else
                     This.Last_Note := This.Last_Note + 1;
                  end if;
               else
                  if This.Last_Note = MIDI.MIDI_Key'First then
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
            else
               This.Next_Index := This.Next_Index + 1;
            end if;

            This.Last_Note := This.Arp_Seq (This.Next_Index);
      end case;

      This.Note_On (This.Last_Note);
      This.Note_To_Turn_Off := This.Last_Note;
   end Trigger;

   -----------
   -- Clear --
   -----------

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

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode (This : in out Instance; M : Arp_Mode) is
   begin
      This.Current_Mode := M;
   end Set_Mode;

   ----------
   -- Mode --
   ----------

   function Mode (This : Instance) return Arp_Mode
   is (This.Current_Mode);

 end Pico_Keys.Arpeggiator;
