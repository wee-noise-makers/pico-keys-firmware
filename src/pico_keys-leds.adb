with HAL; use HAL;

with RP.PIO; use RP.PIO;
with RP.GPIO; use RP.GPIO;

with RP.PIO.WS2812; use RP.PIO.WS2812;
with Pico_Keys.PIO; use Pico_Keys.PIO;

package body Pico_Keys.LEDs is

   Out_Pin : aliased RP.GPIO.GPIO_Point := (Pin => 3);

   Number_Of_LEDs : constant := 19;
   subtype LED_ID is Natural range 1 .. Number_Of_LEDs;

   LED_Strip : aliased RP.PIO.WS2812.Strip (Out_Pin'Access,
                                            WS2812_PIO'Access,
                                            WS2812_SM,
                                            Number_Of_LEDs);

   Fade_Step : constant := 7;

   Fade_On    : array (Button_ID) of Boolean := (others => False);
   Fade_Hue   : array (Button_ID) of Hue := (others => 0);
   Fade_Value : array (Button_ID) of UInt8 := (others => 0);

   Button_To_LED : constant array (Button_ID) of LED_ID :=
     (Btn_C    => 10,
      Btn_Cs   => 9,
      Btn_D    => 11,
      Btn_Ds   => 8,
      Btn_E    => 12,
      Btn_F    => 13,
      Btn_Fs   => 7,
      Btn_G    => 14,
      Btn_Gs   => 6,
      Btn_A    => 15,
      Btn_As   => 5,
      Btn_B    => 16,
      Btn_C2   => 17,
      Btn_C2s  => 4,
      Btn_D2   => 18,
      Btn_D2s  => 3,
      Btn_E2   => 19,
      Btn_Func => 2,
      Btn_Synth => 1
     );

   Step_Cnt : UInt32 := 0;

   --------------
   -- Blink_On --
   --------------

   function Blink_On return Boolean is
   begin
      return (Step_Cnt mod 100) < 50;
   end Blink_On;

   -------------------
   -- Blink_Fast_On --
   -------------------

   function Blink_Fast_On return Boolean is
   begin
      return (Step_Cnt mod 10) < 5;
   end Blink_Fast_On;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      Clear (LED_Strip);
   end Clear;

   ------------
   -- Update --
   ------------

   procedure Update is
   begin
      Step_Cnt := Step_Cnt + 1;

      for Id in Button_ID loop
         if Fade_On (Id) then
            if Fade_Value (Id) < Fade_Step then
               Fade_On (Id) := False;
            else
               Fade_Value (Id) := Fade_Value (Id) - Fade_Step;
               Set_HSV (Id, Fade_Hue (Id), UInt8'Last, Fade_Value (Id));
            end if;
         end if;
      end loop;

      Update (LED_Strip);
   end Update;

   -------------
   -- Set_RGB --
   -------------

   procedure Set_RGB (Id : Button_ID; R, G, B : HAL.UInt8) is
   begin
      Set_RGB (LED_Strip, Button_To_LED (Id), R, G, B);
   end Set_RGB;

   -------------
   -- Set_HSV --
   -------------

   procedure Set_HSV (Id   : Button_ID;
                      H    : Hue;
                      S, V : HAL.UInt8)
   is
   begin
      Set_HSV (LED_Strip, Button_To_LED (Id), UInt8 (H), S, V);
   end Set_HSV;

   -------------
   -- Set_Hue --
   -------------

   procedure Set_Hue (Id : Button_ID; H : Hue; Effect : LED_Effect := None) is
   begin

      Fade_On (Id) := False;

      case Effect is
         when None =>
            Set_HSV (Id, H, UInt8'Last, UInt8'Last);

         when Blink =>
            if Blink_On then
               Set_HSV (Id, H, UInt8'Last, UInt8'Last);
            end if;

         when Blink_Fast =>
            if Blink_Fast_On then
               Set_HSV (Id, H, UInt8'Last, UInt8'Last);
            end if;

         when Dim =>
            Set_HSV (Id, H, UInt8'Last, UInt8'Last / 4);

         when Fade =>
            Fade_On (Id) := True;
            Fade_Hue (Id) := H;
            Fade_Value (Id) := UInt8'Last;
      end case;
   end Set_Hue;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Initialize (LED_Strip, WS2812_Offset);
      Enable_DMA (LED_Strip, LED_PIO_DMA);
   end Initialize;

begin
   Initialize;
end Pico_Keys.LEDs;
