with RP.GPIO; use RP.GPIO;
with RP.Timer; use RP.Timer;

package body Pico_Keys.Buttons is

   type State_Array is array (Button_ID) of Boolean;

   State : State_Array := (others => False);
   Prev_State : State_Array := State;
   Repeat_State : State_Array := (others => False);

   Repeat_Interval : constant RP.Timer.Time := RP.Timer.Milliseconds (300);
   Repeat_Deadline : array (Button_ID) of RP.Timer.Time :=
     (others => RP.Timer.Time'Last);

   GPIOs : array (Button_ID) of RP.GPIO.GPIO_Point :=
     (Btn_C     => (Pin => 21),
      Btn_Cs    => (Pin => 22),
      Btn_D     => (Pin => 19),
      Btn_Ds    => (Pin => 20),
      Btn_E     => (Pin => 18),
      Btn_F     => (Pin => 16),
      Btn_Fs    => (Pin => 10),
      Btn_G     => (Pin => 17),
      Btn_Gs    => (Pin => 9),
      Btn_A     => (Pin => 15),
      Btn_As    => (Pin => 8),
      Btn_B     => (Pin => 14),
      Btn_C2    => (Pin => 13),
      Btn_C2s   => (Pin => 7),
      Btn_D2    => (Pin => 12),
      Btn_D2s   => (Pin => 6),
      Btn_E2    => (Pin => 11),
      Btn_Func  => (Pin => 5),
      Btn_Synth => (Pin => 4)
     );

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      for GP of GPIOs loop
         GP.Configure (Input, Pull_Up);
      end loop;
   end Initialize;

   ----------
   -- Scan --
   ----------

   procedure Scan (Now : RP.Timer.Time) is
   begin
      Prev_State := State;

      for Index in Button_ID loop
         State (Index) := not GPIOs (Index).Set;


         Repeat_State (Index) := False;
         if Falling (Index) then
            Repeat_Deadline (Index) := Now + Repeat_Interval;
         elsif Pressed (Index) and then Repeat_Deadline (Index) <= Now then
            Repeat_State (Index) := True;
            Repeat_Deadline (Index) := Now + Repeat_Interval;
         end if;
      end loop;

   end Scan;

   -------------
   -- Pressed --
   -------------

   function Pressed (ID : Button_ID) return Boolean is
   begin
      return State (ID);
   end Pressed;

   -------------
   -- Falling --
   -------------

   function Falling (ID : Button_ID) return Boolean is
   begin
      return State (ID) and then not Prev_State (ID);
   end Falling;

   ------------
   -- Rising --
   ------------

   function Rising (ID : Button_ID) return Boolean is
   begin
      return not State (ID) and then Prev_State (ID);
   end Rising;

------------
-- Repeat --
------------

function Repeat (ID : Button_ID) return Boolean is
   begin
      return Repeat_State (ID);
   end Repeat;

begin
   Initialize;
end Pico_Keys.Buttons;
