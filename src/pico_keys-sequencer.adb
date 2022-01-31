with HAL; use HAL;

package body Pico_Keys.Sequencer is

   overriding
   procedure Play (This : in out Instance) is
   begin
      Parent (This).Play;
      This.Current_Step := 0;
   end Play;

   --------------
   -- Add_Note --
   --------------

   procedure Add_Note (S : in out Step_Rec; K : MIDI.MIDI_Key) is
   begin
      if S.Count < Note_Index'Last then
         S.Count := S.Count + 1;
         S.Notes (S.Count) := K;
      end if;
   end Add_Note;

   ----------------
   -- Play_Notes --
   ----------------

   procedure Play_Notes (This : in out Instance; S : Step_Rec) is
   begin
      for K of S.Notes (Note_Index'First .. S.Count) loop
         if K /= 0 then
            This.Note_On (K);
         end if;
      end loop;
   end Play_Notes;

   -------------
   -- Falling --
   -------------

   overriding
   procedure Falling (This : in out Instance;
                      K    :        MIDI.MIDI_Key)
   is
   begin
      if This.Edit_Step >= Step_Index'Last then
         return;
      end if;

      if not This.Waiting_For_Notes
        and then
          This.Edit_Step /= Step_Index'Last
      then
         This.Edit_Step := This.Edit_Step + 1;
         This.Waiting_For_Notes := True;
      end if;

      Add_Note (This.Steps (This.Edit_Step), K);
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

   ---------------------
   -- Enter_Func_Mode --
   ---------------------

   overriding
   procedure Enter_Func_Mode (This : in out Instance)
   is
   begin
      null;
   end Enter_Func_Mode;


   -------------
   -- Trigger --
   -------------

   overriding
   procedure Trigger (This : in out Instance) is
   begin

      if not This.Playing or else This.Edit_Step < Step_Index'First then
         This.Release_All;
         return;
      end if;

      This.Current_Step := This.Current_Step + 1;

      if This.Current_Step not in Step_Index'First .. This.Edit_Step then
         This.Current_Step := Step_Index'First;
      end if;

      if not This.Steps (This.Current_Step).Tie then
         This.Release_All;
         Play_Notes (This, This.Steps (This.Current_Step));
      end if;


   end Trigger;

   -----------
   -- Clear --
   -----------

   procedure Clear (This : in out Instance) is
   begin
      This.Edit_Step := Step_Index'First - 1;
      This.Steps := (others => (Count => 0, Tie => False, others => <>));
      This.Current_Step := 0;
      This.Waiting_For_Notes := False;
   end Clear;

   --------------
   -- Add_Rest --
   --------------

   procedure Add_Rest (This : in out Instance) is
   begin
      This.Waiting_For_Notes := False;
      This.Falling (0);
      This.Waiting_For_Notes := False;
   end Add_Rest;

   -------------
   -- Add_Tie --
   -------------

   procedure Add_Tie (This : in out Instance) is
   begin
      if This.Edit_Step >= Step_Index'Last then
         return;
      end if;

      if This.Edit_Step /= Step_Index'Last then
         This.Edit_Step := This.Edit_Step + 1;
         This.Steps (This.Edit_Step).Tie := True;
         This.Waiting_For_Notes := False;
      end if;
   end Add_Tie;

   ------------
   -- In_Seq --
   ------------

   function In_Seq (This : Instance) return Note_Array is
   begin
      if This.Edit_Step >= Step_Index'Last then
         return (1 .. 0 => <>);
      end if;

      declare
         Step : Step_Rec renames This.Steps (This.Edit_Step);
      begin
         return Step.Notes (1 .. Step.Count);
      end;
   end In_Seq;

end Pico_Keys.Sequencer;
