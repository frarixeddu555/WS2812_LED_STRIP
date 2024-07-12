library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LED_FADING_ROULETTE is                   -- THIS MODULE IS NOT COMPLETED. We would the behaviour of a roulette.
    port (                                      -- The idea is to reduce the "velocity" of the "ball" each 4 pixel.
        ck      	: in std_logic;             -- I would use counters that count a certain fixed time for each state  
        reset   	: in std_logic;             -- until the ball stops.
        en_led 		: in std_logic;             -- An FSM will control the correct sequence of outputs/inputs this control signals

        color		: out std_logic_vector (23 downto 0);
		en_next_led	: out std_logic
    );
end LED_FADING_ROULETTE;

architecture Behavioral of LED_FADING_ROULETTE is

    constant tot_count_10ms  : integer := 500000;   -- first 4 pixel will last 10ms
    constant tot_count_15ms  : integer := 750000;   -- next 4 pixel will last 15 ms
    constant tot_count_20ms  : integer := 1000000;  -- next 4 pixel will last 20 ms
    constant tot_count_30ms  : integer := 1500000;
    constant tot_count_50ms  : integer := 2500000;
    constant tot_count_100ms : integer := 5000000;
    constant tot_count_200ms : integer := 10000000;
    constant tot_count_500ms : integer := 25000000;
    constant tot_count_1s    : integer := 50000000; -- next 3 pixel will last 1sec and
                                                    -- I'd like the ball remained in the
                                                    -- last pixel for an undefined time

    signal count_10ms  : unsigned(18 downto 0);  -- 19 bit per rappresentare 500000
    signal count_15ms  : unsigned(19 downto 0);  -- 20 bit per rappresentare 750000
    signal count_20ms  : unsigned(19 downto 0);  -- 20 bit per rappresentare 1000000
    signal count_30ms  : unsigned(20 downto 0);  -- 21 bit per rappresentare 1500000
    signal count_50ms  : unsigned(21 downto 0);  -- 22 bit per rappresentare 2500000
    signal count_100ms : unsigned(22 downto 0);  -- 23 bit per rappresentare 5000000
    signal count_200ms : unsigned(23 downto 0);  -- 24 bit per rappresentare 10000000
    signal count_500ms : unsigned(24 downto 0);  -- 25 bit per rappresentare 25000000
    signal count_1s    : unsigned(25 downto 0);  -- 26 bit per rappresentare 50000000

    signal en_10ms  : std_logic;
    signal en_15ms  : std_logic;
    signal en_20ms  : std_logic;
    signal en_30ms  : std_logic;
    signal en_50ms  : std_logic;
    signal en_100ms : std_logic;
    signal en_200ms : std_logic;
    signal en_500ms : std_logic;
    signal en_1s    : std_logic;

    signal hit_count_10ms  : std_logic;
    signal hit_count_15ms  : std_logic;
    signal hit_count_20ms  : std_logic;
    signal hit_count_30ms  : std_logic;
    signal hit_count_50ms  : std_logic;
    signal hit_count_100ms : std_logic;
    signal hit_count_200ms : std_logic;
    signal hit_count_500ms : std_logic;
    signal hit_count_1s    : std_logic;

    signal count_hit_10ms  : unsigned(2 downto 0);
    signal count_hit_15ms  : unsigned(2 downto 0);
    signal count_hit_20ms  : unsigned(2 downto 0);
    signal count_hit_30ms  : unsigned(2 downto 0);
    signal count_hit_50ms  : unsigned(2 downto 0);
    signal count_hit_100ms : unsigned(2 downto 0);
    signal count_hit_200ms : unsigned(2 downto 0);
    signal count_hit_500ms : unsigned(2 downto 0);
    signal count_hit_1s    : unsigned(2 downto 0);

    signal hit_10ms  : std_logic;
    signal hit_15ms  : std_logic;
    signal hit_20ms  : std_logic;
    signal hit_30ms  : std_logic;
    signal hit_50ms  : std_logic;
    signal hit_100ms : std_logic;
    signal hit_200ms : std_logic;
    signal hit_500ms : std_logic;
    signal hit_1s    : std_logic;
	-- Frequency divisor 
	signal cnt_div  													: unsigned (21 downto 0);
	signal ck_en 														: std_logic;
	-- Operations flip -> add/odd -> flip registers
	signal blue_aux, red_aux, green_aux 								: unsigned (7 downto 0);
	signal blue, red, green 											: unsigned (7 downto 0);
	
	-- "Fade color" Finite State machine
	signal en_count_blue, en_count_red, en_count_green					: std_logic;
	signal inc, dec														: std_logic;
	type estado1 is (IDLE1, INC_GREEN, DEC_GREEN, INC_RED, DEC_RED, INC_BLUE, DEC_BLUE, DEC2);
		signal state1, state1_nxt : estado1;
    -- decoder

