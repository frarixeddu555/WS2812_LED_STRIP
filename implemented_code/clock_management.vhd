library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;



entity reloj_controlador is
    Port (  clk_100_in  : in    STD_LOGIC;
				reloj_100MHz : out std_logic;
				reloj_50MHz : out std_logic;
				reloj_25MHz : out std_logic
           );
end reloj_controlador;

architecture Behavioral of reloj_controlador is


 -- señales MMCME2 ---
 signal clkin1 : std_logic;
 signal clkout0, clkout1, clkout2 : std_logic;
 signal clkfb_in, clkfb_out : std_logic;
 -------------------------------------------



begin

  MMCME2_BASE_inst : MMCME2_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
		CLKFBOUT_MULT_F => 10.0,	-- da 48MHz
--		CLKFBOUT_MULT_F => 60.0,	
--		CLKFBOUT_MULT_F => 30.0,	-- funciona
		
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB (-360.000-360.000).
		CLKIN1_PERIOD => 10.000,	-- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

----- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
		CLKOUT0_DIVIDE_F => 20.0,


		CLKOUT1_DIVIDE => 40,
--		CLKOUT2_DIVIDE => 40,
--    CLKOUT3_DIVIDE => 1,
--    CLKOUT4_DIVIDE => 1,
--    CLKOUT5_DIVIDE => 1,
--    CLKOUT6_DIVIDE => 1,

		DIVCLK_DIVIDE => 1,        -- Master division value (1-106)
      REF_JITTER1 => 0.0,        -- Reference input jitter in UI (0.000-0.999).
      STARTUP_WAIT => FALSE      -- Delays DONE until MMCM is locked (FALSE, TRUE)
   )

		
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0 => CLKOUT0,     -- 1-bit output: CLKOUT0
      CLKOUT1 => CLKOUT1,     -- 1-bit output: CLKOUT1
      CLKOUT2 => CLKOUT2,     -- 1-bit output: CLKOUT2

      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT => CLKFB_OUT,   -- 1-bit output: Feedback clock

      -- Status Ports: 1-bit (each) output: MMCM status ports
      LOCKED => open,      -- 1-bit output: LOCK

      -- Clock Inputs: 1-bit (each) input: Clock input
      CLKIN1 => CLKIN1,    -- 1-bit input: Clock

      -- Control Ports: 1-bit (each) input: MMCM control ports
      PWRDWN => '0',       -- 1-bit input: Power-down
      RST => '0',          -- 1-bit input: Reset

      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN => CLKFB_IN      -- 1-bit input: Feedback clock
   );


 clkin_bufg : BUFG
	port map
		(	I 	=> clk_100_in,
			O 	=> clkin1 	);
	reloj_100MHz <= clkin1;

 clkfb_buf : BUFG
	port map
		(	O => clkfb_in,
			I => clkfb_out );

 clk50MHz_bufg : BUFG
	port map
		(	I 	=> clkout0,
			O 	=> reloj_50MHz 	);


 clk25MHz_bufg: BUFG
  port map (
				I => CLKOUT1,
   	      O => reloj_25MHz );



end Behavioral;