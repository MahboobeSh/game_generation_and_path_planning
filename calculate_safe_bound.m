function bounds = calculate_safe_bound(curve,obstacle,obstacle_radious,percent, threshold)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    bezier_curve = curve;
    obstacles_centers = obstacle;
    obstacles_radii = obstacle_radious;
    distance_matrix = pdist2(bezier_curve, obstacles_centers) - obstacles_radii;
    min_distance_vector = min(distance_matrix, [], 2);
    bounds = min(percent*min_distance_vector,threshold);
end