function ot = js_find(mat, val)
    % ot = js_find(mat, val), mat is the json struct and val is the id
    % value.
    % recursive function, search in dictionary for allen labels. Returns
    % name for id.
    if isempty(mat)
        ot = [];
        return;
    end

    ind = [mat.id] == val;
    if (sum(ind(:)) ~= 0) %|| (isempty(A1.children))
        ot = mat(ind).name;
        return;
    end
    for i = 1:length(mat)

            ot = js_find(mat(i).children, val);
            if ~isempty(ot)
                break;
            end

    end

end