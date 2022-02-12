with HAL; use HAL;

with RP.PIO; use RP.PIO;
with RP.GPIO; use RP.GPIO;

with RP.PIO.WS2812; use RP.PIO.WS2812;
with Pico_Keys.PIO; use Pico_Keys.PIO;

package body Pico_Keys.LEDs is

   Out_Pin : aliased RP.GPIO.GPIO_Point := (Pin => 1);

   Number_Of_LEDs : constant := 18;
   subtype LED_ID is Natural range 1 .. Number_Of_LEDs;

   LED_Strip : aliased RP.PIO.WS2812.Strip (Out_Pin'Access,
                                            WS2812_PIO'Access,
                                            WS2812_SM,
                                            Number_Of_LEDs);

   Button_To_LED : constant array (Button_ID) of LED_ID :=
     (btn_C    => 9,
      btn_Cs   => 8,
      btn_D    => 10,
      btn_Ds   => 7,
      btn_E    => 11,
      btn_F    => 12,
      btn_Fs   => 6,
      btn_G    => 13,
      btn_Gs   => 5,
      btn_A    => 14,
      btn_As   => 4,
      btn_B    => 15,
      btn_C2   => 16,
      btn_C2s  => 3,
      btn_D2   => 17,
      btn_D2s  => 2,
      btn_E2   => 18,
      btn_func => 1
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
