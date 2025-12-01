clc
clear

% ============================================================================
% RANDOM NUMBER GENERATOR SEEDING
% ============================================================================
% Seed the random number generator based on current time to ensure different
% results on each run and across different computers
% 'shuffle' uses the current time as the seed
rng('shuffle');
% Alternative: Use a specific seed for reproducibility (uncomment to use)
% rng(42);  % Replace 42 with any integer for reproducible results

x_range = 48;
y_range = 27;
x_scaled = 0.95*x_range;
y_scaled = 0.95*y_range;
x_margin = 0.025*x_range;  % 2.5% margin
y_margin = 0.025*y_range;
number_of_pairs = 5;
max_distance = sqrt(x_range^2 + y_range^2);
output_folder = "/home/mahboobe/Desktop/game_generation_and_path_planning/new_games";
output_folder = "C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits\new_game_set";


% ============================================================================
% OBSTACLE RADIUS CONFIGURATION (Global Variables - Easy to Modify)
% ============================================================================
% Set the minimum and maximum obstacle radius (in cm)
% These values are used for all pair counts (2-5 pairs)
% To change obstacle sizes, modify these two variables:
min_radius = 2;  % Minimum obstacle radius (cm)
max_radius = 4;  % Maximum obstacle radius (cm)
% ============================================================================

% ============================================================================
% DISTANCE CONSTRAINT CONFIGURATION (Global Variables - Easy to Modify)
% ============================================================================
% SIMPLIFIED APPROACH: Fixed minimums, scaling maximums
% - Minimum values: FIXED (same for all pair counts) - ensures consistent difficulty floor
% - Maximum values: SCALE with number of pairs - adapts to available space
%
% MINIMUM VALUES (Fixed - same for all pairs 2-5):
min_distance_between_obstacles = 1.5;  % Minimum gap between obstacles from different pairs (cm)
min_distance_between_obstacle_pairs = 2.0;  % Minimum gap between obstacles in same pair (cm)
min_distance_to_end_and_start = 2.5;  % Minimum distance from start/end points (cm)
min_distance_middle_points = 2.5;  % Minimum distance between middle points of pairs (cm)
% ============================================================================
% min_distance_between_obstacles = 0.12*sqrt((x_range/number_of_pairs)^2 + (y_range/number_of_pairs)^2)
% max_distance_between_obstacle_pairs = 1.25*min_distance_between_obstacles
% min_distance_to_end_and_start =  0.5*sqrt(x_range^2 + y_range^2)/number_of_pairs;
% min_distance_middle_points = min_distance_to_end_and_start;
% Calculate MAXIMUM distance constraints (scaled with game size and number of pairs)
% These formulas automatically adapt to different numbers of pairs (2-5)
% More pairs = smaller maximums (less space available)
% Fewer pairs = larger maximums (more space available)
% 
% NOTE: Minimum values are FIXED (defined above) - same for all pairs
%       Maximum values SCALE with number of pairs - adapts to available space

% Maximum values (scale with pairs)
max_distance_to_end_and_start = 0.15*max_distance + 0.2*(max_distance/number_of_pairs);
max_distance_between_obstacle_pairs = 0.05* max_distance + 0.03*(max_distance/number_of_pairs);

% Minimum values are already set above as fixed constants
% (min_distance_between_obstacles, min_distance_between_obstacle_pairs, 
%  min_distance_to_end_and_start, min_distance_middle_points)
for mahboobe=1:100
flag = true;


