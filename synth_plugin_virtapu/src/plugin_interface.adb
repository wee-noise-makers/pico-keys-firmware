with System.Storage_Elements;
with System.Machine_Code;
with Ada.Unchecked_Conversion;

with HAL; use HAL;
with RP2040_SVD.SIO; use RP2040_SVD.SIO;

package body Plugin_Interface is

   RAM_Base : constant := 16#20000000#;

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
      Push_Blocking (To_UInt32 (D));
   end Push;

   ---------
   -- Pop --
   ---------

   function Pop (D : out Data) return Boolean is
      function To_Data is new Ada.Unchecked_Conversion (UInt32, Data);
      V : HAL.UInt32;
   begin
      if Try_Pop (V) then
         D := To_Data (V);
         return True;
      else
         return False;
      end if;
   end Pop;

   ------------------
   -- Pop_Blocking --
   ------------------

   function Pop_Blocking return Data is
      function To_Data is new Ada.Unchecked_Conversion (UInt32, Data);
   begin
      return To_Data (Pop_Blocking);
   end Pop_Blocking;

   --------------
   -- RX_Ready --
   --------------

   function RX_Ready return Boolean is
   begin
      return SIO_Periph.FIFO_ST.VLD;
   end RX_Ready;

   --------------
   -- TX_Ready --
   --------------

   function TX_Ready return Boolean is
   begin
      return SIO_Periph.FIFO_ST.RDY;
   end TX_Ready;

   -------------------
   -- Push_Blocking --
   -------------------

   procedure Push_Blocking (V : HAL.UInt32) is
   begin
      loop
         exit when TX_Ready;
      end loop;
      SIO_Periph.FIFO_WR := V;

      System.Machine_Code.Asm ("sev", Volatile => True);
   end Push_Blocking;

   ------------------
   -- Pop_Blocking --
   ------------------

   function Pop_Blocking return HAL.UInt32 is
   begin
      while not RX_Ready loop

         System.Machine_Code.Asm ("wfe", Volatile => True);

      end loop;
      return SIO_Periph.FIFO_RD;
   end Pop_Blocking;

   --------------
   -- Try_Push --
   --------------

   function Try_Push (V : HAL.UInt32) return Boolean is
   begin
      if TX_Ready then
         SIO_Periph.FIFO_WR := V;

         System.Machine_Code.Asm ("sev", Volatile => True);

         return True;
      else
         return False;
      end if;
   end Try_Push;

   -------------
   -- Try_Pop --
   -------------

   function Try_Pop (V : out HAL.UInt32) return Boolean is
   begin
      if RX_Ready then
         V := SIO_Periph.FIFO_RD;
         return True;
      else
         return False;
      end if;
   end Try_Pop;

   -----------
   -- Drain --
   -----------

   procedure Drain is
      Discard : HAL.UInt32;
   begin
      while RX_Ready loop
         Discard := SIO_Periph.FIFO_RD;
      end loop;

   end Drain;
end Plugin_Interface;
