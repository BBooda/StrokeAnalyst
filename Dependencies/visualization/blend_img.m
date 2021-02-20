function out = blend_img(img1, img2, p)
% where img1 the original img
% img2 usually the mask
% img1 should be rgb  
%p -> the transparency percentage 

    mask = zeros(size(img1));
    mask(:,:,2) = (255*img2);
    % opacity percentage 
    alpha = p;
    alpha = alpha/100;
    out = alpha * img1 + (1 - alpha) * uint8(mask);


end