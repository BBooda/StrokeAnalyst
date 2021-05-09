function out = segment_img(img,varargin)
% segment image using either GraphCut method or K-means combined with MRF
% method
% modes = 'K&SUPER', 'K&MRF', 'GraphCut'

if isempty(varargin)
    mode = 'K&SUPER';
else
    mode = varargin{1};
end


if strcmp(mode, 'K&SUPER')
    % compute superpixels
    img_supered = avg_superpixels(img, 0.005);
    
    %kmeans segmentation
    
    segm = imsegkmeans(img_supered, 3);
    
    mask = cmp_out_mask(segm);
    
    out = bsxfun(@times, img, cast(mask,class(img)));
    
elseif (strcmp(mode, 'K&MRF'))
    out = remove_lession_background_ui(img);

elseif (strcmp(mode, 'GraphCut'))
%     out = remove_lession_background(img);

end




% % set up 3 centers for k-means and MRF
% class_number = 3;
% clusters = markovRRF_segmentation(img_supered, 'ClassNumber', class_number);
% out = clusters;


end

function out_mask = cmp_out_mask(segm)
     % check for bounding box area, keep cluster with bigger area
    props = regionprops(segm, 'BoundingBox');
    max_area = -1;
    ind = -1;
    for i = 1:3
        area = props(i).BoundingBox(3) * props(i).BoundingBox(4);
        if area > max_area
            max_area = area;
            ind = i;
        end
    end
    mask = segm == ind;
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
    out_mask = ismember(L, find([S.Area] >= max([S.Area])));
end
