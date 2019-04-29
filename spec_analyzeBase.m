% Spectrum Analysis with RTL-SDR Radio

FILEMODE = 0; % If this flag is set to 0, uses "real" data from RTL-SDR. If set to 1, uses captured data in lab2.dat instead.

% To complete the lab, you shouldn't change these parameters (unless you want to mess
% around and explore beyond the lab instructions... that's encouraged!
% If you do so, include any observations in your lab report!)
fc = 910.0e6; % Center frequency (Hz)
Ts = 1/2e6;   % Samples per second
FrameLength = 256*20;  % number of samples to "grab" each time through loop
simLength = 5000;      % total number of frames to grab (determine total sim time)
                    % Note: total simulation time = simLength * FrameLength * Ts

% Create receiver object
if FILEMODE == 0
    hSDRrRx = comm.SDRRTLReceiver(...
        'CenterFrequency', fc, ...
        'EnableTunerAGC',  true, ...
        'SampleRate',      round(1/Ts), ...
        'SamplesPerFrame', FrameLength, ...
        'OutputDataType',  'double');
else % unless we're in file mode, then open file and set simLength appropriately
    simLength = 1000;
    fid=fopen('lab2.dat');
end

% create spectrum analyzer object
hSpectrum = dsp.SpectrumAnalyzer(...
    'Name',             'Baseband Spectrum',...
    'Title',            'Baseband Spectrum', ...
    'SpectrumType',     'Power density',...
    'FrequencySpan',    'Full', ...
    'SampleRate',       round(1/Ts), ...
    'YLimits',          [-80,10],...
    'SpectralAverages', 50, ...
    'FrequencySpan',    'Start and stop frequencies', ...
    'StartFrequency',   -round(1/Ts/2), ...
    'StopFrequency',    round(1/Ts/2),...
    'Position',         figposition([50 30 30 40]));

% First BPF based on preliminary estimations
frequencies = [0 0.7 0.72 0.88 .9 1];
amplitudes = [0 0 1 1 0 0];
M = 200;
BPFilter = firpm(M,frequencies,amplitudes);
prevdata = zeros(FrameLength,1);

% Better BPF with values based on common behaved patterns observed
% frequencies2 = [0 0.77 0.79 0.81 .83 1];
% amplitudes2 = [0 0 1 1 0 0];
% M2 = 200;
% BPFilter = firpm(M2,frequencies2,amplitudes2);

% Main loop to grab samples
for count = 1 : simLength
    if FILEMODE == 0
        
        [data, ~] = step(hSDRrRx);       % grab complex (i.e. quadrature) samples from RTL-SDR
        data = [prevdata; data];
        
        % Processing the signal
        data = data.^2;        
        data = filter(BPFilter,1,data);
        data = data((length(data)/2):(length(data)));
        
        % Post Processing, keep at end
        data = real(data - mean(data));  % remove DC component, and only keep real portion
        prevdata = data;
        
    else % grab data from file instead
        data=fread(fid, 5120, 'double');
        pause(0.003); % slow things down a little to mimic real-time
    end
    
    step(hSpectrum, data);           % update spectrum analyzer display
    
end

if FILEMODE == 0  % close RTL-SDR object
    release(hSDRrRx);
else % close file
    fclose(fid);
end

% Release all system objects
release(hSpectrum);

