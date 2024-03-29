function [feature_vector, labels] = create_ml_features(hemi_mask,varargin)
    % key value pairs: subject, zscore, zscore_dif, color_features
    % create ml_feature vector. The default options create a vector that consist 
    % of 3 pixel intensity features for every color channel. 2 features for 
    % the zscore image and 2 features for the zscore image difference
    
    % default values 
    neigh = 3;
    filtering = 'average';
    % parse input data 
    for i = 1:length(varargin)
        if strcmp(varargin{i}, 'subject')
            subject = bsxfun(@times, varargin{i+1}, cast(hemi_mask, 'like', varargin{i+1}));
        end
        if strcmp(varargin{i}, 'zscore')
            zscore = bsxfun(@times, varargin{i+1}, cast(hemi_mask, 'like', varargin{i+1}));
        end
        if strcmp(varargin{i}, 'zscore_dif')
            zsc_dif = bsxfun(@times, varargin{i+1}, cast(hemi_mask, 'like', varargin{i+1}));
        end
        if strcmp(varargin{i}, 'color_features')
            color_f.red = bsxfun(@times, varargin{i+1}.red_ch_diff, cast(hemi_mask, 'like', varargin{i+1}.red_ch_diff));
            color_f.green = bsxfun(@times, varargin{i+1}.green_ch_diff, cast(hemi_mask, 'like', varargin{i+1}.green_ch_diff));
            color_f.blue = bsxfun(@times, varargin{i+1}.blue_ch_diff, cast(hemi_mask, 'like', varargin{i+1}.blue_ch_diff));
        end
        if strcmp(varargin{i}, 'ground_truth')
            labels = varargin{i+1};
        end
        if strcmp(varargin{i}, 'filtering')
            filtering = varargin{i+1};
        end
        if strcmp(varargin{i}, 'neighborhood')
            neigh = varargin{i+1};
        end
    end
    
    % follow the default method and create a feature vector containing
    % subject intesities zscore map and zscore difference map using a 3x3
    % average filter
    if exist('color_f', 'var')
        X = zeros(numel(zscore), 19);
    else
        X = zeros(numel(zscore), 13);
    end
    
    % create anonymous function to specify the desired filter and create the
    % desired neighborhood information
    if strcmp(filtering, 'average')
        my_filter = @(img) imfilter(img, fspecial('average', neigh));
    elseif strcmp(filtering, 'median')
        my_filter = @(img) medfilt2(img, [neigh neigh]);   
    end
    
    cha1 = subject(:,:,1);
    cha2 = subject(:,:,2);
    cha3 = subject(:,:,3);    

    X(:,1) = cha1(:);
    
    X(:,2) = cha2(:);
    
    X(:,3) = cha3(:);

    gaussian_img1 = imgaussfilt(cha1, 3); X(:,4) = gaussian_img1(:);
    
    gaussian_img2 = imgaussfilt(cha2, 3);X(:,5) = gaussian_img2(:);
    
    gaussian_img3 = imgaussfilt(cha3, 3);X(:,6) = gaussian_img3(:);
    
    filtered1 = my_filter(cha1); X(:,7) = filtered1(:);

    filtered2 = my_filter(cha2); X(:,8) = filtered2(:);

    filtered3 = my_filter(cha3); X(:,9) = filtered3(:);
    
    % zscore features
    X(:,10) = zscore(:);
    
    filtered_z = my_filter(zscore); X(:,11) = filtered_z(:);

    X(:,12) = zsc_dif(:);  
      
    filtered_z_dif = my_filter(zsc_dif); X(:,13) = filtered_z_dif(:);
   
    if exist('color_f', 'var')
        X(:,14) = color_f.red(:);
        X(:,15) = my_filter(color_f.red(:));
        X(:,16) = color_f.green(:);
        X(:,17) = my_filter(color_f.green(:));
        X(:,18) = color_f.blue(:);
        X(:,19) = my_filter(color_f.blue(:));
    end
    
    feature_vector = X;    
    
    if ~exist('labels', 'var')
        labels = nan;
    end
end