% create training vectors
% load data 
if exist('counter', 'var')
    counter = counter + 1
else
    counter = 1;
    labels = [];
    training_vector = [];
end
load('all', 'training_data', 'index');
ground_truth = ~imbinarize(rgb2gray(imread(strcat(index, '-mmask.jpg'))));

% 19 features vector
training_vector = [training_vector; training_data.f_v_19];
labels = [labels; ground_truth(:)];

%% 13 features vector
training_vector = [training_vector; training_data.f_v_13];
labels = [labels; ground_truth(:)];

%% train classifier
trees = 70;
model = TreeBagger(trees, training_vector, labels, 'OOBPrediction','on',...
    'Method','classification');
description = containers.Map;
description('feature_number') = '19 features';
description('neighborhood') = 'neighborhood size 3 by 3';
description('filter') = 'average filter used';
description('trees') = trees;
description('OOBPrediction') = 'on';
save('model_19', 'model', 'description');





