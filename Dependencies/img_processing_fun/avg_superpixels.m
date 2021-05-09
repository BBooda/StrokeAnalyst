function img_superd = avg_superpixels(img,varargin)
% img_superd = avg_superpixels(img,percentage)
% + img -> input img
% + percentage -> can be specified to any value and represents what portion
% of the pixel used. (Default = 0.0003 i.e. 0.03%)
% create an average superpixel image using different superpixel sizes.
% 

    if isempty(varargin)
        % default value 
        p = 0.0003;
    else
        p = varargin{1};
    end
    
    [heigth, width, ~] = size(img);
    num_of_pix = width * heigth;
    % determine num of superpixels as percentage 
    num_of_super = round(num_of_pix * p); % where 0.0003 % is the 0.03 % of the original number

%     L = superpixels(img,num_of_super);
%     bg_mask = lazysnapping(img,L,foregroundInd,backgroundInd);

    
    % compute average superpixels 
    p_matrix = [p, 2*p, 4*p, 8*p];
    
    out = zeros(size(img), 'like', img);
    img_superd = zeros(size(img), 'like', img);
    
    for i = 1:4 %length of p_matrix
        [L,N] = superpixels(img, round(num_of_pix * p_matrix(i)));
        idx = label2idx(L);

        for labelVal = 1:N
            redIdx = idx{labelVal};
            greenIdx = idx{labelVal}+heigth*width;
            blueIdx = idx{labelVal}+2*heigth*width;
            out(redIdx) = mean(img(redIdx));
            out(greenIdx) = mean(img(greenIdx));
            out(blueIdx) = mean(img(blueIdx));
        end   
        
        img_superd = 0.5*(img_superd + out);
        
    end


end

