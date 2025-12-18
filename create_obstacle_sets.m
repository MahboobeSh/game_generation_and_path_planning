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
x_scaled = 0.9*x_range;
y_scaled = 0.7*y_range;
x_margin = 0.05*x_range;  % 5% margin
y_margin = 0.15*y_range;
number_of_pairs = 5;
max_distance = sqrt(x_range^2 + y_range^2);
output_folder = "/home/mahboobe/Desktop/game_generation_and_path_planning/new_games";
output_folder = "C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits\final_games";


% ============================================================================
% OBSTACLE RADIUS CONFIGURATION (Global Variables - Easy to Modify)
% ============================================================================
% Set the minimum and maximum obstacle radius (in cm)
% These values are used for all pair counts (2-5 pairs)
% To change obstacle sizes, modify these two variables:
min_radius = 2;  % Minimum obstacle radius (cm)
max_radius = 3.5;  % Maximum obstacle radius (cm)
% ============================================================================

% ============================================================================
% DISTANCE CONSTRAINT CONFIGURATION (Global Variables - Easy to Modify)
% ============================================================================
% SIMPLIFIED APPROACH: Fixed minimums, scaling maximums
% - Minimum values: FIXED (same for all pair counts) - ensures consistent difficulty floor
% - Maximum values: SCALE with number of pairs - adapts to available space
%
% MINIMUM VALUES (Fixed - same for all pairs 2-5):
min_distance_between_obstacles = 2;  % Minimum gap between obstacles from different pairs (cm)
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
for mahboobe=1:150
flag = true;


