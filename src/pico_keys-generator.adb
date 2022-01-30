with Pico_Keys.MIDI; use Pico_Keys.MIDI;

package body Pico_Keys.Generator is

   X : constant Boolean := True;
   I : constant Boolean := False;

   Trig_Map : array (Step_Count, Time_Div) of Boolean
     := (1  => (X, X, X, X, X, X, X, X),
         2  => (I, I, I, I, I, I, I, I),
         3  => (I, I, I, I, I, I, I, X),
         4  => (I, I, I, X, I, I, I, I),
         5  => (I, I, I, I, I, I, X, X),
         6  => (I, I, I, I, I, I, I, I),
         7  => (I, I, X, X, I, I, I, X),
         8  => (I, I, I, I, I, I, I, I),
         9  => (I, I, I, I, I, X, X, X),
         10 => (I, I, I, X, I, I, I, I),
         11 => (I, I, I, I, I, I, I, X),
         12 => (I, I, I, I, I, I, I, I),
         13 => (I, X, X, X, I, I, X, X),
         14 => (I, I, I, I, I, I, I, I),
         15 => (I, I, I, I, I, I, I, X),
         16 => (I, I, I, X, I, I, I, I),
         17 => (I, I, I, I, X, X, X, X),
         18 => (I, I, I, I, I, I, I, I),
         19 => (I, I, X, X, I, I, I, X),
         20 => (I, I, I, I, I, I, I, I),
         21 => (I, I, I, I, I, I, X, X),
         22 => (I, I, I, X, I, I, I, I),
         23 => (I, I, I, I, I, I, I, X),
         24 => (I, I, I, I, I, I, I, I),
         25 => (X, X, X, X, I, X, X, X),
         26 => (I, I, I, I, I, I, I, I),
         27 => (I, I, I, I, I, I, I, X),
         28 => (I, I, I, X, I, I, I, I),
         29 => (I, I, I, I, I, I, X, X),
         30 => (I, I, I, I, I, I, I, I),
         31 => (I, I, X, X, I, I, I, X),
         32 => (I, I, I, I, I, I, I, I),
         33 => (I, I, I, I, X, X, X, X),
         34 => (I, I, I, X, I, I, I, I),
         35 => (I, I, I, I, I, I, I, X),
         36 => (I, I, I, I, I, I, I, I),
         37 => (I, X, X, X, I, I, X, X),
         38 => (I, I, I, I, I, I, I, I),
         39 => (I, I, I, I, I, I, I, X),
         40 => (I, I, I, X, I, I, I, I),
         41 => (I, I, I, I, I, X, X, X),
         42 => (I, I, I, I, I, I, I, I),
         43 => (I, I, X, X, I, I, I, X),
         44 => (I, I, I, I, I, I, I, I),
         45 => (I, I, I, I, I, I, X, X),
         46 => (I, I, I, X, I, I, I, I),
         47 => (I, I, I, I, I, I, I, X),
         48 => (I, I, I, I, I, I, I, I));

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
