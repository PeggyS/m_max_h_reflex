function init_table(app, subj_dir)

% % get list of all csv files
% csv_files = regexpdir(subj_dir,'.+\.csv$');
% if length(csv_files) < 1
% 	disp('found no *.csv files')
% 	return;
% end

% look for m_max.csv or m_max_h_reflex.csv & read it in 
% m_max_csv_list = regexpdir(subj_dir,'^m_max.*\.csv$');
% m_msk = contains(m_max_csv_list, 'm_max.csv');
% if sum(m_msk) < 1
% 	m_msk = contains(m_max_csv_list, 'm_max_h_reflex.csv');
% 	assert(sum(m_msk) > 0, 'm_max.csv or m_max_h_reflex.csv not found in %s', subj_dir)
% end
% assert(sum(m_msk) == 1, 'more than 1 m_max.csv or m_max_h_reflex.csv found in %s', subj_dir)
% 
% m_max_csv = m_max_csv_list(m_msk);


file_list = dir(subj_dir);
fname = [];
m_max_msk = arrayfun(@(x)contains(x.name,'m_max.csv'), file_list);
if sum(m_max_msk) == 1
	fname = fullfile(subj_dir, file_list(m_max_msk).name);
	col_format = '%{MM/dd/uuuu}D%q%q%q%f%f%f%f%f%f%f%f';
	h_flg = false;
end
m_max_msk = arrayfun(@(x)contains(x.name,'m_max_h_reflex.csv'), file_list);
if sum(m_max_msk) == 1
	fname = fullfile(subj_dir, file_list(m_max_msk).name);
	col_format = '%{MM/dd/uuuu}D%q%q%q%f%f%f%f%f%f%f%f%f%f%f%f%f';
	h_flg = true;
end
if isempty(fname)
	error('did not find m_max.csv or m_max_h_reflex.csv in %s', subj_dir)
end
% read in the table
m_tbl = readtable(fname, 'Format', col_format);

% add column of check boxes to beginning of uitable to view m data
tmp = cell(height(m_tbl), 1); % empty cell column
view_var = cellfun(@(x)false, tmp); % assign all values as false
m_tbl.view_m = view_var; % add it to the table
% and make it the 1st column
n_cols = width(m_tbl);
m_tbl = m_tbl(:, [n_cols, 1:n_cols-1]);

if h_flg
	% add column of check boxes to beginning of uitable to view h data
	tmp = cell(height(m_tbl), 1); % empty cell column
	view_var = cellfun(@(x)false, tmp); % assign all values as false
	m_tbl.view_h = view_var; % add it to the table
	% and make it the 2nd column
	n_cols = width(m_tbl);
	m_tbl = m_tbl(:, [1, n_cols, 2:n_cols-1]);
end

% data to display in the uitable
app.UITable.Data = m_tbl;
app.UITable.ColumnName = m_tbl.Properties.VariableNames;

if h_flg
	app.UITable.ColumnEditable = logical([1 1 zeros(1,n_cols-2)]);
else
	app.UITable.ColumnEditable = logical([1 zeros(1,n_cols-1)]);
end

app.UITable.UserData.table_changed = false;
return
