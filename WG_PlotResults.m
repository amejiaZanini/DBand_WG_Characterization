% WG_PlotResults.m
% ─────────────────────────────────────────────────────────────────────────
% Lee medidas de guías de onda en banda D y genera dos figuras:
%   Fig. 1 — Transmisión  |S31| (dB)
%   Fig. 2 — Reflexión    |S11| (dB)
%
% Estilos:
%   Thru before  → gris,  línea continua, LW 2.0
%   Thru after   → negro, línea continua, LW 2.0
%   Rep 1–N      → color diferente por repetición (lines colormap),
%                  línea discontinua '--', LW 1.5
%
% Uso: ejecuta el script, selecciona la carpeta del prototipo cuando se abra
%      el explorador de Windows.
%      Los archivos thru_before/after se buscan automáticamente en la carpeta
%      padre (sesión).
% ─────────────────────────────────────────────────────────────────────────

clear; clc; close all;

%% ── 1 · Seleccionar carpeta del prototipo ────────────────────────────────
proto_dir = uigetdir('', 'Selecciona la carpeta del prototipo');
if isequal(proto_dir, 0)
    disp('[Cancelado]');
    return;
end

[session_dir, proto_name] = fileparts(proto_dir);
fprintf('Prototipo  : %s\n', proto_name);
fprintf('Sesión     : %s\n\n', session_dir);

%% ── 2 · Seleccionar referencias THRU (ventana de selección de archivo) ───
% El explorador abre directamente en la carpeta de sesión y filtra por
% thru_before_*.mat / thru_after_*.mat para que sea inmediato de elegir.

[f_tb, p_tb] = uigetfile( ...
    fullfile(session_dir, 'thru_before_*.mat'), ...
    'Selecciona THRU BEFORE (.mat)');
if isequal(f_tb, 0)
    warning('No se seleccionó Thru before — las curvas de referencia no aparecerán.');
    thru_before = [];
else
    thru_before = load(fullfile(p_tb, f_tb));
    fprintf('Thru before : %s\n', f_tb);
end

[f_ta, p_ta] = uigetfile( ...
    fullfile(session_dir, 'thru_after_*.mat'), ...
    'Selecciona THRU AFTER (.mat)');
if isequal(f_ta, 0)
    warning('No se seleccionó Thru after — las curvas de referencia no aparecerán.');
    thru_after = [];
else
    thru_after = load(fullfile(p_ta, f_ta));
    fprintf('Thru after  : %s\n\n', f_ta);
end

%% ── 3 · Cargar medidas del prototipo (orden cronológico por nombre) ───────
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

%% ── 5 · Paleta y estilos ─────────────────────────────────────────────────
COL_TB = [0.00 0.35 0.80];   % azul  — thru before
COL_TA = [0.85 0.10 0.10];   % rojo  — thru after

% Un color distinto por repetición, generado con el colormap 'lines'
% (cicla cada 7 colores; para N > 7 sigue distinguiéndose por posición)
COL_PROTO = lines(max(N, 1));

LW_REF   = 2.0;   % thru
LW_PROTO = 1.5;   % todas las repeticiones del prototipo

