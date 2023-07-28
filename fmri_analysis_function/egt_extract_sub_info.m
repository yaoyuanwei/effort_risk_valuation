% Function to extract subject information and fitted parameters
% Author: Yuanwei Yao
% Date: July 23, 2023

function [sub_id, sub_n] = egt_extract_sub_info(task_name, data_all)

	% sub id
	sub_id        	= unique(data_all.sub);

    % select data based on task type
    % effortful task
    if strcmp(task_name, 'egt')  
        % sub-24 was excluded for effortful task
        sub_id       = sub_id(sub_id~=24);

    % risky task
    elseif strcmp(task_name, 'rgt')
        % % sub-29 and -35 were excluded for risky task
        sub_id        = sub_id(~ismember(sub_id,[29,35]));

    % otherwise, show error message
    else
        error('Unknown task name!');
    end
        
    % number of valid subjects           
    sub_n       = length(sub_id);

end