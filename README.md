# WS2812_VHDL_STRIP
A project that drives a RGB WS2812 LED STRIP.

For this project we used a ZedBoard FPGA with a f=100MHz since Spartan-3 FPGA presented trouble controlling a 60 LED strip. 
Main code was taken from WS2812 single LED project https://github.com/frarixeddu555/WS2812_LED.

Two controlling modes (+ one) are available:
- "FADING_ON_OFF_LEDS" activates each led (with the color you want among blue, green or red) on the strip one at a time with a certain speed.
You can attend such a "shot effect".
- "FADING_LEDS" in which the entire strip is, on LED at time, fully illuminated by 16 millions colors provided by the 8bit resolution for each color.
- "LED FADING ROULETTE" is not completed. I would have liked realize a "roulette effect" where we can attend the moving of a "fading COLOR ball" that decreasing its speed until it stopped.  
