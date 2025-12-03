function [equalized_curve, segment_info] = generate_equalized_bezier_curve(curve_segment_points, step_size)
% GENERATE_EQUALIZED_BEZIER_CURVE Generate an equalized Bezier curve with specified step size
%
% This function:
%   1. Calculates the length of each Bezier segment
%   2. Determines the number of sample points needed for each segment based on step_size
%   3. Generates equalized curves using bezier_equidistant
%   4. Combines segments into a single curve (removing duplicate boundary points)
%
% Inputs:
%   curve_segment_points - 3D array (n_control_points x 2 x num_segments)
%                          Control points for each Bezier segment
%   step_size           - Desired spacing between points (in cm), e.g., 0.25 or 0.5
%
% Outputs:
%   equalized_curve     - Nx2 array of equalized curve points with ~step_size spacing
%                         (duplicate boundary points between segments are removed)
%   segment_info        - Structure containing:
%                         .lengths         - Array of segment arc lengths (cm)
%                         .num_samples     - Array of number of samples per segment
%                         .curves          - Cell array of individual segment curves
%                         .actual_spacing  - Statistics on actual spacing achieved
%
% Example:
%   step_size = 0.25;  % 0.25 cm spacing
%   [curve, info] = generate_equalized_bezier_curve(control_points, step_size);
%
% See also: bezier_equidistant, bezier_curve, calculate_curve_segment_points

    % Input validation
    if nargin < 2
        error('Both curve_segment_points and step_size are required');
    end
    
    if step_size <= 0
        error('step_size must be positive');
    end
    
    if ndims(curve_segment_points) ~= 3 || size(curve_segment_points, 2) ~= 2
        error('curve_segment_points must be a 3D array with dimensions (n_control_points x 2 x num_segments)');
    end
    
    num_segments = size(curve_segment_points, 3);
    
    % ============================================================================
    % STEP 1: Calculate segment lengths
    % ============================================================================
    fprintf('Calculating segment lengths...\n');
    segment_lengths = zeros(num_segments, 1);
    
    for i = 1:num_segments
        segment_control_points = curve_segment_points(:, :, i);
        % Use high-resolution curve to measure true arc length
        temp_curve = bezier_equidistant(segment_control_points, 1000);
        segment_lengths(i) = sum(sqrt(sum(diff(temp_curve, 1, 1).^2, 2)));
    end
    
    % ============================================================================
    % STEP 2: Determine number of samples for each segment
    % ============================================================================
    % For num_samples points, there are (num_samples - 1) gaps
    % If we want spacing = step_size, then: segment_length = (num_samples - 1) * step_size
    % Therefore: num_samples = (segment_length / step_size) + 1
    
    num_samples_list = round(segment_lengths / step_size) + 1;
    % Ensure at least 2 points per segment (start and end)
    num_samples_list = max(num_samples_list, 2);
    
    fprintf('Segment information:\n');
    for i = 1:num_segments
        fprintf('  Segment %d: length = %.4f cm, samples = %d, expected spacing = %.4f cm\n', ...
            i, segment_lengths(i), num_samples_list(i), segment_lengths(i) / (num_samples_list(i) - 1));
    end
    
    % ============================================================================
    % STEP 3: Generate equalized curves with calculated number of samples
    % ============================================================================
    fprintf('Generating equalized curves with %.4f cm step size...\n', step_size);
    
    segment_curves = cell(num_segments, 1);
    equalized_curve = [];  % Composite curve without duplicate boundary points
    
    for i = 1:num_segments
        segment_control_points = curve_segment_points(:, :, i);
        % Apply equidistant equalization with calculated number of samples
        segment_curve = bezier_equidistant(segment_control_points, num_samples_list(i));
        segment_curves{i} = segment_curve;
        
        % For composite curve without duplicates: remove last point of each segment
        % (except last segment) since it's the same as first point of next segment
        if i < num_segments
            equalized_curve = [equalized_curve; segment_curve(1:end-1, :)];
        else
            equalized_curve = [equalized_curve; segment_curve];
        end
    end
    
    % ============================================================================
    % STEP 4: Calculate actual spacing statistics
    % ============================================================================
    distances = sqrt(sum(diff(equalized_curve, 1, 1).^2, 2));
    
    segment_info = struct();
    segment_info.lengths = segment_lengths;
    segment_info.num_samples = num_samples_list;
    segment_info.curves = segment_curves;
    segment_info.actual_spacing = struct();
    segment_info.actual_spacing.mean = mean(distances);
    segment_info.actual_spacing.std = std(distances);
    segment_info.actual_spacing.min = min(distances);
    segment_info.actual_spacing.max = max(distances);
    segment_info.actual_spacing.target = step_size;
    segment_info.actual_spacing.deviation_from_target = abs(mean(distances) - step_size);
    
    % ============================================================================
    % STEP 5: Print summary
    % ============================================================================
    fprintf('\n=== EQUALIZED CURVE SUMMARY ===\n');
    fprintf('Target step size:         %.4f cm\n', step_size);
    fprintf('Total curve length:       %.4f cm\n', sum(segment_lengths));
    fprintf('Total points:             %d\n', size(equalized_curve, 1));
    fprintf('Number of segments:       %d\n', num_segments);
    fprintf('\nActual spacing achieved:\n');
    fprintf('  Mean:                   %.4f cm\n', segment_info.actual_spacing.mean);
    fprintf('  Std deviation:          %.4f cm\n', segment_info.actual_spacing.std);
    fprintf('  Min:                    %.4f cm\n', segment_info.actual_spacing.min);
    fprintf('  Max:                    %.4f cm\n', segment_info.actual_spacing.max);
    fprintf('  Deviation from target:  %.4f cm (%.2f%%)\n', ...
        segment_info.actual_spacing.deviation_from_target, ...
        (segment_info.actual_spacing.deviation_from_target / step_size) * 100);
    fprintf('  Coefficient of variation: %.4f%%\n', ...
        (segment_info.actual_spacing.std / segment_info.actual_spacing.mean) * 100);
    
    fprintf('\nDone! Generated equalized curve with %d points.\n', size(equalized_curve, 1));
end

