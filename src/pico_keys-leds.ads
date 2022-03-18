with HAL;
with Pico_Keys.Meta_Gen;

package Pico_Keys.LEDs is

   procedure Clear;
   procedure Update;

   type LED_Effect is (None, Blink, Blink_Fast, Dim, Fade);

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

   Beat_Hue     : constant LEDs.Hue := Green;
   Triplet_Hue  : constant LEDs.Hue := Orange;
   Arp_Hue      : constant LEDs.Hue := Cyan;
   Seq_Hue      : constant LEDs.Hue := Red;
   Keyboard_Hue : constant LEDs.Hue := Violet;
   Gen_Hue : constant array (Pico_Keys.Meta_Gen.Meta_Mode_Kind) of LEDs.Hue
     := (Pico_Keys.Meta_Gen.Key => Keyboard_Hue,
         Pico_Keys.Meta_Gen.Arp => Arp_Hue,
         Pico_Keys.Meta_Gen.Seq => Seq_Hue);


   procedure Set_HSV (Id : Button_ID;
                      H : Hue;
                      S, V : HAL.UInt8);

   procedure Set_Hue (Id : Button_ID; H : Hue; Effect : LED_Effect := None);
   --  The Hue with full saturation and value

end Pico_Keys.LEDs;
