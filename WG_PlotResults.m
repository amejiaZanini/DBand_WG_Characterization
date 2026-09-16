% WG_PlotResults.m
% ─────────────────────────────────────────────────────────────────────────
% Visualización de medidas de guías de onda en banda D (110–170 GHz).
%
%   Fig. 1 — Transmisión  |S31|        — todas las repeticiones
%   Fig. 2 — Reflexión    |S11|        — todas las repeticiones
%   Fig. 3 — S31 + S11 combinados      — 5 primeras reps, ylim a medida
%   Fig. 4 — TX medida vs simulación   — 5 primeras reps + .txt/.s2p
%   Fig. 5 — RX medida vs simulación   — 5 primeras reps + .txt/.s2p
%
% Las figuras se guardan como PNG en la carpeta del prototipo.
% Requiere MATLAB R2016b o posterior.
% ─────────────────────────────────────────────────────────────────────────

clear; close all; clc;

%% ── 0 · Estilo global ────────────────────────────────────────────────────
set(groot, 'defaultTextInterpreter',          'latex');
set(groot, 'defaultLegendInterpreter',        'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultAxesFontSize',   14);
set(groot, 'defaultAxesFontName',   'Times New Roman');

%% ── 1 · Seleccionar carpeta del prototipo ────────────────────────────────
proto_dir = uigetdir('', 'Selecciona la carpeta del prototipo');
if isequal(proto_dir, 0); disp('[Cancelado]'); return; end

[session_dir, proto_name] = fileparts(proto_dir);
proto_lbl = strrep(proto_name, '_', '\_');   % escapado para LaTeX
fprintf('Prototipo  : %s\n', proto_name);
fprintf('Sesion     : %s\n\n', session_dir);

%% ── 2 · Seleccionar referencias THRU ─────────────────────────────────────
[f_tb, p_tb] = uigetfile( ...
    fullfile(session_dir, 'thru_before_*.mat'), ...
    'Selecciona THRU BEFORE (.mat)');
if isequal(f_tb, 0)
    warning('Sin Thru before.');
    thru_before = [];
else
    thru_before = load(fullfile(p_tb, f_tb));
    fprintf('Thru before : %s\n', f_tb);
end

[f_ta, p_ta] = uigetfile( ...
    fullfile(session_dir, 'thru_after_*.mat'), ...
    'Selecciona THRU AFTER (.mat)');
if isequal(f_ta, 0)
    warning('Sin Thru after.');
    thru_after = [];
else
    thru_after = load(fullfile(p_ta, f_ta));
    fprintf('Thru after  : %s\n\n', f_ta);
end

%% ── 3 · Cargar medidas del prototipo (orden cronológico) ─────────────────
mat_files = dir(fullfile(proto_dir, '*.mat'));
if isempty(mat_files)
    error('No se encontraron archivos .mat en:\n  %s', proto_dir);
end
[~, ord] = sort({mat_files.name});
mat_files = mat_files(ord);
N = numel(mat_files);
fprintf('Medidas cargadas : %d\n\n', N);

proto = cell(N, 1);
for k = 1:N
    proto{k} = load(fullfile(proto_dir, mat_files(k).name));
end

%% ── 4 · Eje de frecuencias ───────────────────────────────────────────────
if ~isempty(thru_before) && isfield(thru_before, 'freq_ghz')
    freq = thru_before.freq_ghz(:).';
elseif N > 0 && isfield(proto{1}, 'freq_ghz')
    freq = proto{1}.freq_ghz(:).';
else
    error('No se pudo obtener el eje de frecuencias.');
end

%% ── 5 · Paleta, estilos y constantes ─────────────────────────────────────
N_COMPARE  = min(5, N);    % reps en Figs. 3–5
SMOOTH     = 5;            % ventana suavizado Gaussiano (muestras)
F_KEY      = 140;          % GHz — frecuencia para anotación de valor
THRESH_TX  = -3;           % dB — umbral inserción
THRESH_RX  = -15;          % dB — umbral adaptación

COL_TB  = [0.00 0.35 0.80];   % azul  — Thru before
COL_TA  = [0.85 0.10 0.10];   % rojo  — Thru after
COL_SIM = [0.10 0.10 0.10];   % negro — simulación

COL_PROTO = lines(max(N, 1)); % color distinto por repetición

LW_REF   = 1.8;
LW_PROTO = 1.3;
LW_SIM   = 2.2;
LW_THRESH = 1.4;

