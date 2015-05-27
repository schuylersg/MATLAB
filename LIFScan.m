function [ ] = LIFScan( swl, ewl, dwl, sm, adc, laser, num_reads, num_scans, fn, gain, conc, cuv)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%   swl: wavelength to start scan at
%   ewl: wavelength to end scan at
%   dwl: wavelength step size between scans
%   sm: stepper motor objectsemilogx(output.T, output.S)
%   adc: ADC object
%   laser: laser object
%   num_reads: number of fpga readings to collect - each fpga reading is sum of 256 triggers
%   num_scans: number of scans to repeat
%   fn: file name to store data
%   gain: voltage gain on PMT, should be in millivolts
%   conc: concentration of solution - used in filename
%   cuv: type of sampling mechanism - used in filename

    wb = waitbar(0,'Laser Warming Up');
    adc.adc_on();   %turn on the ADC
    laser.on();     %turn on the laser
    pause(10);      %pause for 10 seconds for laser to turn on 
                    %pause 30 seconds to flush system
    waitbar(0, wb, 'Starting Scan');
    oldWL = 0;
    
    %we don't need to calibrate the adc because that's done inside CaptureLIF
    tot_i = ((ewl - swl)/dwl + 1) * (num_scans);
    for num_s = 1:num_scans
        for wl = swl:dwl:ewl
            if(wl ~= oldWL)
                sm.move_to_wl(wl); %this is blocking until position is reached
                oldWL = wl;
                %pause(0.1)
            end
            CaptureLIF( num_reads, conc, cuv, gain, fn, sm, adc, laser, wl, 1);
    %       [ output_data, num_events, errors ] = ReadData( num_reads, cp, dws, wb);
    %       save(strcat(fn,num2str(gain),'mv_', num2str(wl),'.mat'), 'output_data');
            num_i = ((wl-swl)/dwl + 1) + ((ewl - swl)/dwl + 1) * (num_s - 1);
            percComplete = round(num_i/tot_i*100);
            waitbar(percComplete/100, wb, strcat('WL = ', num2str(wl), ',', num2str(percComplete), '% Complete'));
        end
    end
    adc.adc_off();  %turn off adc
    laser.off();    %turn off laser
    close(wb)
end
