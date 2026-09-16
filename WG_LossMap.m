% WG_LossMap.m
% ─────────────────────────────────────────────────────────────────────────
% Mapa de pérdidas de una guía EBG a partir de parámetros S, usando
% IFFT + time-gating.  Dos partes:
%
%  PARTE 1 — Mapa de reflexión vs posición
%     IFFT de S11 (desde puerto 1) y S33 (desde puerto 3) → densidad de
%     potencia reflejada vs distancia.  S33 se espeja sobre el mismo eje
%     físico (usando la longitud total conocida) para CRUZAR ambas y
%     confirmar dónde están las transiciones / uniones / defectos.
%
%  PARTE 2 — Pérdida de la EBG de-embebida (gating + thru)
%     · R_ebg  = |S11|²,|S33|² GATEADAS a la sección EBG (quita las
%                reflexiones de las transiciones) → desadaptación del EBG.
%     · T_ebg  = |S31_proto / S31_thru|²  → transmisión normalizada por el
%                thru, que de-embebe la pérdida de inserción de las
%                transiciones (el thru = puerto 1↔3 directo, sin EBG).
%     · L_ebg  = 1 − R_ebg − T_ebg  → pérdida disipada+radiada del EBG.
%     · α      = −10·log10( T_ebg/(1−R_ebg) ) / L_EBG   [dB/cm]  (long. conocida)
%
% LÍMITE FÍSICO (importante): la pérdida DISTRIBUIDA de una sección adaptada
% no es localizable a lo largo de z con una sola medida de 2 puertos (una
% sección adaptada absorbe sin reflejar → invisible en el TDR de reflexión).
% Por eso el "mapa" espacial es de REFLEXIÓN/discontinuidades; la pérdida del
% EBG se cuantifica por sección (de-embebida), no se reparte punto a punto.
% Para α(z) espacial real haría falta cut-back (varias longitudes).
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

%% ── 1 · Parámetros (EDITAR) ──────────────────────────────────────────────
F_LO     = 130;      % GHz — banda de análisis (inferior)
F_HI     = 150;      % GHz — banda de análisis (superior)
L_TOTAL  = 2.00;     % cm  — longitud física entre planos de referencia (P1↔P3)
L_EBG    = 1.00;     % cm  — longitud física de la sección EBG (para dB/cm)
VELFAC   = 1.0;      % v_g/c ; 1 = distancia eléctrica. Ver nota al final.
WIN_BETA = 6;        % Kaiser beta para la ventana en frecuencia
ZPAD     = 8;        % zero-padding para el display (interpola el eje)

% Gate de la sección EBG en distancia (cm). Vacío → selección con el ratón.
GATE_CM  = [];       % p.ej. [0.5 1.5]

%% ── 2 · Cargar prototipo (promedio complejo) ─────────────────────────────
proto_dir = uigetdir('', 'Selecciona la carpeta del prototipo (.mat)');
if isequal(proto_dir, 0); disp('[Cancelado]'); return; end
[session_dir, proto_name] = fileparts(proto_dir);
proto_lbl = strrep(proto_name, '_', '\_');

[S, freq] = wg_load_avg(proto_dir);
np   = numel(freq);
f_s  = freq(1);  f_stop = freq(end);
BW   = (f_stop - f_s) * 1e9;
c    = 299792458;
fprintf('Prototipo : %s  (%d puntos, %.0f–%.0f GHz)\n', proto_name, np, f_s, f_stop);
fprintf('Resolucion espacial  Δd ≈ %.2f cm\n', 100*c/(2*BW)*VELFAC);

%% ── 3 · Cargar thru (referencia de transiciones) ─────────────────────────
[f_thru, p_thru] = uigetfile(fullfile(session_dir,'thru_*.mat'), ...
    'Selecciona el THRU (.mat)  [Cancelar = sin de-embedding]');
thru = [];
if ~isequal(f_thru, 0)
    thru = load(fullfile(p_thru, f_thru));
    fprintf('Thru      : %s\n', f_thru);
else
    warning('Sin thru: T_ebg no se de-embebe (incluirá las transiciones).');
end

%% ── 4 · IFFT para display (envolvente vs distancia) ──────────────────────
w    = kaiser(np, WIN_BETA).';
Nd   = 2^nextpow2(np * ZPAD);
dist = 100 * wg_dist_axis(np, Nd, f_s, f_stop, c, VELFAC);   % cm

h11 = ifft(S.S11 .* w, Nd);
h33 = ifft(S.S33 .* w, Nd);
p11 = abs(h11).^2;  p11 = p11 / max(p11);      % densidad de pot. reflejada
p33 = abs(h33).^2;  p33 = p33 / max(p33);

% Espejar S33 al eje físico de P1:  z_fisico = L_TOTAL − z_desde_P3
dist_33_mirror = L_TOTAL - dist;

%% ── 5 · PARTE 1 · Fig 1 — Mapa de reflexión vs posición ──────────────────
fig1 = figure('Name',['LossMap\_refl\_' proto_name],'NumberTitle','off');
set(fig1,'Units','centimeters','Position',[2 2 22 14]);
ax1 = gca; hold on;
plot(ax1, dist, 10*log10(p11 + 1e-12), '-', 'Color',[0.00 0.45 0.74], ...
    'LineWidth',1.8, 'DisplayName','$S_{11}$ (desde P1)');
