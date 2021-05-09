function segmentation=ICM(image,class_number,potential,maxIter)
[width,height,bands]=size(image);
% MY MODIFICATIONS
%  superpix_num = ceil((width*height)*0.05);
%  [L, ~] = superpixels(image, superpix_num,'Compactness',4);
%     %super pixeled image
%  im_supered = mean_superpixel(image, L, 'false');
% 
% hsv = rgb2hsv(im_supered);
% image = reshape(hsv, width*height,bands);
% 
% [~,centers] = kmeans(image, class_number,'distance','sqEuclidean');
% [segmentation,~]= kmeans(image, class_number,'distance','sqEuclidean','Start',centers);

% original--------------
image=imstack2vectors(image);
[segmentation,~]= kmeans(image,class_number);
% original--------------

% cpy = image;
% img_supered = avg_superpixels(image, 0.005);
% hsv = rgb2hsv(img_supered);
% 
% 
% 
% image=imstack2vectors(hsv);
% [segmentation,~]= kmeans(image,class_number);



iter=0;
while(iter<maxIter)
    [mu,sigma]=GMM_parameter(image,segmentation,class_number);
    Ef=EnergyOfFeatureField(image,mu,sigma,class_number);
    E1=EnergyOfLabelField(segmentation,potential,width,height,class_number);
    E=Ef+E1;
    [tm,segmentation]=min(E,[],2);
    iter=iter+1;
end
segmentation=reshape(segmentation,[width height]);
end