% Script to randomize the order of game modes with hand conditions and difficulty levels
% This script generates a random order for game modes × hands × difficulties
% For each game mode × hand combination, difficulty levels are randomized

clc
clear

% Define your game modes here
% Modify this list to match your actual game modes
game_modes = {
    'Non_Asistive',
    'Asistive_constant',
    'Asistive_varied',
    'Resistive',
};

% Define hand conditions
hands = {'Dominant', 'Non-Dominant'};

% Define difficulty levels
difficulties = {'Easy', 'Medium', 'Hard'};

% OPTION: Enable/disable instance pairing (1 and 2 for each difficulty)
% Set to true if you want instance pairing (Easy1/Easy2, etc.)
% Set to false if you don't need instances
use_instances = true;  % Change to true to enable instance pairing

if use_instances
    difficulty_instances = [1, 2];  % Each difficulty has 2 instances (Easy1, Easy2, etc.)
    num_instances = length(difficulty_instances);
else
    difficulty_instances = [1];  % Just use 1 (will be ignored in output)
    num_instances = 1;
end

% Get the number of game modes, hands, and difficulties
num_modes = length(game_modes);
num_hands = length(hands);
num_difficulties = length(difficulties);

% Find the index of 'Non_Asistive' and 'Resistive'
non_assistive_mode = 'Non_Asistive';
resistive_mode = 'Resistive';
non_assistive_idx = [];
resistive_idx = [];

for i = 1:num_modes
    if strcmp(game_modes{i}, non_assistive_mode)
        non_assistive_idx = i;
    end
    if strcmp(game_modes{i}, resistive_mode)
        resistive_idx = i;
    end
end

% Separate game modes: Non_Asistive first, then others
if ~isempty(non_assistive_idx)
    other_modes = game_modes;
    other_modes(non_assistive_idx) = [];
else
    other_modes = game_modes;
end

% Initialize storage for all combinations (6 games per mode: 2 Easy, 2 Med, 2 Hard)
all_combinations = cell(num_modes * num_hands * num_difficulties, 4);  % Added column for instance number
counter = 1;