FIG_CM = [2 2 20 14];   % posición y tamaño de figura [x y w h] en cm

to_dB = @(S) 20 * log10(max(abs(S(:).'), 1e-12));
sm    = @(v) smoothdata(v(:).', 'gaussian', SMOOTH);

%% ── 6 · Figura 1 — Transmisión |S31| ─────────────────────────────────────
fig1 = wg_new_fig(['TX\_' proto_name], FIG_CM);
ax1  = gca; hold on;

xline(F_KEY, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.0, 'HandleVisibility', 'off');
yline(THRESH_TX, '--', 'Color', [0 0.5 0], 'LineWidth', LW_THRESH, ...
    'DisplayName', ['Threshold (' num2str(THRESH_TX) ' dB)']);

wg_plot_curves(ax1, freq, thru_before, thru_after, proto, 'S31', ...
    COL_TB, COL_TA, COL_PROTO, LW_REF, LW_PROTO, to_dB, sm);

wg_annotate(ax1, freq, thru_before, thru_after, [], ...
    'S31', F_KEY, COL_TB, COL_TA, [], to_dB, sm);

wg_format_ax(ax1, freq, ...
    ['\textbf{Insertion Loss} --- ' proto_lbl], ...
    '$|S_{31}|$ (dB)', [], 'southeast');

saveas(fig1, fullfile(proto_dir, [proto_name '_S31.png']));

%% ── 7 · Figura 2 — Reflexión |S11| ──────────────────────────────────────
fig2 = wg_new_fig(['RX\_' proto_name], FIG_CM);
ax2  = gca; hold on;

xline(F_KEY, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.0, 'HandleVisibility', 'off');
yline(THRESH_RX, '--', 'Color', [0 0.5 0], 'LineWidth', LW_THRESH, ...
    'DisplayName', ['Threshold (' num2str(THRESH_RX) ' dB)']);

wg_plot_curves(ax2, freq, thru_before, thru_after, proto, 'S11', ...
    COL_TB, COL_TA, COL_PROTO, LW_REF, LW_PROTO, to_dB, sm);

wg_annotate(ax2, freq, thru_before, thru_after, [], ...
    'S11', F_KEY, COL_TB, COL_TA, [], to_dB, sm);

wg_format_ax(ax2, freq, ...
    ['\textbf{Return Loss} --- ' proto_lbl], ...
    '$|S_{11}|$ (dB)', [], 'northeast');

saveas(fig2, fullfile(proto_dir, [proto_name '_S11.png']));

%% ── 8 · Figura 3 — S31 + S11 (5 primeras reps, ylim a medida) ───────────

ylim_ans = inputdlg( ...
    {'Limite inferior (dB):', 'Limite superior (dB):'}, ...
    'Fig. 3 --- Escala eje Y', 1, {'-30', '0'});
if isempty(ylim_ans)
    ylim3 = [-30 0];
else
    ylim3 = [str2double(ylim_ans{1}), str2double(ylim_ans{2})];
    if any(isnan(ylim3)) || ylim3(1) >= ylim3(2)
        ylim3 = [-30 0];
    end
end

fig3 = wg_new_fig(['Combined\_' proto_name], [2 2 22 15]);
ax3  = gca; hold on;

xline(F_KEY, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.0, 'HandleVisibility', 'off');

% Thru before/after: S31 sólido, S11 punteado
if ~isempty(thru_before)
    if isfield(thru_before,'S31')
        plot(ax3, freq, sm(to_dB(thru_before.S31)), '-', ...
            'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName', '$S_{31}$ Thru before');
    end
    if isfield(thru_before,'S11')
        plot(ax3, freq, sm(to_dB(thru_before.S11)), ':', ...
            'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName', '$S_{11}$ Thru before');
    end
end
if ~isempty(thru_after)
    if isfield(thru_after,'S31')
        plot(ax3, freq, sm(to_dB(thru_after.S31)), '-', ...
            'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName', '$S_{31}$ Thru after');
    end
    if isfield(thru_after,'S11')
        plot(ax3, freq, sm(to_dB(thru_after.S11)), ':', ...
            'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName', '$S_{11}$ Thru after');
    end
end

% Primeras N_COMPARE reps: S31 (--), S11 (:), mismo color
for k = 1:N_COMPARE
    c = COL_PROTO(k,:);
    if isfield(proto{k},'S31')
        plot(ax3, freq, sm(to_dB(proto{k}.S31)), '--', ...
            'Color', c, 'LineWidth', LW_PROTO, ...
            'DisplayName', ['$S_{31}$ Rep ' num2str(k)]);
    end
    if isfield(proto{k},'S11')
        plot(ax3, freq, sm(to_dB(proto{k}.S11)), ':', ...
            'Color', c, 'LineWidth', LW_PROTO, ...
            'DisplayName', ['$S_{11}$ Rep ' num2str(k)]);
    end
end

wg_format_ax(ax3, freq, ...
    ['\textbf{$S_{31}$ (---) \& $S_{11}$ ($\cdots$)} --- ' proto_lbl], ...
    'Level (dB)', ylim3, 'eastoutside');

saveas(fig3, fullfile(proto_dir, [proto_name '_S31_S11.png']));

%% ── 9 · Comparar medidas vs simulación (opcional) ────────────────────────
resp = questdlg('Comparar las medidas con una simulacion?', ...
    'Simulacion', 'Si', 'No', 'No');

if strcmp(resp, 'Si')

    [f_sim, p_sim] = uigetfile( ...
        {'*.txt;*.s2p;*.dat', 'S-parametros (*.txt, *.s2p, *.dat)'; ...
         '*.*', 'Todos los archivos'}, ...
        'Selecciona el archivo de simulacion');

    if isequal(f_sim, 0)
        disp('[Simulacion cancelada]');
    else
        sim_path = fullfile(p_sim, f_sim);
        [f_sim_lbl, ~] = strtok(f_sim, '.');
        fprintf('Simulacion  : %s\n\n', f_sim);

        [freq_sim, S11_sim, S21_sim] = wg_read_sparams(sim_path);

        ylim_sim = inputdlg( ...
            {'Limite inferior (dB):', 'Limite superior (dB):'}, ...
            'Figs. 4 & 5 --- Escala eje Y', 1, {'-30', '0'});
        if isempty(ylim_sim)
            ylim45 = [-30 0];
        else
            ylim45 = [str2double(ylim_sim{1}), str2double(ylim_sim{2})];
            if any(isnan(ylim45)) || ylim45(1) >= ylim45(2)
                ylim45 = [-30 0];
            end
        end

        % ── Fig. 4 — TX medida vs simulación ──────────────────────────────
        fig4 = wg_new_fig(['TX\_sim\_' proto_name], FIG_CM);
        ax4  = gca; hold on;

        xline(F_KEY, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.0, 'HandleVisibility', 'off');
        yline(THRESH_TX, '--', 'Color', [0 0.5 0], 'LineWidth', LW_THRESH, ...
            'DisplayName', ['Threshold (' num2str(THRESH_TX) ' dB)']);

        if ~isempty(thru_before) && isfield(thru_before,'S31')
            plot(ax4, freq, sm(to_dB(thru_before.S31)), '-', ...
                'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName', 'Thru before');
        end
        if ~isempty(thru_after) && isfield(thru_after,'S31')
            plot(ax4, freq, sm(to_dB(thru_after.S31)), '-', ...
                'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName', 'Thru after');
        end
        for k = 1:N_COMPARE
            if isfield(proto{k},'S31')
                plot(ax4, freq, sm(to_dB(proto{k}.S31)), '--', ...
                    'Color', COL_PROTO(k,:), 'LineWidth', LW_PROTO, ...
                    'DisplayName', ['Rep ' num2str(k)]);
            end
        end
        plot(ax4, freq_sim, sm(to_dB(S21_sim)), '-', ...
            'Color', COL_SIM, 'LineWidth', LW_SIM, ...
            'DisplayName', ['Sim: ' strrep(f_sim_lbl,'_','\_')]);

        wg_annotate(ax4, freq, thru_before, thru_after, ...
            struct('freq', freq_sim, 'S31', S21_sim), ...
            'S31', F_KEY, COL_TB, COL_TA, COL_SIM, to_dB, sm);

        wg_format_ax(ax4, freq, ...
            ['\textbf{Insertion Loss: Measured vs Simulation} --- ' proto_lbl], ...
            '$|S_{31}|$ (dB)', ylim45, 'southeast');

        saveas(fig4, fullfile(proto_dir, [proto_name '_TX_vs_sim.png']));

        % ── Fig. 5 — RX medida vs simulación ──────────────────────────────
        fig5 = wg_new_fig(['RX\_sim\_' proto_name], FIG_CM);
        ax5  = gca; hold on;

        xline(F_KEY, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.0, 'HandleVisibility', 'off');
        yline(THRESH_RX, '--', 'Color', [0 0.5 0], 'LineWidth', LW_THRESH, ...
            'DisplayName', ['Threshold (' num2str(THRESH_RX) ' dB)']);

        if ~isempty(thru_before) && isfield(thru_before,'S11')
            plot(ax5, freq, sm(to_dB(thru_before.S11)), '-', ...
                'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName', 'Thru before');
        end
        if ~isempty(thru_after) && isfield(thru_after,'S11')
            plot(ax5, freq, sm(to_dB(thru_after.S11)), '-', ...
                'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName', 'Thru after');
        end
        for k = 1:N_COMPARE
            if isfield(proto{k},'S11')
                plot(ax5, freq, sm(to_dB(proto{k}.S11)), '--', ...
                    'Color', COL_PROTO(k,:), 'LineWidth', LW_PROTO, ...
                    'DisplayName', ['Rep ' num2str(k)]);
            end
        end
        plot(ax5, freq_sim, sm(to_dB(S11_sim)), '-', ...
            'Color', COL_SIM, 'LineWidth', LW_SIM, ...
            'DisplayName', ['Sim: ' strrep(f_sim_lbl,'_','\_')]);

        wg_annotate(ax5, freq, thru_before, thru_after, ...
            struct('freq', freq_sim, 'S11', S11_sim), ...
            'S11', F_KEY, COL_TB, COL_TA, COL_SIM, to_dB, sm);

        wg_format_ax(ax5, freq, ...
            ['\textbf{Return Loss: Measured vs Simulation} --- ' proto_lbl], ...
            '$|S_{11}|$ (dB)', ylim45, 'northeast');

        saveas(fig5, fullfile(proto_dir, [proto_name '_RX_vs_sim.png']));
    end
end

%% ═══════════════════════════════════════════════════════════════════════════
%  Funciones locales
%% ═══════════════════════════════════════════════════════════════════════════

function fig = wg_new_fig(name, pos_cm)
% Crea figura con tamaño en centímetros.
    fig = figure('Name', name, 'NumberTitle', 'off');
    set(fig, 'Units', 'centimeters', 'Position', pos_cm);
end


function wg_format_ax(ax, freq, ttl, ylbl, ylim_val, leg_loc)
% Formato estándar: título LaTeX, ejes, grid, leyenda horizontal inferior.
    title(ax, ttl, 'FontSize', 16);
    xlabel(ax, 'Frequency (GHz)', 'FontSize', 14);
    ylabel(ax, ylbl, 'FontSize', 14);
    xlim(ax, [min(freq) max(freq)]);
    if ~isempty(ylim_val)
        ylim(ax, ylim_val);
    end
    grid(ax, 'on'); box(ax, 'on');
    lgd = legend(ax, 'Location', 'southoutside', ...
        'Orientation', 'horizontal', 'FontSize', 10);
    set(lgd, 'Box', 'off', 'NumColumns', 3);
    if nargin >= 6 && ~strcmp(leg_loc, 'southoutside')
        lgd.Location = leg_loc;
        lgd.Orientation = 'vertical';
    end
    hold(ax, 'off');
end


function wg_plot_curves(ax, freq, thru_before, thru_after, proto, param, ...
                         col_tb, col_ta, col_proto, lw_ref, lw_proto, to_dB, sm)
% Dibuja thru before/after + todas las repeticiones del prototipo.
    if ~isempty(thru_before) && isfield(thru_before, param)
        plot(ax, freq, sm(to_dB(thru_before.(param))), '-', ...
            'Color', col_tb, 'LineWidth', lw_ref, 'DisplayName', 'Thru before');
    end
    if ~isempty(thru_after) && isfield(thru_after, param)
        plot(ax, freq, sm(to_dB(thru_after.(param))), '-', ...
            'Color', col_ta, 'LineWidth', lw_ref, 'DisplayName', 'Thru after');
    end
    for k = 1:numel(proto)
        if isfield(proto{k}, param)
            plot(ax, freq, sm(to_dB(proto{k}.(param))), '--', ...
                'Color', col_proto(k,:), 'LineWidth', lw_proto, ...
                'DisplayName', ['Rep ' num2str(k)]);
        end
    end
end


function wg_annotate(ax, freq, thru_before, thru_after, sim_data, ...
                     param, f_key, col_tb, col_ta, col_sim, to_dB, sm)
% Añade etiquetas de valor puntual en f_key para Thru before, after y sim.
    text_x = 0.97;
    text_y = 0.96;
    dy     = 0.055;

    entries = {};
    if ~isempty(thru_before) && isfield(thru_before, param)
        entries{end+1} = struct('freq', freq, 'vals', sm(to_dB(thru_before.(param))), ...
            'col', col_tb, 'lbl', 'Thru before');
    end
    if ~isempty(thru_after) && isfield(thru_after, param)
        entries{end+1} = struct('freq', freq, 'vals', sm(to_dB(thru_after.(param))), ...
            'col', col_ta, 'lbl', 'Thru after');
    end
    if ~isempty(sim_data) && isfield(sim_data, param)
        entries{end+1} = struct('freq', sim_data.freq, ...
            'vals', sm(to_dB(sim_data.(param))), ...
            'col', col_sim, 'lbl', 'Sim');
    end

    for i = 1:numel(entries)
        e   = entries{i};
        val = interp1(e.freq, e.vals, f_key, 'linear', NaN);
        if isnan(val); continue; end
        txt = [e.lbl ' @ ' num2str(f_key) ' GHz: ' num2str(val, '%.1f') ' dB'];
        text(ax, text_x, text_y - (i-1)*dy, txt, ...
            'Units', 'normalized', 'Color', e.col, ...
            'FontSize', 9, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'right', ...
            'BackgroundColor', [1 1 1 0.7], ...
            'Interpreter', 'none');
    end
end


function [freq_ghz, S11, S21] = wg_read_sparams(filepath)
% Lee S-parámetros desde archivo de texto (Touchstone RI/DB/MA o genérico).
%
% NOTA DE PUERTOS (archivo de simulación 2-port):
%   S11_sim  ↔  S11_medido  (reflexión en entrada, puerto 1)
%   S21_sim  ↔  S31_medido  (transmisión, puerto 1 → puerto 3 del VNA)

    fid = fopen(filepath, 'r');
    if fid < 0; error('No se pudo abrir: %s', filepath); end

    freq_unit  = 1e9;   % GHz por defecto
    fmt        = 'RI';
    data_lines = {};

    while ~feof(fid)
        raw = fgetl(fid);
        if ~ischar(raw); break; end
        line = strtrim(raw);
        if isempty(line); continue; end
        switch line(1)
            case {'!','%'}
                continue;
            case '#'
                tok = strsplit(lower(line));
                for t = tok
                    switch t{1}
                        case 'hz';  freq_unit = 1;
                        case 'khz'; freq_unit = 1e3;
                        case 'mhz'; freq_unit = 1e6;
                        case 'ghz'; freq_unit = 1e9;
                        case 'db';  fmt = 'DB';
                        case 'ma';  fmt = 'MA';
                    end
                end
            otherwise
                nums = sscanf(line, '%f');
                if numel(nums) >= 5
                    data_lines{end+1} = nums(:).'; %#ok
                end
        end
    end
    fclose(fid);

    if isempty(data_lines)
        error('No se encontraron datos numericos en: %s', filepath);
    end

    maxcols = max(cellfun(@numel, data_lines));
    data = nan(numel(data_lines), maxcols);
    for r = 1:numel(data_lines)
        data(r, 1:numel(data_lines{r})) = data_lines{r};
    end

    raw_freq = data(:, 1);
    if max(raw_freq) > 1e6
        freq_ghz = raw_freq / 1e9;
    else
        freq_ghz = raw_freq * (freq_unit / 1e9);
    end
    freq_ghz = freq_ghz(:).';

    switch fmt
        case 'RI'
            S11 = (data(:,2) + 1j*data(:,3)).';
            S21 = (data(:,4) + 1j*data(:,5)).';
        case 'DB'
            S11 = (10.^(data(:,2)/20) .* exp(1j*data(:,3)*pi/180)).';
            S21 = (10.^(data(:,4)/20) .* exp(1j*data(:,5)*pi/180)).';
        case 'MA'
            S11 = (data(:,2) .* exp(1j*data(:,3)*pi/180)).';
            S21 = (data(:,4) .* exp(1j*data(:,5)*pi/180)).';
    end
end
