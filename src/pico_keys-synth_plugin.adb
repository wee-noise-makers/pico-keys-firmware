with HAL; use HAL;

with Ada.Unchecked_Conversion;

with System.Storage_Elements;

with RP.Multicore;
with RP.Multicore.FIFO;

with Pico_Keys.Audio;

package body Pico_Keys.Synth_Plugin is

   RAM_Base : constant := 16#20000000#;

   CRC : constant HAL.UInt32 := 0;

   Audio_Buffer_Len : constant := 64;
   Audio_Buffer_A : UInt16_Array (1 .. Audio_Buffer_Len);
   Audio_Buffer_B : UInt16_Array (1 .. Audio_Buffer_Len);
   Playing       : System.Address := Audio_Buffer_A'Address;

   Buffer_Miss_Counter : Natural := 0;

   -----------
   -- Start --
   -----------

   procedure Start is
      use System.Storage_Elements;

      RAM_Base : constant := 16#20000000#;
      RAM_Size : constant := 256 * 1024;
      Plugin_Area_Size  : constant := 206 * 1024;
      Plugin_Area_Start : constant := RAM_Base + RAM_Size - Plugin_Area_Size;
      Plugin_Area_End   : constant := Plugin_Area_Start + Plugin_Area_Size;

      Scartch_X_Size  : constant := 4 * 1024;
      Scartch_X_Start : constant := 16#20040000#;
      Scartch_X_End   : constant := Scartch_X_Start + Scartch_X_Size;

      Plugin_Vect : UInt32_Array (1 .. 2)
        with Address => System'To_Address (Plugin_Area_Start);


      Plugin_Load_Start : UInt8;
      pragma Import (ASM, Plugin_Load_Start, "synth_plugin_start");

      Plugin_Load_End : UInt8;
      pragma Import (ASM, Plugin_Load_End, "synth_plugin_end");

      Plugin_Load_Start_Addr : constant Integer_Address :=
        To_Integer (Plugin_Load_Start'Address);

      Plugin_Load_End_Addr : constant Integer_Address :=
        To_Integer (Plugin_Load_End'Address);

      Plugin_Len : constant Integer_Address :=
        Plugin_Load_End_Addr - Plugin_Load_Start_Addr + 1;

   begin

      if Plugin_Len > Plugin_Area_Size then
         raise Program_Error;
      end if;

      --  Copy the plugin in RAM
      declare
         Src : UInt8_Array (1 .. Natural (Plugin_Len))
           with Address => To_Address (Plugin_Load_Start_Addr);

         Dst : UInt8_Array (Src'Range)
           with Address => To_Address (Plugin_Area_Start);
      begin
         Dst := Src;
      end;


      declare
         Vect : constant UInt32 := UInt32 (Plugin_Area_Start);
         SP   : constant UInt32 := Plugin_Vect (1);
         Ent  : constant UInt32 := Plugin_Vect (2);
      begin
         if SP not in Plugin_Area_Start .. Plugin_Area_End
           and then
            SP not in Scartch_X_Start .. Scartch_X_End
         then
            raise Program_Error;
         end if;

         if Ent not in Plugin_Area_Start .. Plugin_Area_End then
            raise Program_Error;
         end if;

         RP.Multicore.Launch_Core1
           (Trap_Vect   => Vect,
            SP          => SP,
            Entry_Point => Ent);
      end;

      Pico_Keys.Audio.Set_Handler (Audio_Handler'Access);

   end Start;

   -------------
   -- Get_CRC --
   -------------

   function Get_CRC return HAL.UInt32 is
   begin
      return CRC;
   end Get_CRC;

   -------------------
   -- Audio_Handler --
   -------------------

   procedure Audio_Handler
     (Buffer : out System.Address; Sample_Count : out HAL.UInt32)
   is
      use System;

      D : Data;

      Count  : constant UInt4 := Synth_Plugin.Sample_Count (Audio_Buffer_A'Length);
      A_Addr : constant System.Address := Audio_Buffer_A'Address;
      B_Addr : constant System.Address := Audio_Buffer_B'Address;
   begin
      if Pop (D) and then D.Kind = Out_Buffer then
         Buffer := Address (D.Offset);
         Sample_Count := 2**Natural (D.Size);

      else
         Buffer_Miss_Counter := Buffer_Miss_Counter + 1;

         --  We don't have any buffer to play from core1
         Buffer := System.Null_Address;
         Sample_Count := 0;
      end if;

      if Playing = A_Addr then
         Push ((Kind => In_Buffer,
                Size => Count,
                Offset => RAM_Offset (B_Addr)));
         Playing := B_Addr;

      else
      --  elsif Playing = Audio_Buffers (False)'Address then
         Push ((Kind => In_Buffer,
                Size => Count,
                Offset => RAM_Offset (A_Addr)));
         Playing := A_Addr;
      --  else
      --     raise Program_Error;
      end if;
   end Audio_Handler;

   ----------
   -- Send --
   ----------

   procedure Send (M : MIDI.Message) is
   begin
      Push ((Kind => MIDI_Msg, Msg => M));
   end Send;


   ----------------
   -- RAM_Offset --
   ----------------

   function RAM_Offset (Addr : System.Address) return HAL.UInt24 is
      use System.Storage_Elements;
   begin
      return UInt24 (To_Integer (Addr) - RAM_Base);
   end RAM_Offset;

   -------------
   -- Address --
   -------------

   function Address (Offset : HAL.UInt24) return System.Address is
      use System.Storage_Elements;
   begin
      return To_Address (Integer_Address (Offset) + RAM_Base);
   end Address;

   ------------------
   -- Sample_Count --
   ------------------

   function Sample_Count (Len : Natural) return HAL.UInt4 is
   begin
      case Len is
         when 2**0  => return 0;
         when 2**1  => return 1;
         when 2**2  => return 2;
         when 2**3  => return 3;
         when 2**4  => return 4;
         when 2**5  => return 5;
         when 2**6  => return 6;
         when 2**7  => return 7;
         when 2**8  => return 8;
         when 2**9  => return 9;
         when 2**10 => return 10;
         when 2**11 => return 11;
         when 2**12 => return 12;
         when 2**13 => return 13;
         when 2**14 => return 14;
         when 2**15 => return 15;
         when others => raise Program_Error;
      end case;
   end Sample_Count;

   ----------
   -- Push --
   ----------

   procedure Push (D : Data) is
      function To_UInt32 is new Ada.Unchecked_Conversion (Data, UInt32);
   begin
      RP.Multicore.FIFO.Push_Blocking (To_UInt32 (D));
   end Push;

   ---------
   -- Pop --
   ---------

   function Pop (D : out Data) return Boolean is
      function To_Data is new Ada.Unchecked_Conversion (UInt32, Data);
      V : HAL.UInt32;
   begin
      if RP.Multicore.FIFO.Try_Pop (V) then
         D := To_Data (V);
         return True;
      else
         return False;
      end if;
   end Pop;

end Pico_Keys.Synth_Plugin;
