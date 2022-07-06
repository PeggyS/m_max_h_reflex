function open_view_data_fig(app, view_row, h_or_m)

% from view_row in the UITable, get info to open correct .csv data file
% exported from Cadwell. Info: session, muscle, side (converted from
% inv/uninv to left/right)
session = app.UITable.Data.session{view_row};
inv_uninv = app.UITable.Data.side{view_row};
muscle = app.UITable.Data.muscle{view_row};

switch inv_uninv
	case 'inv'
		if app.Left.Value
			side = 'left';
		else
			side = 'right';
		end
	case 'uninv'
		if app.Left.Value
			side = 'right';
		else
			side = 'left';
		end
end

% if uitable has 13 columns
switch h_or_m
	case 'm'
		if width(app.UITable.Data) == 13
			% then it is lower limb m_max data only - filename contains the muscle
			csv_file = fullfile(app.SubjectFolderEditField.Value, session, [side '_' muscle '.csv']);
		else
			% m_max_h_reflex - view m-max data ( filename has 'inc')
			csv_file = fullfile(app.SubjectFolderEditField.Value, session, [side '_' muscle '_inc.csv']);
		end
		
	case 'h'
		csv_file = fullfile(app.SubjectFolderEditField.Value, session, [side '_' muscle '_dec.csv']);
end
if ~exist(csv_file, 'file')
	disp(['no csv file named ' csv_file])
	return
end

% read in the data
info_struc = read_cadwell_file(csv_file);


switch h_or_m
	case 'm'
		% create the figure with the data
		h_fig = create_m_fig(info_struc, app.UITable, view_row);
% 		disp(['row ' num2str(view_row) '  h_fig = ' ])
% 		disp(h_fig)
		% and store it in the uitable's userdata
		app.UITable.UserData.h_mfigs(view_row) = h_fig;
	case 'h'
		h_fig = create_h_fig(info_struc, app.UITable, view_row);
		app.UITable.UserData.h_hfigs(view_row) = h_fig;
end

return