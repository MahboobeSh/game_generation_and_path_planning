% Script to randomize the order of game modes with hand conditions and difficulty levels
% This script generates a random order for game modes × hands × difficulties
% For each game mode × hand combination, difficulty levels are randomized
% UPDATED VERSION: Non-Dominant hand only, 12 games total

clc
clear

% Define your game modes here
% Modify this list to match your actual game modes
game_modes = {
    'Non_Asistive',
    'Asistive_constant',
    'Asistive_varied',
    'Progression',
};

% Define hand conditions (only Non-Dominant)
% Direction convention: Dominant hand = 1, Non-Dominant hand = -1
hands = {'Non-Dominant'};

% Define difficulty levels
difficulties = {'Easy', 'Medium', 'Hard'};

% Define game set mapping (map mode + difficulty to set numbers)
% Format: game_set_map.(Mode).(Difficulty) = set_number
game_set_map = struct();

% Non_Asistive mappings
game_set_map.Non_Asistive.Easy = 1;
game_set_map.Non_Asistive.Medium = 2;
game_set_map.Non_Asistive.Hard = 3;

% Asistive_constant mappings
game_set_map.Asistive_constant.Easy = 4;
game_set_map.Asistive_constant.Medium = 5;
game_set_map.Asistive_constant.Hard = 6;

% Asistive_varied mappings
game_set_map.Asistive_varied.Easy = 7;
game_set_map.Asistive_varied.Medium = 8;
game_set_map.Asistive_varied.Hard = 9;

% Progression mappings
game_set_map.Progression.Easy = 10;
game_set_map.Progression.Medium = 11;
game_set_map.Progression.Hard = 12;

% OPTION: Enable/disable instance pairing (1 and 2 for each difficulty)
% Set to true if you want instance pairing (Easy1/Easy2, etc.)
% Set to false if you don't need instances
use_instances = false;  % Set to false for 12 games (1 instance per difficulty)

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

% Find the index of 'Non_Asistive'
non_assistive_mode = 'Non_Asistive';
non_assistive_idx = [];

for i = 1:num_modes
    if strcmp(game_modes{i}, non_assistive_mode)
        non_assistive_idx = i;
    end
end

% Separate game modes: Non_Asistive first, then others
if ~isempty(non_assistive_idx)
    other_modes = game_modes;
    other_modes(non_assistive_idx) = [];
else
    other_modes = game_modes;
end

% Initialize storage for all combinations (12 games total: 4 modes × 1 hand × 3 difficulties)
all_combinations = cell(num_modes * num_hands * num_difficulties * num_instances, 5);  % Columns: Mode, Hand, Difficulty, Instance, Set_Number
counter = 1;

% STEP 1: Handle 'Non_Asistive' first (always first, Non-Dominant hand only)
if ~isempty(non_assistive_idx)
    % Initialize cell array for Non-Dominant hand (includes both instances)
    non_asistive_nondominant = cell(num_difficulties * num_instances, 2);
    
    % Handle instances based on use_instances flag
    entry_idx = 1;
    for diff_idx = 1:num_difficulties
        diff_name = difficulties{diff_idx};
        
        if use_instances
            % Add BOTH instances for each difficulty
            for inst = 1:num_instances
                non_asistive_nondominant{entry_idx, 1} = diff_name;
                non_asistive_nondominant{entry_idx, 2} = difficulty_instances(inst);
                entry_idx = entry_idx + 1;
            end
        else
            % No instance pairing
            non_asistive_nondominant{entry_idx, 1} = diff_name;
            non_asistive_nondominant{entry_idx, 2} = 1;
            entry_idx = entry_idx + 1;
        end
    end
    
    % Randomize the order of all difficulty+instance combinations
    num_entries = entry_idx - 1;
    nondominant_order = randperm(num_entries);
    
    % Add Non-Dominant hand block (3 consecutive games: Easy, Medium, Hard in random order)
    for i = 1:num_entries
        idx = nondominant_order(i);
        diff_name = non_asistive_nondominant{idx, 1};
        
        % Get set number from mapping
        mode_field = strrep(non_assistive_mode, '_', '_');  % Keep underscores
        set_num = game_set_map.(mode_field).(diff_name);
        
        all_combinations{counter, 1} = non_assistive_mode;
        all_combinations{counter, 2} = hands{1}; % Non-Dominant
        all_combinations{counter, 3} = diff_name;
        all_combinations{counter, 4} = non_asistive_nondominant{idx, 2};
        all_combinations{counter, 5} = set_num;
        counter = counter + 1;
    end