begin

--- FREQUENCY DIVISOR -----
FREQ_DIV : process (ck, reset)	-- this process outputs ck_en to drive changing of brightness of the chose color
	begin
		if (reset = '1') then
				
			cnt_div <= (others => '0');
			ck_en <= '0';
		
		elsif (ck'event and ck = '1') then
			if (cnt_div < 124999) then		-- The frequency for the LED must be > 400 Hz
				cnt_div <= cnt_div + 1;
				ck_en <= '0';
					
			else
				cnt_div <= (others => '0');
				ck_en <= '1';				-- When ck_en = '1', LED assume the current color
			end if;
		end if;
end process;
			

----- FADING AUX  ------  -- flip and add/odd an offset to the color chose by the sequence of the FSM
FLIP_ADD_ODD_AUX : process (ck, reset) 
begin
	if (reset = '1') then
		green_aux 		<= (others => '0');
		red_aux 		<= (others => '0');
		blue_aux 		<= (others => '0');
	elsif (ck'event and ck = '1') then
		if (ck_en = '1') then
			if (en_count_blue = '1') then		-- en_count_xxxxx signal is generated by the FSM and selects what 8 bit's group must change
				if (inc = '1') then			
					blue_aux <=         		-- Put in an auxiliar signal the sum of blue flipped,
								(blue(0) &		--
								blue(1) &		--
								blue(2) &		--
								blue(3) &		--
								blue(4) &		--
								blue(5) &		--
								blue(6) &		--
								blue(7)) + 5 ;	-- plus an offset (to change the brightness)
				elsif (dec = '1') then
					blue_aux <= 
								(blue(0) &
								blue(1) &
								blue(2) &
								blue(3) &
								blue(4) & 
								blue(5) & 
								blue(6) &
								blue(7)) - 5 ;
				end if;
			elsif (en_count_red = '1') then
				if (inc = '1') then	
					red_aux <= 
								(red(0) &
								red(1) &
								red(2) &
								red(3) &
								red(4) &
								red(5) &
								red(6) &
								red(7)) + 5 ;
				elsif (dec = '1') then
					red_aux <= 
								(red(0) &
								red(1) &
								red(2) &
								red(3) &
								red(4) & 
								red(5) & 
								red(6) &
								red(7)) - 5 ;
				end if;
			elsif (en_count_green = '1') then
				if (inc = '1') then	
					green_aux <= 
								(green(0) &
								green(1) &
								green(2) &
								green(3) &
								green(4) &
								green(5) &
								green(6) &
								green(7)) + 5 ;
				elsif (dec = '1') then
					green_aux <= 
								(green(0) &
								green(1) &
								green(2) &
								green(3) &
								green(4) & 
								green(5) & 
								green(6) &
								green(7)) - 5 ;
				end if;
			end if;
		end if;
	end if;						

end process;
		
------ FADING -----					-- this with the previous process complete the "flip -> add/odd -> flip" function
FLIP_ADD_ODD : process (ck, reset)	-- we want to realize. In particular, this process gets the final reverse operation 
	begin							-- and outputs the color signal.	
		if (reset = '1') then					-- This operation is necessary to respect
			color 	<= (others => '0');			-- the correct order of the bits to send to the LED.
			green 	<= (others => '0');			-- G R B = 7654321_7654321_7654321 where the
			red 	<= (others => '0');			-- rightmost bit of each 8 bit (of each color)
			blue 	<= (others => '0');			-- drive the highest brightness, the leftmost 
		elsif (ck'event and ck = '1') then		-- the lowest one.
			blue 			
					<= blue_aux(0) &
						blue_aux(1) & 
						blue_aux(2) & 
						blue_aux(3) & 
						blue_aux(4) & 
						blue_aux(5) & 
						blue_aux(6) & 
						blue_aux(7);  
			red 			
					<= red_aux(0) &
						red_aux(1) & 
						red_aux(2) & 
						red_aux(3) & 
						red_aux(4) & 
						red_aux(5) & 
						red_aux(6) & 
						red_aux(7);
			green			
					<= green_aux(0) &
						green_aux(1) & 
						green_aux(2) & 
						green_aux(3) & 
						green_aux(4) & 
						green_aux(5) & 
						green_aux(6) & 
						green_aux(7);
		end if;							
		color <= std_logic_vector(blue & red & green);  -- color [23:0] signal
end process;
	

COUNTER_10ms : process (ck, reset)
begin
    if (reset = '1') then
        count_10ms <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_10ms = '1') then
            if (count_10ms < tot_count_10ms) then
                count_10ms <= count_10ms + 1;
                hit_count_10ms <= '0';
            else
                count_10ms <= (others => '0');
                hit_count_10ms <= '1';
            end if;
        end if;
    end if;
end process;

COUNTER_15ms : process (ck, reset)
begin
    if (reset = '1') then
        count_15ms <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_15ms = '1') then
            if (count_15ms < tot_count_15ms) then
                count_15ms <= count_15ms + 1;
                hit_count_15ms <= '0';
            else
                count_15ms <= (others => '0');
                hit_count_15ms <= '1';
            end if;
        end if;
    end if;
end process;

COUNTER_20ms : process (ck, reset)
begin
    if (reset = '1') then
        count_20ms <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_20ms = '1') then
            if (count_20ms < tot_count_20ms) then
                count_20ms <= count_20ms + 1;
                hit_count_20ms <= '0';
            else
                count_20ms <= (others => '0');
                hit_count_20ms <= '1';
            end if;
        end if;
    end if;
