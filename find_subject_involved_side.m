function side = find_subject_involved_side(subj)
% look up in the database the involved side of the tdvg subject
side = '';

% subjects in the db have full s27xxtdvg name, matlab processing uses shorthand s27xx
full_subj = subj;
if length(subj) < 9
	switch subj(2:3)
		case '27'
			full_subj = strcat(subj, 'tdvg');
		case '28'
			full_subj = strcat(subj, 'mytb');
		otherwise
			error('unknown study number: %s when looking up subject side', subj)
	end
end

switch full_subj(6:9)
	case 'tdvg'
		db_name = 'tdcs_vgait';
	case 'mytb'
		db_name = 'myomo';
end


% open connection to database
dbparams = get_db_login_params(db_name);

try
	conn = dbConnect(dbparams.dbname, dbparams.user, dbparams.password, dbparams.serveraddr);
catch e
	fprintf(1,'The error identifier was:\n%s', e.identifier);
	fprintf(1,'Error message: \n%s', e.message);
	side = 'left';
	disp('No database - left side chosen as default')
	return
end


% select affected_side from tdcs_vgait.demographics where subj = 's2701tdvg';

result = conn.dbSearch('demographics', 'affected_side',...
                           'subj', full_subj);
% close the database
conn.dbClose()

if length(result)~=1
	warning('error finding affected side for %s', full_subj);
else
	side = result{:};
end


