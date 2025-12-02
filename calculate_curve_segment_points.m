function [curve_segment_points] =  calculate_curve_segment_points(variables_matrix, Start_points, End_points, num_segments, n_d, n_phi)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
    general_phi_d_matrix =  variables_matrix;
    curve_segment_points = zeros(5,2,num_segments);
    if n_d == 3 && n_phi == 2
        curve_segment_points = zeros(6,2,num_segments);
    end
    for i = 1:num_segments
        if n_d == 1 && n_phi == 1
            % not impelemnted for forth degree
            temp1=  control_points_with_d_and_phi(Start_points(i,:), general_phi_d_matrix(i,1), general_phi_d_matrix(i,2));
            temp2= control_points_with_d_and_phi(End_points(i,:), general_phi_d_matrix(i+1,1), general_phi_d_matrix(i+1,2));

        elseif n_d == 2 && n_phi == 1
            temp1=  control_points_with_d_and_phi(Start_points(i,:), general_phi_d_matrix(i,2), general_phi_d_matrix(i,4));
            temp2= control_points_with_d_and_phi(End_points(i,:), general_phi_d_matrix(i+1,1), general_phi_d_matrix(i+1,4));
            temp3 = control_points_with_d_and_phi(Start_points(i,:), general_phi_d_matrix(i,3), general_phi_d_matrix(i,5));
            curve_segment_points(:, :,i)=[Start_points(i,:);temp1(2,:);temp3(2,:);temp2(1,:);End_points(i,:)];
        elseif n_d == 3 && n_phi == 2
            temp1=  control_points_with_d_and_phi(Start_points(i,:), general_phi_d_matrix(i,2), general_phi_d_matrix(i,5));
            temp2= control_points_with_d_and_phi(End_points(i,:), general_phi_d_matrix(i+1,1), general_phi_d_matrix(i+1,5));
            temp3 = control_points_with_d_and_phi(Start_points(i,:), general_phi_d_matrix(i,3), general_phi_d_matrix(i,6));
            temp4 = control_points_with_d_and_phi(Start_points(i,:), general_phi_d_matrix(i,4), general_phi_d_matrix(i,7));
            curve_segment_points(:, :,i)=[Start_points(i,:);temp1(2,:);temp3(2,:);temp4(2,:);temp2(1,:);End_points(i,:)];
        else
            %not impelmented for forth degree
            temp1=  control_points_with_d_and_phi(Start_points(i,:), general_phi_d_matrix(i,2), general_phi_d_matrix(i,4));
            temp2= control_points_with_d_and_phi(End_points(i,:), general_phi_d_matrix(i+1,1), general_phi_d_matrix(i+1,3));
        end
        
    end
end