counter_1 =0;
counter_2 =0;
counter_3 = 0;
counter_4 = 0;
counter_5 = 0;
while flag
    flag = false;
    
    % ============================================================================
    % OBSTACLE CENTER GENERATION (Improved Space Utilization)
    % ============================================================================
    % OPTION 1: Stratified X, Random Y (Recommended - Better space usage)

    
    % Divide X-axis into number_of_pairs regions for even distribution

    centers = [x_margin, y_margin] + [x_range-2*x_margin, y_range-2*y_margin].*rand(2*number_of_pairs,2);
    centers = sortrows(centers, 1);
    
    % OPTION 2: Pure Random (Original - More variety, less space efficient)
    % Uncomment below and comment above to use original random approach
    % centers = [0.1*x_range, 0.1*y_range] + [x_scaled, y_scaled].*rand(2*number_of_pairs,2);
    % centers = sortrows(centers, 1);
    % Fixed radius range (consistent size, difficulty from number of obstacles)
    % Uses global variables min_radius and max_radius defined at top of file
    % This provides consistent obstacle sizes across all pair counts
    % To change obstacle sizes, modify min_radius and max_radius at the top
    radii = min_radius + (max_radius - min_radius)*rand(number_of_pairs,1);
    
    % Alternative: Scaled approach (smaller obstacles for more pairs)
    % Uncomment below and comment above to use scaling instead of fixed size
    % radii = 2 + (0.1*rand(number_of_pairs,1))*(max_distance/(2*number_of_pairs));
    radii = repelem(radii, 2);
    
    % Define the obstacle parameters (all centers and radii concatenated)
    % centers = [2, 3; 4, 6; 10, 15; 12, 14; 0, 0; -3, -3]; % All coordinates of centers
    % radii = [1; 2; 1; 2; 1; 1.5]; % All radii concatenated
    

    % ============================================================================
    % CONSTRAINT CHECK 1: Middle Points Distance (COMMENTED OUT - Testing)
    % ============================================================================
    % Ensures middle points of obstacle pairs are sufficiently separated
    % COMMENTED: User testing if this constraint is necessary
    % X_m = find_middle_point_in_obstacles(centers);
    % if min(pdist(X_m)) < min_distance_middle_points
    %     flag = true;
    %     counter_5 = counter_5 +1; 
    % end
    % Number of centers per set
    numCentersPerSet = 2;
    numSets = number_of_pairs;
    
    % Initialize rectangle parameters storage
    rectangles = zeros(numSets, 4); % Each row will store [xMin, yMin, width, height]

    % for checking if the rectangles are coliding
    for i = 1:numSets
        startIndex = (i - 1) * numCentersPerSet + 1;
        endIndex = i * numCentersPerSet;
        set_centers = centers(startIndex:endIndex, :);
        set_radii = radii(startIndex:endIndex);
    
        xMin = min(set_centers(:,1) - set_radii);
        yMin = min(set_centers(:,2) - set_radii);
        xMax = max(set_centers(:,1) + set_radii);
        yMax = max(set_centers(:,2) + set_radii);
    
        width = xMax - xMin;
        height = yMax - yMin;
    
        rectangles(i, :) = [xMin, yMin, width, height];

        radius = radii(startIndex);
        distance_between_obstacles = norm(centers(startIndex,:) - centers(endIndex,:));
        
        % ============================================================================
        % CONSTRAINT CHECK 2: Distance Between Obstacles in Same Pair (ACTIVE)
        % ============================================================================
        % Ensures obstacles in the same pair are at least min_distance_between_obstacle_pairs apart
        % This is the main constraint you want to keep
        if distance_between_obstacles < (min_distance_between_obstacle_pairs + 2*radius)
            flag = true;
            counter_1 = counter_1 + 1;
        end
        
        % ============================================================================
        % CONSTRAINT CHECK 3: Maximum Distance Between Obstacles in Same Pair (ACTIVE)
        % ============================================================================
        % Prevents obstacles in same pair from being too far apart
        % This is NECESSARY - without it, gates become too wide and games are too easy
        if distance_between_obstacles > (max_distance_between_obstacle_pairs + 2*radius)
            flag = true;
            counter_1 = counter_1 + 1;
        end
    end
    
    % ============================================================================
    % CONSTRAINT CHECK 4: Rectangle Collisions (ACTIVE)
    % ============================================================================
    % Prevents bounding rectangles of different pairs from overlapping
    % This is NECESSARY to prevent pairs from being too close together
    if checkRectanglesForCollision(rectangles)
        flag = true;
        counter_2 = counter_2 + 1;
    end

    num_obstacles = size(centers, 1);
    
    % ============================================================================
    % CONSTRAINT CHECK 5: Collision Check Between Obstacles (ACTIVE)
    % ============================================================================
    % This is the main collision check - ensures obstacles from different pairs don't overlap
    % This is ESSENTIAL and should be kept active
    for i = 1:num_obstacles
        for j = i+1:num_obstacles
            % Determine which pairs these obstacles belong to
            pair_i = ceil(i / 2);
            pair_j = ceil(j / 2);
            
            % Skip if they're in the same pair (already checked above)
            if pair_i == pair_j
                continue
            end
            
            center1 = centers(i, :);
            center2 = centers(j, :);
            radius1 = radii(i);
            radius2 = radii(j);
            distance = norm(center1 - center2);
            
            % Check if obstacles overlap (collision)
            if distance < (radius1 + radius2 + min_distance_between_obstacles)
                flag = true;
                counter_3 = counter_3 + 1;
            end
        end
        % obstacle_position = temp_obstacle(i, :);
        % obstacle_radius = temp_radius(i);
        % 
        % % Calculate the distance to the start and end points
        % distance_to_start = norm(X_s - obstacle_position);
        % distance_to_end = norm(X_e - obstacle_position);
        % 
        % % Check if the distance is at least 'd' for both start and end points
        % if distance_to_start >= (min_distance_to_end_and_start + obstacle_radius) && distance_to_end >= (min_distance_to_end_and_start + obstacle_radius)
        % else
        %     flag = true;
        % end
    end


    % setting start and end point

    point1 = centers(1, :);
    point2 = centers(2, :);
    
    
    % Calculate the midpoint
    midpoint = (point1 + point2) / 2;
    
    % Calculate the slope of the line connecting point1 and point2
    line_slope = (point2(2) - point1(2)) / (point2(1) - point1(1));
    
    % Calculate the y-intercept of the line connecting point1 and point2
    line_intercept = point1(2) - line_slope * point1(1);
    
    % Calculate the slope of the perpendicular line
    perpendicular_slope = -1 / line_slope;
    
    % Calculate the y-intercept of the perpendicular line using the midpoint
    perpendicular_intercept = midpoint(2) - perpendicular_slope * midpoint(1);
    
    % Calculate the intersection point of the perpendicular line with x = end_x
    intersection_x = 0;
    intersection_y = perpendicular_slope * intersection_x + perpendicular_intercept;
    
    

    if intersection_y < 0 
        intersection_y = 0;
    elseif  intersection_y > y_range
        intersection_y = y_range;
    end

    X_s = [intersection_x, intersection_y];
    % setting end point


    point1 = centers(end, :);
    point2 = centers(end-1, :);
    
    
    % Calculate the midpoint
    midpoint = (point1 + point2) / 2;
    
    % Calculate the slope of the line connecting point1 and point2
    line_slope = (point2(2) - point1(2)) / (point2(1) - point1(1));
    
    % Calculate the y-intercept of the line connecting point1 and point2
    line_intercept = point1(2) - line_slope * point1(1);
    
    % Calculate the slope of the perpendicular line
    perpendicular_slope = -1 / line_slope;
    
    % Calculate the y-intercept of the perpendicular line using the midpoint
    perpendicular_intercept = midpoint(2) - perpendicular_slope * midpoint(1);
    
    % Calculate the intersection point of the perpendicular line with x = end_x
    intersection_x = x_range;
    intersection_y = perpendicular_slope * intersection_x + perpendicular_intercept;

    if intersection_y < 0 
        intersection_y = 0;
    elseif  intersection_y > y_range
        intersection_y = y_range;
    end
    X_e = [intersection_x, intersection_y];


    % ============================================================================
    % CONSTRAINT CHECK 6: Start/End Distance (COMMENTED OUT - Testing)
    % ============================================================================
    % Ensures obstacles are not too close to start/end points
    % COMMENTED: User testing if this constraint is necessary
    % for i = 1:num_obstacles
    %     obstacle_position = centers(i, :);
    %     obstacle_radius = radii(i);
    %     % Calculate the distance to the start and end points
    %     distance_to_start = norm(X_s - obstacle_position);
    %     distance_to_end = norm(X_e - obstacle_position);
    %     
    %     % Check first obstacle's distance to start point (with range constraint)
    %     if i == 1
    %         if distance_to_start < (min_distance_to_end_and_start + obstacle_radius) || distance_to_start > (max_distance_to_end_and_start + obstacle_radius)
    %             flag = true;
    %             counter_4 = counter_4 + 1;
    %         end
    %     % Check last obstacle's distance to end point (with range constraint)
    %     elseif i == num_obstacles
    %         if distance_to_end < (min_distance_to_end_and_start + obstacle_radius) || distance_to_end > (max_distance_to_end_and_start + obstacle_radius)
    %             flag = true;
    %             counter_4 = counter_4 + 1;
    %         end
    %     else
    %         % For all other obstacles, ensure they're not too close to start/end
    %         % (minimum distance check only, no maximum constraint)
    %         if distance_to_start < (min_distance_to_end_and_start + obstacle_radius)
    %             flag = true;
    %             counter_4 = counter_4 + 1;
    %         end
    %         if distance_to_end < (min_distance_to_end_and_start + obstacle_radius)
    %             flag = true;
    %             counter_4 = counter_4 + 1;
    %         end
    %     end
    % end

