classdef Stepper < handle
    %Stepper A class for connecting to a stepper motor
    %   Detailed explanation goes here
    
    properties
        initial_velocity = 56; %the minumum
        ramp  = [8 8];
        velocity %600 is good max speed assuming divide by 4
        settle_delay
        divide = 4;
        port_status
        position
        debug_mode

        low_wl = -13.5;   %old -12.5?
        high_wl =  801.5; %old 802.5
        MAX_V = 150*4;
        
        wlPerStep  = 0.1248;
        s_serial;
        
    end
    
    methods
        
        function SM = Stepper(port)
            if (strcmp(port, 'DEBUG'))
                SM.debug_mode = 1;
            else
                SM.debug_mode = 0;
                SM.s_serial = serial(port, 'BaudRate', 9600, 'FlowControl', 'none', 'Terminator', 10, 'Timeout', 1);
                set(SM.s_serial, 'InputBufferSize', 512);
                fopen(SM.s_serial);
            
                SM.reset()
                while(~isempty(Stepper.get_serial(SM.s_serial)))
                end
                SM.set_ports();
    %            SM.invert_limits();
                SM.set_divide(SM.divide);
                SM.set_ramp(SM.ramp(1), SM.ramp(2));
                SM.set_velocity(SM.MAX_V);
                SM.set_initial_velocity(SM.initial_velocity);
            end
        end
        
        function delete(SM)
           disp('destructor')
           if ~SM.debug_mode
               SM.set_off();
               fclose(SM.s_serial);
           end
        end
        
        function reset(SM)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, 3);
                pause(1);
                SM.write_chars(SM.s_serial, ' ');
            end
        end
        
        %Physical parameters
        function get_params(SM)
            if ~SM.debug_mode
                val = SM.write_chars(SM.s_serial, 'X');
                char(val)
            end
        end
        
        function set_ramp(SM, ir, fr)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, ['K', int2str(ir), ',', int2str(fr)]);
            end
        end
        
        function set_initial_velocity(SM, iv)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, ['I', int2str(iv)]);
            end
        end
        
        function set_divide(SM, d)
            if ~SM.debug_mode 
                SM.write_chars(SM.s_serial, ['D', int2str(d)]);
            end
        end
        function set_velocity(SM, vel)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, ['V', int2str(vel)]);
                SM.velocity = vel;
            end
        end
        
        function invert_limits(SM)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, 'l1');  %lower case L then number 1    
            end
        end

        %Basic I/O to monochromator
        function set_ports(SM)
            if ~SM.debug_mode
                val = SM.write_chars(SM.s_serial, 'A63');
            end
        end
        
        function set_off(SM)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, 'A0');
            end
        end
        
        function  get_ports(SM)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, 'A');
            end
        end
        
        function set_origin(SM)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, 'O');
            end
        end
        
        function update_position(SM)
            if ~SM.debug_mode
                val = SM.write_chars(SM.s_serial, 'Z');
                t = strfind(val, ' ');
                try
                s = t(numel(t));
                t = strfind(val, 13);
                e = t(1);
                SM.position = str2double(char(val(s+1:e-1)));
                catch

                end
            end
        end
        
        function move_to_position(SM, pos)
            if ~SM.debug_mode
                SM.write_chars(SM.s_serial, ['R', int2str(pos)]);
                moving = 1;
                while (moving)
                    pause(1);
                    moving = Stepper.get_moving_status(SM.s_serial);
                end
            end
        end
        
        function move_to_limit(SM, dir)
            if ~SM.debug_mode
                if(dir < -1 || dir > 1 || dir ==0)
                    dir = 1;
                end
                val = SM.write_chars(SM.s_serial, ['M', int2str(SM.velocity*dir)]);

                moving = 1;
                while (moving)
                    pause(1);
                    moving = Stepper.get_moving_status(SM.s_serial);
                end
            end
        end

        %Multi-step instructions
        function set_params()
            
        end
        
        function manual_calibrate(SM)
            if ~SM.debug_mode
                SM.set_off();
                disp('Move to 200 nm, then press any key.');
                pause();
                SM.set_ports();
                SM.set_origin();
                SM.update_position();
                SM.move_to_position(3000);
                while(Stepper.get_moving_status(SM.s_serial))
                end            
                finWL = input('Enter final wavelength: ');
                SM.update_position();
                SM.wlPerStep = (finWL - 200) / SM.position;
                SM.set_off();
            end
        end            
        
        function calibrate(SM)
            if ~SM.debug_mode
                SM.set_ports();
                old_v = SM.velocity;

                SM.move_to_limit(-1);
                SM.set_origin();
                SM.move_to_position(200);
                while(Stepper.get_moving_status(SM.s_serial))
                end
                SM.set_velocity(200);
                SM.move_to_limit(-1);
                SM.set_origin();
                SM.move_to_position(100);
                while(Stepper.get_moving_status(SM.s_serial))
                end
                SM.set_velocity(56);
                SM.move_to_limit(-1);

                SM.set_origin();

                SM.velocity = SM.MAX_V;

                SM.set_velocity(SM.velocity);
                SM.move_to_limit(1);
                SM.update_position();
                SM.move_to_position(SM.position - 200);
                while(Stepper.get_moving_status(SM.s_serial))
                end

                SM.set_velocity(200);
                SM.move_to_limit(1);
                SM.update_position();
                SM.move_to_position(SM.position - 100);
                while(Stepper.get_moving_status(SM.s_serial))
                end
                SM.set_velocity(56);
                SM.move_to_limit(1);

                SM.velocity = old_v;
                SM.set_velocity(SM.velocity);
                SM.update_position();
                SM.wlPerStep = (SM.high_wl - SM.low_wl) / SM.position;
                SM.set_off();
            end
        end
        
        function move_to_wl(SM,wl)
            if ~SM.debug_mode
                SM.set_ports();
                pause(0.1);
                SM.update_position();
                pause(0.1);
                %new_pos = (wl - SM.low_wl) / SM.wlPerStep;
                new_pos = (wl - 200) / SM.wlPerStep;
                SM.move_to_position(int32(round(new_pos)));
                SM.set_off();
            end
        end
        
    end
       
    methods (Static)
        function val = write_chars(serial_obj, chars)
            for i = 1:numel(chars) 
                fprintf(serial_obj, '%c', chars(i));
            end
            fprintf(serial_obj, '%c', 13);
            val = Stepper.get_serial(serial_obj);
        end
        
        function [val] = get_serial(serial_obj)
            tic;
            val = '';
            while(serial_obj.BytesAvailable == 0 && toc < 1)
            end
            
            if(toc > 1)
                return
            end
            
            val = fread(serial_obj, serial_obj.BytesAvailable, 'uchar');
            while(val(end) ~= 10 && toc < 1)
                while(serial_obj.BytesAvailable == 0 && toc < 1)
                end
                val = [val; fread(serial_obj, serial_obj.BytesAvailable, 'uchar')];
            end
            val = val';
        end
        
        function [val, lim] = get_limits(serial_obj)
            val = Stepper.write_chars(serial_obj, ']');
            t = strfind(val, ' ');
            s = t(numel(t));
            t = strfind(val, 13);
            e = t(1);
            lim = str2double(char(val(s+1:e-1)));
        end
        
        function mov = get_moving_status(serial_obj)
            val = Stepper.write_chars(serial_obj, '^');
            t = strfind(val, ' ');
            try
                s = t(numel(t));
                t = strfind(val, 13);
                e = t(1);
                mov = str2double(char(val(s+1:e-1)));
            catch
               %mov = 1; 
            end
        end
        
    end
    
end

