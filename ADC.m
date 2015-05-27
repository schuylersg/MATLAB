classdef ADC < handle
    %ADC 
    %   Detailed explanation goes here
    
    properties
        dataCount
        numEventsToWaitFor = 0;
        cp;     %communication port
        wordSize = 1;
        eventDataSize; %the number of bytes in an event
        echoOn = 0;
        adcData;
        triggerOn = 0;
        errors = 0;
        tempData = [];
        statusBar;
    end
    
    events
       AllEventsCaptured 
    end
    
    methods
        %constructor
        function adc = ADC(port)
            adc.cp = serial(port, 'BaudRate', 2000000, 'FlowControl', 'none', 'Terminator', [], 'Timeout', 0.1);
            set(adc.cp, 'InputBufferSize', 2^24);
            set(adc.cp, 'BytesAvailableFcnMode', 'byte'); %Call callback on set number of bytes
            set(adc.cp, 'BytesAvailableFcnCount', 1);  %The number of bytes to generate a callback
            adc.cp.BytesAvailableFcn = {@adc.serialCallback, adc};
            adc.eventDataSize = 1018;   %this value is fixed for photon counting
            fopen(adc.cp);
            fprintf(adc.cp, '%c', 'E'); %Turn on character echo
            adc.dataCount = 0;
            adc.echoOn = 1; 
            fclose(adc.cp);
            adc.cp.BytesAvailableFcnCount = 2;
            fopen(adc.cp);
            adc.echo_off();
        end
        
        %destructor
        function delete(adc)
           disp('ADC destroyed')
           fclose(adc.cp); 
        end
        
        %Turn on ADC
        function adc_on(adc)
           fprintf(adc.cp, '%c', 'O');
        end
        
        %Turn off ADC
        function adc_off(adc)
           fprintf(adc.cp, '%c', 'o'); 
        end
        
        %Turn off character echo
        function echo_off(adc)
           if(adc.echoOn == 0)
               if(adc.cp.BytesAvailableFcnCount~=1)
                   fclose(adc.cp);
                   adc.cp.BytesAvailableFcnCount = 1;
                   fopen(adc.cp);
               end
               return
           end
           
           if(adc.cp.BytesAvailableFcnCount~=2)
                fclose(adc.cp);
                adc.cp.BytesAvailableFcnCount = 2;
                fopen(adc.cp);
           end
           fprintf(adc.cp, '%c', 'e');
           fclose(adc.cp);
           adc.cp.BytesAvailableFcnCount = 1;
           fopen(adc.cp);
           adc.echoOn = 0;
        end
        
        %Turn on character echo
        function echo_on(adc)
            if(adc.echoOn == 1)
                if(adc.cp.BytesAvailableFcnCount~=2)
                   fclose(adc.cp);
                   adc.cp.BytesAvailableFcnCount = 2;
                   fopen(adc.cp);
                end
                return
            end
            
            if(adc.cp.BytesAvailableFcnCount~=1)
                fclose(adc.cp);
                adc.cp.BytesAvailableFcnCount = 1;
                fopen(adc.cp);
            end
            fprintf(adc.cp, '%c', 'E');
            fclose(adc.cp);
            adc.cp.BytesAvailableFcnCount = 2;
            fopen(adc.cp);
            adc.echoOn = 1;
        end
        
        function calibrate(adc)
            if(adc.echoOn)
                if(adc.cp.BytesAvailableFcnCount~=2)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 2;
                    fopen(adc.cp);
                end
            else
                if(adc.cp.BytesAvailableFcnCount~=1)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 1;
                    fopen(adc.cp);
                end
            end
            fprintf(adc.cp, '%c', 'C');
        end
        
        %set the amount of time to collect data after a trigger
        function set_data_length(adc, val)
            disp('Data length fixed');
            return
            if(adc.echoOn)
                if(adc.cp.BytesAvailableFcnCount~=12)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 12;
                    fopen(adc.cp);
                end
            else
                if(adc.cp.BytesAvailableFcnCount~=1)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 1;
                    fopen(adc.cp);
                end
            end
            fprintf(adc.cp, '%c', 'M');
            adc.send_num2bin(adc.cp, val, 10);
            adc.eventDataSize = (val+2)*adc.wordSize*4 + 2 + adc.wordSize + adc.echoOn;
            adc.adcData = [];
        end
        
        function set_trig_voltage(adc, val)
            if(adc.echoOn)
                if(adc.cp.BytesAvailableFcnCount~=12)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 12;
                    fopen(adc.cp);
                end
            else
                if(adc.cp.BytesAvailableFcnCount~=1)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 1;
                    fopen(adc.cp);
                end
            end
            fprintf(adc.cp, '%c', 'V');
            adc.send_num2bin(adc.cp, val, 10);
        end
        
        function record_event(adc)
            if(adc.cp.BytesAvailableFcnCount ~= adc.eventDataSize)
                fclose(adc.cp);
                adc.cp.BytesAvailableFcnCount = adc.eventDataSize;
                fopen(adc.cp);
            end
            adc.numEventsToWaitFor = 1;
            adc.dataCount = 0;
            adc.adcData = zeros(adc.eventDataSize, adc.numEventsToWaitFor);
            fprintf(adc.cp, '%c', 'X');
        end
        
        function record_trig_event(adc)
            if(adc.cp.BytesAvailableFcnCount ~= adc.eventDataSize)
                fclose(adc.cp);
                adc.cp.BytesAvailableFcnCount = adc.eventDataSize;
                fopen(adc.cp);
            end

            adc.numEventsToWaitFor = 1;
            adc.dataCount = 0;
            adc.adcData = zeros(adc.eventDataSize, adc.numEventsToWaitFor);
            
            if(adc.triggerOn  == 1)
                fprintf(adc.cp, '%c', 'U');
            else
                fprintf(adc.cp, '%c', 'T');
                adc.triggerOn = 1;
            end
        end
        
        function trigger_on(adc)
            if(adc.echoOn)
                if(adc.cp.BytesAvailableFcnCount~=2)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 2;
                    fopen(adc.cp);
                end
            else
                if(adc.cp.BytesAvailableFcnCount~=1)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 1;
                    fopen(adc.cp);
                end
            end
            fprintf(adc.cp, '%c', 'T');
            adc.triggerOn = 1;
        end
        
        function trigger_off(adc)
            if(adc.echoOn)
                if(adc.cp.BytesAvailableFcnCount~=2)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 2;
                    fopen(adc.cp);
                end
            else
                if(adc.cp.BytesAvailableFcnCount~=1)
                    fclose(adc.cp);
                    adc.cp.BytesAvailableFcnCount = 1;
                    fopen(adc.cp);
                end
            end
            fprintf(adc.cp, '%c', 't');
            adc.triggerOn = 0;
        end
            
        function record_events(adc, num_events)
            if(adc.echoOn)
                adc.echo_off(); 
            end
            
            %if(~mod(adc.eventDataSize, 2))
            %    adc.eventDataSize = adc.eventDataSize - 1;
            %end
            if(adc.triggerOn)
                adc.trigger_off();
            end
            fprintf(adc.cp, '%c', 'B');
            pause(0.1);
            flushinput(adc.cp);
            if(adc.cp.BytesAvailableFcnCount ~= adc.eventDataSize*num_events ...
                    || adc.cp.InputBufferSize < adc.eventDataSize*num_events + 2^8)
                fclose(adc.cp);
                adc.cp.BytesAvailableFcnCount = adc.eventDataSize*num_events;
                set(adc.cp, 'InputBufferSize', adc.eventDataSize*num_events + 2^8);
                fopen(adc.cp);
            end
            adc.numEventsToWaitFor = num_events;
            adc.dataCount = 0;
            adc.errors = 0;
            adc.adcData = uint8(zeros(adc.eventDataSize, adc.numEventsToWaitFor));
            %adc.statusBar = waitbar(0, 'Gathering data');
            fprintf(adc.cp, '%c', 'T');
            pause(0.1);
            flushinput(adc.cp);
            %while(adc.numEventsToWaitFor > 0)
            %   waitbar(adc.cp.BytesAvailable/(adc.eventDataSize*num_events), ...
            %       adc.statusBar); 
            %   pause(2); 
            %end
            %close(adc.statusBar);
        end
        
    end
    methods(Static)
        function serialCallback(sp, event, obj)
           
           if(obj.numEventsToWaitFor == 0)
               if(sp.BytesAvailable > 0)
                   d = fread(sp, sp.BytesAvailable, 'uchar');
                   %disp(strcat('Bytes Received:', d'));
               else
                   d = [];
               end
           %Waiting to read in ADC capture events    
           else
               fprintf(sp, '%c', 't');
               fprintf(sp, '%c', 'b');
               if(sp.BytesAvailable > 0)
                   obj.adcData = reshape(fread(sp, sp.BytesAvailableFcnCount, 'uchar'), obj.eventDataSize, obj.numEventsToWaitFor);
               end
               %Case where we are done reading events
               %if(obj.dataCount >= obj.numEventsToWaitFor)
                   %fprintf(sp, '%c', 't');
                   %fprintf(sp, '%c', 'b');
               
               pause(0.1);
               while(sp.BytesAvailable > 0)
                   flushinput(sp);
                   pause(0.1);
               end
               obj.numEventsToWaitFor = 0;
               %disp('All Events Captured');
               notify(obj, 'AllEventsCaptured');
           end
        end
        
        function send_num2bin(sp, val, len)
            ch = dec2bin(val, len);
            for i = 1:numel(ch)
                fprintf(sp, '%c', ch(i));
            end
        end
    end
    
end



               %end
               
               
%                %while(sp.BytesAvailable >= sp.BytesAvailableFcnCount - numel(obj.tempData))
%                if(sp.BytesAvailable <1)
%                    return;
%                end
%                obj.tempData = cat(1, obj.tempData, fread(sp, sp.BytesAvailable, 'uchar'));
%                numEventsToRead = floor(numel(obj.tempData)/sp.BytesAvailableFcnCount); 
%                
%                i = 1;
%                while (i <= numEventsToRead)
%                    if(isequal(obj.tempData((i-1)*sp.BytesAvailableFcnCount+1:...
%                                            (i-1)*sp.BytesAvailableFcnCount+2),[128; 2]) ...
%                            && obj.tempData(i*sp.BytesAvailableFcnCount) == 1)
%                         obj.dataCount = obj.dataCount + 1;
%                         obj.adcData(:, obj.dataCount) = obj.tempData((i-1)*sp.BytesAvailableFcnCount+1:...
%                             i*sp.BytesAvailableFcnCount);
%                    else
%                        x = strfind(obj.tempData((i-1)*sp.BytesAvailableFcnCount+2, :)', [128 2]);
%                        obj.errors = obj.errors + 1;
%                        if(isempty(x))
%                            obj.tempData = [];
%                            numEventsToRead = 0;
%                        else
%                            obj.tempData = obj.tempData(x(1):end);
%                            i = i - 1;
%                            numEventsToRead = numEventsToRead - 1;
%                        end
%                    end
%                    i = i + 1; 
%                end
%                
%                if((i-1)*sp.BytesAvailableFcnCount < numel(obj.tempData))
%                    obj.tempData = obj.tempData((i-1)*sp.BytesAvailableFcnCount+1:end);
%                else
%                    obj.tempData = [];
%                end
%                
%                waitbar(obj.dataCount/ obj.numEventsToWaitFor, obj.statusBar, num2str(sp.BytesAvailable))
%                %Case where we are done reading events
%                if(obj.dataCount >= obj.numEventsToWaitFor)
%                    fprintf(sp, '%c', 't');
%                    fprintf(sp, '%c', 'b');
%                    pause(0.1);
%                    while(sp.BytesAvailable > 0)
%                        flushinput(sp);
%                        pause(0.1);
%                    end
%                    obj.numEventsToWaitFor = 0;
%                    close(obj.statusBar);
%                    disp('All Events Captured');
%                    disp(strcat('Errors: ', num2str(obj.errors)));
%                    notify(obj, 'AllEventsCaptured');
%                end