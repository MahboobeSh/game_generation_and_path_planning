clc
clear
% base_folder = 'C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_code\new_obstacles\three_pairs\results\fit';
% 
% filePattern = 'path_data_for_*_test.mat';


% % Get a list of all files in the source folder matching the pattern
% files = dir(fullfile(base_folder, filePattern));

%for g = 1:numel(files)
for k=1:15
% for g = 1:2
% for g = 1

    set_number = k;
    base_folder = 'C:\Users\mahbo\OneDrive - University of Calgary\code\game_creation_and_fits';
    set_name = sprintf('set_%d.mat', set_number);
    fullFileName = fullfile(base_folder, set_name);

    % Get the full source file path
    % matches = regexp(files(g).name, 'set(\d+)', 'tokens');
    % setNumber = matches{1}{1};
    % k = setNumber;
    fit_results_file = fullFileName;
    
    % Load the A* path data
    path_data = load(fit_results_file);
    percent = 0.5;
    threshold= 2;
    safe_bound = calculate_safe_bound(path_data.curve,path_data.obstacle,path_data.obstacle_radious,percent, threshold);

    save(fit_results_file, 'safe_bound', 'percent', 'threshold', '-append');
end