counter_1 =0;
counter_2 =0;
counter_3 = 0;
counter_4 = 0;
counter_5 = 0;
counter_6 = 0;  % New counter for obstacle rejections
while flag
    flag = false;
    obstacle_flag = false;  % Flag for obstacle-only constraints
    
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
            obstacle_flag = true;
            counter_1 = counter_1 + 1;
        end
        
        % ============================================================================
        % CONSTRAINT CHECK 3: Maximum Distance Between Obstacles in Same Pair (ACTIVE)
        % ============================================================================
        % Prevents obstacles in same pair from being too far apart
        % This is NECESSARY - without it, gates become too wide and games are too easy
        if distance_between_obstacles > (max_distance_between_obstacle_pairs + 2*radius)
            obstacle_flag = true;
            counter_1 = counter_1 + 1;
        end
    end
    
    % ============================================================================
    % CONSTRAINT CHECK 4: Rectangle Collisions (ACTIVE)
    % ============================================================================
    % Prevents bounding rectangles of different pairs from overlapping
    % This is NECESSARY to prevent pairs from being too close together
    if checkRectanglesForCollision(rectangles)
        obstacle_flag = true;
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
                obstacle_flag = true;
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
        %         end
    end

    % ============================================================================
    % CHECK IF OBSTACLES ARE VALID
    % ============================================================================
    % If obstacles failed constraints, skip start/end generation and try new obstacles
    if obstacle_flag
        flag = true;
        counter_6 = counter_6 + 1;
        continue;  % Skip to next iteration, regenerate obstacles
    end
    
    % ============================================================================
    % OBSTACLES ARE VALID - NOW TRY MULTIPLE START/END PLACEMENTS
    % ============================================================================
    % Try up to max_start_end_attempts different start/end positions
    % Only regenerate obstacles if ALL start/end attempts fail
    
    max_start_end_attempts = 20;  % Try 20 different start/end placements
    start_end_found = false;
    
    for attempt = 1:max_start_end_attempts
    
    % ============================================================================
    % START AND END POINT GENERATION (Choose Method Below)
    % ============================================================================
    
    % ============================================================================
    % MULTI-ANGLE START/END POINT GENERATION STRATEGY
    % ============================================================================
    % Tries different approach angles relative to gate line:
    %
    % METHOD 1 (Attempts 1-5): ANGLED APPROACH LINES
    %   Attempt 1: 90° (perpendicular - classic straight path)
    %   Attempt 2: 80° (slight angle)
    %   Attempt 3: 75° (moderate angle)
    %   Attempt 4: 60° (steeper angle)
    %   Attempt 5: 45° (diagonal approach)
    %
    % METHOD 2 (Attempts 6-15): GATE-ALIGNED
    %   - Y directly aligned with gate midpoint (reliable)
    %
    % METHOD 3 (Attempts 16-20): RANDOM
    %   - Y randomly placed in safe zone
    %
    % X positions progressively explore extended range (-3 to 0, 48 to 51)
    % ============================================================================
    
    start_x_min = -3;  % Can extend 3cm before play area
    start_x_max = 0;   % Up to play area start
    end_x_min = x_range;  % From play area end (48)
    end_x_max = x_range + 3;  % Can extend 3cm beyond play area (51)
    start_end_y_margin = 2.0;  % Minimum margin from top/bottom edges (cm)
    
    % Define approach angles (in degrees from perpendicular)
    % 90° = perpendicular, smaller = more angled toward horizontal
    approach_angles = [90, 80, 75, 60, 45];  % degrees
    
    % === START POINT - MULTI-ANGLE APPROACH ===
    point1 = centers(1, :);
    point2 = centers(2, :);
    midpoint_first = (point1 + point2) / 2;
    
    % Calculate gate angle
    gate_angle = atan2(point2(2) - point1(2), point2(1) - point1(1));
    
    % X position varies by attempt
    if attempt == 1
        X_s_x = 0;  % At play area edge
    elseif attempt <= 5
        X_s_x = -1.5 + rand() * 1.5;  % Range: [-1.5, 0]
    elseif attempt <= 10
        X_s_x = start_x_min + rand() * 2;  % Range: [-3, -1]
    else
        X_s_x = start_x_min + rand() * (start_x_max - start_x_min);
    end
    
    % Y-COORDINATE STRATEGY:
    if attempt <= 5
        % METHOD 1: Angled approach lines (try different angles)
        angle_idx = attempt;
        approach_deg = approach_angles(angle_idx);
        approach_rad = deg2rad(approach_deg);
        
        % Calculate approach line angle (perpendicular + deviation)
        % For start point, we want line going LEFT from midpoint
        approach_line_angle = gate_angle + approach_rad;
        approach_slope = tan(approach_line_angle);
        approach_intercept = midpoint_first(2) - approach_slope * midpoint_first(1);
        
        X_s_y = approach_slope * X_s_x + approach_intercept;
    elseif attempt <= 15
        % METHOD 2: Gate-aligned (reliable fallback)
        if attempt <= 10
            % Exact alignment with gate
            X_s_y = midpoint_first(2);
        else
            % Small variations around gate (±1.5cm)
            variation = (rand() - 0.5) * 3.0;
            X_s_y = midpoint_first(2) + variation;
        end
    else
        % METHOD 3: Random in safe zone (last resort)
        X_s_y = start_end_y_margin + (y_range - 2*start_end_y_margin) * rand();
    end
    
    % Clamp to safe bounds
    X_s_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_s_y));
    X_s = [X_s_x, X_s_y];
    
    % === END POINT - MULTI-ANGLE APPROACH ===
    point1 = centers(end, :);
    point2 = centers(end-1, :);
    midpoint_last = (point1 + point2) / 2;
    
    % Calculate gate angle
    gate_angle_end = atan2(point2(2) - point1(2), point2(1) - point1(1));
    
    % X position varies by attempt
    if attempt == 1
        X_e_x = x_range;  % At play area edge
    elseif attempt <= 5
        X_e_x = x_range + rand() * 1.5;  % Range: [48, 49.5]
    elseif attempt <= 10
        X_e_x = x_range + 1 + rand() * 2;  % Range: [49, 51]
    else
        X_e_x = end_x_min + rand() * (end_x_max - end_x_min);
    end
    
    % Y-COORDINATE STRATEGY:
    if attempt <= 5
        % METHOD 1: Angled approach lines (try different angles)
        angle_idx = attempt;
        approach_deg = approach_angles(angle_idx);
        approach_rad = deg2rad(approach_deg);
        
        % Calculate approach line angle (perpendicular + deviation)
        % For end point, we want line going RIGHT from midpoint
        approach_line_angle = gate_angle_end + approach_rad;
        approach_slope = tan(approach_line_angle);
        approach_intercept = midpoint_last(2) - approach_slope * midpoint_last(1);
        
        X_e_y = approach_slope * X_e_x + approach_intercept;
    elseif attempt <= 15
        % METHOD 2: Gate-aligned (reliable fallback)
        if attempt <= 10
            % Exact alignment with gate
            X_e_y = midpoint_last(2);
        else
            % Small variations around gate (±1.5cm)
            variation = (rand() - 0.5) * 3.0;
            X_e_y = midpoint_last(2) + variation;
        end
    else
        % METHOD 3: Random in safe zone (last resort)
        X_e_y = start_end_y_margin + (y_range - 2*start_end_y_margin) * rand();
    end
    
    % Clamp to safe bounds
    X_e_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_e_y));
    X_e = [X_e_x, X_e_y];

    % ============================================================================
    % CONSTRAINT CHECK 6: Start/End Points Not Inside Rectangles (ACTIVE)
    % ============================================================================
    % Ensures start and end points are not inside any obstacle bounding boxes
    % AND have a safety buffer around the boxes
    % This is ESSENTIAL to prevent start/end points from being blocked
    
    start_end_valid = true;  % Assume valid until proven otherwise
    
    % Buffer distance around rectangles (cm) - adjust this value as needed
    rectangle_buffer = 2.5;  % Same as min_distance_to_end_and_start for consistency
    
    for i = 1:numSets
        rect = rectangles(i, :);
        % Expand rectangle by buffer distance
        expanded_rect = [rect(1) - rectangle_buffer, ...
                         rect(2) - rectangle_buffer, ...
                         rect(3) + 2*rectangle_buffer, ...
                         rect(4) + 2*rectangle_buffer];
        
        % Check if start point is inside expanded rectangle
        if isPointInsideRectangle(X_s, expanded_rect)
            start_end_valid = false;
            counter_4 = counter_4 + 1;
            break;
        end
        % Check if end point is inside expanded rectangle
        if isPointInsideRectangle(X_e, expanded_rect)
            start_end_valid = false;
            counter_4 = counter_4 + 1;
            break;
        end
    end

    % ============================================================================
    % CONSTRAINT CHECK 7: Start/End Distance from Obstacles (ACTIVE)
    % ============================================================================
    % Ensures obstacles are not too close to start/end points
    % This is RECOMMENDED for fair gameplay
    if start_end_valid  % Only check if still valid
        for i = 1:num_obstacles
            obstacle_position = centers(i, :);
            obstacle_radius = radii(i);
            % Calculate the distance to the start and end points
            distance_to_start = norm(X_s - obstacle_position);
            distance_to_end = norm(X_e - obstacle_position);
            
            % For all obstacles, ensure they're not too close to start/end
            % (minimum distance check to ensure accessibility)
            if distance_to_start < (min_distance_to_end_and_start + obstacle_radius)
                start_end_valid = false;
                counter_5 = counter_5 + 1;
                break;
            end
            if distance_to_end < (min_distance_to_end_and_start + obstacle_radius)
                start_end_valid = false;
                counter_5 = counter_5 + 1;
                break;
            end
        end
    end
    
    % ============================================================================
    % CHECK IF THIS START/END PLACEMENT IS VALID
    % ============================================================================
    if start_end_valid
        start_end_found = true;
        break;  % Exit start/end attempt loop, we found valid points!
    end
    
    end  % End of start/end attempt loop
    
    % ============================================================================
    % IF NO VALID START/END FOUND AFTER ALL ATTEMPTS
    % ============================================================================
    if ~start_end_found
        flag = true;  % Regenerate obstacles
        counter_6 = counter_6 + 1;
    end

end



% Initialize figure (invisible - no popup)
figure('Visible', 'off');
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

% Plot start and end points
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

% Close figure to free memory (since we're in a loop)
close(gcf);

% Display information
fprintf('\n=== Obstacle Set Created ===\n');
fprintf('Number of Pairs: %d\n', number_of_pairs);
fprintf('Total Obstacles: %d\n', num_obstacles);
fprintf('Folder: %s\n', pairs_folder);
fprintf('File saved: %s\n', filename);
fprintf('Figure saved: %s\n', figure_filename);
fprintf('\nRejection Counters:\n');
fprintf('  Distance between pairs: %d\n', counter_1);
fprintf('  Rectangle collisions: %d\n', counter_2);
fprintf('  Obstacle intersections: %d\n', counter_3);
fprintf('  Start/End constraints: %d\n', counter_4 + counter_5);
fprintf('  Total obstacle rejections: %d\n', counter_6);
fprintf('\n');

disp(mahboobe)
end