plot(ax1, dist_33_mirror, 10*log10(p33 + 1e-12), '--', 'Color',[0.85 0.33 0.10], ...
    'LineWidth',1.8, 'DisplayName','$S_{33}$ (desde P3, espejado)');
% Planos de referencia
xline(ax1, 0,       ':', 'Color',[0.4 0.4 0.4], 'HandleVisibility','off');
xline(ax1, L_TOTAL, ':', 'Color',[0.4 0.4 0.4], 'HandleVisibility','off');
title(ax1, ['\textbf{Mapa de reflexion vs posicion} --- ' proto_lbl], 'FontSize',15);
xlabel(ax1, 'Distancia fisica (cm)', 'FontSize',14);
ylabel(ax1, 'Potencia reflejada (dB, norm.)', 'FontSize',14);
xlim(ax1, [-0.2, L_TOTAL + 0.2]);
ylim(ax1, [-60 2]);
grid(ax1,'on'); box(ax1,'on');
lgd = legend(ax1,'Location','northeast','FontSize',10);
set(lgd,'Box','on','Color',[1 1 1],'EdgeColor',[0.75 0.75 0.75]);
try; lgd.BackgroundAlpha = 0.75; catch; end
saveas(fig1, fullfile(proto_dir, [proto_name '_LossMap_refl.png']));

