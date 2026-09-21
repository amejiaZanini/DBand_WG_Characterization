% WG_TimeGating.m
% ─────────────────────────────────────────────────────────────────────────
% IFFT (respuesta en el dominio del espacio) y time-gating de un prototipo
% de guía de onda en banda D.
%
% Objetivos:
%   · Transformar S11 y S33 al dominio de la distancia para LOCALIZAR
%     discontinuidades (transiciones, uniones, defectos, fugas).
%   · Cruzar S11 (visto desde el puerto 1) y S33 (desde el puerto 3): una
%     discontinuidad cercana al puerto 1 aparece "temprano" en S11 y "tarde"
%     en S33 — cruzarlas ayuda a situar cada característica.
%   · Con un GATE en distancia, aislar la guía EBG y quitar las transiciones,
%     y volver al dominio de la frecuencia con el S11 "gateado".
%
% Física del eje de distancia (reflexión, ida y vuelta):
%     Δf = (f_stop - f_s)/(N-1)          paso en frecuencia
%     dt = 1/(Nfft · Δf)                 paso temporal (Nfft = long. IFFT)
%     d  = c · t · VELFAC / 2            /2 = camino de ida y vuelta
%   Resolución (la fija el ancho de banda, NO el zero-padding):
%     Δd ≈ c/(2·BW)·VELFAC
%   VELFAC = 1  → distancia ELÉCTRICA (referida a c). En guía la velocidad de
%   grupo es v_g < c y dispersiva; para distancia física aproximada usa
%   VELFAC ≈ v_g/c en la banda central (ver notas al final).
%
% Requiere MATLAB R2016b o posterior (usa physconst → Antenna/Phased Toolbox;
% si no la tienes, define c = 299792458 manualmente en la sección 2).
% ─────────────────────────────────────────────────────────────────────────

clear; close all; clc;

%% ── 0 · Estilo global ────────────────────────────────────────────────────
set(groot, 'defaultTextInterpreter',          'latex');
set(groot, 'defaultLegendInterpreter',        'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultAxesFontSize',   14);
set(groot, 'defaultAxesFontName',   'Times New Roman');

%% ── 1 · Carpeta del prototipo (promedio complejo de repeticiones) ────────
proto_dir = uigetdir('', 'Selecciona la carpeta del prototipo (.mat)');
if isequal(proto_dir, 0); disp('[Cancelado]'); return; end
[~, proto_name] = fileparts(proto_dir);
proto_lbl = strrep(proto_name, '_', '\_');

files = dir(fullfile(proto_dir, '*.mat'));
if isempty(files); error('Sin archivos .mat en: %s', proto_dir); end
N = numel(files);

freq = [];
S = struct('S11',0,'S31',0,'S13',0,'S33',0);
for k = 1:N
    d = load(fullfile(proto_dir, files(k).name));
    if isempty(freq); freq = d.freq_ghz(:).'; end
    S.S11 = S.S11 + d.S11(:).';     % promedio COMPLEJO (coherente):
    S.S31 = S.S31 + d.S31(:).';     % en dominio del tiempo se necesita el
    S.S13 = S.S13 + d.S13(:).';     % fasor, no la potencia.
    S.S33 = S.S33 + d.S33(:).';
end
S.S11 = S.S11/N;  S.S31 = S.S31/N;  S.S13 = S.S13/N;  S.S33 = S.S33/N;
np = numel(freq);
f_s = freq(1);  f_stop = freq(end);
BW  = (f_stop - f_s) * 1e9;                 % Hz
fprintf('Prototipo : %s  (%d reps, %d puntos, %.0f–%.0f GHz)\n', ...
    proto_name, N, np, f_s, f_stop);

%% ── 2 · Parámetros ───────────────────────────────────────────────────────
c        = physconst('Lightspeed');   % 299792458 m/s
WIN_BETA = 6;          % Kaiser beta (0 = rectangular; 6 ≈ buen compromiso)
ZPAD     = 8;          % factor de zero-padding para el DISPLAY (interpola)
D_MAX_CM = 7;         % límite del eje de distancia en cm (vacío = auto)

% Gate en distancia (m). Vacío → selección interactiva con el ratón.
GATE_D   = [];         % p.ej. [0.010 0.045] para aislar 1.0–4.5 cm

% VELFAC (factor de velocidad, v_g/c). Opciones:
%   AUTO_VELFAC = true  → se calcula de la FASE de S31 (Opción B).
%   AUTO_VELFAC = false → se usa el valor fijo de VELFAC de abajo.
AUTO_VELFAC = true;
VELFAC      = 1.0;     % usado solo si AUTO_VELFAC = false (1 = dist. eléctrica)
L_REF_MM    = 68.24;   % longitud física entre planos de referencia (P1↔P3) [mm]
F_VG_BAND   = [110 170];  % banda GHz para promediar v_g

