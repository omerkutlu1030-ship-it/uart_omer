library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all; 

package uart_pkg is
    constant OVERSAMPLE : integer := 16;

    function divisior_calculator (CLK_FREQ, baud : integer) return integer;
    

end package;

package body uart_pkg is
    
    function divisior_calculator (CLK_FREQ, baud : integer) return integer is
    begin
        -- ceil floor
        report "The Divisor Value of Baudrate " & 
                to_string(baud) & " is" 
                & to_string(integer(real(CLK_FREQ) / real (baud * OVERSAMPLE))); 
        return integer(real(CLK_FREQ) / real (baud * OVERSAMPLE));
    end function;

end package body;