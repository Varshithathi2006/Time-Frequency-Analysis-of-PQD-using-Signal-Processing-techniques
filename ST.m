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

% Perform S-Transform on each signal
sTransform = @(sig, Fs) st(sig, Fs);  % S-Transform function handle

% Initialize cell arrays to store results
sTransformResults = cell(disturbance_classes, 1);
frequencies = cell(disturbance_classes, 1);

for i = 1:disturbance_classes
    signal = signals{i};
    
    % Perform the S-Transform
    [S, t, f] = sTransform(signal, Fs);
    sTransformResults{i} = S;
    frequencies{i} = f;
end

% Plot the results
for i = 1:disturbance_classes
    signal = signals{i};
    S = sTransformResults{i};
    f = frequencies{i};
    
    figure;
    subplot(3, 1, 1);
    plot(t, signal);
    title(['Disturbance Class ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude');
    
    subplot(3, 1, 2);
    imagesc(t, f, abs(S));
    axis xy;
    title('S-Transform');
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
end

% S-Transform function definition
function [S, t, f] = st(sig, Fs)
    N = length(sig);
    t = (0:N-1)/Fs;
    f = linspace(0, Fs/2, N/2+1);
    S = zeros(N/2+1, N);
    for k = 1:N/2+1
        gauss = exp(-2*pi^2*f(k)^2.*(t-mean(t)).^2);
        S(k, :) = fftshift(ifft(fft(sig).*fft(gauss, N)));
    end
end
