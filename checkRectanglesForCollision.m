function flag = checkRectanglesForCollision(rectangles)
    n = size(rectangles, 1);
    flag = false;
    for i = 1:n
        for j = i+1:n
            if checkRectangleCollision(rectangles(i,1), rectangles(i,2), rectangles(i,3), rectangles(i,4), rectangles(j,1), rectangles(j,2), rectangles(j,3), rectangles(j,4))
                % fprintf('Rectangles %d and %d are colliding.\n', i, j);
                flag = true;
            else
                % fprintf('Rectangles %d and %d are not colliding.\n', i, j);
            end
        end
    end
end