to_dB = @(S) 20 * log10(max(abs(S(:).'), 1e-12));  % fila → para plot

%% ── 6 · Figura 1 — Transmisión |S31| ─────────────────────────────────────
fig1 = figure( ...
    'Name',        ['Transmisión — ' proto_name], ...
    'NumberTitle', 'off', ...
    'Position',    [80 280 980 540]);

ax1 = axes(fig1);
hold(ax1, 'on');

wg_plot_curves(ax1, freq, thru_before, thru_after, proto, 'S31', ...
    COL_TB, COL_TA, COL_PROTO, LW_REF, LW_PROTO, to_dB);

title(ax1, ['Transmisión  |S_{31}|  —  ' strrep(proto_name, '_', '\_')], ...
    'Interpreter', 'tex', 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax1, 'Frecuencia (GHz)', 'FontSize', 11);
ylabel(ax1, '|S_{31}| (dB)',    'Interpreter', 'tex', 'FontSize', 11);
xlim(ax1, [min(freq) max(freq)]);
grid(ax1, 'on');
box(ax1, 'on');
legend(ax1, 'Location', 'best', 'FontSize', 9);
hold(ax1, 'off');

%% ── 7 · Figura 2 — Reflexión |S11| ──────────────────────────────────────
fig2 = figure( ...
    'Name',        ['Reflexión — ' proto_name], ...
    'NumberTitle', 'off', ...
    'Position',    [1080 280 980 540]);

ax2 = axes(fig2);
hold(ax2, 'on');

wg_plot_curves(ax2, freq, thru_before, thru_after, proto, 'S11', ...
    COL_TB, COL_TA, COL_PROTO, LW_REF, LW_PROTO, to_dB);

title(ax2, ['Reflexión  |S_{11}|  —  ' strrep(proto_name, '_', '\_')], ...
    'Interpreter', 'tex', 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax2, 'Frecuencia (GHz)', 'FontSize', 11);
ylabel(ax2, '|S_{11}| (dB)',    'Interpreter', 'tex', 'FontSize', 11);
xlim(ax2, [min(freq) max(freq)]);
grid(ax2, 'on');
box(ax2, 'on');
legend(ax2, 'Location', 'best', 'FontSize', 9);
hold(ax2, 'off');

%% ── 8 · Figura 3 — Transmisión + Reflexión (rango fijo 0 a −30 dB) ────────
fig3 = figure( ...
    'Name',        ['S31 + S11 — ' proto_name], ...
    'NumberTitle', 'off', ...
    'Position',    [560 730 980 560]);

ax3 = axes(fig3);
hold(ax3, 'on');

% ── Thru before: S31 (gris, continua) y S11 (gris discontinua más fina) ──
if ~isempty(thru_before)
    if isfield(thru_before, 'S31')
        plot(ax3, freq, to_dB(thru_before.S31), ...
            'Color', COL_TB, 'LineWidth', LW_REF, ...
            'DisplayName', 'S31  Thru before');
    end
    if isfield(thru_before, 'S11')
        plot(ax3, freq, to_dB(thru_before.S11), ':', ...
            'Color', COL_TB, 'LineWidth', LW_REF, ...
            'DisplayName', 'S11  Thru before');
    end
end

% ── Thru after: S31 (negro, continua) y S11 (negro discontinua más fina) ─
if ~isempty(thru_after)
    if isfield(thru_after, 'S31')
        plot(ax3, freq, to_dB(thru_after.S31), ...
            'Color', COL_TA, 'LineWidth', LW_REF, ...
            'DisplayName', 'S31  Thru after');
    end
    if isfield(thru_after, 'S11')
        plot(ax3, freq, to_dB(thru_after.S11), ':', ...
            'Color', COL_TA, 'LineWidth', LW_REF, ...
            'DisplayName', 'S11  Thru after');
    end
end

% ── Repeticiones del prototipo: S31 sólido, S11 punteado, mismo color ─────
for k = 1:N
    c = COL_PROTO(k, :);
    if isfield(proto{k}, 'S31')
        plot(ax3, freq, to_dB(proto{k}.S31), '--', ...
            'Color', c, 'LineWidth', LW_PROTO, ...
            'DisplayName', sprintf('S31  Rep %d', k));
    end
    if isfield(proto{k}, 'S11')
        plot(ax3, freq, to_dB(proto{k}.S11), ':', ...
            'Color', c, 'LineWidth', LW_PROTO, ...
            'DisplayName', sprintf('S11  Rep %d', k));
    end
end

title(ax3, ['S31 (––)  &  S11 (···)  —  ' strrep(proto_name, '_', '\_')], ...
    'Interpreter', 'tex', 'FontSize', 13, 'FontWeight', 'bold');
xlabel(ax3, 'Frecuencia (GHz)', 'FontSize', 11);
ylabel(ax3, 'Nivel (dB)',        'FontSize', 11);
xlim(ax3, [min(freq) max(freq)]);
ylim(ax3, [-30 0]);
grid(ax3, 'on');
box(ax3, 'on');
legend(ax3, 'Location', 'eastoutside', 'FontSize', 8);
hold(ax3, 'off');

%% ═══════════════════════════════════════════════════════════════════════════
%  Funciones locales  (requiere MATLAB R2016b o posterior)
%% ═══════════════════════════════════════════════════════════════════════════

function wg_plot_curves(ax, freq, thru_before, thru_after, proto, param, ...
                         col_tb, col_ta, col_proto, lw_ref, lw_proto, to_dB)
% Añade todas las curvas al eje ax para el parámetro S indicado.
%
%   Thru before/after → sólido, más grueso, gris/negro
%   Repeticiones 1–N  → discontinuo '--', LW lw_proto, color diferente c/u

    % ── Thru before (gris, continua) ──────────────────────────────────────
    if ~isempty(thru_before) && isfield(thru_before, param)
        plot(ax, freq, to_dB(thru_before.(param)), ...
            'Color', col_tb, 'LineWidth', lw_ref, ...
            'DisplayName', 'Thru before');
    end

    % ── Thru after (negro, continua) ──────────────────────────────────────
    if ~isempty(thru_after) && isfield(thru_after, param)
        plot(ax, freq, to_dB(thru_after.(param)), ...
            'Color', col_ta, 'LineWidth', lw_ref, ...
            'DisplayName', 'Thru after');
    end

    % ── Todas las repeticiones (discontinuo, color propio) ─────────────────
    for k = 1:numel(proto)
        if isfield(proto{k}, param)
            plot(ax, freq, to_dB(proto{k}.(param)), '--', ...
                'Color', col_proto(k, :), 'LineWidth', lw_proto, ...
                'DisplayName', sprintf('Rep %d', k));
        end
    end
end
