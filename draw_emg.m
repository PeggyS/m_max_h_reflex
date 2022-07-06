function draw_emg(data_struc)

figure

t = maket(data_struc.data(:,1), data_struc.samp_freq); % time vector in sec

% plot data vs time in msec
h_lines = plot(t*1000, data_struc.data);