end

% STEP 2: Create mode/hand blocks for all other modes (Non-Dominant hand only)
num_other_modes = length(other_modes);
num_blocks = num_other_modes;  % One block per mode (Non-Dominant hand only)
games_per_block = num_difficulties * num_instances;  % 3 games per block (3 difficulties)
other_blocks = cell(num_blocks, games_per_block);  % Each block has 3 games
other_blocks_instances = cell(num_blocks, games_per_block);  % Instance numbers
block_modes = cell(num_blocks, 1);
block_hands = cell(num_blocks, 1);
block_idx = 1;

for i = 1:num_other_modes
    current_mode = other_modes{i};
    
    % For each difficulty, add instances
    mode_nondominant = cell(games_per_block, 2);  % [difficulty, instance]
    
    entry_idx = 1;
    for diff_idx = 1:num_difficulties
        diff_name = difficulties{diff_idx};
        
        if use_instances
            % Add BOTH instances for each difficulty
            for inst = 1:num_instances
                mode_nondominant{entry_idx, 1} = diff_name;
                mode_nondominant{entry_idx, 2} = difficulty_instances(inst);
                entry_idx = entry_idx + 1;
            end
        else
            % No instance pairing
            mode_nondominant{entry_idx, 1} = diff_name;
            mode_nondominant{entry_idx, 2} = 1;
            entry_idx = entry_idx + 1;
        end
    end
    
    % Randomize order of all difficulty+instance combinations
    num_entries = entry_idx - 1;
    nondominant_order = randperm(num_entries);
    
    % Store Non-Dominant hand block
    for k = 1:num_entries
        idx = nondominant_order(k);
        other_blocks{block_idx, k} = mode_nondominant{idx, 1};
        other_blocks_instances{block_idx, k} = mode_nondominant{idx, 2};
    end
    block_modes{block_idx} = current_mode;
    block_hands{block_idx} = hands{1};  % Non-Dominant
    block_idx = block_idx + 1;
end

% STEP 3: Randomize the order of mode/hand blocks (keeping all games in a block together)
if num_blocks > 0
    random_block_order = randperm(num_blocks);
    for i = 1:num_blocks
        block_num = random_block_order(i);
        % Add all 3 games for this mode/hand block consecutively (Easy, Medium, Hard)
        for k = 1:games_per_block
            mode_name = block_modes{block_num};
            diff_name = other_blocks{block_num, k};
            
            % Get set number from mapping
            mode_field = strrep(mode_name, '_', '_');  % Keep underscores
            set_num = game_set_map.(mode_field).(diff_name);
            
            all_combinations{counter, 1} = mode_name;
            all_combinations{counter, 2} = block_hands{block_num};
            all_combinations{counter, 3} = diff_name;
            all_combinations{counter, 4} = other_blocks_instances{block_num, k};
            all_combinations{counter, 5} = set_num;
            counter = counter + 1;
        end
    end
end

% Get total number of combinations
total_combinations = counter - 1;
all_combinations = all_combinations(1:total_combinations, :);

