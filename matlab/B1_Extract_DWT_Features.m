%% ==========================================================================
%  B1_Extract_DWT_Features.m (with voltage rescaling + per-cycle labelling)
%  DWT feature extraction from Algharaibeh Data.mat
%
%  Cycle-level labelling (matches Python v2 pipeline):
%    - Pre-event cycles (0-9)  -> Class 0 (Non-islanding)
%    - Event cycle (10)        -> event's post-event class
%    - Post-event cycles (11-19) -> event's post-event class
%
%  Row 1 (load switching, status=0)     -> all 20 cycles = Class 0
%  Row 2 islanding (status=1)           -> cycles 0-9 = Class 0, cycles 10-19 = Class 1
%  Row 2 non-islanding (status=0)       -> all 20 cycles = Class 0
%  Row 3 line fault (status=2)          -> cycles 0-9 = Class 0, cycles 10-19 = Class 2
%
%  Voltage rescaling: Algharaibeh peak (1.937 pu) -> Training peak (1.011 pu)
%  ==========================================================================

clear all
clc

%% Configuration
WAVELET    = 'sym4';
DWT_LEVEL  = 2;
N_PHASES   = 3;
N_BANDS    = 3;
N_STATS    = 12;
N_FEATURES = N_PHASES * N_BANDS * N_STATS;
WINDOW     = 64;
N_CYCLES   = 20;
EVENT_CYCLE = 10;   % cycle 10 is the first post-event cycle (0-indexed)

% Voltage rescaling factor
RESCALE = 1.011 / 1.937;

BAND_NAMES = {'cA2', 'cD2', 'cD1'};
STAT_NAMES = {'mean', 'std', 'rms', 'peak', ...
              'crest_factor', 'impulse_factor', 'shape_factor', ...
              'clearance_factor', 'kurtosis', 'skewness', 'thd', 'sinad'};
PHASE_NAMES = {'Va', 'Vb', 'Vc'};

%% Build feature names
feature_names = cell(N_FEATURES, 1);
idx = 1;
for p = 1:N_PHASES
    for b = 1:N_BANDS
        for s = 1:N_STATS
            feature_names{idx} = sprintf('%s_%s_%s', ...
                PHASE_NAMES{p}, BAND_NAMES{b}, STAT_NAMES{s});
            idx = idx + 1;
        end
    end
end

fprintf('=== DWT Feature Extraction ===\n');
fprintf('Rescaling factor: %.4f\n', RESCALE);
fprintf('Event cycle: %d (first post-event cycle, 0-indexed)\n', EVENT_CYCLE);
fprintf('Features per cycle: %d\n', N_FEATURES);

%% Load Data
if ~exist('Data.mat', 'file')
    error('Data.mat not found in current directory');
end
load('Data.mat');
fprintf('Data loaded: %d rows x %d cols\n', size(Data,1), size(Data,2));

%% Count total valid events
n_events_total = 0;
for row = 1:size(Data, 1)
    for col = 1:size(Data, 2)
        if ~isempty(Data{row,col}) && isstruct(Data{row,col}) && ...
           isfield(Data{row,col}, 'Local')
            n_events_total = n_events_total + 1;
        end
    end
end
fprintf('Total valid events: %d\n', n_events_total);

n_rows = n_events_total * N_CYCLES;
fprintf('Total feature vectors expected: %d\n\n', n_rows);

%% Preallocate
X = zeros(n_rows, N_FEATURES, 'single');
y = zeros(n_rows, 1, 'uint8');
dP = zeros(n_rows, 2, 'single');
cycle_idx = zeros(n_rows, 1, 'uint8');
event_idx = zeros(n_rows, 1, 'uint16');
event_row = zeros(n_rows, 1, 'uint8');

%% Extract features
row_out = 1;
global_event = 0;

for row = 1:size(Data, 1)
    for col = 1:size(Data, 2)
        if isempty(Data{row,col}) || ~isstruct(Data{row,col}) || ...
           ~isfield(Data{row,col}, 'Local')
            continue;
        end
        
        global_event = global_event + 1;
        
        V = Data{row,col}.Local;
        event_status = Data{row,col}.status;
        
        if isfield(Data{row,col}, 'dP')
            this_dP = Data{row,col}.dP;
        else
            this_dP = [0, 0];
        end
        
        if mod(global_event, 50) == 0 || global_event == 1
            fprintf('  Event %d/%d (row=%d col=%d status=%d)\n', ...
                global_event, n_events_total, row, col, event_status);
        end
        
        for c = 1:N_CYCLES
            start = (c-1) * WINDOW + 1;
            stop = c * WINDOW;
            cycle = V(start:stop, :);
            
            % Rescale to match training amplitude
            cycle = cycle * RESCALE;
            
            feats = extract_cycle_features(cycle, WAVELET, DWT_LEVEL);
            
            % Cycle-level labelling:
            % Before event cycle (0-indexed cycle < EVENT_CYCLE): Class 0
            % At/after event cycle: use event_status
            current_cycle_idx = c - 1;  % 0-indexed
            if current_cycle_idx < EVENT_CYCLE
                cycle_label = 0;
            else
                cycle_label = event_status;
            end
            
            X(row_out, :) = single(feats);
            y(row_out) = uint8(cycle_label);
            dP(row_out, :) = single(this_dP);
            cycle_idx(row_out) = uint8(current_cycle_idx);
            event_idx(row_out) = uint16(global_event);
            event_row(row_out) = uint8(row);
            
            row_out = row_out + 1;
        end
    end
