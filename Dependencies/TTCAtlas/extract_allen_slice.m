function slice = extract_allen_slice(index)
    %UNTITLED3 Summary of this function goes here
    %   Detailed explanation goes here
    %load atlas
     size1 = [528 320 456];
    % VOL = 3-D matrix of atlas Nissl volume
    fid = fopen('/home/makis/Documents/GitRepos/data_dependencies/atlasVolume.raw', 'r', 'l' );
    VOL = fread( fid, prod(size1), 'uint8' );
    fclose( fid );
    VOL = reshape(VOL,size1);   

    atlas = cell(1, size(VOL, 1));
    empty = [];
    data = [];
    for i = 1:size(VOL, 1)
        atlas{i} = uint8(squeeze(VOL(i, :, :)));
    end

    slice = atlas{index};
end