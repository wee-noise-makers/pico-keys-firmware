package body Pico_Keys.Meta_Gen is

   -------------
   -- Playing --
   -------------

   overriding
   function Playing (This : Instance) return Boolean is
   begin
      case This.Meta is
         when Key => return This.Key_Gen.Playing;
         when Arp => return This.Arp_Gen.Playing;
         when Seq => return This.Seq_Gen.Playing;
      end case;
   end Playing;

   ----------
   -- Play --
   ----------

   overriding
   procedure Play (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Play;
         when Arp => This.Arp_Gen.Play;
         when Seq => This.Seq_Gen.Play;
      end case;
   end Play;

   ----------
   -- Play --
   ----------

   overriding
   procedure Continue (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Continue;
         when Arp => This.Arp_Gen.Continue;
         when Seq => This.Seq_Gen.Continue;
      end case;
   end Continue;

   ----------
   -- Stop --
   ----------

   overriding
   procedure Stop (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Stop;
         when Arp => This.Arp_Gen.Stop;
         when Seq => This.Seq_Gen.Stop;
      end case;
   end Stop;

   ------------------
   -- Next_Channel --
   ------------------

   overriding
   procedure Next_Channel (This : in out Instance) is
   begin
      Parent (This).Next_Channel;
      This.Arp_Gen.Next_Channel;
      This.Key_Gen.Next_Channel;
      This.Seq_Gen.Next_Channel;
   end Next_Channel;

   ------------------
   -- Prev_Channel --
   ------------------

   overriding
   procedure Prev_Channel (This : in out Instance) is
   begin
      Parent (This).Prev_Channel;
      This.Arp_Gen.Prev_Channel;
      This.Key_Gen.Prev_Channel;
      This.Seq_Gen.Prev_Channel;
   end Prev_Channel;

   -------------------
   -- Next_Division --
   -------------------

   overriding
   procedure Next_Division (This : in out Instance) is
   begin
      Parent (This).Next_Division;
      This.Arp_Gen.Next_Division;
      This.Key_Gen.Next_Division;
      This.Seq_Gen.Next_Division;
   end Next_Division;

   -------------
   -- Falling --
   -------------

   overriding
   procedure Falling (This : in out Instance; K : MIDI.MIDI_Key) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Falling (K);
         when Arp => This.Arp_Gen.Falling (K);
         when Seq => This.Seq_Gen.Falling (K);
      end case;
   end Falling;

   -------------
   -- Raising --
   -------------

   overriding
   procedure Rising (This : in out Instance; K : MIDI.MIDI_Key) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Rising (K);
         when Arp => This.Arp_Gen.Rising (K);
         when Seq => This.Seq_Gen.Rising (K);
      end case;
   end Rising;

   ---------------------
   -- No_Keys_Pressed --
   ---------------------

   overriding
   procedure No_Keys_Pressed (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.No_Keys_Pressed;
         when Arp => This.Arp_Gen.No_Keys_Pressed;
         when Seq => This.Seq_Gen.No_Keys_Pressed;
      end case;
   end No_Keys_Pressed;

   -----------------
   -- Enter_Focus --
   -----------------

   overriding
   procedure Enter_Focus (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Enter_Focus;
         when Arp => This.Arp_Gen.Enter_Focus;
         when Seq => This.Seq_Gen.Enter_Focus;
      end case;
   end Enter_Focus;

   -----------------
   -- Leave_Focus --
   -----------------

   overriding
   procedure Leave_Focus (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Leave_Focus;
         when Arp => This.Arp_Gen.Leave_Focus;
         when Seq => This.Seq_Gen.Leave_Focus;
      end case;
   end Leave_Focus;

   ---------------------
   -- Enter_Func_Mode --
   ---------------------

   overriding
   procedure Enter_Func_Mode (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Enter_Func_Mode;
         when Arp => This.Arp_Gen.Enter_Func_Mode;
         when Seq => This.Seq_Gen.Enter_Func_Mode;
      end case;
   end Enter_Func_Mode;

   -------------
   -- Trigger --
   -------------

   overriding
   procedure Trigger (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Trigger;
         when Arp => This.Arp_Gen.Trigger;
         when Seq => This.Seq_Gen.Trigger;
      end case;
   end Trigger;

   -----------
   -- Clear --
   -----------

   overriding
   procedure Clear (This : in out Instance) is
   begin
      case This.Meta is
         when Key => This.Key_Gen.Clear;
         when Arp => This.Arp_Gen.Clear;
         when Seq => This.Seq_Gen.Clear;
      end case;
   end Clear;

   ------------
   -- In_Arp --
   ------------

   function In_Arp (This : Instance; K : MIDI.MIDI_Key) return Boolean is
   begin
      if This.Meta = Arp then
         return This.Arp_Gen.In_Arp (K);
      else
         return False;
      end if;
   end In_Arp;

   --------------
   -- Arp_Mode --
   --------------

   function Arp_Mode (This : Instance) return Arpeggiator.Arp_Mode is
   begin
      return This.Arp_Gen.Mode;
   end Arp_Mode;

   -------------------
   -- Next_Arp_Mode --
   -------------------

   procedure Next_Arp_Mode (This : in out Instance) is
   begin
      if This.Meta = Arp then
         This.Arp_Gen.Next_Mode;
      end if;
   end Next_Arp_Mode;

   --------------
   -- Add_Rest --
   --------------

   procedure Add_Rest (This : in out Instance) is
   begin
      if This.Meta = Seq then
         This.Seq_Gen.Add_Rest;
      end if;
   end Add_Rest;

   -------------
   -- Add_Tie --
   -------------

   procedure Add_Tie (This : in out Instance) is
   begin
      if This.Meta = Seq then
         This.Seq_Gen.Add_Tie;
      end if;
   end Add_Tie;

   ------------
   -- In_Seq --
   ------------

   function In_Seq (This : Instance) return Sequencer.Note_Array is
   begin
      if This.Meta = Seq then
         return This.Seq_Gen.In_Seq;
      else
         return (1 .. 0 => <>);
      end if;
   end In_Seq;

   ------------------
   -- Current_Mode --
   ------------------

   function Current_Mode (This : Instance) return Meta_Mode_Kind is
   begin
      return This.Meta;
   end Current_Mode;

   ---------------
   -- Next_Meta --
   ---------------

   procedure Next_Meta (This : in out Instance) is
   begin
      This.Stop;
      if This.Meta /= Meta_Mode_Kind'Last then
         This.Meta := Meta_Mode_Kind'Succ (This.Meta);
      else
         This.Meta := Meta_Mode_Kind'First;
      end if;
   end Next_Meta;

end Pico_Keys.Meta_Gen;
