function slice = extract_allen_mask(index)
    %UNTITLED3 Summary of this function goes here
    %   Detailed explanation goes here
    %load atlas
    % ANO = 3-D matrix of annotation labels
    size1 = [528 320 456];
    fid = fopen('/home/makis/Documents/MouseStrokeImageAnalysis/Data/atlasVolume/P56_Mouse_annotation/annotation.raw', 'r', 'l' );
    ANO = fread( fid, prod(size1), 'uint32' );
    fclose( fid );
    ANO = reshape(ANO,size1);  

    atlas = cell(1, size(ANO, 1));
    empty = [];
    data = [];
    for i = 1:size(ANO, 1)
        atlas{i} = (squeeze(ANO(i, :, :)));
    end

    slice = atlas{index};
end