% STEP 1: Handle 'Non_Asistive' first (always first, Dominant then Non-Dominant)
if ~isempty(non_assistive_idx)
    % Initialize cell arrays
    non_asistive_dominant = cell(num_difficulties, 2);
    non_asistive_nondominant = cell(num_difficulties, 2);
    
    % Handle instances based on use_instances flag
    for diff_idx = 1:num_difficulties
        diff_name = difficulties{diff_idx};
        
        if use_instances
            % Pair instances: randomly decide which hand gets instance 1 and which gets instance 2
            hand_order = randperm(2);
            if hand_order(1) == 1  % Dominant gets instance 1
                non_asistive_dominant{diff_idx, 1} = diff_name;
                non_asistive_dominant{diff_idx, 2} = difficulty_instances(1);
                non_asistive_nondominant{diff_idx, 1} = diff_name;
                non_asistive_nondominant{diff_idx, 2} = difficulty_instances(2);
            else  % Non-Dominant gets instance 1
                non_asistive_dominant{diff_idx, 1} = diff_name;
                non_asistive_dominant{diff_idx, 2} = difficulty_instances(2);
                non_asistive_nondominant{diff_idx, 1} = diff_name;
                non_asistive_nondominant{diff_idx, 2} = difficulty_instances(1);
            end
        else
            % No instance pairing: both hands get the same difficulty (instance 1, but won't be shown)
            non_asistive_dominant{diff_idx, 1} = diff_name;
            non_asistive_dominant{diff_idx, 2} = 1;
            non_asistive_nondominant{diff_idx, 1} = diff_name;
            non_asistive_nondominant{diff_idx, 2} = 1;
        end
    end
    
    % Randomize difficulty order for each hand
    dominant_order = randperm(num_difficulties);
    nondominant_order = randperm(num_difficulties);
    
    % Add Dominant hand block (3 consecutive difficulties)
    for i = 1:num_difficulties
        idx = dominant_order(i);
        all_combinations{counter, 1} = non_assistive_mode;
        all_combinations{counter, 2} = hands{1}; % Dominant
        all_combinations{counter, 3} = non_asistive_dominant{idx, 1};
        all_combinations{counter, 4} = non_asistive_dominant{idx, 2};
        counter = counter + 1;
    end
    
    % Add Non-Dominant hand block (3 consecutive difficulties)
    for i = 1:num_difficulties
        idx = nondominant_order(i);
        all_combinations{counter, 1} = non_assistive_mode;
        all_combinations{counter, 2} = hands{2}; % Non-Dominant
        all_combinations{counter, 3} = non_asistive_nondominant{idx, 1};
        all_combinations{counter, 4} = non_asistive_nondominant{idx, 2};
        counter = counter + 1;
    end
end

% STEP 2: Create mode/hand blocks for all other modes with instance pairing
% Each mode: pair instances between hands (if Dominant gets Easy1, Non-Dominant gets Easy2)
num_other_modes = length(other_modes);
num_blocks = num_other_modes * num_hands;  % One block per mode/hand combination
other_blocks = cell(num_blocks, num_difficulties);  % Each block has 3 difficulties
other_blocks_instances = cell(num_blocks, num_difficulties);  % Instance numbers
block_modes = cell(num_blocks, 1);
block_hands = cell(num_blocks, 1);
block_idx = 1;

for i = 1:num_other_modes
    current_mode = other_modes{i};
    
    % For each difficulty, pair instances between hands
    mode_dominant = cell(num_difficulties, 2);  % [difficulty, instance]
    mode_nondominant = cell(num_difficulties, 2);
    
    for diff_idx = 1:num_difficulties
        diff_name = difficulties{diff_idx};
        
        if use_instances
            % Pair instances: randomly decide which hand gets instance 1 and which gets instance 2
            hand_order = randperm(2);
            if hand_order(1) == 1  % Dominant gets instance 1
                mode_dominant{diff_idx, 1} = diff_name;
                mode_dominant{diff_idx, 2} = difficulty_instances(1);
                mode_nondominant{diff_idx, 1} = diff_name;
                mode_nondominant{diff_idx, 2} = difficulty_instances(2);
            else  % Non-Dominant gets instance 1
                mode_dominant{diff_idx, 1} = diff_name;
                mode_dominant{diff_idx, 2} = difficulty_instances(2);
                mode_nondominant{diff_idx, 1} = diff_name;
                mode_nondominant{diff_idx, 2} = difficulty_instances(1);
            end
        else
            % No instance pairing: both hands get the same difficulty (instance 1, but won't be shown)
            mode_dominant{diff_idx, 1} = diff_name;
            mode_dominant{diff_idx, 2} = 1;
            mode_nondominant{diff_idx, 1} = diff_name;
            mode_nondominant{diff_idx, 2} = 1;
        end
    end
    
    % Randomize difficulty order for each hand
    dominant_order = randperm(num_difficulties);
    nondominant_order = randperm(num_difficulties);
    
    % Store Dominant hand block
    for k = 1:num_difficulties
        idx = dominant_order(k);
        other_blocks{block_idx, k} = mode_dominant{idx, 1};
        other_blocks_instances{block_idx, k} = mode_dominant{idx, 2};
    end
    block_modes{block_idx} = current_mode;
    block_hands{block_idx} = hands{1};  % Dominant
    block_idx = block_idx + 1;
    
    % Store Non-Dominant hand block
    for k = 1:num_difficulties
        idx = nondominant_order(k);
        other_blocks{block_idx, k} = mode_nondominant{idx, 1};
        other_blocks_instances{block_idx, k} = mode_nondominant{idx, 2};
    end
    block_modes{block_idx} = current_mode;
    block_hands{block_idx} = hands{2};  % Non-Dominant
    block_idx = block_idx + 1;
end

% STEP 3: Randomize the order of mode/hand blocks (keeping difficulties together)
if num_blocks > 0
    random_block_order = randperm(num_blocks);
    for i = 1:num_blocks
        block_num = random_block_order(i);
        % Add all 3 difficulties for this mode/hand block consecutively
        for k = 1:num_difficulties
            all_combinations{counter, 1} = block_modes{block_num};
            all_combinations{counter, 2} = block_hands{block_num};
            all_combinations{counter, 3} = other_blocks{block_num, k};
            all_combinations{counter, 4} = other_blocks_instances{block_num, k};
            counter = counter + 1;
        end
    end
end

% Get total number of combinations
total_combinations = counter - 1;
all_combinations = all_combinations(1:total_combinations, :);

% Display the results
fprintf('\n=== Random Game Mode, Hand, and Difficulty Order ===\n\n');
for i = 1:total_combinations
    if use_instances
        fprintf('%d. %s - %s Hand - %s %d\n', i, all_combinations{i, 1}, all_combinations{i, 2}, all_combinations{i, 3}, all_combinations{i, 4});
    else
        fprintf('%d. %s - %s Hand - %s\n', i, all_combinations{i, 1}, all_combinations{i, 2}, all_combinations{i, 3});
    end
end
fprintf('\n');

% Save to CSV file for easy loading and use with game files
save_to_csv = true;  % Set to false if you don't want to save
if save_to_csv
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    filename = sprintf('game_mode_order_%s.csv', timestamp);
    fid = fopen(filename, 'w');
    if fid ~= -1
        % Write CSV header (conditionally include Instance column)
        if use_instances
            fprintf(fid, 'Trial_Number,Mode,Hand,Difficulty,Instance\n');
        else
            fprintf(fid, 'Trial_Number,Mode,Hand,Difficulty\n');
        end
        
        % Write data rows
        for i = 1:total_combinations
            if use_instances
                fprintf(fid, '%d,%s,%s,%s,%d\n', i, ...
                    all_combinations{i, 1}, ...
                    all_combinations{i, 2}, ...
                    all_combinations{i, 3}, ...
                    all_combinations{i, 4});
            else
                fprintf(fid, '%d,%s,%s,%s\n', i, ...
                    all_combinations{i, 1}, ...
                    all_combinations{i, 2}, ...
                    all_combinations{i, 3});
            end
        end
        fclose(fid);
        fprintf('Order saved to CSV: %s\n', filename);
    else
        fprintf('Error: Could not create CSV file\n');
    end
end

% Store the randomized order in workspace for further use
assignin('base', 'all_combinations', all_combinations);
assignin('base', 'randomized_game_modes', all_combinations(:, 1));
assignin('base', 'randomized_hands', all_combinations(:, 2));
assignin('base', 'randomized_difficulties', all_combinations(:, 3));
assignin('base', 'randomized_instances', all_combinations(:, 4));

% To load the CSV file later in MATLAB, use:
%   data = readtable('game_mode_order_YYYY-MM-DD_HH-MM-SS.csv');
%   mode = data.Mode{trial_number};
%   hand = data.Hand{trial_number};
%   difficulty = data.Difficulty{trial_number};
%   % If instances are enabled:
%   if use_instances
%       instance = data.Instance(trial_number);
%   end
%
% Or in Python:
%   import pandas as pd
%   data = pd.read_csv('game_mode_order_YYYY-MM-DD_HH-MM-SS.csv')
%   mode = data.loc[trial_number-1, 'Mode']
%   hand = data.loc[trial_number-1, 'Hand']
%   difficulty = data.loc[trial_number-1, 'Difficulty']
%   # If instances are enabled:
%   if 'Instance' in data.columns:
%       instance = data.loc[trial_number-1, 'Instance']

