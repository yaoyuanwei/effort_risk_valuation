function [sub_id, sub_n] = egt_extract_sub_info(task_name, data_all)
% EGT_EXTRACT_SUB_INFO: Extract subject id and number for effort-based gambling
% July 23, 2023, Yuanwei Yao
%
% Input:
%   task_name:  Name of the task for analysis, e.g., 'egt'
%   data_all:   Data for all subjects
%
% Output:
%   sub_id:     Subject id
%   sub_n:      Subject number

	% Unique sub id
	sub_id        	= unique(data_all.sub);

    % Select data based on task type
    % Effortful task
    if strcmp(task_name, 'egt') 

        % sub-24 was excluded for effortful task
        sub_id      = sub_id(sub_id~=24);

    % Risky task
    elseif strcmp(task_name, 'rgt')

        % sub-29 and -35 were excluded for risky task
        sub_id      = sub_id(~ismember(sub_id,[29,35]));

    % Otherwise, show error message
    else
        error('Unknown task name!');
    end
        
    % Number of valid subjects           
    sub_n       = length(sub_id);

end