end



% Initialize figure
figure;
hold on;
axis equal;
colors = ['r', 'g', 'b','c', 'k', 'm']; % Colors for different sets
for i = 1:numSets
        % Plotting circles
    startIndex = (i - 1) * numCentersPerSet + 1;
    endIndex = i * numCentersPerSet;
    set_centers = centers(startIndex:endIndex, :);
    set_radii = radii(startIndex:endIndex);

    xMin = min(set_centers(:,1) - set_radii);
    yMin = min(set_centers(:,2) - set_radii);
    xMax = max(set_centers(:,1) + set_radii);
    yMax = max(set_centers(:,2) + set_radii);

    width = xMax - xMin;
    height = yMax - yMin;
    theta = linspace(0, 2*pi, 100);
    for j = 1:length(set_radii)
        fill(set_centers(j,1) + set_radii(j)*cos(theta), set_centers(j,2) + set_radii(j)*sin(theta), colors(i), 'LineStyle', 'none');
    end

    % Plotting rectangle
    rectangle('Position', [xMin, yMin, width, height], 'EdgeColor', colors(i), 'LineWidth', 2);

end

plot(X_s(1,1), X_s(1,2), 'ro', 'MarkerSize', 10);
plot(X_e(1,1), X_e(1,2), 'ro', 'MarkerSize', 10);
% Label the plot
xlabel('X-coordinate');
ylabel('Y-coordinate');
title(sprintf('Obstacle Sets Configuration (Number of Pairs: %d)', number_of_pairs));
grid on;
legend('Set 1', 'Set 2', 'Set 3', 'Location', 'bestoutside');

