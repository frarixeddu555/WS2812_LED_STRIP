----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.numeric_std.ALL;

entity top is
    Port (	clk_100_in		: in  STD_LOGIC;
				reset				: in  STD_LOGIC;	
				btn1 			: in std_logic;
				btn2			: in std_logic;
				btn3			: in std_logic;

				s_out	: out std_logic
           );
end top;


architecture Behavioral of top is

component TX_WS2812_STRIP is
	port (
		ck   	: in std_logic;
		reset 	: in std_logic;
		btn1 	: in std_logic;
		btn2 	: in std_logic;
		btn3 	: in std_logic;

		s_out 	: out std_logic
	);
end component;	


-- clk ------------------------------------------------------------------
	component reloj_controlador is
    Port (  clk_100_in  : in    STD_LOGIC;
				reloj_100MHz : out std_logic;
				reloj_50MHz : out std_logic;
				reloj_25MHz : out std_logic
           );
	end component;
   signal clk : std_logic;


begin
 
-- MMCM ------------------------------------------
	modulo_reloj_controlador : reloj_controlador
    Port Map
	 ( clk_100_in  	=> clk_100_in,
		reloj_100MHz	=> open,
		reloj_50MHz		=> clk        );

-- modulo DRIVER LEDs
	modulo_TX_WS2812_STRIP : TX_WS2812_STRIP
	Port Map
	(		ck => clk,
			reset => reset,
			btn1 => btn1,
			btn2 => btn2,
			btn3 => btn3,
	
			s_out => s_out			);
 

 

end Behavioral;

