function [out,scores] = ml_prediction(model, f_v, varargin)
    
    [pre, scores] = predict(model, f_v);
    
    out = str2double(cell2mat(pre));

    out = reshape(out, size(rgb2gray(subject)));
    
    % select morthological operation to filter output
    morph_oper = 'areafilt'; % default value 
    for i = 1:length(varargin)
        if strcmp(varargin{i}, 'MorphOperation')
            morph_oper = varargin{i+1};
        end
    end
    
    if strcmp(morph_oper, 'areafilt')
        out = bwareafilt(imbinarize(out),5); 
    end
end