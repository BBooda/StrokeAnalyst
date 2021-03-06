%%
files = dir(pwd);
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];
% Extract only those that are directories.
subFolders = files(dirFlags);
folders = {};
j = 1;
for i = 1:length(subFolders)
    if length(subFolders(i).name) > 5
        folders{j} = subFolders(i).name;
        j = j + 1;
    end
end
%
for i = 1:numel(folders)
    cd(folders{i});

    if ~exist('dice_score', 'var')
            dice_score = [];
            fpr = [];
            tpr = [];
            xl = cell(30, 5);
            counter = 1; 
    end

    % load 

    load('all', 'ml_p', 'index')
    % 
    % 
    % 
    % load image 
    manual = imread(strcat(index, '-mmask.jpg'));
    manual = ~imbinarize(rgb2gray(manual));
    xl{counter, 1} = '-n003-14a';
    try
        [FPR, TPR, valid, DICE, ACC] = compute_FPR_TPR(ml_p, manual);
    catch 
        FPR = 'Nan';
        TPR = 'Nan';
        valid = 'Nan';
        DICE = 'Nan';
        ACC = 'Nan';
    end
    fpr = [fpr, FPR];
    tpr = [tpr, TPR];
    dsc = dice(ml_p, manual);
    dice_score = [dice_score; dsc];
    xl{counter, 2} = FPR;
    xl{counter, 3} = TPR;
    xl{counter, 4} = DICE;
    xl{counter, 5} = index;

    xl{counter, :}

    counter = counter + 1;
    cd('..')
end
% imwrite(ml_p, strcat(index, '_pre.jpg'));




