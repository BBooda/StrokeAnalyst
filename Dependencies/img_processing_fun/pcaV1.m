function [imRotated, rgbout] = pcaV1(im, varargin)
%[imRotated, rgbout] = pcaV1(im, varargin)
%pcaV1: rotate image to horizontal axes. second input: true => plot pca
% works with images that have their background removed.

%check if image is rgb 
[~, ~ ,channels] = size(im);
if channels > 2
    imrgb = im;
    im = rgb2gray(im);
end

%find non zero(no black pixels) point cloud
[y,x] = find(im(:,:) ~= 0);

%Subtract mean from each dimension 
x = x - mean(x);
y = y - mean(y);
coords = [x,y];

%compute covariance matrix and its eigenvectors and eigenvalues
covi = cov(coords);
[evecs, evals] = eig(covi);

%Sort eigenvalues in decreasing order
[~, sort_ind] = sort(diag(evals));
x1 = evecs(1, sort_ind(1));% Eigenvector with largest eigenvalue
y1 = evecs(2, sort_ind(1));% Eigenvector with largest eigenvalue 
x2 = evecs(1, sort_ind(2));
y2 = evecs(2, sort_ind(2));

%Plot the principal components(optional)
if (0)
        scatter(x,-y,'g'); hold on;
        scale = 20;
        plot([x1*-scale*2, x2*scale*2],[y1*-scale*2, y2*scale*2], 'r');
        hold on;
        plot([x2*scale, x1*scale],[y2*scale, y1*scale], 'b');
        
        %compute center mass and check for alignement with vectors 
        xmean = mean(x(:));
        ymean = mean(y(:));
        
        hold on; scatter(xmean,ymean, 'r');
end

%calculate theta and rotation matrix 
if (isempty(varargin)) || (varargin{1} == 0)
    theta = atan(y2/x2);
elseif (varargin{1} == 1)
    %flip axis alignment
    theta = atan(y1/x1);
end
rotation_mat = [cos(theta), -sin(theta), 0;sin(theta), cos(theta), 0; 0, 0, 1];
%rotate image using the calculated matrix and an affine2d transform 
tf = affine2d(rotation_mat);
imRotated = imwarp(im, tf);
if channels >2 
    rgbout = zeros([size(imRotated), 3], 'uint8');
    rgbout(:,:,1) = imwarp(imrgb(:,:,1), tf);
    rgbout(:,:,2) = imwarp(imrgb(:,:,2), tf);
    rgbout(:,:,3) = imwarp(imrgb(:,:,3), tf);
else
    rgbout = imRotated;
end


end

