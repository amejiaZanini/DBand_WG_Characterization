% WG_PlotResults.m
% ─────────────────────────────────────────────────────────────────────────
% Dos modos de operación (se pregunta al inicio):
%
%  [Visualizar]  — Un prototipo con todas sus repeticiones.
%    Fig 1: Transmisión |S21| — todas las reps
%    Fig 2: Reflexión   |S11| — todas las reps
%    Fig 3: S21 + S11 combinados — 5 primeras reps, ylim a medida
%    (nota: los datos .mat guardan el campo S31, que se etiqueta como S21;
%     de igual modo S33→S22 y S13→S12 en los otros scripts.)
%
%  [Comparar]   — Varias carpetas de prototipo, una curva promedio c/u.
%    Color por material (Ni=rojo suave, Cu=azul suave), opacidad por muestra;
%    S21 continua, S11 discontinua.
%    Fig C1: Transmisión S21 — sin límite, con thru
%    Fig C2: Reflexión   S11 — sin límite, con thru
%    Fig C3/C4: S21/S11 con escala + simulación (sin thru, sin threshold)
%    Fig CT: thru before/after (S21 y S11 en la misma figura)
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

%% ── 1 · Modo de operación ────────────────────────────────────────────────
mode_sel = questdlg('Selecciona el modo de operacion:', ...
    'WG Plot Results', 'Visualizar', 'Comparar', 'Visualizar');
if isempty(mode_sel); disp('[Cancelado]'); return; end

