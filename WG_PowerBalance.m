% WG_PowerBalance.m
% ─────────────────────────────────────────────────────────────────────────
% Balance de potencia de un prototipo de guía de onda (banda D).
%
% A partir de S11, S21, S12, S22 (complejos, R+jI; en los .mat: S11, S31,
% S13, S33) descompone la potencia incidente (normalizada a 1) en tres
% fracciones. Forma estándar (matriz unitaria, UNA excitación, puerto 1):
%
%     R = |S11|^2          → potencia REFLEJADA (desadaptación)
%     T = |S21|^2          → potencia TRANSMITIDA
%     L = 1 - R - T        → potencia PERDIDA (óhmica + radiación, juntas)
%
% (SIN /2: el /2 solo aparece si se PROMEDIAN las dos excitaciones, y entonces
%  va en R y T a la vez → AVERAGE_DIRECTIONS en la sección 4.)
%
% Sobre las repeticiones se promedia la POTENCIA (|S|^2), no el fasor
% complejo: es lo físicamente correcto para un balance de potencia y evita
% que una deriva de fase entre barridos reduzca artificialmente la potencia.
%
% Banda de análisis por defecto: 130–150 GHz (editable en la sección 2).
%
% Nota: el balance supone parámetros S calibrados en el plano de referencia
% del DUT. Sin de-embedding del thru, la pérdida de los conectores/tramos
% de guía cuenta como "pérdida".
%
% Requiere MATLAB R2016b o posterior.
% ─────────────────────────────────────────────────────────────────────────

clear; close all; clc;

%% ── 0 · Estilo global ────────────────────────────────────────────────────
set(groot, 'defaultTextInterpreter',          'latex');
set(groot, 'defaultLegendInterpreter',        'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultAxesFontSize',   14);
set(groot, 'defaultAxesFontName',   'Times New Roman');

%% ── 1 · Carpeta del prototipo ────────────────────────────────────────────
proto_dir = uigetdir('', 'Selecciona la carpeta del prototipo (.mat)');
if isequal(proto_dir, 0); disp('[Cancelado]'); return; end
[~, proto_name] = fileparts(proto_dir);
proto_lbl = strrep(proto_name, '_', '\_');
fprintf('Prototipo : %s\n', proto_name);

%% ── 2 · Parámetros de análisis ───────────────────────────────────────────
F_LO   = 130;    % GHz — límite inferior de la banda de análisis
F_HI   = 150;    % GHz — límite superior de la banda de análisis
SMOOTH = 5;      % ventana gaussiana de suavizado (muestras); 0 = sin suavizar
FIG_CM = [2 2 20 14];

% Colores (composición de potencia)
COL_T = [0.20 0.60 0.25];   % transmisión — verde
COL_L = [0.90 0.55 0.10];   % pérdida     — ámbar
COL_R = [0.80 0.15 0.15];   % reflexión   — rojo

%% ── 3 · Cargar y promediar la potencia sobre las repeticiones ────────────
files = dir(fullfile(proto_dir, '*.mat'));
if isempty(files); error('Sin archivos .mat en: %s', proto_dir); end
N = numel(files);
fprintf('Repeticiones : %d\n', N);

