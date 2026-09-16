% WG_PlotResults.m
% ─────────────────────────────────────────────────────────────────────────
% Lee medidas de guías de onda en banda D y genera:
%   Fig. 1 — Transmisión  |S31| (dB)            — todas las repeticiones
%   Fig. 2 — Reflexión    |S11| (dB)            — todas las repeticiones
%   Fig. 3 — S31 + S11 combinados               — 5 primeras reps, ylim a medida
%   Fig. 4 — Transmisión medida vs simulación   — 5 primeras reps + .txt sim
%   Fig. 5 — Reflexión    medida vs simulación  — 5 primeras reps + .txt sim
%
% Estilos (coherentes en todas las figuras):
%   Thru before → azul sólido,    LW 2.0
%   Thru after  → rojo sólido,    LW 2.0
%   Reps 1–N    → colors lines(), discontinuo '--', LW 1.5
%   Simulación  → negro sólido grueso, LW 2.2  (marcador opcional)
%
% Uso: ejecuta el script, responde las ventanas en orden.
% ─────────────────────────────────────────────────────────────────────────

clear; clc; close all;

%% ── 1 · Seleccionar carpeta del prototipo ────────────────────────────────
proto_dir = uigetdir('', 'Selecciona la carpeta del prototipo');
if isequal(proto_dir, 0); disp('[Cancelado]'); return; end

[session_dir, proto_name] = fileparts(proto_dir);
fprintf('Prototipo  : %s\n', proto_name);
fprintf('Sesión     : %s\n\n', session_dir);

%% ── 2 · Seleccionar referencias THRU ─────────────────────────────────────
[f_tb, p_tb] = uigetfile( ...
    fullfile(session_dir, 'thru_before_*.mat'), ...
    'Selecciona THRU BEFORE (.mat)');
if isequal(f_tb, 0)
    warning('Sin Thru before — referencias no aparecerán.');
    thru_before = [];
else
    thru_before = load(fullfile(p_tb, f_tb));
    fprintf('Thru before : %s\n', f_tb);
end

[f_ta, p_ta] = uigetfile( ...
    fullfile(session_dir, 'thru_after_*.mat'), ...
    'Selecciona THRU AFTER (.mat)');
if isequal(f_ta, 0)
    warning('Sin Thru after — referencias no aparecerán.');
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
    freq = thru_before.freq_ghz;
elseif N > 0 && isfield(proto{1}, 'freq_ghz')
    freq = proto{1}.freq_ghz;
else
    error('No se pudo obtener el eje de frecuencias.');
end

%% ── 5 · Paleta, estilos y constantes ─────────────────────────────────────
N_COMPARE = min(5, N);   % repeticiones mostradas en Fig. 3, 4 y 5

COL_TB  = [0.00 0.35 0.80];   % azul  — thru before
COL_TA  = [0.85 0.10 0.10];   % rojo  — thru after
COL_SIM = [0.10 0.10 0.10];   % negro — simulación

% Color distinto por repetición (colormap 'lines', cicla cada 7)
COL_PROTO = lines(max(N, 1));

LW_REF   = 2.0;   % thru before / after
LW_PROTO = 1.5;   % repeticiones del prototipo
LW_SIM   = 2.2;   % simulación

