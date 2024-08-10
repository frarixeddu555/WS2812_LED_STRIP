library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TX_WS2812_STRIP is
	generic (
		num_of_led 		: integer := 60	-- set the number of used LEDs.
		);								-- Remember to change the MIXER_COLOR widht as well!
	port ( 
			ck 			: in 		std_logic;                                            -- 50MHz
			reset 		: in 		std_logic;
--			color 		: in  		std_logic_vector ((num_of_led * 24 - 1) downto 0);                   -- it is decoded by the DECODER process
--			switch 		: in  		std_logic_vector (7 downto 0);
			btn1 		: in  		std_logic;
			btn2		: in		std_logic;
			btn3		: in 		std_logic;	

			s_out		: out 		std_logic
		);
end TX_WS2812_STRIP; 

architecture Behavioral of TX_WS2812_STRIP is 

	-- constants
	constant 	tot_count_tmp 				: integer := 63;  				-- cycles to send one data of 24.
	constant 	time_up1 					: integer := 40; 				-- set time up1. time_down1 is tot_count_tmp - time_up1;
	constant 	time_up0 					: integer := 18; 		 		-- set time up0. time_down0 is tot_count_tmp - time_up0;
	constant 	tot_count_rst 				: integer := 13000; 				-- number of waiting clock cycles to refresh. Apparently, the min clock's cycle to count is 13000, say, at least 260 us.
	constant 	tot_count_bits_sent 		: integer := num_of_led * 24;  	-- number of bit to send
	
	-- counter single signal 0->1
	signal hit_down_1, hit_down_0, hit_up_1, hit_up_0 		: std_logic;
	signal clr_tmp, en_tmp 									: std_logic;
	signal count_tmp 										: unsigned (6 downto 0);
	-- counter num_of_bit * 24 bit signal
	signal hit_bits_sent 									: std_logic;
	signal clr_bits_sent, en_bits_sent						: std_logic;
	signal count_bits_sent 									: unsigned (10 downto 0); -- EDIT IF the number of the used LEDs is greater than 85 LEDs
	-- counter rst time
	signal hit_rst 											: std_logic;
	signal clr_rst, en_rst 									: std_logic;
	signal count_rst										: unsigned (15 downto 0);
	-- shifter register
	signal load, shift 										: std_logic;
	signal s_value 											: std_logic;
	signal reg 												: unsigned ((num_of_led * 24 - 1) downto 0);
	-- "Send data to LED" finite states machine
	type estado2 is (IDLE2, START, INIT, UP0, UP1, DOWN0, DOWN1, SH, RST_CODE);
		signal state2, state2_nxt : estado2;
	
		-- definition of the type array
	type color_array_t is array (1 to num_of_led) of std_logic_vector(23 downto 0);	-- define a color array type for 60 LED strip
	type en_led_array_t is array (1 to num_of_led + 1) of std_logic;				-- define the en_led in input and output for each fading block

	-- declaration of the signals with their type
	signal en_led_array								: en_led_array_t;
	signal en_led_array_blue						: en_led_array_t;
	signal en_led_array_red							: en_led_array_t;
	signal en_led_array_green						: en_led_array_t;
	signal color_array						: color_array_t;
		

	signal color 			: std_logic_vector ((num_of_led * 24 - 1) downto 0); 

component LED_FADING_BLOCK is
	port (
		ck   	: in std_logic;
		reset 	: in std_logic;
		en_led 	: in std_logic;

		color		: out std_logic_vector(23 downto 0);
		en_next_led	: out std_logic
	);
end component;	

component LED_FADING_ON_OFF is
	port (
	ck	     	: in std_logic;
    reset   	: in std_logic;
    en_led_blue 		: in std_logic;
	en_led_green 		: in std_logic;
	en_led_red 			: in std_logic;

    color		: out std_logic_vector (23 downto 0);
	en_next_led_blue	: out std_logic;
	en_next_led_green	: out std_logic;
	en_next_led_red	: out std_logic
		
	);
end component;

begin
---------------------------------------------------
-- COMMENT/DECOMMENT IF YOU WANT TO USE/NOT USE ---
---------------------------------------------------
-- gen_FADING_LEDS : for i in 1 to num_of_led generate
-- 	LED_FADING_BLOCK_inst : LED_FADING_BLOCK
-- 	port map (
-- 		ck   		=> ck,
-- 		reset 		=> reset,
-- 		en_led 		=> en_led_array(i),
--
-- 		color		=> color_array(i),
-- 		en_next_led	=> en_led_array(i+1)
-- 	);
--
-- end generate gen_FADING_LEDS;
--
-- en_led_array(1) <= btn2;	-- initialize the first en_led
----------------------------------------------------------
----------------------------------------------------------