end process;

COUNTER_30ms : process (ck, reset)
begin
    if (reset = '1') then
        count_30ms <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_30ms = '1') then
            if (count_30ms < tot_count_30ms) then
                count_30ms <= count_30ms + 1;
                hit_count_30ms <= '0';
            else
                count_30ms <= (others => '0');
                hit_count_30ms <= '1';
            end if;
        end if;
    end if;
end process;

COUNTER_50ms : process (ck, reset)
begin
    if (reset = '1') then
        count_50ms <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_50ms = '1') then
            if (count_50ms < tot_count_50ms) then
                count_50ms <= count_50ms + 1;
                hit_count_50ms <= '0';
            else
                count_50ms <= (others => '0');
                hit_count_50ms <= '1';
            end if;
        end if;
    end if;
end process;

COUNTER_100ms : process (ck, reset)
begin
    if (reset = '1') then
        count_100ms <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_100ms = '1') then
            if (count_100ms < tot_count_100ms) then
                count_100ms <= count_100ms + 1;
                hit_count_100ms <= '0';
            else
                count_100ms <= (others => '0');
                hit_count_100ms <= '1';
            end if;
        end if;
    end if;
end process;

COUNTER_200ms : process (ck, reset)
begin
    if (reset = '1') then
        count_200ms <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_200ms = '1') then
            if (count_200ms < tot_count_200ms) then
                count_200ms <= count_200ms + 1;
                hit_count_200ms <= '0';
            else
                count_200ms <= (others => '0');
                hit_count_200ms <= '1';
            end if;
        end if;
    end if;
end process;

COUNTER_500ms : process (ck, reset)
begin
    if (reset = '1') then
        count_500ms <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_500ms = '1') then
            if (count_500ms < tot_count_500ms) then
                count_500ms <= count_500ms + 1;
                hit_count_500ms <= '0';
            else
                count_500ms <= (others => '0');
                hit_count_500ms <= '1';
            end if;
        end if;
    end if;
end process;

