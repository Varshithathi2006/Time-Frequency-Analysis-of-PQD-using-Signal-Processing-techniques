Fs = 1000;                % Sampling frequency (Hz)
t = 0:1/Fs:1-1/Fs;        % Time vector
disturbance_classes = 15; % Number of disturbance classes

% Define parameters
A = 0.5;               % Magnitude of sag/swell/interruption
B = 1;                 % Magnitude of interruption
C = 0.1;               % Flicker modulation depth
w = 2 * pi * 50;       % Angular frequency of the fundamental component
gamma = 2 * pi * 10;   % Angular frequency of the flicker
beta3 = 0.1;           % 3rd harmonic coefficient
beta5 = 0.05;          % 5th harmonic coefficient
t1 = 0.2;              % Start time of disturbance
t2 = 0.5;              % End time of disturbance
u = @(t) double(t >= 0); % Unit step function

% Initialize cell array to store signals
signals = cell(disturbance_classes, 1);

% Generate signals for each disturbance type
signals{1} = sin(w * t);  % Sine Wave
signals{2} = (1 - A * (u(t - t1) - u(t - t2))) .* sin(w * t);  % Sag
signals{3} = (1 + A * (u(t - t1) - u(t - t2))) .* sin(w * t);  % Swell
signals{4} = (1 + C * sin(gamma * t)) .* sin(w * t);  % Flicker
signals{5} = sin(w * t) - sin(sin(w * t));  % Notch
signals{6} = A * (sin(w * t) + beta3 * sin(3 * w * t) + beta5 * sin(5 * w * t));  % Harmonics
signals{7} = (1 - B * (u(t - t1) - u(t - t2))) .* sin(w * t);  % Interruption

% Oscillation Transients
damping = exp(-200 * (t - t1));  % Damping factor for oscillation
transient = sin(2 * pi * 100 * t);  % Higher frequency transient
signals{8} = sin(w * t);
signals{8}(t >= t1 & t <= t2) = signals{8}(t >= t1 & t <= t2) + damping(t >= t1 & t <= t2) .* transient(t >= t1 & t <= t2);

% Impulse Transient
impulse = zeros(size(t));
impulse(t == t1) = 1;  % Dirac-like impulse at t1
signals{9} = sin(w * t) + impulse;

% Sag with Harmonics
signals{10} = (1 - A * (u(t - t1) - u(t - t2))) .* (sin(w * t) + beta3 * sin(3 * w * t) + beta5 * sin(5 * w * t));

% Sag with Oscillations
signals{11} = (1 - A * (u(t - t1) - u(t - t2))) .* sin(w * t);
signals{11}(t >= t1 & t <= t2) = signals{11}(t >= t1 & t <= t2) + damping(t >= t1 & t <= t2) .* transient(t >= t1 & t <= t2);

% Sag with Harmonics and Oscillations
signals{12} = (1 - A * (u(t - t1) - u(t - t2))) .* (sin(w * t) + beta3 * sin(3 * w * t) + beta5 * sin(5 * w * t));
signals{12}(t >= t1 & t <= t2) = signals{12}(t >= t1 & t <= t2) + damping(t >= t1 & t <= t2) .* transient(t >= t1 & t <= t2);

% Swell with Harmonics
signals{13} = (1 + A * (u(t - t1) - u(t - t2))) .* (sin(w * t) + beta3 * sin(3 * w * t) + beta5 * sin(5 * w * t));

% Swell with Oscillations
signals{14} = (1 + A * (u(t - t1) - u(t - t2))) .* sin(w * t);
signals{14}(t >= t1 & t <= t2) = signals{14}(t >= t1 & t <= t2) + damping(t >= t1 & t <= t2) .* transient(t >= t1 & t <= t2);

% Swell with Harmonics and Oscillations
signals{15} = (1 + A * (u(t - t1) - u(t - t2))) .* (sin(w * t) + beta3 * sin(3 * w * t) + beta5 * sin(5 * w * t));
signals{15}(t >= t1 & t <= t2) = signals{15}(t >= t1 & t <= t2) + damping(t >= t1 & t <= t2) .* transient(t >= t1 & t <= t2);

% Define disturbance names
disturbance_names = {
    'Sine Wave', ...
    'Sag', ...
    'Swell', ...
    'Flicker', ...
    'Notch', ...
    'Harmonics', ...
    'Interruption', ...
    'Oscillation Transients', ...
    'Impulse Transient', ...
    'Sag with Harmonics', ...
    'Sag with Oscillations', ...
    'Sag with Harmonics and Oscillations', ...
    'Swell with Harmonics', ...
    'Swell with Oscillations', ...
    'Swell with Harmonics and Oscillations'
};

% Open a text file for writing
fileID = fopen('disturbance_values.txt', 'w');

% Write disturbance names and values to the file
for i = 1:numel(disturbance_names)
    fprintf(fileID, 'Disturbance Class %d: %s\n', i, disturbance_names{i});
    fprintf(fileID, '%s\n', num2str(signals{i}));
    fprintf(fileID, '\n');
end

% Close the file
fclose(fileID);

% Perform SPWVD on each signal
spwvdResults = cell(disturbance_classes, 1);
frequencies = cell(disturbance_classes, 1);
timeVectors = cell(disturbance_classes, 1);

for i = 1:disturbance_classes
    signal = signals{i};
    
    % Perform the SPWVD
    [tfr, t, f] = spwvd(signal, Fs);
    spwvdResults{i} = tfr;
    frequencies{i} = f;
    timeVectors{i} = t;
end

% Plot the results
for i = 1:disturbance_classes
    signal = signals{i};
    tfr = spwvdResults{i};
    f = frequencies{i};
    t = timeVectors{i};
    
    figure;
    subplot(3, 1, 1);
    plot(t, signal);
    title(['Disturbance Class ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude');
    
    subplot(3, 1, 2);
    imagesc(t, f, abs(tfr));
    axis xy;
    title('SPWVD');
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
end

% SPWVD function definition
function [tfr, t, f] = spwvd(sig, Fs)
    N = length(sig);
    t = (0:N-1)/Fs;
    f = linspace(0, Fs/2, N/2+1);
    tfr = zeros(length(f), N);
    
    % Window function for smoothing
    win = hamming(N/4)';
    
    for n = 1:N
        % Time lag
        tau = -min([N/4-1, n-1]):min([N/4-1, N-n]);
        
        % Ensure indices are valid
        valid_indices = (n+tau > 0) & (n-tau > 0) & (n+tau <= N) & (n-tau <= N);
        tau = tau(valid_indices);
        
        % Smoothing in time
        tfr(:,n) = sum((sig(n+tau) .* conj(sig(n-tau))) .* win(abs(tau)+1), 2);
    end
    
    tfr = abs(tfr(1:N/2+1, :));
end