---------------------------------------------------
-- COMMENT/DECOMMENT IF YOU WANT TO USE/NOT USE ---
-----------------------------------------------
gen_FADING_ON_OFF_LEDS : for i in 1 to num_of_led generate
	LED_FADING_ON_OFF_inst : LED_FADING_ON_OFF
	port map (
		ck   		=> ck,
		reset 		=> reset,
		en_led_blue 		=> en_led_array_blue(i),
		en_led_green 		=> en_led_array_green(i),
		en_led_red 			=> en_led_array_red(i),

		color				=> color_array(i),
		en_next_led_blue	=> en_led_array_blue(i+1),
		en_next_led_green	=> en_led_array_green(i+1),
		en_next_led_red		=> en_led_array_red(i+1)
	);

end generate gen_FADING_ON_OFF_LEDS;

en_led_array_blue(1) <= btn1;	
en_led_array_red(1) <= btn2;
en_led_array_green(1) <= btn3;
--------------------------------------------------
--------------------------------------------------

----------- COUNTER SINGLE SIGNAL (1 -> 0 cycle) --------	
COUNTER_PERIOD : process (ck, reset)						
	begin													
		if (reset = '1') then								
				count_tmp <= (others => '0');
		elsif (ck'event and ck = '1') then
				if (clr_tmp = '1') then
						count_tmp <= (others => '0');	
				elsif (en_tmp = '1') then
						if (count_tmp < tot_count_tmp - 1) then  
								count_tmp <= count_tmp + 1;	
						else
								count_tmp <= (others => '0');
						end if;																	
				end if;
		end if;
end process;
		
RC_COUNTER_PERIOD : process (count_tmp)				-- at time_up0 	=> hit_up_0 = 1
	begin											-- at time_up1  => hit_up_1 = 1
		if (count_tmp < tot_count_tmp - 1) then		-- at time_max 	=> hit_down_0, hit_down_1 = 1
				if (count_tmp = time_up0 - 1) then	-- I use a single counter to drive the system counting part
						hit_down_1 		<= '0';
						hit_up_1 		<= '0';
						hit_down_0 		<= '0';
						hit_up_0 		<= '1';
				elsif (count_tmp = time_up1 - 1) then	
						hit_down_1 		<= '0';
						hit_up_1		<= '1';
						hit_down_0		<= '0';
						hit_up_0 		<= '0';	
				else
						hit_down_1 		<= '0';									
						hit_up_1 		<= '0';
						hit_down_0 		<= '0';
						hit_up_0 		<= '0';
				end if;	
		else
				hit_down_1 <= '1';									
				hit_up_1 <= '0';
				hit_down_0 <= '1';
				hit_up_0 <= '0';
		end if;
					
end process;
									

	----------- COUNTER SINGLE SIGNAL (24 BIT) --------		
COUNTER_NUM_BIT_SENT : process (ck, reset)				-- this module gives a hit_24 = 1 when the 24bits have been sent.
	begin
		if (reset = '1') then
			count_bits_sent <= (others => '0');
		elsif (ck'event and ck = '1') then
			if (clr_bits_sent = '1') then
					count_bits_sent <= (others => '0');
			elsif (en_bits_sent = '1') then
					if (count_bits_sent < tot_count_bits_sent - 1) then
							count_bits_sent <= count_bits_sent + 1;			
					else
							count_bits_sent <= (others => '0');	
					end if;
			end if;
		end if;
end process;	
		
RC_COUNTER_24_BIT : process (count_bits_sent)
	begin
		if (count_bits_sent = tot_count_bits_sent - 1) then
			hit_bits_sent <= '1';	
		else
			hit_bits_sent <= '0';
		end if;
end process;
							
	----------- COUNTER SINGLE SIGNAL (50 us) --------					
COUNTER_RESET_TIME : process (ck, reset)	-- this module counts how long should stay in the RST_CODE state
	begin
		if (reset = '1') then
			count_rst <= (others => '0');
		elsif (ck'event and ck = '1') then
			if (clr_rst = '1') then
					count_rst <= (others => '0');
			elsif (en_rst = '1') then
				if (count_rst = tot_count_rst - 1) then
					count_rst <= (others => '0');
					hit_rst <= '1';
				else
					count_rst <= count_rst + 1;
					hit_rst <= '0';
				end if;
			end if;
		end if;
end process;

--------------- MIXER COLOR ----------------
 MIXER_COLOR : process (color_array)	-- you have to change this block manually 
begin									-- to have the same width of the num_of_led
    color <= 							-- 
			color_array(60) & 
			color_array(59) &
			color_array(58) & 
			color_array(57) & 
			color_array(56) &
            color_array(55) & 
			color_array(54) & 
			color_array(53) & 
			color_array(52) & 
			color_array(51) &
            color_array(50) & 
			color_array(49) & 
			color_array(48) & 
			color_array(47) & 
			color_array(46) &
            color_array(45) & 
			color_array(44) & 
			color_array(43) & 
			color_array(42) & 
			color_array(41) &
            color_array(40) & 
			color_array(39) & 
			color_array(38) & 
			color_array(37) & 
			color_array(36) &
            color_array(35) & 
			color_array(34) & 
			color_array(33) & 
			color_array(32) & 
			color_array(31) &
            color_array(30) & 
			color_array(29) & 
			color_array(28) & 
			color_array(27) & 
			color_array(26) &
            color_array(25) & 
			color_array(24) & 
			color_array(23) & 
			color_array(22) & 
			color_array(21) &
			color_array(20) & 
			color_array(19) & 
			color_array(18) & 
			color_array(17) & 
			color_array(16) &
            color_array(15) & 
			color_array(14) & 
			color_array(13) & 
			color_array(12) & 
			color_array(11) &
          	color_array(10) & 
			color_array(9)  & 
			color_array(8)  & 
			color_array(7)  & 
			color_array(6)  &
            color_array(5)  & 
			color_array(4)  & 
			color_array(3)  & 
			color_array(2)  & 
			color_array(1);
end process;

--MIXER_COLOR : process(color_array)
--    variable temp_color : std_logic_vector((num_of_led * 24) - 1 downto 0);
--begin
--    for i in 1 to num_of_led loop
--        temp_color((i * 24) - 1 downto (i - 1) * 24) := color_array(i);
--    end loop;
--    color <= temp_color;
--end process;

	------------- SHIFTER REGISTER ------	
SHIFT_REGISTER : process (ck, reset)	-- a simple shift register that sets the leftmost 
	begin								-- bits to 0 and provides the LSB as output to s_value
		if (reset = '1') then
			reg <= (others => '0');
		elsif (ck'event and ck = '1') then		
			if (load = '1') then	
				reg <= unsigned (color);
			elsif (shift = '1') then
				reg <= ('0' & reg ((num_of_led * 24 - 1) downto 1));		
			end if;
		end if;
end process;

s_value <= std_logic(reg(0)); -- s_value represent the bit I am current extracting (the LSB)
							  -- from the 24 bit "color" signal transmitted to turn on the LED

	------------ "Send data to LED" finite states machine ------
FSM : process (ck, reset)	-- this FSM leads the 24 bits stream as
begin						-- the protocol of WS2812 LED want
	if (reset = '1') then
		state2 <= IDLE2;
	elsif (ck'event and ck = '1') then
		state2 <= state2_nxt;
	end if;
end process;

RC_FSM : process (state2, s_value, hit_up_1, hit_up_0, hit_down_0, hit_down_1, hit_bits_sent, hit_rst)    -- driven just by SWITCH signal
begin
	case state2 is
		when IDLE2 => 
					state2_nxt <= INIT;	
		when INIT => 
					state2_nxt <= START;
		when START => 
					if (s_value = '1') then
						state2_nxt <= UP1;
					else
						state2_nxt <= UP0;
					end if;	
		when UP1 =>				
					if (hit_up_1 = '1') then
						state2_nxt <= DOWN1;
					else
						state2_nxt <= UP1;
					end if;			
		when DOWN1 =>
					if (hit_down_1 = '1') then
						state2_nxt <= SH;
					else
						state2_nxt <= DOWN1;
					end if;			
		when UP0 =>
					if (hit_up_0 = '1') then
						state2_nxt <= DOWN0;
					else
						state2_nxt <= UP0;
					end if;					
		when DOWN0 =>
					if (hit_down_0 = '1') then
						state2_nxt <= SH;
					else
						state2_nxt <= DOWN0;
					end if;			
		when SH =>
					if (hit_bits_sent = '1') then
						state2_nxt <= RST_CODE;
					else
						state2_nxt <= START;
					end if;				
		when RST_CODE =>
					if (hit_rst = '1') then
						state2_nxt <= INIT;
					else
						state2_nxt <= RST_CODE;
					end if;
					
		when others =>	
					state2_nxt <= IDLE2;
	end case;
	
end process;
									
RC_FSM_OUTPUTS : process (state2)
begin
	case state2 is
		when IDLE2 => 
						load 			<= '0';  
						shift			<= '0';
						clr_tmp 		<= '0';
						en_tmp 			<= '0';
						clr_bits_sent 	<= '0';
						en_bits_sent 	<= '0';
						clr_rst 			<= '1'; -- clr_rst
						en_rst 			<= '0';
						s_out 			<= '0';
		when INIT => 
						load 				<= '1';	-- load
						shift 			<= '0';
						clr_tmp				<= '1';	-- clr_tmp
						en_tmp 			<= '0';
						clr_bits_sent		<= '1';	-- clr_24
						en_bits_sent 	<= '0';
						clr_rst				<= '1';	-- clr_rst
						en_rst 			<= '0';
						s_out 			<= '0';
		when START => 
						load 			<= '0'; 
						shift 			<= '0'; 
						clr_tmp 		<= '0';
						en_tmp 			<= '0';  
						clr_bits_sent 	<= '0';
						en_bits_sent 	<= '0';  
						clr_rst 			<= '1';	-- clr_rst
						en_rst 			<= '0';
						s_out 			<= '0';
		when UP1 => 
						load 			<= '0';
						shift			<= '0';
						clr_tmp 		<= '0';
						en_tmp 				<= '1';	-- en_tmp
						clr_bits_sent 	<= '0';
						en_bits_sent 	<= '0';
						clr_rst 		<= '0';
						en_rst 			<= '0';
						s_out 				<= '1';  -- s_out
		when DOWN1 => 
						load 			<= '0';
						shift 			<= '0';
						clr_tmp 		<= '0';
						en_tmp 				<= '1';	-- en_tmp
						clr_bits_sent 	<= '0';
						en_bits_sent 	<= '0';
						clr_rst 		<= '0';
						en_rst 			<= '0';
						s_out 			<= '0';
		when UP0 => 
						load 			<= '0';
						shift 			<= '0';  
						clr_tmp 		<= '0';
						en_tmp 				<= '1';	-- en_tmp
						clr_bits_sent 	<= '0';
						en_bits_sent 	<= '0';
						clr_rst 		<= '0';
						en_rst 			<= '0';
						s_out 				<= '1';  --s_out	
		when DOWN0 => 
						load 			<= '0';
						shift 			<= '0';
						clr_tmp 		<= '0';
						en_tmp 				<= '1';	-- en_tmp
						clr_bits_sent 	<= '0';
						en_bits_sent 	<= '0';
						clr_rst 		<= '0';
						en_rst 			<= '0';
						s_out 			<= '0';
		when SH => 
						load 			<= '0';
						shift				<= '1';	-- shift
						clr_tmp 		<= '0'; 
						en_tmp 			<= '0';
						clr_bits_sent 	<= '0';
						en_bits_sent 		<= '1'; -- en_24
						clr_rst 		<= '0';
						en_rst 			<= '0';
						s_out 			<= '0';
		when RST_CODE => 
						load 			<= '0';
						shift 			<= '0';
						clr_tmp 		<= '0';
						en_tmp 			<= '0';
						clr_bits_sent 	<= '0';
						en_bits_sent 	<= '0';
						clr_rst 		<= '0';
						en_rst 				<= '1';	--en_50
						s_out 			<= '0';	
						
		when others =>              -- clear all	
						load 			<= '0';
						shift 			<= '0';
						clr_tmp 			<= '1';	-- clr_tmp
						en_tmp 			<= '0';
						clr_bits_sent 		<= '1';	-- clr_24
						en_bits_sent 	<= '0';  
						clr_rst 			<= '1';	-- clr_rst
						en_rst 			<= '0';
						s_out 			<= '0';				
	end case;
end process;							

end Behavioral;
