classdef Laser
    %Laser Matlab class for turning laser on and off    
    properties
        sp;
        debug_mode;
    end
    
    methods
        function laser = Laser(port)
            if (strcmp(port, 'DEBUG'))
                laser.debug_mode = 1;
            else
                laser.debug_mode = 0;
                laser.sp = serial(port, 'BaudRate', 19200, 'FlowControl', 'none', 'Terminator', 'CR/LF', 'Timeout', 1);
                fopen(laser.sp);
            end
            
        end
        
        function delete(laser)
            if ~laser.debug_mode
               disp('Laser destroyed')
               fclose(laser.sp);
            end
        end
        
        function on(laser)
            if ~laser.debug_mode
                fprintf(laser.sp, '%s\n', 'SSSD 1'); 
            end
        end
        
        function off(laser)
            if ~laser.debug_mode
                fprintf(laser.sp, '%s\n', 'SSSD 0');
            end
        end
        
    end
    
end

