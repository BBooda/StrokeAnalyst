function xthresh = compute_midline_threshold(im,varargin)
%xthresh = compute_midline_threshold(im,name-value pairs)
%-> xthresh = compute_midline_threshold(img,varargin)
%Specify with name-value pair what type of input are you using.
% + 'Display' can be either 'Box' or 'Midline'
% + 'Scale', this option scales the width of the box with a factor in (0,1)
%'Type', 'SegmentedImage', default option covers a non segmented image.

%check channels of img 
[~, ~, channels] = size(im);
if channels > 1
    im = rgb2gray(im);
end

 bw = imbinarize(im);
 
 if ~isempty(varargin)
     if strcmp(varargin{1}, 'Type') & strcmp(varargin{2}, 'RGBRaw')
         bw = ~bw;
     end
 end
 
 [y, x] = find(bw(:,:) ~= 0);
 
 %find centroid
 xcen = mean(x);
 ycen = mean(y);
 
 %determine search area for symmetry line (around centroid)
 %calculate x bounds
 wx = max(x) - min(x); %distance between xmax and xmin
 xpbound = xcen + wx/4; %plus x bound
 xmbound = xcen - wx/4; %minus x bound
 %calculate y bounds
 %split desired points to up and down from ycen and inside x bounds
 %(not used at this point..)
 ind = find(x<xpbound & x > xmbound );
 x = x(ind); 
 y = y(ind);
 
 ind = find(y < ycen);
 xup = x(ind);
 yup = y(ind);
 
 ind = find(y > ycen);
 xdown = x(ind);
 ydown = y(ind);
 
 %know calculate boundary points of this point cloud
 

 %############ settings ###############
 width = 70;
 heigth = (max(y) - min(y))/1.3;% / 1.15 as default
 ylocation = min(y) + heigth/15;
 step = 1;
 
  if ~isempty(varargin)
     for i = 1:(length(varargin) - 1)
             if strcmp(varargin{i}, 'Scale')
                 %check if scale in (0, 1)
                 if varargin{i + 1} > 0 & varargin{i + 1} < 1
                    width = width * varargin{i+1};
                 end
             end
     end
 end
 %############ settings ###############

 
 
 errors = [];
 ind = [];
 counter = 0;
 
 for i = 1:step:(xpbound - (2*width + step))
    A = imcrop(im, [i ylocation width heigth]);
    B = imcrop(im, [i + width, ylocation, width, heigth]);
    errors = [errors, immse(A, fliplr(B))];
    ind = [ind, i];
    counter = counter + 1;
 end
 
  m_i = find((ind(:) > 150) &(ind(:)< 450));
 
 errors = errors(m_i);
 
 ind = ind(m_i);
 
 m_i = find(min(errors) == errors(:));
 
 %calculate threshold
 xthresh = ind(m_i) + width;% value needed to cut determine areas at the right
                            % and left hemispheres
 
 % diplay
 if ~isempty(varargin)
     for i = 1:(length(varargin) - 1)
             if strcmp(varargin{i}, 'Display') & strcmp(varargin{i+ 1}, 'Box')
                 imshow(im); hold on; 
                 rectangle('Position', [ind(m_i), ylocation, width heigth], 'EdgeColor', 'g');
                 hold on; scatter(xcen, ycen, 'b');
%                  rectangle('Position', [(ind(m_i) +width) , ylocation, width heigth], 'EdgeColor', 'r');
             end
             if strcmp(varargin{i}, 'Display') & strcmp(varargin{i+ 1}, 'Midline')
                  imshow(im);
                  hold on;
                  line([xthresh xthresh], [ylocation (heigth + ylocation)], 'Color','r')
             end
     end
 end
 
 
 
end