%% ── 6 · Definir el gate de la EBG ────────────────────────────────────────
if isempty(GATE_CM)
    disp('Selecciona el GATE del EBG: clic en INICIO y luego en FIN (eje X, cm).');
    figure(fig1);
    [xg, ~] = ginput(2);
    GATE_CM = sort(xg(:).');
end
fprintf('Gate EBG : %.2f – %.2f cm\n', GATE_CM(1), GATE_CM(2));
xline(ax1, GATE_CM(1), '-.', 'Color',[0.2 0.6 0.2], 'LineWidth',1.4, 'DisplayName','Gate EBG');
xline(ax1, GATE_CM(2), '-.', 'Color',[0.2 0.6 0.2], 'LineWidth',1.4, 'HandleVisibility','off');
saveas(fig1, fullfile(proto_dir, [proto_name '_LossMap_refl.png']));

%% ── 7 · PARTE 2 · Pérdida EBG de-embebida ────────────────────────────────
% Gate exactamente invertible (Nfft = np) en el eje físico de P1 y P3.
dist_g   = 100 * wg_dist_axis(np, np, f_s, f_stop, c, VELFAC);   % cm (desde su puerto)
g11      = wg_gate(dist_g,           GATE_CM(1),           GATE_CM(2));           % S11 desde P1
g33      = wg_gate(dist_g, L_TOTAL - GATE_CM(2), L_TOTAL - GATE_CM(1));           % S33 desde P3

S11_g = wg_apply_gate(S.S11, w, g11);
S33_g = wg_apply_gate(S.S33, w, g33);

% R_ebg : desadaptación del EBG (promedio de ambas direcciones)
R_ebg = ( abs(S11_g).^2 + abs(S33_g).^2 ) / 2;

% T_ebg : transmisión normalizada por el thru (de-embebe las transiciones)
if ~isempty(thru)
    T21 = abs(S.S31 ./ thru.S31).^2;
    T13 = abs(S.S13 ./ thru.S13).^2;
    T_ebg = (T21 + T13) / 2;
else
    T_ebg = ( abs(S.S31).^2 + abs(S.S13).^2 ) / 2;   % sin de-embedding
end
T_ebg = min(T_ebg, 1);                    % clamp por ruido de normalización

% L_ebg : pérdida disipada + radiada del EBG
L_ebg = 1 - R_ebg - T_ebg;

% α (dB/cm): quita la desadaptación y reparte sobre la longitud del EBG
alpha_db_cm = -10*log10( max(T_ebg ./ max(1 - R_ebg, 1e-6), 1e-6) ) / L_EBG;

%% ── 8 · Estadísticas en la banda ─────────────────────────────────────────
mask = (freq >= F_LO) & (freq <= F_HI);
Rb = mean(R_ebg(mask));  Tb = mean(T_ebg(mask));  Lb = mean(L_ebg(mask));
ab = mean(alpha_db_cm(mask));
fprintf('\n─── EBG de-embebido, media en %g–%g GHz ───\n', F_LO, F_HI);
fprintf('  R_ebg (reflejada)  : %6.2f %%\n', 100*Rb);
fprintf('  T_ebg (transmitida): %6.2f %%\n', 100*Tb);
fprintf('  L_ebg (perdida)    : %6.2f %%\n', 100*Lb);
fprintf('  alpha              : %6.3f dB/cm  (L_EBG = %.2f cm)\n', ab, L_EBG);
if Lb < 0
    fprintf('  [!] L_ebg < 0: revisar gate / thru / calibracion.\n');
end
fprintf('──────────────────────────────────────────\n\n');

%% ── 9 · Fig 2 — Balance de potencia del EBG vs frecuencia ────────────────
sm = @(v) smoothdata(v(:).','gaussian',5);
fig2 = figure('Name',['LossMap\_bal\_' proto_name],'NumberTitle','off');
set(fig2,'Units','centimeters','Position',[2 2 20 14]);
ax2 = gca; hold on;
patch(ax2, [F_LO F_HI F_HI F_LO], [0 0 100 100], [0.90 0.90 0.95], ...
    'EdgeColor','none','FaceAlpha',0.5,'HandleVisibility','off');
plot(ax2, freq, 100*sm(T_ebg), '-', 'Color',[0.20 0.60 0.25], 'LineWidth',1.8, ...
    'DisplayName','Transmitida $T_{ebg}$');
plot(ax2, freq, 100*sm(L_ebg), '-', 'Color',[0.90 0.55 0.10], 'LineWidth',1.8, ...
    'DisplayName','Perdida $L_{ebg}$');
plot(ax2, freq, 100*sm(R_ebg), '-', 'Color',[0.80 0.15 0.15], 'LineWidth',1.8, ...
    'DisplayName','Reflejada $R_{ebg}$');
txt = { sprintf('$T$ = %.1f\\%%', 100*Tb), sprintf('$L$ = %.1f\\%%', 100*Lb), ...
        sprintf('$R$ = %.1f\\%%', 100*Rb), sprintf('$\\alpha$ = %.2f dB/cm', ab) };
cols = {[0.20 0.60 0.25],[0.90 0.55 0.10],[0.80 0.15 0.15],[0.1 0.1 0.1]};
for i = 1:4
    text(ax2, 0.985, 0.96-(i-1)*0.06, txt{i}, 'Units','normalized', ...
        'Color',cols{i}, 'FontSize',11, 'FontWeight','bold', ...
        'HorizontalAlignment','right', 'BackgroundColor',[1 1 1 0.7]);
end
title(ax2, ['\textbf{Balance de potencia del EBG (de-embebido)} --- ' proto_lbl], ...
    'FontSize',14);
xlabel(ax2, 'Frequency (GHz)', 'FontSize',14);
ylabel(ax2, 'Power fraction (\%)', 'FontSize',14);
xlim(ax2, [f_s f_stop]);  ylim(ax2, [0 100]);
grid(ax2,'on'); box(ax2,'on');
lgd2 = legend(ax2,'Location','east','FontSize',10);
set(lgd2,'Box','on','Color',[1 1 1],'EdgeColor',[0.75 0.75 0.75]);
try; lgd2.BackgroundAlpha = 0.75; catch; end
saveas(fig2, fullfile(proto_dir, [proto_name '_LossMap_balance.png']));

fprintf('Figuras guardadas en: %s\n', proto_dir);

%% ═══════════════════════════════════════════════════════════════════════════
%  Funciones locales
%% ═══════════════════════════════════════════════════════════════════════════

function [S, freq] = wg_load_avg(proto_dir)
% Promedio COMPLEJO (coherente) de todas las repeticiones .mat.
    files = dir(fullfile(proto_dir,'*.mat'));
    if isempty(files); error('Sin .mat en: %s', proto_dir); end
    N = numel(files);  freq = [];
    S = struct('S11',0,'S31',0,'S13',0,'S33',0);
    for k = 1:N
        d = load(fullfile(proto_dir, files(k).name));
        if isempty(freq); freq = d.freq_ghz(:).'; end
        S.S11 = S.S11 + d.S11(:).';  S.S31 = S.S31 + d.S31(:).';
        S.S13 = S.S13 + d.S13(:).';  S.S33 = S.S33 + d.S33(:).';
    end
    f = fieldnames(S);
    for i = 1:numel(f); S.(f{i}) = S.(f{i}) / N; end
end


function dist = wg_dist_axis(n_orig, Nfft, f_s_GHz, f_stop_GHz, c, velfac)
% Eje de distancia (m) para reflexión (ida y vuelta → /2).
    df   = (f_stop_GHz - f_s_GHz) * 1e9 / (n_orig - 1);
    dt   = 1 / (Nfft * df);
    dist = (0:Nfft-1) * dt * c * velfac / 2;
end


function g = wg_gate(dist, d1, d2)
% Gate raised-cosine entre d1 y d2 (mismas unidades que dist).
    d1 = min(d1,d2); d2 = max(d1,d2);
    g = double((dist >= d1) & (dist <= d2));
    edge = 0.10 * (d2 - d1);
    if edge > 0
        li = (dist >= d1-edge) & (dist < d1);
        ri = (dist > d2) & (dist <= d2+edge);
        g(li) = 0.5*(1 + cos(pi*(d1 - dist(li))/edge));
        g(ri) = 0.5*(1 + cos(pi*(dist(ri) - d2)/edge));
    end
end


function Sg = wg_apply_gate(Sf, w, g)
% Gating: ventana → IFFT → gate → FFT → deshacer ventana (con suelo).
    h  = ifft(Sf .* w);
    Sw = fft(h .* g);
    wsafe = max(w, 0.05*max(w));
    Sg = Sw ./ wsafe;
end
