with HAL;

package Pico_Keys.LEDs is

   procedure Clear;
   procedure Update;

   type LED_Effect is (None, Blink, Blink_Fast, Dim);

   procedure Set_RGB (Id : Button_ID; R, G, B : HAL.UInt8);

   type Hue is new HAL.UInt8;

   Red    : constant Hue := 0;
   Orange : constant Hue := 21;
   Yellow : constant Hue := 42;
   Green  : constant Hue := 80;
   Cyan   : constant Hue := 128;
   Blue   : constant Hue := 169;
   Violet : constant Hue := 203;
   Pink   : constant Hue := 212;

   procedure Set_HSV (Id : Button_ID;
                      H : Hue;
                      S, V : HAL.UInt8);

   procedure Set_Hue (Id : Button_ID; H : Hue; Effect : LED_Effect := None);
   --  The Hue with full saturation and value

end Pico_Keys.LEDs;
