function curve = bezier_curve(points, num_samples)
    t = linspace(0, 1, num_samples);
    n = size(points, 1) - 1;
    curve = zeros(num_samples, 2);
    for i = 1:num_samples
        for j = 0:n
            curve(i, :) = curve(i, :) + points(j+1, :) * binomial_coefficient(n, j) * (1 - t(i))^(n - j) * t(i)^j;
        end
    end
end