end

fprintf('\nExtraction complete. %d feature vectors produced.\n', row_out - 1);

%% Verify
fprintf('\nClass distribution:\n');
for cls = 0:2
    n = sum(y == cls);
    fprintf('  Class %d: %d cycles (%.1f%%)\n', cls, n, 100*n/length(y));
end

fprintf('\nPre-event vs Post-event label check:\n');
pre_mask = cycle_idx < EVENT_CYCLE;
post_mask = cycle_idx >= EVENT_CYCLE;
fprintf('  Pre-event cycles: %d (all should be Class 0)\n', sum(pre_mask));
fprintf('    Class 0: %d  Class 1: %d  Class 2: %d\n', ...
    sum(y(pre_mask)==0), sum(y(pre_mask)==1), sum(y(pre_mask)==2));
fprintf('  Post-event cycles: %d\n', sum(post_mask));
fprintf('    Class 0: %d  Class 1: %d  Class 2: %d\n', ...
    sum(y(post_mask)==0), sum(y(post_mask)==1), sum(y(post_mask)==2));

fprintf('\nAny NaN or Inf in features?\n');
fprintf('  NaN: %d\n', sum(isnan(X(:))));
fprintf('  Inf: %d\n', sum(isinf(X(:))));

%% Save
save('features.mat', 'X', 'y', 'dP', 'cycle_idx', 'event_idx', ...
     'event_row', 'feature_names', '-v7.3');
fprintf('\nSaved features.mat\n');
fprintf('  X: %d x %d\n', size(X,1), size(X,2));

%% ==========================================================================
%  Local functions
%  ==========================================================================

function feats = extract_cycle_features(cycle, wavelet, level)
    n_stats = 12;
    n_bands = 3;
    feats = zeros(1, 3 * n_bands * n_stats);
    idx = 1;
    for p = 1:3
        signal = cycle(:, p);
        [c, l] = wavedec(signal, level, wavelet);
        
        cA2 = appcoef(c, l, wavelet, level);
        cD2 = detcoef(c, l, level);
        cD1 = detcoef(c, l, 1);
        
        bands = {cA2, cD2, cD1};
        for b = 1:n_bands
            band_feats = extract_band_features(bands{b});
            feats(idx:idx + n_stats - 1) = band_feats;
            idx = idx + n_stats;
        end
    end
end

function feats = extract_band_features(coeffs)
    x = double(coeffs(:));
    xabs = abs(x);
    eps_val = 1e-10;
    
    mean_val = mean(x);
    std_val = std(x, 1);
    rms_val = sqrt(mean(x.^2));
    peak_val = max(xabs);
    mean_abs = mean(xabs);
    mean_sqrt = mean(sqrt(xabs))^2;
    
    crest_factor     = peak_val / (rms_val + eps_val);
    impulse_factor   = peak_val / (mean_abs + eps_val);
    shape_factor     = rms_val / (mean_abs + eps_val);
    clearance_factor = peak_val / (mean_sqrt + eps_val);
    
    if std_val > eps_val
        z = (x - mean_val) / std_val;
        kurt_val = mean(z.^4);
        skew_val = mean(z.^3);
    else
        kurt_val = 0;
        skew_val = 0;
    end
    
    N = length(x);
    fft_full = fft(x);
    n_rfft = floor(N/2) + 1;
    fft_vals = abs(fft_full(1:n_rfft));
    
    if length(fft_vals) < 2 || fft_vals(2) < eps_val
        thd_val = 0;
    else
        fundamental = fft_vals(2);
        harmonics = fft_vals(3:end);
        thd_val = sqrt(sum(harmonics.^2)) / fundamental;
    end
    
    total_power = sum(fft_vals.^2);
    if total_power < eps_val
        sinad_val = 0;
    else
        [~, fund_idx] = max(fft_vals(2:end));
        fund_idx = fund_idx + 1;
        signal_power = fft_vals(fund_idx)^2;
        noise_power = total_power - signal_power;
        if noise_power < eps_val
            sinad_val = signal_power / eps_val;
        else
            sinad_val = signal_power / noise_power;
        end
    end
    
    feats = [mean_val, std_val, rms_val, peak_val, ...
             crest_factor, impulse_factor, shape_factor, clearance_factor, ...
             kurt_val, skew_val, thd_val, sinad_val];
end