to_dB = @(S) 20 * log10(max(abs(S(:).'), 1e-12));

%% ── 6 · Figura 1 — Transmisión |S31| (todas las reps) ────────────────────
fig1 = figure('Name', ['Transmisión — ' proto_name], ...
    'NumberTitle', 'off', 'Position', [40 420 950 510]);
ax1  = axes(fig1); hold(ax1, 'on');

wg_plot_curves(ax1, freq, thru_before, thru_after, proto, 'S31', ...
    COL_TB, COL_TA, COL_PROTO, LW_REF, LW_PROTO, to_dB);

wg_format_ax(ax1, freq, ...
    ['Transmisión  |S_{31}|  —  ' strrep(proto_name,'_','\_')], ...
    '|S_{31}| (dB)', []);

%% ── 7 · Figura 2 — Reflexión |S11| (todas las reps) ─────────────────────
fig2 = figure('Name', ['Reflexión — ' proto_name], ...
    'NumberTitle', 'off', 'Position', [1010 420 950 510]);
ax2  = axes(fig2); hold(ax2, 'on');

wg_plot_curves(ax2, freq, thru_before, thru_after, proto, 'S11', ...
    COL_TB, COL_TA, COL_PROTO, LW_REF, LW_PROTO, to_dB);

wg_format_ax(ax2, freq, ...
    ['Reflexión  |S_{11}|  —  ' strrep(proto_name,'_','\_')], ...
    '|S_{11}| (dB)', []);

%% ── 8 · Figura 3 — S31 + S11 combinados (5 primeras reps, ylim libre) ────

% Preguntar límites del eje Y
ylim_ans = inputdlg( ...
    {'Límite inferior (dB):', 'Límite superior (dB):'}, ...
    'Fig. 3 — Escala eje Y', 1, {'-30', '0'});
if isempty(ylim_ans)
    ylim3 = [-30 0];
else
    ylim3 = [str2double(ylim_ans{1}), str2double(ylim_ans{2})];
    if any(isnan(ylim3)) || ylim3(1) >= ylim3(2)
        warning('Escala inválida — usando [-30, 0] dB por defecto.');
        ylim3 = [-30 0];
    end
end

fig3 = figure('Name', ['S31+S11 — ' proto_name], ...
    'NumberTitle', 'off', 'Position', [525 420 1000 560]);
ax3  = axes(fig3); hold(ax3, 'on');

% Thru before: S31 sólido, S11 punteado — azul
if ~isempty(thru_before)
    if isfield(thru_before,'S31')
        plot(ax3, freq, to_dB(thru_before.S31), '-', ...
            'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName', 'S31  Thru before');
    end
    if isfield(thru_before,'S11')
        plot(ax3, freq, to_dB(thru_before.S11), ':', ...
            'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName', 'S11  Thru before');
    end
end

% Thru after: S31 sólido, S11 punteado — rojo
if ~isempty(thru_after)
    if isfield(thru_after,'S31')
        plot(ax3, freq, to_dB(thru_after.S31), '-', ...
            'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName', 'S31  Thru after');
    end
    if isfield(thru_after,'S11')
        plot(ax3, freq, to_dB(thru_after.S11), ':', ...
            'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName', 'S11  Thru after');
    end
end

% Primeras N_COMPARE repeticiones: S31 (--), S11 (:), mismo color
for k = 1:N_COMPARE
    c = COL_PROTO(k,:);
    if isfield(proto{k},'S31')
        plot(ax3, freq, to_dB(proto{k}.S31), '--', ...
            'Color', c, 'LineWidth', LW_PROTO, 'DisplayName', sprintf('S31  Rep %d',k));
    end
    if isfield(proto{k},'S11')
        plot(ax3, freq, to_dB(proto{k}.S11), ':', ...
            'Color', c, 'LineWidth', LW_PROTO, 'DisplayName', sprintf('S11  Rep %d',k));
    end
end

wg_format_ax(ax3, freq, ...
    ['S31 (– –)  &  S11 (···)  —  ' strrep(proto_name,'_','\_')], ...
    'Nivel (dB)', ylim3);
legend(ax3, 'Location', 'eastoutside', 'FontSize', 8);

%% ── 9 · Comparar medidas vs simulación (opcional) ────────────────────────
resp = questdlg('¿Comparar las medidas con una simulación?', ...
    'Simulación', 'Sí', 'No', 'No');

if strcmp(resp, 'Sí')

    % Seleccionar archivo de simulación (.txt, .s2p o similar)
    [f_sim, p_sim] = uigetfile( ...
        {'*.txt;*.s2p;*.dat', 'S-parámetros (*.txt, *.s2p, *.dat)'; ...
         '*.*', 'Todos los archivos'}, ...
        'Selecciona el archivo de simulación');

    if isequal(f_sim, 0)
        disp('[Simulación cancelada]');
    else
        sim_path = fullfile(p_sim, f_sim);
        fprintf('Simulación  : %s\n\n', f_sim);

        % Leer S-parámetros de simulación
        [freq_sim, S11_sim, S21_sim] = wg_read_sparams(sim_path);

        % Preguntar límites de eje Y para Figs. 4 y 5
        ylim_sim = inputdlg( ...
            {'Límite inferior (dB):', 'Límite superior (dB):'}, ...
            'Figs. 4 & 5 — Escala eje Y', 1, {'-30', '0'});
        if isempty(ylim_sim)
            ylim45 = [-30 0];
        else
            ylim45 = [str2double(ylim_sim{1}), str2double(ylim_sim{2})];
            if any(isnan(ylim45)) || ylim45(1) >= ylim45(2)
                ylim45 = [-30 0];
            end
        end

        % ── Fig. 4 — Transmisión medida vs simulación ─────────────────────
        fig4 = figure('Name', ['TX medida vs sim — ' proto_name], ...
            'NumberTitle', 'off', 'Position', [40 60 950 510]);
        ax4  = axes(fig4); hold(ax4, 'on');

        % Thru references
        if ~isempty(thru_before) && isfield(thru_before,'S31')
            plot(ax4, freq, to_dB(thru_before.S31), '-', ...
                'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName','S31  Thru before');
        end
        if ~isempty(thru_after) && isfield(thru_after,'S31')
            plot(ax4, freq, to_dB(thru_after.S31), '-', ...
                'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName','S31  Thru after');
        end

        % Primeras N_COMPARE medidas
        for k = 1:N_COMPARE
            if isfield(proto{k},'S31')
                plot(ax4, freq, to_dB(proto{k}.S31), '--', ...
                    'Color', COL_PROTO(k,:), 'LineWidth', LW_PROTO, ...
                    'DisplayName', sprintf('Rep %d', k));
            end
        end

        % Simulación (S21 sim ↔ S31 medido: ambos son TX port1→port3/2)
        plot(ax4, freq_sim, to_dB(S21_sim), '-', ...
            'Color', COL_SIM, 'LineWidth', LW_SIM, 'DisplayName', ['Sim: ' f_sim]);

        wg_format_ax(ax4, freq, ...
            ['Transmisión  |S_{31}|  medida vs sim  —  ' strrep(proto_name,'_','\_')], ...
            '|S_{31}| (dB)', ylim45);

        % ── Fig. 5 — Reflexión medida vs simulación ────────────────────────
        fig5 = figure('Name', ['RX medida vs sim — ' proto_name], ...
            'NumberTitle', 'off', 'Position', [1010 60 950 510]);
        ax5  = axes(fig5); hold(ax5, 'on');

        if ~isempty(thru_before) && isfield(thru_before,'S11')
            plot(ax5, freq, to_dB(thru_before.S11), '-', ...
                'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName','S11  Thru before');
        end
        if ~isempty(thru_after) && isfield(thru_after,'S11')
            plot(ax5, freq, to_dB(thru_after.S11), '-', ...
                'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName','S11  Thru after');
        end

        for k = 1:N_COMPARE
            if isfield(proto{k},'S11')
                plot(ax5, freq, to_dB(proto{k}.S11), '--', ...
                    'Color', COL_PROTO(k,:), 'LineWidth', LW_PROTO, ...
                    'DisplayName', sprintf('Rep %d', k));
            end
        end

        % Simulación (S11 sim ↔ S11 medido)
        plot(ax5, freq_sim, to_dB(S11_sim), '-', ...
            'Color', COL_SIM, 'LineWidth', LW_SIM, 'DisplayName', ['Sim: ' f_sim]);

        wg_format_ax(ax5, freq, ...
            ['Reflexión  |S_{11}|  medida vs sim  —  ' strrep(proto_name,'_','\_')], ...
            '|S_{11}| (dB)', ylim45);
    end
end

%% ═══════════════════════════════════════════════════════════════════════════
%  Funciones locales  (requiere MATLAB R2016b o posterior)
%% ═══════════════════════════════════════════════════════════════════════════

function wg_plot_curves(ax, freq, thru_before, thru_after, proto, param, ...
                         col_tb, col_ta, col_proto, lw_ref, lw_proto, to_dB)
% Dibuja thru before/after + todas las repeticiones del prototipo.
    if ~isempty(thru_before) && isfield(thru_before, param)
        plot(ax, freq, to_dB(thru_before.(param)), '-', ...
            'Color', col_tb, 'LineWidth', lw_ref, 'DisplayName', 'Thru before');
    end
    if ~isempty(thru_after) && isfield(thru_after, param)
        plot(ax, freq, to_dB(thru_after.(param)), '-', ...
            'Color', col_ta, 'LineWidth', lw_ref, 'DisplayName', 'Thru after');
    end
    for k = 1:numel(proto)
        if isfield(proto{k}, param)
            plot(ax, freq, to_dB(proto{k}.(param)), '--', ...
                'Color', col_proto(k,:), 'LineWidth', lw_proto, ...
                'DisplayName', sprintf('Rep %d', k));
        end
    end
end


function wg_format_ax(ax, freq, ttl, ylbl, ylim_val)
% Aplica formato estándar a un eje: título, etiquetas, grid, leyenda.
    title(ax, ttl, 'Interpreter', 'tex', 'FontSize', 13, 'FontWeight', 'bold');
    xlabel(ax, 'Frecuencia (GHz)', 'FontSize', 11);
    ylabel(ax, ylbl, 'Interpreter', 'tex', 'FontSize', 11);
    xlim(ax, [min(freq) max(freq)]);
    if ~isempty(ylim_val)
        ylim(ax, ylim_val);
    end
    grid(ax, 'on');
    box(ax, 'on');
    legend(ax, 'Location', 'best', 'FontSize', 9);
    hold(ax, 'off');
end


function [freq_ghz, S11, S21] = wg_read_sparams(filepath)
% Lee un archivo de texto con S-parámetros de simulación.
%
% Formatos soportados:
%   · Touchstone 2-port (.s2p / .txt):
%       Línea de opciones:  # [Hz|MHz|GHz] S [RI|DB|MA] R 50
%       Datos (RI):  freq  S11re S11im  S21re S21im  S12re S12im  S22re S22im
%       Datos (DB):  freq  S11dB S11ang S21dB S21ang  ...  (ángulo en grados)
%       Datos (MA):  freq  |S11| ang11  |S21| ang21  ...
%   · Genérico sin cabecera: columnas [freq, S11re, S11im, S21re, S21im, ...]
%
% NOTA DE PUERTOS:
%   En el archivo de simulación, puerto 1 = entrada, puerto 2 = salida.
%   Esto corresponde a VNA puerto 1 y puerto 3 respectivamente:
%     S11_sim  ↔  S11_medido  (reflexión en entrada)
%     S21_sim  ↔  S31_medido  (transmisión entrada→salida)

    fid = fopen(filepath, 'r');
    if fid < 0; error('No se pudo abrir: %s', filepath); end

    freq_unit = 1e9;   % GHz por defecto
    fmt       = 'RI';
    data_lines = {};

    while ~feof(fid)
        raw = fgetl(fid);
        if ~ischar(raw); break; end
        line = strtrim(raw);
        if isempty(line); continue; end

        switch line(1)
            case {'!', '%'}   % comentario Touchstone / genérico
                continue;
            case '#'          % línea de opciones Touchstone
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
                % Línea de datos
                nums = sscanf(line, '%f');
                if numel(nums) >= 5
                    data_lines{end+1} = nums(:).'; %#ok
                end
        end
    end
    fclose(fid);

    if isempty(data_lines)
        error('No se encontraron datos numéricos en: %s', filepath);
    end

    % Homogeneizar filas (rellenar con NaN si hay longitudes distintas)
    maxcols = max(cellfun(@numel, data_lines));
    data = nan(numel(data_lines), maxcols);
    for r = 1:numel(data_lines)
        data(r, 1:numel(data_lines{r})) = data_lines{r};
    end

    raw_freq = data(:, 1);

    % Auto-detectar unidades si no hubo línea #
    % (si el max está entre 1e8 y 1e12 asumimos Hz)
    if max(raw_freq) > 1e6
        freq_ghz = raw_freq / 1e9;
    else
        freq_ghz = raw_freq * (freq_unit / 1e9);
    end
    freq_ghz = freq_ghz(:).';   % fila

    % Extraer S11 y S21 según formato
    switch fmt
        case 'RI'
            S11 = data(:,2) + 1j*data(:,3);
            S21 = data(:,4) + 1j*data(:,5);
        case 'DB'
            S11 = 10.^(data(:,2)/20) .* exp(1j * data(:,3) * pi/180);
            S21 = 10.^(data(:,4)/20) .* exp(1j * data(:,5) * pi/180);
        case 'MA'
            S11 = data(:,2) .* exp(1j * data(:,3) * pi/180);
            S21 = data(:,4) .* exp(1j * data(:,5) * pi/180);
    end
    S11 = S11(:).';
    S21 = S21(:).';
end
