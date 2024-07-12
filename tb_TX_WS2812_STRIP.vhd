--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:17:51 06/18/2024
-- Design Name:   
-- Module Name:   C:/Users/matte/Documents/ISE projects/RGB_WS2812/tb_TX_WS2812_FOR_TWO.vhd
-- Project Name:  RGB_WS2812
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: WS2812
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_TX_WS2812_STRIP IS
END tb_TX_WS2812_STRIP;
 
ARCHITECTURE behavior OF tb_TX_WS2812_STRIP IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TX_WS2812_STRIP
    PORT(
			ck : in std_logic;
			reset : in std_logic;
--			switch : in  STD_LOGIC_VECTOR (7 downto 0);
--        color : IN  std_logic_vector(23 downto 0);
			btn1 : IN  std_logic;
			btn2 : IN  std_logic;
--         btn3 : IN  std_logic;
         s_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
	signal ck : std_logic;
	signal reset : std_logic;
	signal switch : STD_LOGIC_VECTOR (7 downto 0);
--   signal color : std_logic_vector(23 downto 0) := (others => '0');
   signal btn1, btn2, btn3 : std_logic := '0';

 	--Outputs
   signal s_out : std_logic;
   -- No clocks detected in port list. Replace ck below with 
   -- appropriate port name 
 
   constant ck_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TX_WS2812_STRIP PORT MAP (
			 ck => ck,
			 reset => reset,
--			 switch => switch,
--          color => color,
			 btn1 => btn1,
			 btn2 => btn2,
--			 btn3 => btn3,
          s_out => s_out
        );

   -- Clock process definitions
   ck_process :process
   begin
		ck <= '0';
		wait for ck_period/2;
		ck <= '1';
		wait for ck_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		reset <= '1';
		
      wait for 100 ns;	
		
		reset <= '0';
		
		wait for 200 ns;
		
		btn2 <= '1';
		
		wait for 70 ms;
		
		btn2 <= '0';
		
		wait for 500 us;
		
		btn2 <= '1';
		
		wait for 20 us;
		
		btn2 <= '0';
		
      -- insert stimulus here 

      wait;
   end process;

END;