COUNTER_1s : process (ck, reset)
begin
    if (reset = '1') then
        count_1s <= (others => '0');
    elsif (ck'event and ck = '1') then
        if (en_1s = '1') then
            if (count_1s < tot_count_1s) then
                count_1s <= count_1s + 1;
                hit_count_1s <= '0';
            else
                count_1s <= (others => '0');
                hit_count_1s <= '1';
            end if;
        end if;
    end if;
end process;

GEN_HIT_10ms : process (hit_count_10ms)
begin
    if (count_hit_10ms < 4) then
        count_hit_10ms <= count_hit_10ms + 1;
        hit_10ms <= '0';
    else
        count_hit_10ms <= (others => '0');
        hit_10ms <= '1';
    end if;
end process;

GEN_HIT_15ms : process (hit_count_15ms)
begin
    if (count_hit_15ms < 4) then
        count_hit_15ms <= count_hit_15ms + 1;
        hit_15ms <= '0';
    else
        count_hit_15ms <= (others => '0');
        hit_15ms <= '1';
    end if;
end process;

GEN_HIT_20ms : process (hit_count_20ms)
begin
    if (count_hit_20ms < 4) then
        count_hit_20ms <= count_hit_20ms + 1;
        hit_20ms <= '0';
    else
        count_hit_20ms <= (others => '0');
        hit_20ms <= '1';
    end if;
end process;

GEN_HIT_30ms : process (hit_count_30ms)
begin
    if (count_hit_30ms < 4) then
        count_hit_30ms <= count_hit_30ms + 1;
        hit_30ms <= '0';
    else
        count_hit_30ms <= (others => '0');
        hit_30ms <= '1';
    end if;
end process;

GEN_HIT_50ms : process (hit_count_50ms)
begin
    if (count_hit_50ms < 4) then
        count_hit_50ms <= count_hit_50ms + 1;
        hit_50ms <= '0';
    else
        count_hit_50ms <= (others => '0');
        hit_50ms <= '1';
    end if;
end process;

GEN_HIT_100ms : process (hit_count_100ms)
begin
    if (count_hit_100ms < 4) then
        count_hit_100ms <= count_hit_100ms + 1;
        hit_100ms <= '0';
    else
        count_hit_100ms <= (others => '0');
        hit_100ms <= '1';
    end if;
end process;

GEN_HIT_200ms : process (hit_count_200ms)
begin
    if (count_hit_200ms < 4) then
        count_hit_200ms <= count_hit_200ms + 1;
        hit_200ms <= '0';
    else
        count_hit_200ms <= (others => '0');
        hit_200ms <= '1';
    end if;
end process;

GEN_HIT_500ms : process (hit_count_500ms)
begin
    if (count_hit_500ms < 4) then
        count_hit_500ms <= count_hit_500ms + 1;
        hit_500ms <= '0';
    else
        count_hit_500ms <= (others => '0');
        hit_500ms <= '1';
    end if;
end process;

GEN_HIT_1s : process (hit_count_1s)
begin
    if (count_hit_1s < 4) then
        count_hit_1s <= count_hit_1s + 1;
        hit_1s <= '0';
    else
        count_hit_1s <= (others => '0');
        hit_1s <= '1';
    end if;
end process;




----- FIRST Finite State Machine to control LED fading
	
FADE_LED_FSM : process (ck, reset)  			
	begin										
		if (reset = '1') then					
			state1 <= IDLE1;
		elsif (ck'event and ck = '1') then
			state1 <= state1_nxt;
		end if;
end process;
						
process (blue, red, green, state1, en_led)
	begin
		case state1 is			
			when IDLE1 =>
				if (en_led = '1') then			
					state1_nxt <= INC_RED;	
				else							 
					state1_nxt <= IDLE1;		
				end if;		
			when INC_RED =>					-- starts from state1 = x"FF00FF"
				if (red = "11111111") then
					state1_nxt <= DEC_RED;
				else
					state1_nxt <= INC_RED;
				end if;

			when DEC_RED =>				
				if (red = "00000000") then
					state1_nxt <= IDLE1;
				else
					state1_nxt <= DEC_RED;
				end if;
								
			when others => 
				state1_nxt <= IDLE1;
		end case;
end process;
								
process (state1)
	begin
		
		case state1 is
			when IDLE1 =>            
					inc       		    <= '0';
					dec       		    <= '0';
					en_count_blue 		<= '0';
					en_count_red 		<= '0';
					en_count_green 		<= '0';
					en_next_led 	    <= '0';
			when INC_RED =>				
					inc       		    <= '1';
					dec       		    <= '0';
					en_count_blue 		<= '0';
					en_count_red 		<= '1';
					en_count_green 		<= '0';
					en_next_led 	    <= '0';
					if (red = "11111111") then
						en_next_led <= '1';	-- The first time the color green is reached,
					else					-- an enable that allows at the next led to
						en_next_led <= '0';	-- start fading is generated
					end if;  
			when DEC_RED =>				
					inc       		    <= '0';
					dec       		    <= '1';
					en_count_blue 		<= '0';
					en_count_red 		<= '1';
					en_count_green 		<= '0';
					en_next_led 	    <= '0';
			
				 
			when others => 
					inc       		    <= '0';
					dec       		    <= '0';
					en_count_blue 		<= '0';
					en_count_red 		<= '0';
					en_count_green 		<= '0';
					en_next_led 	    <= '0';
		end case;
end process;

end Behavioral;
