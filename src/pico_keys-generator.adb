with Pico_Keys.MIDI; use Pico_Keys.MIDI;

package body Pico_Keys.Generator is

   T : constant Boolean := True;
   F : constant Boolean := False;

   Trig_Map : array (Step_Count, Time_Div) of Boolean
     := (1  => (T, T, T, T),
         2  => (F, F, F, F),
         3  => (F, F, F, F),
         4  => (F, F, F, T),
         5  => (F, F, F, F),
         6  => (F, F, F, F),
         7  => (F, F, T, T),
         8  => (F, F, F, F),
         9  => (F, F, F, F),
         10 => (F, F, F, T),
         11 => (F, F, F, F),
         12 => (F, F, F, F),
         13 => (F, T, T, T),
         14 => (F, F, F, F),
         15 => (F, F, F, F),
         16 => (F, F, F, T),
         17 => (F, F, F, F),
         18 => (F, F, F, F),
         19 => (F, F, T, T),
         20 => (F, F, F, F),
         21 => (F, F, F, F),
         22 => (F, F, F, T),
         23 => (F, F, F, F),
         24 => (F, F, F, F));

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

   function Channel (This : Instance) return MIDI.MIDI_Channel is
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

   ----------------
   -- Do_Trigger --
   ----------------

   function Do_Trigger (This : Instance; Step : Step_Count) return Boolean is
   begin
      return Trig_Map (Step, This.Div);
   end Do_Trigger;

   -------------
   -- Note_On --
   -------------

   procedure Note_On (This : in out Instance; K : MIDI.MIDI_Key) is
   begin
      MIDI.Send_Note_On (K, This.Chan);
      This.Notes_On (K) := True;
   end Note_On;

   --------------
   -- Note_Off --
   --------------

   procedure Note_Off (This : in out Instance; K : MIDI.MIDI_Key) is
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
