with RP.GPIO; use RP.GPIO;
with RP.Timer; use RP.Timer;

package body Pico_Keys.Buttons is

   type State_Array is array (Button_ID) of Boolean;

   State : State_Array := (others => False);
   Prev_State : State_Array := State;

   Long_Press_Interval : constant RP.Timer.Time := RP.Timer.Milliseconds (1000);
   Long_Press_State : State_Array := (others => False);
   Long_Press_Deadline : array (Button_ID) of Time := (others => Time'Last);

   Dbl_Press_Interval : constant RP.Timer.Time := RP.Timer.Milliseconds (500);
   Dbl_Press_State : State_Array := (others => False);
   Dbl_Press_Deadline : array (Button_ID) of Time := (others => Time'First);

   Repeat_Interval : constant RP.Timer.Time := RP.Timer.Milliseconds (300);
   Repeat_State : State_Array := (others => False);
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

      Repeat_State := (others => False);
      Dbl_Press_State := (others => False);
      Long_Press_State := (others => False);

      for Index in Button_ID loop
         State (Index) := not GPIOs (Index).Set;


         if Falling (Index) then
            Repeat_Deadline (Index) := Now + Repeat_Interval;
            Long_Press_Deadline (Index) := Now + Long_Press_Interval;
         elsif Pressed (Index) then

            if Now >= Repeat_Deadline (Index) then
               Repeat_State (Index) := True;
               Repeat_Deadline (Index) := Now + Repeat_Interval;
            end if;

            if Now >= Long_Press_Deadline (Index) then
               Long_Press_State (Index) := True;
               Long_Press_Deadline (Index) := Time'Last;
            end if;

         elsif Rising (Index) then
            if Now <= Dbl_Press_Deadline (Index) then
               Dbl_Press_State (Index) := True;
               Dbl_Press_Deadline (Index) := Time'First;
            else
               Dbl_Press_Deadline (Index) := Now + Dbl_Press_Interval;
            end if;
         end if;
      end loop;

   end Scan;

   --------------------
   -- Reset_Dbl_Long --
   --------------------

   procedure Reset_Dbl_Long is
   begin
      Long_Press_State := (others => False);
      Long_Press_Deadline := (others => Time'Last);

      Dbl_Press_State := (others => False);
      Dbl_Press_Deadline := (others => Time'First);

      Repeat_State := (others => False);
      Repeat_Deadline := (others => RP.Timer.Time'Last);
   end Reset_Dbl_Long;


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

   ----------------
   -- Long_Press --
   ----------------

   function Long_Press (ID : Button_ID) return Boolean is
   begin
      return Long_Press_State (ID);
   end Long_Press;

   ------------------
   -- Double_Press --
   ------------------

   function Double_Press (ID : Button_ID) return Boolean is
   begin
      return Dbl_Press_State (ID);
   end Double_Press;

begin
   Initialize;
end Pico_Keys.Buttons;