% Display the results
fprintf('\n=== Random Game Mode, Hand, and Difficulty Order ===\n');
fprintf('Total games: %d\n\n', total_combinations);
for i = 1:total_combinations
    set_num = all_combinations{i, 5};
    hand_type = all_combinations{i, 2};
    
    % Set direction: 1 for Dominant, -1 for Non-Dominant
    if strcmp(hand_type, 'Dominant')
        direction = 1;
    else  % Non-Dominant
        direction = -1;
    end
    
    if use_instances
        fprintf('%d. %s - %s Hand - %s %d - set_%d.mat (direction: %d)\n', i, all_combinations{i, 1}, hand_type, all_combinations{i, 3}, all_combinations{i, 4}, set_num, direction);
    else
        fprintf('%d. %s - %s Hand - %s - set_%d.mat (direction: %d)\n', i, all_combinations{i, 1}, hand_type, all_combinations{i, 3}, set_num, direction);
    end
end
fprintf('\n');

% Create a structured format for easy access
game_order = struct();
for i = 1:total_combinations
    set_num = all_combinations{i, 5};
    hand_type = all_combinations{i, 2};
    
    % Set direction: 1 for Dominant, -1 for Non-Dominant
    if strcmp(hand_type, 'Dominant')
        direction = 1;
    else  % Non-Dominant
        direction = -1;
    end
    
    game_order(i).trial_number = i;
    game_order(i).mode = all_combinations{i, 1};
    game_order(i).hand = hand_type;
    game_order(i).difficulty = all_combinations{i, 3};
    game_order(i).instance = all_combinations{i, 4};
    game_order(i).set_number = set_num;
    game_order(i).game_file = sprintf('set_%d.mat', set_num);
    game_order(i).direction = direction;
end

% Save to MAT file for easy loading in MATLAB
save_to_mat = true;  % Set to false if you don't want to save
if save_to_mat
    % Prompt for user number
    user_number = input('Enter user number (e.g., 1, 2, 3... or 0 to skip saving): ');
    
    if user_number == 0
        fprintf('\nFile not saved (user number = 0).\n\n');
    else
        mat_filename = sprintf('game_order_for_user_%d.mat', user_number);
        
        % Save to .mat file
        save(mat_filename, 'game_order');
        fprintf('\nGame order saved to MAT file: %s\n', mat_filename);
        fprintf('\nTo load and use:\n');
        fprintf('  load(''%s'')\n', mat_filename);
        fprintf('  trial_1 = game_order(1)\n');
        fprintf('  game_file = game_order(1).game_file\n\n');
    end
end

% Store the randomized order in workspace for further use
assignin('base', 'all_combinations', all_combinations);
assignin('base', 'game_order', game_order);
assignin('base', 'randomized_game_modes', all_combinations(:, 1));
assignin('base', 'randomized_hands', all_combinations(:, 2));
assignin('base', 'randomized_difficulties', all_combinations(:, 3));
assignin('base', 'randomized_instances', all_combinations(:, 4));
assignin('base', 'randomized_set_numbers', all_combinations(:, 5));

% ========================================================================
% USAGE INSTRUCTIONS
% ========================================================================
%
% Load from MAT file:
% -------------------
%   load('game_order_for_user_1.mat')
%   
%   % Access trial 1
%   trial_1 = game_order(1)
%   
%   % Get specific trial information
%   trial_num = 5;
%   mode = game_order(trial_num).mode
%   difficulty = game_order(trial_num).difficulty
%   game_file = game_order(trial_num).game_file
%   set_number = game_order(trial_num).set_number
%   direction = game_order(trial_num).direction  % 1 for dominant, -1 for non-dominant
%   
%   % Load the actual game file
%   load(game_order(trial_num).game_file)
%   
%   % Loop through all trials
%   for i = 1:length(game_order)
%       fprintf('Trial %d: %s - %s - %s (dir: %d)\n', i, ...
%           game_order(i).mode, ...
%           game_order(i).difficulty, ...
%           game_order(i).game_file, ...
%           game_order(i).direction);
%   end