freq = [];
acc = struct('P11',0, 'P31',0, 'P13',0, 'P33',0);
for k = 1:N
    d = load(fullfile(proto_dir, files(k).name));
    if isempty(freq); freq = d.freq_ghz(:).'; end
    acc.P11 = acc.P11 + abs(d.S11(:).').^2;
    acc.P31 = acc.P31 + abs(d.S31(:).').^2;
    acc.P13 = acc.P13 + abs(d.S13(:).').^2;
    acc.P33 = acc.P33 + abs(d.S33(:).').^2;
end
P11 = acc.P11 / N;   % <|S11|^2>
P31 = acc.P31 / N;   % <|S31|^2>
P13 = acc.P13 / N;   % <|S13|^2>
P33 = acc.P33 / N;   % <|S33|^2>

%% ── 4 · Fracciones de potencia ───────────────────────────────────────────
% Balance por conservación de energía (matriz S, UNA excitación):
%       1 = |S11|^2 + |S21|^2 + L   →   L = 1 - |S11|^2 - |S21|^2   (SIN /2)
% Esta es la forma estándar (matriz unitaria) y es lo que pide el tutor: el
% /2 NO va aquí.
%
% AVERAGE_DIRECTIONS = true promedia las DOS excitaciones (puerto 1 y 3).
% En ese caso el /2 va en R y en T a la vez y L = 1-R-T sigue siendo válido
% (es el promedio de los dos balances de energía). Con guía recíproca y
% simétrica (|S11|≈|S22|, |S21|≈|S12|) ambos resultados coinciden; el
% promedio solo reduce ruido.  Lo que NUNCA es válido es quitar el /2 pero
% seguir sumando las dos direcciones (daría R+T≈2 y L negativo).
AVERAGE_DIRECTIONS = false;
if AVERAGE_DIRECTIONS
    R = (P11 + P33) / 2;      % reflejada   (promedio P1 y P3, con /2)
    T = (P31 + P13) / 2;      % transmitida (promedio P1 y P3, con /2)
else
    R = P11;                  % reflejada   (excitación puerto 1, sin /2)
    T = P31;                  % transmitida (excitación puerto 1, sin /2)
end
L = 1 - R - T;                % perdida (óhmica + radiación)

if SMOOTH > 1
    sm = @(v) smoothdata(v(:).', 'gaussian', SMOOTH);
else
    sm = @(v) v(:).';
end
Rs = sm(R);  Ts = sm(T);  Ls = sm(L);

%% ── 5 · Estadísticas en la banda 130–150 GHz ─────────────────────────────
mask = (freq >= F_LO) & (freq <= F_HI);
if ~any(mask)
    error('El rango medido no cubre %g–%g GHz.', F_LO, F_HI);
end
R_band = mean(R(mask));
T_band = mean(T(mask));
L_band = mean(L(mask));

fprintf('\n─── Balance de potencia medio en %g–%g GHz ───\n', F_LO, F_HI);
fprintf('  Reflejada  (R) : %6.2f %%\n', 100*R_band);
fprintf('  Transmitida(T) : %6.2f %%\n', 100*T_band);
fprintf('  Perdida    (L) : %6.2f %%\n', 100*L_band);
fprintf('  Suma           : %6.2f %%\n', 100*(R_band+T_band+L_band));
if L_band < 0
    fprintf('  [!] L < 0: revisar calibración/ruido (R+T > 1 en la banda).\n');
end
fprintf('────────────────────────────────────────────\n\n');

%% ── 6 · Fig 1 — Fracciones de potencia vs frecuencia ─────────────────────
fig1 = figure('Name',['PowerBalance\_' proto_name],'NumberTitle','off');
set(fig1,'Units','centimeters','Position',FIG_CM);
ax1 = gca; hold on;

% Banda de análisis sombreada
yl = [0 100];
patch(ax1, [F_LO F_HI F_HI F_LO], [yl(1) yl(1) yl(2) yl(2)], ...
    [0.90 0.90 0.95], 'EdgeColor','none', 'FaceAlpha',0.5, ...
    'HandleVisibility','off');

plot(ax1, freq, 100*Ts, '-', 'Color',COL_T, 'LineWidth',1.8, ...
    'DisplayName','Transmitida $T$');
plot(ax1, freq, 100*Ls, '-', 'Color',COL_L, 'LineWidth',1.8, ...
    'DisplayName','Perdida $L$');
plot(ax1, freq, 100*Rs, '-', 'Color',COL_R, 'LineWidth',1.8, ...
    'DisplayName','Reflejada $R$');

xline(ax1, F_LO, '--', 'Color',[0.4 0.4 0.4], 'HandleVisibility','off');
xline(ax1, F_HI, '--', 'Color',[0.4 0.4 0.4], 'HandleVisibility','off');

% Anotaciones con el valor medio en banda
txt = { sprintf('$T$ = %.1f\\%%', 100*T_band), ...
        sprintf('$L$ = %.1f\\%%', 100*L_band), ...
        sprintf('$R$ = %.1f\\%%', 100*R_band) };
cols = {COL_T, COL_L, COL_R};
for i = 1:3
    text(ax1, 0.985, 0.96-(i-1)*0.06, txt{i}, 'Units','normalized', ...
        'Color',cols{i}, 'FontSize',11, 'FontWeight','bold', ...
        'HorizontalAlignment','right', 'BackgroundColor',[1 1 1 0.7]);
end

title(ax1, ['\textbf{Power Balance} --- ' proto_lbl], 'FontSize',16);
xlabel(ax1, 'Frequency (GHz)', 'FontSize',14);
ylabel(ax1, 'Power fraction (\%)', 'FontSize',14);
xlim(ax1, [min(freq) max(freq)]);
ylim(ax1, yl);
grid(ax1,'on'); box(ax1,'on');
lgd = legend(ax1, 'Location','east', 'FontSize',10);
set(lgd,'Box','on','Color',[1 1 1],'EdgeColor',[0.75 0.75 0.75]);
try; lgd.BackgroundAlpha = 0.75; catch; end
hold(ax1,'off');
saveas(fig1, fullfile(proto_dir, [proto_name '_PowerBalance.png']));

%% ── 7 · Fig 2 — Composición apilada (100 %) en la banda ──────────────────
fig2 = figure('Name',['PowerStack\_' proto_name],'NumberTitle','off');
set(fig2,'Units','centimeters','Position',FIG_CM);
ax2 = gca; hold on;

fb = freq(mask);
stack = 100 * [Ts(mask).', Ls(mask).', Rs(mask).'];   % T abajo, L medio, R arriba
har = area(ax2, fb, stack, 'LineStyle','none');
har(1).FaceColor = COL_T;  har(1).DisplayName = 'Transmitida $T$';
har(2).FaceColor = COL_L;  har(2).DisplayName = 'Perdida $L$';
har(3).FaceColor = COL_R;  har(3).DisplayName = 'Reflejada $R$';
for h = har; h.FaceAlpha = 0.85; end

title(ax2, ['\textbf{Power Composition} (' num2str(F_LO) '--' num2str(F_HI) ...
    ' GHz) --- ' proto_lbl], 'FontSize',15);
xlabel(ax2, 'Frequency (GHz)', 'FontSize',14);
ylabel(ax2, 'Cumulative power (\%)', 'FontSize',14);
xlim(ax2, [F_LO F_HI]);
ylim(ax2, [0 100]);
grid(ax2,'on'); box(ax2,'on');
lgd2 = legend(ax2, 'Location','southoutside', 'Orientation','horizontal', ...
    'FontSize',10);
set(lgd2,'Box','on','Color',[1 1 1],'EdgeColor',[0.75 0.75 0.75]);
hold(ax2,'off');
saveas(fig2, fullfile(proto_dir, [proto_name '_PowerStack.png']));

fprintf('Figuras guardadas en: %s\n', proto_dir);
