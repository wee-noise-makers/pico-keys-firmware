with MIDI; use MIDI;

with Pico_Keys.MIDI;

package body Pico_Keys.Generator is

   subtype Dispatch is Instance'Class;

   -------------
   -- Playing --
   -------------

   function Playing (This : Instance) return Boolean
   is (This.Is_Playing);

   ----------
   -- Play --
   ----------

   procedure Play (This : in out Instance) is
   begin
      This.Is_Playing := True;

      This.Next_Trig := RP.Timer.Time'Last;
      This.First_Of_Pair := True;
   end Play;

   ----------
   -- Stop --
   ----------

   procedure Stop (This : in out Instance) is
   begin
      This.Is_Playing := False;
   end Stop;

   -----------------
   -- Toggle_play --
   -----------------

   procedure Toggle_play (This : in out Instance) is
   begin
      if Dispatch (This).Playing then
         Dispatch (This).Stop;
      else
         Dispatch (This).Play;
      end if;
   end Toggle_play;

   -------------
   -- Channel --
   -------------

   function Channel (This : Instance) return MIDI_Channel is
   begin
      return This.Chan;
   end Channel;

   ------------------
   -- Next_Channel --
   ------------------

   procedure Next_Channel (This : in out Instance) is
   begin
      if This.Chan /= MIDI_Channel'Last then
         This.Chan := This.Chan + 1;
      end if;
   end Next_Channel;

   ------------------
   -- Prev_Channel --
   ------------------

   procedure Prev_Channel (This : in out Instance) is
   begin
      if This.Chan /= MIDI_Channel'First then
         This.Chan := This.Chan - 1;
      end if;
   end Prev_Channel;

   --------------
   -- Division --
   --------------

   function Division (This : Instance) return Time_Div is
   begin
      return This.Div;
   end Division;

   -------------------
   -- Next_Division --
   -------------------

   procedure Next_Division (This : in out Instance) is
   begin
      if This.Div /= Time_Div'Last then
         This.Div := Time_Div'Succ (This.Div);
      else
         This.Div := Time_Div'First;
      end if;
   end Next_Division;

   -----------
   -- Swing --
   -----------

   function Swing (This : Instance) return Time_Swing is
   begin
      return This.Swing;
   end Swing;

   ----------------
   -- Next_Swing --
   ----------------

   procedure Next_Swing (This : in out Instance) is
   begin
      if This.Swing /= Time_Swing'Last then
         This.Swing := Time_Swing'Succ (This.Swing);
      else
         This.Swing := Time_Swing'First;
      end if;
   end Next_Swing;

   -----------------
   -- Signal_Step --
   -----------------

   procedure Signal_Step (This : in out Instance;
                          BPM  :        BPM_Range;
                          Step :        Step_Count;
                          Now  :        RP.Timer.Time)
   is
      use RP.Timer;

      Step_Time : constant Time := Time ((Ticks_Per_Second * 60) / (BPM * 24));
      Steps     : constant Natural := (case This.Division is
                                          when Div_4   => 24,
                                          when Div_8   => 12,
                                          when Div_16  => 6,
                                          when Div_32  => 3,
                                          when Div_4T  => 16,
                                          when Div_8T  => 8,
                                          when Div_16T => 4,
                                          when Div_32T => 2);
      Straight  : constant Time := Step_Time * Time (Steps);

      Swing_Time : constant Time :=
        Time (Float (Straight) * (case This.Swing is
                                    when Swing_Off => 0.0,
                                    when Swing_55  => 0.10,
                                    when Swing_60  => 0.20,
                                    when Swing_65  => 0.30,
                                    when Swing_70  => 0.40,
                                    when Swing_75  => 0.50));

   begin
      if Dispatch (This).Playing then
         if On_Time (This.Division, Step) then
            if This.First_Of_Pair then
               This.Next_Trig := Now;
            else
               This.Next_Trig := Now + Swing_Time;
            end if;

            This.First_Of_Pair := not This.First_Of_Pair;
         end if;
      end if;
   end Signal_Step;

   -------------------
   -- Check_Trigger --
   -------------------

   procedure Check_Trigger (This : in out Instance;
                            Now  :        RP.Timer.Time)
   is
      use RP.Timer;

   begin
      if This.Next_Trig <= Now then
         Dispatch (This).Trigger;
         This.Next_Trig := RP.Timer.Time'Last;
      end if;
   end Check_Trigger;

   -------------
   -- Note_On --
   -------------

   procedure Note_On (This : in out Instance; K : MIDI_Key) is
   begin
      MIDI.Send_Note_On (K, This.Chan);
      This.Notes_On (K) := True;
   end Note_On;

   --------------
   -- Note_Off --
   --------------

   procedure Note_Off (This : in out Instance; K : MIDI_Key) is
   begin
      MIDI.Send_Note_Off (K, This.Chan);
      This.Notes_On (K) := False;
   end Note_Off;

   -----------------
   -- Release_All --
   -----------------

   procedure Release_All (This : in out Instance) is
   begin
      for K in This.Notes_On'Range loop
         if This.Notes_On (K) then
            MIDI.Send_Note_Off (K, This.Chan);
         end if;
      end loop;

      This.Notes_On := (others => False);
   end Release_All;

end Pico_Keys.Generator;
