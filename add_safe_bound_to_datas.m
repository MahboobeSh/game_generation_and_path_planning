clc
clear
% base_folder = 'C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_code\new_obstacles\three_pairs\results\fit';
% 
% filePattern = 'path_data_for_*_test.mat';


% % Get a list of all files in the source folder matching the pattern
% files = dir(fullfile(base_folder, filePattern));

%for g = 1:numel(files)
for k=
% for g = 1:2
% for g = 1

    set_number = k;
    pair_number = 0;
    base_folder = 'C:\Users\mahbo\OneDrive - University of Calgary\code\game_creation_and_fits\new_games\selected_games\4pairs\fit\';
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/selected_games_2';
    base_folder = '/home/mahboobe/Desktop/study_information/game_sets_data/solved_games';
    set_name = sprintf('%dpairs/fit/set_%d_%dpairs.mat', pair_number,set_number,pair_number);
    if pair_number == 0
        set_name = sprintf('set_%d_fit.mat', set_number);
    end
    
    fullFileName = fullfile(base_folder, set_name);

    % Get the full source file path
    % matches = regexp(files(g).name, 'set(\d+)', 'tokens');
    % setNumber = matches{1}{1};
    % k = setNumber;
    fit_results_file = fullFileName;
    
    % Load the A* path data
    path_data = load(fit_results_file);
    percent = 2;
    threshold= 0.7087;
    safe_bound = calculate_safe_bound(path_data.curve_equalized,path_data.obstacle,path_data.obstacle_radious,percent, threshold);
    title_text = sprintf('percent = %f , Threshold = %f', percent, threshold);
    % show_figure_with_safe_bound(path_data.curve_equalized,path_data.obstacle,path_data.obstacle_radious,safe_bound, title_text)
    save(fit_results_file, 'safe_bound', 'percent', 'threshold', '-append');
    disp(min(safe_bound))
end