if AUTO_VELFAC
    [VELFAC, vg_band, ~] = wg_group_velocity(S.S31, freq, L_REF_MM*1e-3, ...
                                             F_VG_BAND, c);
    fprintf('VELFAC (de fase S31)  : %.4f   (v_g ≈ %.3e m/s en %g–%g GHz)\n', ...
        VELFAC, vg_band, F_VG_BAND(1), F_VG_BAND(2));
end

res_cm = 100 * c/(2*BW) * VELFAC;
fprintf('Resolucion espacial  Δd ≈ %.2f cm  (BW = %.0f GHz)\n', res_cm, BW/1e9);

%% ── 3 · Ventana + IFFT para DISPLAY (envolvente vs distancia) ────────────
w   = kaiser(np, WIN_BETA).';         % ventana en frecuencia
Nd  = 2^nextpow2(np * ZPAD);          % longitud IFFT para display
dist_d = wg_dist_axis(np, Nd, f_s, f_stop, c, VELFAC);   % m

h11 = ifft(S.S11 .* w, Nd);
h33 = ifft(S.S33 .* w, Nd);
env11 = 20*log10(abs(h11) / max(abs(h11)) + 1e-12);   % dB, normalizado
env33 = 20*log10(abs(h33) / max(abs(h33)) + 1e-12);

if isempty(D_MAX_CM)
    D_MAX_CM = 100 * dist_d(round(Nd/2));    % media ventana sin ambigüedad
end

%% ── 3b · Simulación opcional (comparar medida vs simulación) ─────────────
% Carga el S11 de simulación (.txt: freq/Re/Im o freq/dB), lo interpola a la
% rejilla de frecuencia MEDIDA (mismo eje de distancia) y lo transforma con
% la misma ventana/IFFT para comparar en distancia y en return loss gateado.
S11_sim = [];  env_sim = [];  sim_lbl = '';
resp_sim = questdlg('Anadir simulacion (S11 .txt) para comparar?', ...
    'Simulacion', 'Si', 'No', 'No');
if strcmp(resp_sim, 'Si')
    [f_sim, p_sim] = uigetfile( ...
        {'*.txt;*.dat','S11 sim (freq/Re/Im o freq/dB)';'*.*','Todos'}, ...
        'Selecciona S11 de simulacion (reflexion)');
    if ~isequal(f_sim, 0)
        [fsim, S11_raw] = wg_read_txt_cplx(fullfile(p_sim, f_sim));
        S11_sim = interp1(fsim, real(S11_raw), freq, 'linear', 0) + ...
             1j * interp1(fsim, imag(S11_raw), freq, 'linear', 0);
        hsim    = ifft(S11_sim .* w, Nd);
        env_sim = 20*log10(abs(hsim)/max(abs(hsim)) + 1e-12);
        sim_lbl = strrep(strtok(f_sim,'.'),'_','\_');
        fprintf('Simulacion: %s\n', f_sim);
    end
end

%% ── 4 · Fig 1 — S11 y S33 en distancia (localizar discontinuidades) ──────
fig1 = figure('Name',['TDR\_' proto_name],'NumberTitle','off');
set(fig1,'Units','centimeters','Position',[2 2 22 14]);
ax1 = gca; hold on;
plot(ax1, 100*dist_d, env11, '-',  'Color',[0.00 0.45 0.74], ...
    'LineWidth',1.8, 'DisplayName','$S_{11}$ (desde puerto 1)');
plot(ax1, 100*dist_d, env33, '--', 'Color',[0.85 0.33 0.10], ...
    'LineWidth',1.8, 'DisplayName','$S_{22}$ (desde puerto 3)');
if ~isempty(env_sim)
    plot(ax1, 100*dist_d, env_sim, ':', 'Color',[0.10 0.10 0.10], ...
        'LineWidth',1.8, 'DisplayName',['Sim: ' sim_lbl]);
end
title(ax1, ['\textbf{Respuesta en distancia (reflexion)} --- ' proto_lbl], ...
    'FontSize',15);
xlabel(ax1, 'Distancia (cm)  [ida y vuelta / 2]', 'FontSize',14);
ylabel(ax1, 'Amplitud (dB, norm.)', 'FontSize',14);
xlim(ax1, [0 D_MAX_CM]);
ylim(ax1, [-60 2]);
grid(ax1,'on'); box(ax1,'on');
lgd = legend(ax1,'Location','northeast','FontSize',10);
set(lgd,'Box','on','Color',[1 1 1],'EdgeColor',[0.75 0.75 0.75]);
try; lgd.BackgroundAlpha = 0.75; catch; end
saveas(fig1, fullfile(proto_dir, [proto_name '_TDR.png']));

