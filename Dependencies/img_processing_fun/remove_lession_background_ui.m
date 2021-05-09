function [masked_image, mask] = remove_lession_background_ui(img, varargin)
    class_number = 3;
    clusters = markovRRF_segmentation(img, 'ClassNumber', class_number);

    % check for bounding box area, keep cluster with bigger area
    props = regionprops(clusters, 'BoundingBox');
    max_area = -1;
    ind = -1;
    for i = 1:class_number
        area = props(i).BoundingBox(3) * props(i).BoundingBox(4);
        if area > max_area
            max_area = area;
            ind = i;
        end
    end
    mask = clusters == ind;
    mask = ~mask;
    mask = imclose(mask, strel('disk', 5));
    windowSize = 5;
    kernel = ones(windowSize) / windowSize ^ 2;
    blurryImage = conv2(single(mask), kernel, 'same');
    mask = blurryImage > 0.5;
    mask = imfill(mask, 'holes');
    % area filter
    CC = bwconncomp(mask);
    S = regionprops(CC, 'Area');
    L = labelmatrix(CC);
    mask = ismember(L, find([S.Area] >= max([S.Area])));

   
    
    
    if ~isempty(varargin)
        if strcmp(varargin{1}, 'active_contour')& strcmp(varargin{2}, 'edge')
             bw = activecontour(rgb2gray(img), mask, 400, 'edge');
             masked_image = bsxfun(@times, img, cast(bw,class(img)));
             [~, masked_image] = pcaV1(masked_image);
        elseif strcmp(varargin{1}, 'active_contour')& strcmp(varargin{2}, 'Chan-Vese')
             bw = activecontour(rgb2gray(img), mask, 'Chan-Vese');
             masked_image = bsxfun(@times, img, cast(bw,class(img)));
             [~, masked_image] = pcaV1(masked_image);
        else
            masked_image = bsxfun(@times, img, cast(mask,class(img)));
            [~, masked_image] = pcaV1(masked_image);    
        end
    else
        masked_image = bsxfun(@times, img, cast(mask,class(img)));
        [~, masked_image] = pcaV1(masked_image);
    end
    
end