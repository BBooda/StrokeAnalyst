function bw = pixel_brush(cols,rows, radius, center)
%bw = pixel_brush(cols,rows, radius, center)
% center(1) controls the column position
% center(2) controls the row position

    [columnsInImage, rowsInImage] = meshgrid(1:cols, 1:rows);
    % Next create the circle in the image.
    centerX = center(1);
    centerY = center(2);
    
    % bw is the binary image of the circle
    bw = (rowsInImage - centerY).^2 ...
        + (columnsInImage - centerX).^2 <= radius.^2;
    


end