%% ── 5 · Definir el gate (config o interactivo) ───────────────────────────
if isempty(GATE_D)
    disp('Selecciona el GATE: haz clic en el INICIO y luego en el FIN (eje X, cm).');
    figure(fig1);
    [xg, ~] = ginput(2);
    GATE_D  = sort(xg(:).') / 100;    % cm → m
end
fprintf('Gate : %.2f – %.2f cm\n', 100*GATE_D(1), 100*GATE_D(2));

% Marcar el gate en la Fig 1
xline(ax1, 100*GATE_D(1), '-.', 'Color',[0.2 0.6 0.2], 'LineWidth',1.4, ...
    'DisplayName','Gate');
xline(ax1, 100*GATE_D(2), '-.', 'Color',[0.2 0.6 0.2], 'LineWidth',1.4, ...
    'HandleVisibility','off');
saveas(fig1, fullfile(proto_dir, [proto_name '_TDR.png']));

%% ── 6 · Aplicar el gate y volver a frecuencia ────────────────────────────
% Camino exactamente invertible: Nfft = np (sin zero-padding).
dist_g = wg_dist_axis(np, np, f_s, f_stop, c, VELFAC);   % m
g = wg_gate_window(dist_g, GATE_D(1), GATE_D(2));         % raised-cosine 0..1

S11_gated = wg_apply_gate(S.S11, w, g);
S33_gated = wg_apply_gate(S.S33, w, g);
S11_sim_gated = [];
if ~isempty(S11_sim)
    S11_sim_gated = wg_apply_gate(S11_sim, w, g);
end

%% ── 7 · Fig 2 — S11 original vs gateado (frecuencia) ─────────────────────
to_dB = @(x) 20*log10(abs(x) + 1e-12);
fig2 = figure('Name',['Gated\_' proto_name],'NumberTitle','off');
set(fig2,'Units','centimeters','Position',[2 2 22 14]);
ax2 = gca; hold on;
plot(ax2, freq, to_dB(S.S11),   '-',  'Color',[0.70 0.70 0.70], ...
    'LineWidth',1.4, 'DisplayName','$S_{11}$ original');
plot(ax2, freq, to_dB(S11_gated), '-','Color',[0.00 0.45 0.74], ...
    'LineWidth',1.9, 'DisplayName','$S_{11}$ gateado (guia EBG)');
if ~isempty(S11_sim_gated)
    plot(ax2, freq, to_dB(S11_sim_gated), '-', 'Color',[0.10 0.10 0.10], ...
        'LineWidth',1.7, 'DisplayName',['Sim gateado: ' sim_lbl]);
end
title(ax2, ['\textbf{Return Loss: original vs gateado} --- ' proto_lbl], ...
    'FontSize',15);
xlabel(ax2, 'Frequency (GHz)', 'FontSize',14);
ylabel(ax2, '$|S_{11}|$ (dB)', 'FontSize',14);
xlim(ax2, [f_s f_stop]);
grid(ax2,'on'); box(ax2,'on');
lgd2 = legend(ax2,'Location','southeast','FontSize',10);
set(lgd2,'Box','on','Color',[1 1 1],'EdgeColor',[0.75 0.75 0.75]);
try; lgd2.BackgroundAlpha = 0.75; catch; end
saveas(fig2, fullfile(proto_dir, [proto_name '_S11_gated.png']));

fprintf('Figuras guardadas en: %s\n', proto_dir);

%% ═══════════════════════════════════════════════════════════════════════════
%  Funciones locales
%% ═══════════════════════════════════════════════════════════════════════════

function dist = wg_dist_axis(n_orig, Nfft, f_s_GHz, f_stop_GHz, c, velfac)
% Eje de distancia (m) para reflexión (ida y vuelta → /2).
%   n_orig : nº de puntos de frecuencia ORIGINALES (fija Δf)
%   Nfft   : longitud de la IFFT (puede ser > n_orig por zero-padding)
    df   = (f_stop_GHz - f_s_GHz) * 1e9 / (n_orig - 1);   % Hz
    dt   = 1 / (Nfft * df);
    t    = (0:Nfft-1) * dt;
    dist = t * c * velfac / 2;        % /2 : reflexión
end


function [velfac_band, vg_band, vg] = wg_group_velocity(S21, freq_GHz, L_m, band_GHz, c)
% Velocidad de grupo a partir de la FASE de la transmisión (Opción B).
%   S21      : transmisión compleja (fila, p.ej. S31)
%   freq_GHz : eje de frecuencia (GHz)
%   L_m      : longitud física entre planos de referencia (m)
%   band_GHz : [f_lo f_hi] banda para promediar (GHz)
%   c        : velocidad de la luz (m/s)
% Salidas:
%   velfac_band : v_g/c promediado en la banda (escalar)
%   vg_band     : v_g promediado en la banda (m/s)
%   vg          : v_g(f) completo (dispersión), mismo tamaño que freq
%
% Física:  phi(f) = unwrap(angle(S21)) = -beta(f)*L   (fase de propagación)
%          tau_g  = -(1/2pi) dphi/df       (retardo de grupo)
%          v_g    =  L / tau_g
% Nota: usa L entre planos de referencia → v_g medio de TODA la estructura
% (transiciones + EBG). Para la dispersión intrínseca del EBG, de-embeber el
% thru y pasar L = longitud del EBG.
    f  = freq_GHz(:).' * 1e9;              % Hz
    phi = unwrap(angle(S21(:).'));         % fase desenvuelta [rad]
    % Retardo de grupo por diferencias centradas:  tau = -(1/2pi) dphi/df
    tau = -(1/(2*pi)) * gradient(phi, f);  % s
    tau(tau <= 0) = NaN;                   % descarta tramos no físicos
    vg  = L_m ./ tau;                      % m/s  (v_g(f))

    m = (freq_GHz(:).' >= band_GHz(1)) & (freq_GHz(:).' <= band_GHz(2));
    vg_band     = mean(vg(m), 'omitnan');
    velfac_band = vg_band / c;
    if ~isfinite(velfac_band) || velfac_band <= 0
        warning('v_g no física (fase ruidosa?). Usa AUTO_VELFAC=false.');
        velfac_band = 1.0;  vg_band = c;
    end
end


function g = wg_gate_window(dist, d1, d2)
% Gate raised-cosine (Tukey-like) entre d1 y d2, con bordes suaves.
    g = zeros(size(dist));
    inside = (dist >= d1) & (dist <= d2);
    g(inside) = 1;
    % Bordes suaves: 10 % del ancho del gate a cada lado
    edge = 0.10 * (d2 - d1);
    if edge > 0
        li = (dist >= d1-edge) & (dist < d1);
        ri = (dist > d2) & (dist <= d2+edge);
        g(li) = 0.5*(1 + cos(pi*(d1 - dist(li))/edge));
        g(ri) = 0.5*(1 + cos(pi*(dist(ri) - d2)/edge));
    end
end


function Sg = wg_apply_gate(Sf, w, g)
% Gating estándar: ventana → IFFT → gate → FFT → deshacer ventana.
%   Sf : S-param complejo (frecuencia), fila 1×np
%   w  : ventana en frecuencia (1×np)
%   g  : gate en tiempo/distancia (1×np)
    h  = ifft(Sf .* w);          % dominio del tiempo (Nfft = np)
    hg = h .* g;                 % aplicar el gate
    Sw = fft(hg);                % de vuelta a frecuencia (aún con ventana)
    % Deshacer la ventana con un suelo para no amplificar los bordes de banda
    wsafe = max(w, 0.05 * max(w));
    Sg = Sw ./ wsafe;
end


function [freq_ghz, val] = wg_read_txt_cplx(filepath)
% Lee un .txt de simulación → valor complejo. Auto-detecta el formato:
%   3 columnas: freq | Real | Imag  → S = Re + jIm
%   2 columnas: freq | Magnitud dB  → S = 10^(dB/20)
% Ignora líneas que empiezan con #. Detecta la unidad de frecuencia.
    fid = fopen(filepath, 'r');
    if fid < 0; error('No se pudo abrir: %s', filepath); end
    rows = {};
    while ~feof(fid)
        raw = fgetl(fid);
        if ~ischar(raw); break; end
        line = strtrim(raw);
        if isempty(line) || line(1) == '#'; continue; end
        nums = sscanf(line, '%f').';
        if numel(nums) >= 2; rows{end+1} = nums; end %#ok
    end
    fclose(fid);
    if isempty(rows); error('Sin datos numericos en: %s', filepath); end
    ncol = min(cellfun(@numel, rows));
    M = nan(numel(rows), ncol);
    for r = 1:numel(rows); M(r,1:ncol) = rows{r}(1:ncol); end
    freq_ghz = M(:,1).';
    if ncol >= 3
        val = (M(:,2) + 1j*M(:,3)).';       % Re/Im → complejo
    else
        val = 10.^(M(:,2).' / 20);          % dB → lineal (real positivo)
    end
    if     max(freq_ghz) > 1e6; freq_ghz = freq_ghz / 1e9;   % Hz → GHz
    elseif max(freq_ghz) > 1e3; freq_ghz = freq_ghz / 1e3;   % MHz → GHz
    end
end
