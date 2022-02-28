with HAL; use HAL;

with RP.PIO; use RP.PIO;
with RP.GPIO; use RP.GPIO;

with RP.PIO.WS2812; use RP.PIO.WS2812;
with Pico_Keys.PIO; use Pico_Keys.PIO;

package body Pico_Keys.LEDs is

   Out_Pin : aliased RP.GPIO.GPIO_Point := (Pin => 1);

   Number_Of_LEDs : constant := 19;
   subtype LED_ID is Natural range 1 .. Number_Of_LEDs;

   LED_Strip : aliased RP.PIO.WS2812.Strip (Out_Pin'Access,
                                            WS2812_PIO'Access,
                                            WS2812_SM,
                                            Number_Of_LEDs);

   Button_To_LED : constant array (Button_ID) of LED_ID :=
     (Btn_C    => 9,
      Btn_Cs   => 8,
      Btn_D    => 10,
      Btn_Ds   => 7,
      Btn_E    => 11,
      Btn_F    => 12,
      Btn_Fs   => 6,
      Btn_G    => 13,
      Btn_Gs   => 5,
      Btn_A    => 14,
      Btn_As   => 4,
      Btn_B    => 15,
      Btn_C2   => 16,
      Btn_C2s  => 3,
      Btn_D2   => 17,
      Btn_D2s  => 2,
      Btn_E2   => 18,
      Btn_Func => 1,
      Btn_Synth => 19
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
            Set_HSV (Id, H, UInt8'Last / 4, UInt8'Last);
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