%% ═══════════════════════════════════════════════════════════════════════════
%  MODO VISUALIZAR
%% ═══════════════════════════════════════════════════════════════════════════
if strcmp(mode_sel, 'Visualizar')

    % ── V1 · Carpeta del prototipo ─────────────────────────────────────────
    proto_dir = uigetdir('', 'Selecciona la carpeta del prototipo');
    if isequal(proto_dir, 0); disp('[Cancelado]'); return; end

    [session_dir, proto_name] = fileparts(proto_dir);
    proto_lbl = strrep(proto_name, '_', '\_');
    fprintf('Prototipo  : %s\n', proto_name);
    fprintf('Sesion     : %s\n\n', session_dir);

    % ── V2 · Thru before / after ──────────────────────────────────────────
    [thru_before, thru_after] = wg_load_thru(session_dir);

    % ── V3 · Medidas del prototipo ─────────────────────────────────────────
    [proto, N, freq] = wg_load_proto(proto_dir, thru_before);

    % ── V4 · Estilos ───────────────────────────────────────────────────────
    [COL_TB, COL_TA, ~, COL_PROTO, LW, SM, K] = wg_style(N);
    to_dB = @(S) 20 * log10(max(abs(S(:).'), 1e-12));
    sm    = SM;

    THRESH_TX  = -3;
    THRESH_RX  = -15;
    F_KEY      = 140;
    FIG_CM     = [2 2 20 14];
    save_dir   = proto_dir;

    % ── V4b · Archivos de simulación (opcional) ────────────────────────────
    % Formato .txt: freq/Re/Im (3 col) o freq/dB (2 col), líneas # ignoradas.
    % Se piden 2 archivos por simulación: uno para S21 (transmisión, campo
    % S31 en los .mat) y otro para S11 (reflexión).
    SIM_COLS  = [0.10 0.10 0.10; 0.00 0.50 0.00; 0.60 0.00 0.60; 0.55 0.27 0.07];
    LW_SIM    = 2.0;
    sim_files = {};
    add_sim = questdlg('Anadir simulaciones a Fig 1 y Fig 2?', ...
        'Simulacion', 'Si', 'No', 'No');
    while strcmp(add_sim, 'Si')
        n_s = numel(sim_files) + 1;
        % Archivo S31 (Transmisión)
        [f31, p31] = uigetfile({'*.txt;*.dat','Datos (*.txt, *.dat)';'*.*','Todos'}, ...
            sprintf('Sim %d — S21 / Transmision (.txt)', n_s));
        if isequal(f31, 0); break; end
        [fs31_, s31_lin_] = wg_read_txt_dB(fullfile(p31, f31));
        f_lbl_ = strrep(strtok(f31, '.'),'_','\_');
        % Archivo S11 (Reflexión) — Cancelar para omitir
        [f11, p11] = uigetfile({'*.txt;*.dat','Datos (*.txt, *.dat)';'*.*','Todos'}, ...
            sprintf('Sim %d — S11 / Reflexion (.txt)  [Cancelar = omitir]', n_s));
        s11_lin_ = [];
        if ~isequal(f11, 0)
            [~, s11_lin_] = wg_read_txt_dB(fullfile(p11, f11));
        end
        c_idx_ = mod(numel(sim_files), size(SIM_COLS,1)) + 1;
        sim_files{end+1} = struct('freq',fs31_,'S11',s11_lin_,'S31',s31_lin_, ...
            'lbl',f_lbl_,'col',SIM_COLS(c_idx_,:));
        fprintf('  Sim %d: S31 = %s\n', numel(sim_files), f31);
        if numel(sim_files) >= size(SIM_COLS,1); break; end
        add_sim = questdlg('Anadir otra simulacion?', 'Simulacion', 'Si', 'No', 'No');
    end

    % ── V5 · Fig 1 — Transmisión |S31| ────────────────────────────────────
    fig1 = wg_new_fig(['TX\_' proto_name], FIG_CM);
    ax1 = gca; hold on;
    wg_ref_lines(ax1, F_KEY, THRESH_TX);
    wg_plot_curves(ax1, freq, thru_before, thru_after, proto, 'S31', ...
        COL_TB, COL_TA, COL_PROTO, LW.ref, LW.proto, to_dB, sm);
    for si = 1:numel(sim_files)
        sf = sim_files{si};
        if ~isempty(sf.S31)
            plot(ax1, sf.freq, sm(to_dB(sf.S31)), '-', ...
                'Color', sf.col, 'LineWidth', LW_SIM, 'DisplayName', ['Sim: ' sf.lbl]);
        end
    end
    wg_annotate_all(ax1, freq, thru_before, thru_after, proto, K, sim_files, ...
        'S31', F_KEY, COL_TB, COL_TA, COL_PROTO, to_dB, sm);
    wg_format_ax(ax1, freq, ...
        ['\textbf{Insertion Loss} --- ' proto_lbl], '$|S_{21}|$ (dB)', []);
    saveas(fig1, fullfile(save_dir, [proto_name '_S31.png']));

    % ── V6 · Fig 2 — Reflexión |S11| ──────────────────────────────────────
    fig2 = wg_new_fig(['RX\_' proto_name], FIG_CM);
    ax2 = gca; hold on;
    wg_ref_lines(ax2, F_KEY, THRESH_RX);
    wg_plot_curves(ax2, freq, thru_before, thru_after, proto, 'S11', ...
        COL_TB, COL_TA, COL_PROTO, LW.ref, LW.proto, to_dB, sm);
    for si = 1:numel(sim_files)
        sf = sim_files{si};
        if ~isempty(sf.S11)
            plot(ax2, sf.freq, sm(to_dB(sf.S11)), '-', ...
                'Color', sf.col, 'LineWidth', LW_SIM, 'DisplayName', ['Sim: ' sf.lbl]);
        end
    end
    wg_annotate_all(ax2, freq, thru_before, thru_after, proto, K, sim_files, ...
        'S11', F_KEY, COL_TB, COL_TA, COL_PROTO, to_dB, sm);
    wg_format_ax(ax2, freq, ...
        ['\textbf{Return Loss} --- ' proto_lbl], '$|S_{11}|$ (dB)', []);
    saveas(fig2, fullfile(save_dir, [proto_name '_S11.png']));

    % ── V7 · Fig 3 — S31 + S11 combinados (5 primeras reps) ───────────────
    ylim3 = wg_ask_ylim('Fig. 3 --- Escala eje Y', '-30', '0');

    fig3 = wg_new_fig(['Combined\_' proto_name], [2 2 22 15]);
    ax3 = gca; hold on;
    wg_ref_lines(ax3, F_KEY, []);
    if ~isempty(thru_before)
        if isfield(thru_before,'S31')
            plot(ax3, freq, sm(to_dB(thru_before.S31)), '-', ...
                'Color', COL_TB, 'LineWidth', LW.ref, 'DisplayName', '$S_{21}$ Thru before');
        end
        if isfield(thru_before,'S11')
            plot(ax3, freq, sm(to_dB(thru_before.S11)), '--', ...
                'Color', COL_TB, 'LineWidth', LW.ref, 'DisplayName', '$S_{11}$ Thru before');
        end
    end
    if ~isempty(thru_after)
        if isfield(thru_after,'S31')
            plot(ax3, freq, sm(to_dB(thru_after.S31)), '-', ...
                'Color', COL_TA, 'LineWidth', LW.ref, 'DisplayName', '$S_{21}$ Thru after');
        end
        if isfield(thru_after,'S11')
            plot(ax3, freq, sm(to_dB(thru_after.S11)), '--', ...
                'Color', COL_TA, 'LineWidth', LW.ref, 'DisplayName', '$S_{11}$ Thru after');
        end
    end
    for k = 1:K
        c = COL_PROTO(k,:);
        if isfield(proto{k},'S31')
            plot(ax3, freq, sm(to_dB(proto{k}.S31)), '-', ...
                'Color', c, 'LineWidth', LW.proto, ...
                'DisplayName', ['$S_{21}$ Rep ' num2str(k)]);
        end
        if isfield(proto{k},'S11')
            plot(ax3, freq, sm(to_dB(proto{k}.S11)), '--', ...
                'Color', c, 'LineWidth', LW.proto, ...
                'DisplayName', ['$S_{11}$ Rep ' num2str(k)]);
        end
    end
    wg_format_ax(ax3, freq, ...
        ['\textbf{$S_{21}$ (---) \& $S_{11}$ (- -)} --- ' proto_lbl], ...
        'Level (dB)', ylim3);
    set(legend(ax3), 'Location', 'eastoutside');
    saveas(fig3, fullfile(save_dir, [proto_name '_S31_S11.png']));


%% ═══════════════════════════════════════════════════════════════════════════
%  MODO COMPARAR
%% ═══════════════════════════════════════════════════════════════════════════
else  % Comparar

    % ── C1 · Carpeta maestra ───────────────────────────────────────────────
    master_dir = uigetdir('', 'Selecciona la carpeta maestra (sesion)');
    if isequal(master_dir, 0); disp('[Cancelado]'); return; end
    [~, master_name] = fileparts(master_dir);
    fprintf('Carpeta maestra : %s\n\n', master_dir);

    % ── C2 · Thru before / after ──────────────────────────────────────────
    [thru_before, thru_after] = wg_load_thru(master_dir);

    % ── C3 · Selección de subcarpetas (listdlg) ────────────────────────────
    items = dir(master_dir);
    subdirs = {items([items.isdir] & ...
        ~strcmp({items.name},'.') & ~strcmp({items.name},'..')).name};
    if isempty(subdirs)
        error('No se encontraron subcarpetas en:\n  %s', master_dir);
    end
    [sel_idx, ok] = listdlg( ...
        'ListString',   subdirs, ...
        'SelectionMode','multiple', ...
        'Name',         'Selecciona los prototipos', ...
        'PromptString', 'Carpetas a comparar (media de 5 primeras medidas):', ...
        'ListSize',     [320 220]);
    if ~ok; disp('[Cancelado]'); return; end
    selected = subdirs(sel_idx);
    M = numel(selected);
    fprintf('Prototipos seleccionados : %d\n', M);

    % ── C4 · Cargar y promediar ────────────────────────────────────────────
    % Paleta de comparación (colores bien diferenciados)
    COL_COMP = [
        0.00 0.45 0.74;   % azul
        0.85 0.33 0.10;   % naranja
        0.13 0.70 0.28;   % verde
        0.49 0.18 0.56;   % púrpura
        0.90 0.62 0.00;   % amarillo oscuro
        0.30 0.75 0.93;   % cyan
        0.64 0.08 0.18;   % rojo oscuro
        0.00 0.50 0.50;   % teal
    ];
    COL_TB  = [0.00 0.35 0.80];
    COL_TA  = [0.85 0.10 0.10];
    COL_SIM = [0.10 0.10 0.10];
    LW_REF  = 1.8;
    LW_COMP = 1.6;
    LW_SIM  = 2.2;
    SMOOTH  = 5;
    F_KEY   = 140;
    FIG_CM  = [2 2 20 14];

    to_dB = @(S) 20 * log10(max(abs(S(:).'), 1e-12));
    sm    = @(v) smoothdata(v(:).', 'gaussian', SMOOTH);

    cases   = struct('name',{},'S11',{},'S31',{},'freq',{},'col',{},'n',{});
    freq_c  = [];

    for i = 1:M
        folder = fullfile(master_dir, selected{i});
        files  = dir(fullfile(folder, '*.mat'));
        if isempty(files)
            warning('Sin archivos .mat en: %s — omitido.', folder);
            continue;
        end
        [~, ord] = sort({files.name});
        files = files(ord);
        n_avg = min(5, numel(files));

        acc_S11 = 0;  acc_S31 = 0;
        for k = 1:n_avg
            d = load(fullfile(folder, files(k).name));
            acc_S11 = acc_S11 + d.S11(:).';
            acc_S31 = acc_S31 + d.S31(:).';
        end
        c_idx = mod(i-1, size(COL_COMP,1)) + 1;
        cases(end+1) = struct( ...
            'name', selected{i}, ...
            'S11',  acc_S11 / n_avg, ...
            'S31',  acc_S31 / n_avg, ...
            'freq', d.freq_ghz(:).', ...
            'col',  COL_COMP(c_idx,:), ...
            'n',    n_avg);
        if isempty(freq_c); freq_c = d.freq_ghz(:).'; end
        fprintf('  %s : %d medidas promediadas\n', selected{i}, n_avg);
    end
    fprintf('\n');

    if isempty(cases)
        error('Ningun prototipo cargado correctamente.');
    end

    % ── C5 · Estilo por material (color) y muestra (opacidad) ──────────────
    % Color por material: Niquel → rojo, Cobre → azul (gama azul↔rojo).
    % Muestras del mismo material comparten color y se distinguen por
    % opacidad.  Linea: S21 (--), S11 (—).  El thru va en neutros (negro/gris)
    % para no chocar con los colores de material.
    cases   = wg_assign_material_style(cases);
    COL_TB  = [0.00 0.00 0.00];   % thru before → negro
    COL_TA  = [0.50 0.50 0.50];   % thru after  → gris
    STY_S21 = '-';                % transmision → continua
    STY_S11 = '--';               % reflexion   → discontinua

    % ── C6 · Fig C1 — Transmisión S21 (sin límite, con thru) ───────────────
    fig_c1 = wg_new_fig(['CompTX\_' master_name], FIG_CM);
    ax_c1  = gca; hold on;
    wg_ref_lines(ax_c1, F_KEY, []);
    wg_plot_thru2(ax_c1, freq_c, thru_before, thru_after, 'S31', STY_S21, ...
        COL_TB, COL_TA, LW_REF, to_dB, sm);
    wg_plot_cases(ax_c1, cases, 'S31', STY_S21, LW_COMP, to_dB, sm);
    wg_format_ax(ax_c1, freq_c, ...
        ['\textbf{Insertion Loss Comparison} --- ' strrep(master_name,'_','\_')], ...
        '$|S_{21}|$ (dB)', []);
    saveas(fig_c1, fullfile(master_dir, [master_name '_Comp_TX.png']));

    % ── C7 · Fig C2 — Reflexión S11 (sin límite, con thru) ─────────────────
    fig_c2 = wg_new_fig(['CompRX\_' master_name], FIG_CM);
    ax_c2  = gca; hold on;
    wg_ref_lines(ax_c2, F_KEY, []);
    wg_plot_thru2(ax_c2, freq_c, thru_before, thru_after, 'S11', STY_S11, ...
        COL_TB, COL_TA, LW_REF, to_dB, sm);
    wg_plot_cases(ax_c2, cases, 'S11', STY_S11, LW_COMP, to_dB, sm);
    wg_format_ax(ax_c2, freq_c, ...
        ['\textbf{Return Loss Comparison} --- ' strrep(master_name,'_','\_')], ...
        '$|S_{11}|$ (dB)', []);
    saveas(fig_c2, fullfile(master_dir, [master_name '_Comp_RX.png']));

    % ── C8 · Figs C3/C4 — con escala + simulación (sin thru, sin threshold) ─
    resp2 = questdlg('Anadir escala fija y/o simulacion?', ...
        'Comparacion avanzada', 'Si', 'No', 'No');
    if strcmp(resp2, 'Si')
        % Simulación opcional (múltiples; formato .txt freq/Re/Im o freq/dB)
        SIM_COLS_C = [0.10 0.10 0.10; 0.00 0.50 0.00; 0.60 0.00 0.60; 0.55 0.27 0.07];
        sim_files_c = {};
        add_sim_c = questdlg('Anadir simulacion?', 'Simulacion', 'Si', 'No', 'No');
        while strcmp(add_sim_c, 'Si')
            n_sc = numel(sim_files_c) + 1;
            [f31c, p31c] = uigetfile({'*.txt;*.dat','Datos';'*.*','Todos'}, ...
                sprintf('Sim %d — S21 / Transmision (.txt)', n_sc));
            if isequal(f31c, 0); break; end
            [fs31c, s31c_lin] = wg_read_txt_dB(fullfile(p31c, f31c));
            f_lbl_c = strrep(strtok(f31c,'.'),'_','\_');
            [f11c, p11c] = uigetfile({'*.txt;*.dat','Datos';'*.*','Todos'}, ...
                sprintf('Sim %d — S11 / Reflexion (.txt)  [Cancelar = omitir]', n_sc));
            s11c_lin = [];
            if ~isequal(f11c, 0)
                [~, s11c_lin] = wg_read_txt_dB(fullfile(p11c, f11c));
            end
            c_idx_c = mod(numel(sim_files_c), size(SIM_COLS_C,1)) + 1;
            sim_files_c{end+1} = struct('freq',fs31c,'S11',s11c_lin,'S31',s31c_lin, ...
                'lbl',f_lbl_c,'col',SIM_COLS_C(c_idx_c,:));
            fprintf('  Sim %d: %s\n', numel(sim_files_c), f31c);
            if numel(sim_files_c) >= size(SIM_COLS_C,1); break; end
            add_sim_c = questdlg('Anadir otra simulacion?', 'Simulacion', 'Si', 'No', 'No');
        end

        % Fig C3 — S21 con escala (medidas por material + simulación, sin thru)
        ylim_tx = wg_ask_ylim('Fig. C3 — S21 Escala eje Y', '-5', '0');
        fig_c3 = wg_new_fig(['CompTX\_lim\_' master_name], FIG_CM);
        ax_c3  = gca; hold on;
        wg_ref_lines(ax_c3, F_KEY, []);
        wg_plot_cases(ax_c3, cases, 'S31', STY_S21, LW_COMP, to_dB, sm);
        for si = 1:numel(sim_files_c)
            sf = sim_files_c{si};
            if ~isempty(sf.S31)
                plot(ax_c3, sf.freq, sm(to_dB(sf.S31)), '-', ...
                    'Color', sf.col, 'LineWidth', LW_SIM, ...
                    'DisplayName', ['Sim: ' sf.lbl]);
            end
        end
        wg_format_ax(ax_c3, freq_c, '\textbf{Insertion Loss Comparison}', ...
            '$|S_{21}|$ (dB)', ylim_tx);
        saveas(fig_c3, fullfile(master_dir, [master_name '_Comp_TX_lim.png']));

        % Fig C4 — S11 con escala (medidas por material + simulación, sin thru)
        ylim_rx = wg_ask_ylim('Fig. C4 — S11 Escala eje Y', '-30', '0');
        fig_c4 = wg_new_fig(['CompRX\_lim\_' master_name], FIG_CM);
        ax_c4  = gca; hold on;
        wg_ref_lines(ax_c4, F_KEY, []);
        wg_plot_cases(ax_c4, cases, 'S11', STY_S11, LW_COMP, to_dB, sm);
        for si = 1:numel(sim_files_c)
            sf = sim_files_c{si};
            if ~isempty(sf.S11)
                plot(ax_c4, sf.freq, sm(to_dB(sf.S11)), '-', ...
                    'Color', sf.col, 'LineWidth', LW_SIM, ...
                    'DisplayName', ['Sim: ' sf.lbl]);
            end
        end
        wg_format_ax(ax_c4, freq_c, '\textbf{Return Loss Comparison}', ...
            '$|S_{11}|$ (dB)', ylim_rx);
        saveas(fig_c4, fullfile(master_dir, [master_name '_Comp_RX_lim.png']));

        % Fig CT — Thru before/after (S21 y S11 en la misma figura)
        % S21 continua, S11 discontinua; before negro, after gris. Escala S11.
        fig_ct = wg_new_fig(['CompThru\_' master_name], FIG_CM);
        ax_ct  = gca; hold on;
        wg_ref_lines(ax_ct, F_KEY, []);
        if ~isempty(thru_before)
            if isfield(thru_before,'S31')
                plot(ax_ct, freq_c, sm(to_dB(thru_before.S31)), STY_S21, ...
                    'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName', 'Thru before $S_{21}$');
            end
            if isfield(thru_before,'S11')
                plot(ax_ct, freq_c, sm(to_dB(thru_before.S11)), STY_S11, ...
                    'Color', COL_TB, 'LineWidth', LW_REF, 'DisplayName', 'Thru before $S_{11}$');
            end
        end
        if ~isempty(thru_after)
            if isfield(thru_after,'S31')
                plot(ax_ct, freq_c, sm(to_dB(thru_after.S31)), STY_S21, ...
                    'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName', 'Thru after $S_{21}$');
            end
            if isfield(thru_after,'S11')
                plot(ax_ct, freq_c, sm(to_dB(thru_after.S11)), STY_S11, ...
                    'Color', COL_TA, 'LineWidth', LW_REF, 'DisplayName', 'Thru after $S_{11}$');
            end
        end
        wg_format_ax(ax_ct, freq_c, ...
            ['\textbf{Thru reference (before/after)} --- ' strrep(master_name,'_','\_')], ...
            'Level (dB)', ylim_rx);
        saveas(fig_ct, fullfile(master_dir, [master_name '_Comp_Thru.png']));
    end

end  % fin modo comparar

%% ═══════════════════════════════════════════════════════════════════════════
%  Funciones locales
%% ═══════════════════════════════════════════════════════════════════════════

function [thru_before, thru_after] = wg_load_thru(folder)
% Abre ventanas de selección para thru_before y thru_after.
    [f_tb, p_tb] = uigetfile(fullfile(folder,'thru_before_*.mat'), ...
        'Selecciona THRU BEFORE (.mat)');
    thru_before = [];
    if ~isequal(f_tb,0)
        thru_before = load(fullfile(p_tb,f_tb));
        fprintf('Thru before : %s\n', f_tb);
    else
        warning('Sin Thru before.');
    end
    [f_ta, p_ta] = uigetfile(fullfile(folder,'thru_after_*.mat'), ...
        'Selecciona THRU AFTER (.mat)');
    thru_after = [];
    if ~isequal(f_ta,0)
        thru_after = load(fullfile(p_ta,f_ta));
        fprintf('Thru after  : %s\n\n', f_ta);
    else
        warning('Sin Thru after.');
    end
end


function [proto, N, freq] = wg_load_proto(proto_dir, thru_before)
% Carga todos los .mat de la carpeta del prototipo en orden cronológico.
    files = dir(fullfile(proto_dir,'*.mat'));
    if isempty(files); error('Sin archivos .mat en: %s', proto_dir); end
    [~, ord] = sort({files.name});
    files = files(ord);
    N = numel(files);
    fprintf('Medidas cargadas : %d\n\n', N);
    proto = cell(N,1);
    for k = 1:N; proto{k} = load(fullfile(proto_dir,files(k).name)); end
    if ~isempty(thru_before) && isfield(thru_before,'freq_ghz')
        freq = thru_before.freq_ghz(:).';
    else
        freq = proto{1}.freq_ghz(:).';
    end
end


function [COL_TB, COL_TA, COL_SIM, COL_PROTO, LW, SM, K] = wg_style(N)
% Devuelve paleta y estilos. K = min(5,N) reps mostradas en Figs 3-5.
    COL_TB  = [0.00 0.35 0.80];
    COL_TA  = [0.85 0.10 0.10];
    COL_SIM = [0.10 0.10 0.10];
    COL_PROTO = lines(max(N,1));
    LW = struct('ref',1.8, 'proto',1.3, 'sim',2.2);
    SM = @(v) smoothdata(v(:).','gaussian',5);
    K  = min(5,N);
end


function fig = wg_new_fig(name, pos_cm)
% Crea figura con tamaño en centímetros.
    fig = figure('Name',name,'NumberTitle','off');
    set(fig,'Units','centimeters','Position',pos_cm);
end


function wg_ref_lines(ax, f_key, thresh)
% Añade línea vertical en f_key y, opcionalmente, horizontal en thresh.
    xline(ax, f_key, '--', 'Color',[0.3 0.3 0.3], 'LineWidth',1.0, 'HandleVisibility','off');
    if ~isempty(thresh)
        yline(ax, thresh, '--', 'Color',[0 0.5 0], 'LineWidth',1.4, ...
            'DisplayName', ['Threshold (' num2str(thresh) ' dB)']);
    end
end


function wg_format_ax(ax, freq, ttl, ylbl, ylim_val)
% Formato estándar: LaTeX, grid, leyenda en esquina inferior derecha.
    title(ax, ttl, 'FontSize',16);
    xlabel(ax,'Frequency (GHz)','FontSize',14);
    ylabel(ax, ylbl,'FontSize',14);
    xlim(ax,[min(freq) max(freq)]);
    if ~isempty(ylim_val); ylim(ax, ylim_val); end
    grid(ax,'on'); box(ax,'on');
    lgd = legend(ax,'Location','southeast','FontSize',9);
    set(lgd,'Box','on','Color',[1 1 1],'EdgeColor',[0.75 0.75 0.75]);
    try; lgd.BackgroundAlpha = 0.75; catch; end  % R2018a+
    hold(ax,'off');
end


function wg_plot_curves(ax, freq, thru_before, thru_after, proto, param, ...
                         col_tb, col_ta, col_proto, lw_ref, lw_proto, to_dB, sm)
% Dibuja thru before/after + todas las reps del prototipo.
    if ~isempty(thru_before) && isfield(thru_before,param)
        plot(ax,freq,sm(to_dB(thru_before.(param))),'-', ...
            'Color',col_tb,'LineWidth',lw_ref,'DisplayName','Thru before');
    end
    if ~isempty(thru_after) && isfield(thru_after,param)
        plot(ax,freq,sm(to_dB(thru_after.(param))),'-', ...
            'Color',col_ta,'LineWidth',lw_ref,'DisplayName','Thru after');
    end
    for k = 1:numel(proto)
        if isfield(proto{k},param)
            plot(ax,freq,sm(to_dB(proto{k}.(param))),'--', ...
                'Color',col_proto(k,:),'LineWidth',lw_proto, ...
                'DisplayName',['Rep ' num2str(k)]);
        end
    end
end


function wg_annotate_all(ax, freq, thru_before, thru_after, proto, K, ...
                          sim_files, param, F_KEY, ...
                          col_tb, col_ta, col_proto, to_dB, sm)
% Anotaciones de valor en F_KEY: thru before, thru after, reps 1..K, sims.
% sim_files: cell array of structs with .freq .S11 .S31 .lbl .col
    entries = {};
    if ~isempty(thru_before) && isfield(thru_before,param)
        entries{end+1} = struct('f',freq,'v',sm(to_dB(thru_before.(param))), ...
            'c',col_tb,'l','Thru before');
    end
    if ~isempty(thru_after) && isfield(thru_after,param)
        entries{end+1} = struct('f',freq,'v',sm(to_dB(thru_after.(param))), ...
            'c',col_ta,'l','Thru after');
    end
    for k = 1:K
        if isfield(proto{k},param)
            entries{end+1} = struct('f',freq,'v',sm(to_dB(proto{k}.(param))), ...
                'c',col_proto(k,:),'l',['Rep ' num2str(k)]);
        end
    end
    for si = 1:numel(sim_files)
        sf = sim_files{si};
        if isfield(sf, param) && ~isempty(sf.(param))
            entries{end+1} = struct('f',sf.freq,'v',sm(to_dB(sf.(param))), ...
                'c',sf.col,'l',['Sim: ' sf.lbl]);
        end
    end
    tx = 0.97; ty = 0.96; dy = 0.048;
    for i = 1:numel(entries)
        val = interp1(entries{i}.f, entries{i}.v, F_KEY, 'linear', NaN);
        if isnan(val); continue; end
        txt = [entries{i}.l ': ' num2str(val,'%.1f') ' dB @ ' num2str(F_KEY) ' GHz'];
        text(ax, tx, ty-(i-1)*dy, txt, 'Units','normalized', ...
            'Color',entries{i}.c,'FontSize',8.5,'FontWeight','bold', ...
            'HorizontalAlignment','right','BackgroundColor',[1 1 1 0.7], ...
            'Interpreter','none');
    end
end


function ylim_val = wg_ask_ylim(title_str, def_lo, def_hi)
% Abre inputdlg para pedir los límites del eje Y.
    ans_ = inputdlg({'Limite inferior (dB):','Limite superior (dB):'}, ...
        title_str, 1, {def_lo, def_hi});
    if isempty(ans_)
        ylim_val = [str2double(def_lo), str2double(def_hi)];
    else
        ylim_val = [str2double(ans_{1}), str2double(ans_{2})];
        if any(isnan(ylim_val)) || ylim_val(1) >= ylim_val(2)
            ylim_val = [str2double(def_lo), str2double(def_hi)];
        end
    end
end


function cases = wg_assign_material_style(cases)
% Asigna a cada caso: color por material y opacidad por muestra.
%   Niquel → rojo, Cobre → azul, otro → gris.
%   Muestras del mismo material: misma tonalidad, opacidad 1.0 → 0.45.
    mat = cell(1, numel(cases));
    for j = 1:numel(cases); mat{j} = wg_material_of(cases(j).name); end
    um = unique(mat, 'stable');
    for u = 1:numel(um)
        idx = find(strcmp(mat, um{u}));
        nm  = numel(idx);
        rgb = wg_material_rgb(um{u});
        for r = 1:nm
            if nm > 1; a = 1.0 - 0.55*(r-1)/(nm-1); else; a = 1.0; end
            cases(idx(r)).mrgb  = rgb;
            cases(idx(r)).alpha = a;
        end
    end
end


function m = wg_material_of(name)
% Detecta el material a partir del nombre de la carpeta del prototipo.
    ln = lower(name);
    if contains(ln,'ni')
        m = 'Ni';
    elseif contains(ln,'cop') || contains(ln,'cu')
        m = 'Cu';
    else
        m = 'Otro';
    end
end


function rgb = wg_material_rgb(m)
% Color base por material (gama azul↔rojo, tonos suaves/apagados).
    switch m
        case 'Ni';   rgb = [0.82 0.42 0.35];   % niquel → rojo suave (tipo "Echo")
        case 'Cu';   rgb = [0.29 0.45 0.69];   % cobre  → azul suave (tipo "Bravo")
        otherwise;   rgb = [0.45 0.45 0.45];   % otro   → gris
    end
end


function wg_plot_cases(ax, cases, param, style, lw, to_dB, sm)
% Dibuja cada caso con su color de material y su opacidad de muestra.
    for j = 1:numel(cases)
        c = cases(j);
        if ~isfield(c, param) || isempty(c.(param)); continue; end
        lbl = [strrep(c.name,'_','\_') ' (n=' num2str(c.n) ')'];
        h = plot(ax, c.freq, sm(to_dB(c.(param))), style, ...
            'Color', c.mrgb, 'LineWidth', lw, 'DisplayName', lbl);
        try
            h.Color = [c.mrgb c.alpha];                      % opacidad real (R2018b+)
        catch
            h.Color = c.mrgb*c.alpha + (1-c.alpha)*[1 1 1];  % fallback: mezcla a blanco
        end
    end
end


function wg_plot_thru2(ax, freq, tb, ta, param, style, col_b, col_a, lw, to_dB, sm)
% Dibuja thru before/after de un parámetro en colores neutros (negro/gris).
    if ~isempty(tb) && isfield(tb, param)
        plot(ax, freq, sm(to_dB(tb.(param))), style, ...
            'Color', col_b, 'LineWidth', lw, 'DisplayName', 'Thru before');
    end
    if ~isempty(ta) && isfield(ta, param)
        plot(ax, freq, sm(to_dB(ta.(param))), style, ...
            'Color', col_a, 'LineWidth', lw, 'DisplayName', 'Thru after');
    end
end


function [freq_ghz, val] = wg_read_txt_dB(filepath)
% Lee un archivo .txt de simulación y devuelve el valor complejo/lineal.
% Detecta automáticamente el formato por el nº de columnas de datos:
%   3 columnas: freq | Parte Real | Parte Imaginaria  → S = Re + jIm
%   2 columnas: freq | Magnitud [dB]                  → S = 10^(dB/20)
% Líneas que empiezan con # se ignoran (comentarios/cabeceras).
% El resultado es compatible con to_dB = 20*log10(abs(x)).
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
    nr   = numel(rows);
    M = nan(nr, ncol);
    for r = 1:nr; M(r,1:ncol) = rows{r}(1:ncol); end

    freq_ghz = M(:,1).';
    if ncol >= 3
        val = (M(:,2) + 1j*M(:,3)).';          % Re/Im → complejo
    else
        val = 10.^(M(:,2).' / 20);             % dB → lineal (real positivo)
    end

    % Detección automática de unidad de frecuencia
    if max(freq_ghz) > 1e6
        freq_ghz = freq_ghz / 1e9;   % Hz → GHz
    elseif max(freq_ghz) > 1e3
        freq_ghz = freq_ghz / 1e3;   % MHz → GHz
    end
end


function [freq_ghz, S11, S21] = wg_read_sparams(filepath)
% Lee S-params de archivo Touchstone (RI/DB/MA) o columnas genéricas.
% S11_sim ↔ S11_meas;  S21_sim ↔ S31_meas  (puerto 2 sim = puerto 3 VNA)
    fid = fopen(filepath,'r');
    if fid < 0; error('No se pudo abrir: %s', filepath); end
    freq_unit = 1e9; fmt = 'RI'; data_lines = {};
    while ~feof(fid)
        raw = fgetl(fid);
        if ~ischar(raw); break; end
        line = strtrim(raw);
        if isempty(line); continue; end
        switch line(1)
            case {'!','%'}; continue;
            case '#'
                tok = strsplit(lower(line));
                for t = tok
                    switch t{1}
                        case 'hz';  freq_unit=1;
                        case 'khz'; freq_unit=1e3;
                        case 'mhz'; freq_unit=1e6;
                        case 'ghz'; freq_unit=1e9;
                        case 'db';  fmt='DB';
                        case 'ma';  fmt='MA';
                    end
                end
            otherwise
                nums = sscanf(line,'%f');
                if numel(nums)>=5; data_lines{end+1}=nums(:).'; end %#ok
        end
    end
    fclose(fid);
    if isempty(data_lines); error('Sin datos en: %s', filepath); end
    maxc = max(cellfun(@numel,data_lines));
    data = nan(numel(data_lines),maxc);
    for r=1:numel(data_lines); data(r,1:numel(data_lines{r}))=data_lines{r}; end
    rf = data(:,1);
    freq_ghz = (max(rf)>1e6) * (rf/1e9) + (max(rf)<=1e6) * (rf*freq_unit/1e9);
    freq_ghz = freq_ghz(:).';
    switch fmt
        case 'RI'; S11=(data(:,2)+1j*data(:,3)).'; S21=(data(:,4)+1j*data(:,5)).';
        case 'DB'
            S11=(10.^(data(:,2)/20).*exp(1j*data(:,3)*pi/180)).';
            S21=(10.^(data(:,4)/20).*exp(1j*data(:,5)*pi/180)).';
        case 'MA'
            S11=(data(:,2).*exp(1j*data(:,3)*pi/180)).';
            S21=(data(:,4).*exp(1j*data(:,5)*pi/180)).';
    end
end
