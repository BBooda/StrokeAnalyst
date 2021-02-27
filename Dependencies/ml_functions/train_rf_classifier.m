function model = train_rf_classifier(imgs,zsc,h_dif,labeled_imgs, trees)
% train_rf_classifier(imgs, color_features, zscore_images, zscore_hemisphere_difference, ground_truth, trees)
%UNTITLED3 Summary of this function goes here
% this function has been corrected at 31/10/20
% initial there was a typo and for the creation of the moving average image
% was used medfilt2... now we use the correct one.

num_count = 0;
for i = 1:size(labeled_imgs, 2)
    num_count = num_count + numel(labeled_imgs{i});
    
end
Y = [];
X = zeros(num_count, 13);

index = 1;
%set filter kernel 
h = fspecial('average', 3);
for i = 1:size(imgs, 2)
    
    img = imgs{i};
    img = rgb2hsv(img);
    %intensity feature of each channel
    cha1 = img(:,:,1);
    cha2 = img(:,:,2);
    cha3 = img(:,:,3);
    zscore = zsc{i};
    
    

    hem_dif = h_dif{i};
    X(index:((index -1) + numel(cha1)),1) = cha1(:);
    
    X(index:((index - 1) + numel(cha2)),2) = cha2(:);
    
    X(index:((index - 1) + numel(cha3)),3) = cha3(:);

    gaussian_img1 = imgaussfilt(cha1, 3);X(index:((index - 1) + numel(cha1)),4) = gaussian_img1(:);
    
    gaussian_img2 = imgaussfilt(cha2, 3);X(index:((index - 1) + numel(cha2)),5) = gaussian_img2(:);
    
    gaussian_img3 = imgaussfilt(cha3, 3);X(index:((index - 1) + numel(cha3)),6) = gaussian_img3(:);
    
    median1 = imfilter(cha1, h); X(index:((index - 1) + numel(cha1)),7) = median1(:);

    median2 = imfilter(cha2, h); X(index:((index - 1) + numel(cha2)),8) = median2(:);

    median3 = imfilter(cha3, h); X(index:((index - 1) + numel(cha3)),9) = median3(:);
    
    % test with these two extra features
    X(index:((index - 1) + numel(zscore)),10) = zscore(:);
    
    median_z = imfilter(zscore, h); X(index:((index - 1) + numel(zscore)),11) = median_z(:);

      X(index:((index - 1) + numel(zscore)),12) = hem_dif(:);  
      
      median_z = imfilter(hem_dif, h); X(index:((index - 1) + numel(hem_dif)),13) = median_z(:);
   % % test end
    
    labels = labeled_imgs{i};
    Y = [Y; labels(:)];
    index = index + numel(cha1);
    
end


% train model 
model = TreeBagger(trees, X, Y, 'OOBPrediction','on',...
    'Method','classification');
end