function seg = markovRRF_segmentation(I, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
I=double(I);
class_number=3;
potential=0.5;
maxIter=30;%default is 30 iterations.

if ~isempty(varargin)
    if strcmp(varargin{1}, 'ClassNumber')
        class_number = varargin{2};
    end
end

seg=ICM(I,class_number,potential,maxIter);
% figure;
% imshow(I);
% imshow(seg,[]); 
end

