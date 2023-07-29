function [onsets, names, durations, nr_ind] = edt_extract_model(task_name, anal_fold, sub_data, run_n, sub_sv, si)
% EDT_EXTRACT_MODEL: Extract events and timing information for effort-based decision-making
% July 23, 2023, by Yuanwei Yao
%
% Input:
%   task_name:  Name of the task for analysis, e.g., 'edt'
%   anal_fold:  Name of the main fMRI analysis folder
%   sub_data:   Data for a subject
%   run_n:      Number of runs
%   sub_sv:     Subjective values for each subject
%   si:         Subject numeric id (e.g., 20)
%
% Output:
%   onsets:     Onset for each event in the model
%   names:      Name for each event in the model
%   duractions: Duration for each event in the model
%   nr_ind:     No-response matrix, the first colume is no-response index across the task and the
%               second is the subject id (e.g., nr_ind = [1,20])

    % Mat file name
    matfile     = [task_name, '_model_sv'];
    
    % Divide subjective values based on the median
    sv_md       = median(sub_sv);
    sv_high     = (sub_sv >= sv_md);
    sv_low      = (sub_sv < sv_md);

    % Initiate the no-response index
    nr_ind      = zeros(1,2);

    % Add sub_id to the no-response recording matrix
    nr_ind(1,1) = si;
    
    % Index for no-response trials
    nan_ind     = isnan(sub_data.choice_rt);

    % Index of valid trials
    valid_ind   = ~(nan_ind);
    
    % Onset for fixation, cue, and choice
    fix_ons     = sub_data.trial_onset;
    cue_ons     = fix_ons + sub_data.fix_dura;
    choice_ons  = cue_ons + 2;

    % Number of trials and regressors in each run
    rtrial_n    = 28;

    % Number of regressors in each run: high and low sv 
    rreg_n      = 2;  

    % Initialize names, onsets, durations for each run
    names       = {};
    onsets      = {};
    durations   = {};

    % Generate events and timing info for each run
    for ri = 1:run_n
        
        % Initiate index vector for each run    
        trial_ri    = zeros(rtrial_n*run_n,1);

        % Index for the first trial of this run
        rtrial_head = (ri-1)*rtrial_n + 1;

        % Index for the last trial of this run
        rtrial_end  = ri*rtrial_n;

        % Index for trials of this run
        trial_ri(rtrial_head:rtrial_end) = 1;

        % Exclude no-response trials
        valid_ri    = trial_ri & valid_ind;

        % High and low sv trials index for each run
        sv_hri      = sv_high & valid_ri;
        sv_lri      = sv_low & valid_ri;
        
        % Onset for high and low sv cues
        svh_ons_ri  = cue_ons(sv_hri);
        svl_ons_ri  = cue_ons(sv_lri);

        % Position of the first regressor in the contrast vector in each run
        rreg_head   = (ri-1)*rreg_n + 1;

        % Position of the last regressor in the contrast vector in each run
        rreg_end    = ri*rreg_n;

        %% Build spm.mat
        % Onset for the high- and low-sv trials
        onsets{rreg_head}   = svh_ons_ri;
        onsets{rreg_end}    = svl_ons_ri;
        
        % Names for for the high- and low-sv trials
        names{rreg_head}    = 'sv_high';
        names{rreg_end}     = 'sv_low';

        % Use stick function, so duration = 0
        durations{rreg_head}    = 0;
        durations{rreg_end}     = 0;

    end % End for ri = 1:run_n
            
    % Model choice as a separate regressor
    choice_valid    = choice_ons(valid_ind);

    % put it after all high- and low-sv events in the GLM
    choice_pos      = run_n*2+1;
    
    % Onset, Names, and Duraction of choices
    onsets{choice_pos}  = choice_valid;
    names{choice_pos}   = 'choice';
    durations{choice_pos}   = 2;

    % If there are any no-response trials, add another regressor 
    if max(nan_ind) > 0
        
        % Note it in the no-response matrix
        nr_ind(1,2) = 1;

        % Onset for no-response trials
        nr_ons      = cue_ons(nan_ind);

        % put it behind the choice in the GLM
        nr_pos      = choice_pos+1;

        % Onset, Names, and Duraction of choices
        onsets{nr_pos}  = nr_ons;
        names{nr_pos}   = 'missing';
        durations{nr_pos}   = 4;
    end
    
    % Specify subject id
    sub_id      = sprintf('Sub%d', si);

    % Create a heb folder to store the generated mat file
    aim_fold    = fullfile(anal_fold, sub_id, 'beh');
    if ~isfolder(aim_fold)
        mkdir(aim_fold);
    end
        
    % Save names, onsets, durations as a mat file for checking
    save([aim_fold '/' matfile '_1run.mat'], 'names', 'onsets', 'durations');
end