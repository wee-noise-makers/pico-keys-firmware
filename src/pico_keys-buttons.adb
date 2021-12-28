with RP.GPIO; use RP.GPIO;

package body Pico_Keys.Buttons is

   type State_Array is array (Button_ID) of Boolean;

   State : State_Array := (others => False);
   Prev_State : State_Array := State;

   GPIOs : array (Button_ID) of RP.GPIO.GPIO_Point :=
     (btn_C    => (Pin => 21),
      btn_Cs   => (Pin => 22),
      btn_D    => (Pin => 19),
      btn_Ds   => (Pin => 20),
      btn_E    => (Pin => 18),
      btn_F    => (Pin => 16),
      btn_Fs   => (Pin => 7),
      btn_G    => (Pin => 17),
      btn_Gs   => (Pin => 6),
      btn_A    => (Pin => 15),
      btn_As   => (Pin => 5),
      btn_B    => (Pin => 14),
      btn_C2   => (Pin => 13),
      btn_C2s  => (Pin => 4),
      btn_D2   => (Pin => 12),
      btn_D2s  => (Pin => 3),
      btn_E2   => (Pin => 8),
      btn_func => (Pin => 2)
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

   procedure Scan is
   begin
      Prev_State := State;

      for Index in Button_ID loop
         State (Index) := not GPIOs (Index).Set;
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

begin
   Initialize;
end Pico_Keys.Buttons;