hold off; % Release the hold on the current figure

obstacle_radious = radii';
obstacle = centers;

% ============================================================================
% CREATE FOLDER FOR THIS NUMBER OF PAIRS
% ============================================================================
pairs_folder = fullfile(output_folder, sprintf('%dpairs', number_of_pairs));
if ~exist(pairs_folder, 'dir')
    mkdir(pairs_folder);
end

% Find the next available set number for this number of pairs
% Look for existing files matching pattern: set_[number]_[pairs]pairs.mat
% Search in the pairs-specific folder
pattern = sprintf('set_*_%dpairs.mat', number_of_pairs);
existing_files = dir(fullfile(pairs_folder, pattern));

% Extract set numbers from existing files
set_numbers = [];
for i = 1:length(existing_files)
    filename_parts = strsplit(existing_files(i).name, '_');
    if length(filename_parts) >= 3
        try
            set_num = str2double(filename_parts{2});
            if ~isnan(set_num)
                set_numbers = [set_numbers, set_num];
            end
        catch
            % Skip if conversion fails
        end
    end
end

% Determine the next available set number
if isempty(set_numbers)
    next_set_number = 1;
else
    next_set_number = max(set_numbers) + 1;
end

% Create filename: set_[number]_[pairs]pairs.mat
filename = sprintf('set_%d_%dpairs.mat', next_set_number, number_of_pairs);
% Save in pairs-specific folder
file_path = fullfile(pairs_folder, filename);
% Save variables to the file (including number of pairs)
save(file_path, 'y_range', 'x_range', 'X_e','X_s','obstacle','obstacle_radious','number_of_pairs');

% ============================================================================
% SAVE FIGURE TO FOLDER
% ============================================================================
figure_filename = sprintf('set_%d_%dpairs.png', next_set_number, number_of_pairs);
figure_path = fullfile(pairs_folder, figure_filename);
saveas(gcf, figure_path);

% Display information
fprintf('\n=== Obstacle Set Created ===\n');
fprintf('Number of Pairs: %d\n', number_of_pairs);
fprintf('Total Obstacles: %d\n', num_obstacles);
fprintf('Folder: %s\n', pairs_folder);
fprintf('File saved: %s\n', filename);
fprintf('Figure saved: %s\n', figure_filename);
fprintf('\nRejection Counters:\n');
fprintf('  Middle points too close: %d\n', counter_5);
fprintf('  Distance between pairs: %d\n', counter_1);
fprintf('  Rectangle collisions: %d\n', counter_2);
fprintf('  Obstacle intersections: %d\n', counter_3);
fprintf('  Start/End distance: %d\n', counter_4);
fprintf('\n');

disp(mahboobe)
end