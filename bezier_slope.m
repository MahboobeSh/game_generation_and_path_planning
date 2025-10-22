function slopes = bezier_slope(P,num_samples)
    % BEZIER_SLOPE calculates the slopes of the Bezier curve at parameters in t_values
    % P - matrix of control points (each row is a point)
    % t_values - vector of parameters [0, 1]
    t_values = linspace(0, 1, num_samples);
    n = size(P, 1) - 1; % degree of the curve
    slopes = zeros(size(t_values)); % initialize the output slopes

    for j = 1:length(t_values)
        t = t_values(j);
        B_prime = zeros(size(P(1, :))); % initialize the derivative point

        for i = 0:n-1
            B_prime = B_prime + binomial_coefficient(n-1, i) * (1 - t)^(n-1-i) * t^i * (P(i+2, :) - P(i+1, :));
        end

        % Calculate slope as dy/dx
        slopes(j) = B_prime(2) / B_prime(1);
    end
end
