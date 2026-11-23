// =============================================================================
// Metrologia_EBG.ijm — medidas de fabricación de las guías EBG a partir de TAC
// (pilas .tiff de VGSTUDIO / escáner UPC). Fiji / ImageJ 1.54+.
//
// Instalación:  Plugins ▸ Macros ▸ Install…  y elegir este archivo
//               (o copiarlo a Fiji.app/macros/StartupMacros para tenerlo siempre).
// Uso:          cada herramienta trabaja sobre TU selección en la imagen activa:
//               rectángulo, línea recta o puntos. Los resultados se AÑADEN a CSV
//               en la carpeta de salida de la sesión (una fila por medida).
//
//   F1  0 · Configurar sesión        muestra, material, geometría, vóxel, carpeta
//   F2  1 · Niveles aire / metal     gris del aire y del metal macizo -> ISO-50
//   F3  2 · Pines en corte XY        rectángulo sobre los pines -> diámetro, centro,
//                                    forma; opcional: 3 pines de referencia
//   F4  3 · Reslice por fila         línea a lo largo de una fila -> corte longitudinal
//   F5  4 · Perfil: bordes           línea -> bordes al 50 % y longitudes de cada tramo
//                                    (gap, altura de cavidad, paredes…)
//   F6  5 · Sección del canal        rectángulo alrededor del canal -> ancho y alto
//   F7  6 · Rugosidad de una pared   línea paralela a una pared -> perfil del borde,
//                                    Ra, Rq, Rt (con y sin filtro gaussiano)
//   F8  7 · Poros por corte          rectángulo + rango de cortes -> poros internos
//
// Criterio de borde: ISO-50 (mitad entre el gris del aire y el del metal macizo),
// con interpolación lineal entre píxeles (resolución sub-vóxel).
// Límite físico: un rasgo de menos de ~2 vóxeles no se mide (45.335 µm -> ~90 µm;
// 11 µm -> ~22 µm). La rugosidad medida por TAC es ondulación a escala del vóxel,
// no la Ra de un perfilómetro.
// =============================================================================

var gOut = "";
var gMuestra = "";
var gMaterial = "";
var gGeom = "";
var gEscaneo = "";
var gVoxel = 0;
var gAire = NaN;
var gMetal = NaN;
var gUltimos = 0;   // nº de elementos de la última medida (para avisos)

var META_HDR = "muestra,material,geometria,escaneo,voxel_um,imagen,slice,z_um,fecha";
var PINES_HDR = ",metodo,nivel,x_um,y_um,area_um2,d_eq_um,lado_eq_um,feret_um,minferet_um,feret_ang,circ,solidez,ancho_um,alto_um,roi_x_um,roi_y_um,roi_w_um,roi_h_um";
var REF_HDR = ",ref,x_um,y_um,fila,col";
var PERFIL_HDR = ",etiqueta,nominal_um,n_bordes,tramo,tipo,inicio_um,fin_um,longitud_um,nivel,aire,metal,contraste_min,x1_um,y1_um,x2_um,y2_um,ancho_linea_px,archivo_perfil";
var CANAL_HDR = ",nivel,ancho_bbox_um,alto_bbox_um,area_um2,ancho_sub_um,alto_sub_um,xc_um,yc_um";
var RUG_HDR = ",nivel,longitud_um,n_puntos,n_validos,Ra_um,Rq_um,Rt_um,lambdac_um,Ra_f_um,Rq_f_um,Rt_f_um,x1_um,y1_um,x2_um,y2_um,archivo_perfil";
var POROS_HDR = ",nivel,dmin_um,area_solida_um2,n_poros,area_poros_um2,porosidad_pct";
var PORO_HDR = ",x_um,y_um,area_um2,d_eq_um";

macro "0 · Configurar sesión [F1]" { configurarSesion(); }
macro "1 · Niveles aire / metal [F2]" { nivelesInteractivo(); }
macro "2 · Pines en corte XY [F3]" { pinesInteractivo(); }
macro "3 · Reslice por fila de pines [F4]" { resliceInteractivo(); }
macro "4 · Perfil: bordes y distancias [F5]" { perfilInteractivo(); }
macro "5 · Sección del canal [F6]" { canalInteractivo(); }
macro "6 · Rugosidad de una pared [F7]" { rugosidadInteractivo(); }
macro "7 · Poros por corte [F8]" { porosInteractivo(); }

// ==== INTERACTIVO (diálogos; no se usa en las pruebas en batch) ==============

function configurarSesion() {
	cargarSesion();
	Dialog.create("Metrología EBG · sesión");
	Dialog.addString("Muestra (sin comas)", gMuestra, 24);
	Dialog.addChoice("Material", newArray("Ni", "Cu", "resina+Cu", "resina+Ni", "otro"), def(gMaterial, "Ni"));
	Dialog.addChoice("Geometría de pines", newArray("circular", "rectangular"), def(gGeom, "circular"));
	Dialog.addChoice("Escaneo", newArray("general", "ROI", "otro"), def(gEscaneo, "general"));
	Dialog.addNumber("Vóxel (µm)", defn(gVoxel, 45.335), 3, 8, "µm  (general 45.335 · ROI ≈ 11)");
	Dialog.addCheckbox("Aplicar este vóxel a la imagen activa", nImages > 0);
	Dialog.addCheckbox("Elegir carpeta de salida", gOut == "");
	Dialog.show();
	gMuestra = replace(Dialog.getString(), ",", "_");
	gMaterial = Dialog.getChoice();
	gGeom = Dialog.getChoice();
	gEscaneo = Dialog.getChoice();
	gVoxel = Dialog.getNumber();
	aplicar = Dialog.getCheckbox();
	elegir = Dialog.getCheckbox();
	if (elegir || gOut == "") gOut = getDirectory("Carpeta de salida para los CSV de metrología");
	if (aplicar && nImages > 0) setVoxelSize(gVoxel, gVoxel, gVoxel, fromCharCode(181) + "m");
	guardarSesion();
	appendCSV("sesiones.csv", "muestra,material,geometria,escaneo,voxel_um,carpeta,fecha",
		gMuestra + "," + gMaterial + "," + gGeom + "," + gEscaneo + "," + gVoxel + "," + replace(gOut, ",", ";") + "," + fecha());
	print("[Metrología EBG] Sesión: " + gMuestra + " · " + gMaterial + " · " + gGeom + " · " + gEscaneo + " · vóxel " + gVoxel + " µm");
	print("   salida: " + gOut);
}

function nivelesInteractivo() {
	requiereImagen();
	cargarSesion();
	waitForUser("Niveles · AIRE", "Dibuja un rectángulo en AIRE (fuera de la pieza o dentro del canal),\nlejos de los bordes, y pulsa OK.");
	if (selectionType() < 0 || selectionType() > 4) exit("Necesito un rectángulo, óvalo o polígono en aire.");
	aire = getValue("Mean"); sa = getValue("StdDev");
	waitForUser("Niveles · METAL", "Dibuja un rectángulo en METAL MACIZO (zona gruesa, p. ej. la brida)\ny pulsa OK.");
	if (selectionType() < 0 || selectionType() > 4) exit("Necesito un rectángulo, óvalo o polígono en metal.");
	metal = getValue("Mean"); sm = getValue("StdDev");
	registrarNiveles(aire, sa, metal, sm);
}

function pinesInteractivo() {
	requiereImagen();
	cargarSesion();
	if (selectionType() != 0) exit("Dibuja un RECTÁNGULO que contenga los pines (en un corte a media altura del pin).");
	getSelectionBounds(rx, ry, rw, rh);
	dnom = 400;
	Dialog.create("Pines en corte XY");
	Dialog.addChoice("Umbral", newArray("ISO50 (niveles de la sesión)", "Otsu (local)"), "ISO50 (niveles de la sesión)");
	Dialog.addNumber("Diámetro mínimo aceptado", 0.4 * dnom, 0, 6, "µm");
	Dialog.addNumber("Diámetro máximo aceptado", 1.9 * dnom, 0, 6, "µm  (los fusionados salen como área grande)");
	Dialog.addCheckbox("Incluir huecos interiores (pines que parecen huecos por cupping)", true);
	Dialog.addCheckbox("Excluir pines cortados por el borde del rectángulo", true);
	Dialog.addCheckbox("Guardar imagen de control (contornos)", true);
	Dialog.addCheckbox("Marcar 3 pines de referencia (fila/columna)", true);
	Dialog.show();
	metodo = Dialog.getChoice();
	dmin = Dialog.getNumber(); dmax = Dialog.getNumber();
	incluir = Dialog.getCheckbox(); excluir = Dialog.getCheckbox(); png = Dialog.getCheckbox();
	refs = Dialog.getCheckbox();
	if (startsWith(metodo, "ISO50")) { requiereNiveles(); met = "ISO50"; } else met = "Otsu";
	n = medirPines(rx, ry, rw, rh, met, (gAire + gMetal) / 2, dmin, dmax, incluir, excluir, png);
	print("[Pines] corte " + getSliceNumber() + ": " + n + " pines medidos -> pines_xy.csv");
	makeRectangle(rx, ry, rw, rh);
	if (refs) referenciasInteractivo();
}

function referenciasInteractivo() {
	setTool("multipoint");
	run("Select None");
	waitForUser("Pines de referencia",
		"Con la herramienta MULTI-POINT marca 3 pines, en este orden:\n" +
		"  A y B en la MISMA fila, lo más separados posible;\n" +
		"  C en OTRA fila.\n" +
		"Filas, de un lado a otro del canal: 1 = exterior, 2 = interior | canal | 3 = interior, 4 = exterior\n" +
		"(elige qué lado es el de las filas 1-2 y usa siempre el mismo, p. ej. el de una marca de la pieza).\n" +
		"Columnas 1–79 desde la boca de referencia. Pulsa OK.");
	getSelectionCoordinates(xs, ys);
	if (xs.length != 3) exit("Necesito exactamente 3 puntos (A, B, C).");
	Dialog.create("Fila / columna de los pines A, B, C");
	nombres = newArray("A", "B", "C");
	for (i = 0; i < 3; i++) {
		Dialog.addNumber("Pin " + nombres[i] + " · fila (1-4)", 1);
		Dialog.addNumber("Pin " + nombres[i] + " · columna (1-79)", 1);
	}
	Dialog.show();
	filas = newArray(3); cols = newArray(3);
	for (i = 0; i < 3; i++) { filas[i] = Dialog.getNumber(); cols[i] = Dialog.getNumber(); }
	registrarReferencias(xs, ys, filas, cols);
	print("[Pines] referencias A, B, C guardadas -> referencias.csv");
}

function resliceInteractivo() {
	requiereImagen();
	if (selectionType() != 5) exit("Dibuja una LÍNEA RECTA a lo largo de una fila de pines (por el centro de los pines).");
	t = resliceLinea();
	print("[Reslice] creado: " + t + "  (usa F5 sobre esta imagen para medir gap y alturas)");
}

function perfilInteractivo() {
	requiereImagen();
	cargarSesion();
	if (selectionType() != 5) exit("Dibuja una LÍNEA RECTA que cruce los bordes que quieres medir.");
	Dialog.create("Perfil: bordes y distancias");
	Dialog.addChoice("Qué mides", newArray("gap_pin_tapa", "altura_cavidad", "altura_pin", "alto_canal", "ancho_canal",
		"diametro_pin", "paso_pines", "pared", "planitud_tapa", "otro"), "gap_pin_tapa");
	Dialog.addNumber("Valor nominal (0 = no aplica)", 0, 1, 8, "µm");
	Dialog.addChoice("Niveles", newArray("sesión (aire/metal)", "locales (percentiles 5/95 del perfil)"), "sesión (aire/metal)");
	Dialog.addNumber("Ancho de la línea (promedia ruido)", 3, 0, 4, "px");
	Dialog.show();
	etiqueta = Dialog.getChoice(); nominal = Dialog.getNumber();
	modo = Dialog.getChoice(); ancho = Dialog.getNumber();
	if (startsWith(modo, "sesión")) { requiereNiveles(); m = "sesion"; } else m = "local";
	n = medirPerfil(etiqueta, nominal, m, gAire, gMetal, ancho);
	print("[Perfil] " + etiqueta + ": " + n + " bordes -> perfiles.csv");
}

function canalInteractivo() {
	requiereImagen();
	cargarSesion();
	requiereNiveles();
	if (selectionType() != 0) exit("Dibuja un RECTÁNGULO que contenga la sección del canal y algo de metal alrededor.");
	getSelectionBounds(rx, ry, rw, rh);
	ok = medirCanal(rx, ry, rw, rh, (gAire + gMetal) / 2);
	if (ok) print("[Canal] medido -> canal.csv"); else print("[Canal] no se encontró un hueco cerrado de aire en el rectángulo.");
}

function rugosidadInteractivo() {
	requiereImagen();
	cargarSesion();
	requiereNiveles();
	if (selectionType() != 5) exit("Dibuja una LÍNEA RECTA paralela a la pared, por encima del borde.");
	Dialog.create("Rugosidad de una pared");
	Dialog.addNumber("Semiancho de búsqueda perpendicular", 6 * defn(gVoxel, 11), 1, 8, "µm");
	Dialog.addNumber("Filtro gaussiano λc (0 = sin filtro)", 250, 0, 8, "µm");
	Dialog.show();
	sw = Dialog.getNumber(); lc = Dialog.getNumber();
	r = medirRugosidad(sw, lc, (gAire + gMetal) / 2);
	print("[Rugosidad] Rq = " + d2s(r, 2) + " µm (sin filtro, sin tendencia) -> rugosidad.csv");
}

function porosInteractivo() {
	requiereImagen();
	cargarSesion();
	requiereNiveles();
	if (selectionType() != 0) exit("Dibuja un RECTÁNGULO sobre la zona de metal a analizar.");
	getSelectionBounds(rx, ry, rw, rh);
	Dialog.create("Poros por corte");
	Dialog.addNumber("Primer corte", getSliceNumber());
	Dialog.addNumber("Último corte", minOf(nSlices, getSliceNumber() + 9));
	Dialog.addNumber("Diámetro mínimo de poro (≥ 2–3 vóxeles)", 3 * defn(gVoxel, 45.335), 0, 8, "µm");
	Dialog.show();
	z1 = Dialog.getNumber(); z2 = Dialog.getNumber(); dmin = Dialog.getNumber();
	n = medirPoros(rx, ry, rw, rh, z1, z2, (gAire + gMetal) / 2, dmin);
	print("[Poros] " + n + " poros en cortes " + z1 + "–" + z2 + " -> poros.csv, poros_lista.csv");
}

// ==== FUNCIONES DE MEDIDA (sin diálogos: las usan las pruebas) ===============

function registrarNiveles(aire, sa, metal, sm) {
	gAire = aire; gMetal = metal;
	guardarSesion();
	cnr = (metal - aire) / sqrt((sa * sa + sm * sm) / 2 + 1e-12);
	appendCSV("niveles.csv", META_HDR + ",aire,sd_aire,metal,sd_metal,iso50,cnr",
		"" + meta() + "," + aire + "," + sa + "," + metal + "," + sm + "," + ((aire + metal) / 2) + "," + cnr);
	print("[Niveles] aire = " + d2s(aire, 1) + " · metal = " + d2s(metal, 1) + " · ISO-50 = " + d2s((aire + metal) / 2, 1) + " · CNR = " + d2s(cnr, 1));
}

function medirPines(rx, ry, rw, rh, metodo, nivel, dmin, dmax, incluir, excluir, png) {
	f = factorUm(); getPixelSize(u, pw, ph, pd);
	px = pw * f; py = ph * f; pz = pd * f;
	orig = getImageID(); m0 = meta();
	setBatchMode(true);
	makeRectangle(rx, ry, rw, rh);
	run("Duplicate...", "title=ebg_pines");
	run("Properties...", "unit=um pixel_width=" + px + " pixel_height=" + py + " voxel_depth=" + pz);
	umbralizar(metodo, nivel);
	run("Set Measurements...", "area centroid perimeter bounding fit shape feret's redirect=None decimal=6");
	amin = PI * pow(dmin / 2, 2); amax = PI * pow(dmax / 2, 2);
	opts = "size=" + amin + "-" + amax + " display clear";
	if (incluir) opts = opts + " include";
	if (excluir) opts = opts + " exclude";
	if (png) opts = opts + " show=Outlines"; else opts = opts + " show=Nothing";
	run("Analyze Particles...", opts);
	n = nResults;
	nivelTxt = "" + nivel; if (metodo != "ISO50") nivelTxt = "auto";
	roi = "," + (rx * px) + "," + (ry * py) + "," + (rw * px) + "," + (rh * py);
	for (i = 0; i < n; i++) {
		A = getResult("Area", i);
		linea = m0 + "," + metodo + "," + nivelTxt + "," + (getResult("X", i) + rx * px) + "," + (getResult("Y", i) + ry * py) +
			"," + A + "," + (2 * sqrt(A / PI)) + "," + sqrt(A) + "," + getResult("Feret", i) + "," + getResult("MinFeret", i) +
			"," + getResult("FeretAngle", i) + "," + getResult("Circ.", i) + "," + getResult("Solidity", i) +
			"," + getResult("Width", i) + "," + getResult("Height", i) + roi;
		appendCSV("pines_xy.csv", META_HDR + PINES_HDR, linea);
	}
	if (png) {
		selectWindow("Drawing of ebg_pines");
		dir = gOut + "control" + File.separator; File.makeDirectory(dir);
		campos = split(m0, ",");
		saveAs("PNG", dir + "pines_" + gMuestra + "_z" + IJ.pad(parseInt(campos[6]), 4) + ".png");
		close();
	}
	selectWindow("ebg_pines"); close();
	setBatchMode(false);
	selectImage(orig);
	gUltimos = n;
	return n;
}

function registrarReferencias(xs, ys, filas, cols) {
	f = factorUm(); getPixelSize(u, pw, ph, pd);
	nombres = newArray("A", "B", "C");
	for (i = 0; i < 3; i++)
		appendCSV("referencias.csv", META_HDR + REF_HDR,
			"" + meta() + "," + nombres[i] + "," + (xs[i] * pw * f) + "," + (ys[i] * ph * f) + "," + filas[i] + "," + cols[i]);
}

function resliceLinea() {
	getPixelSize(u, pw, ph, pd);
	run("Reslice [/]...", "output=" + pd + " slice_count=1 avoid");
	return getTitle();
}

function medirPerfil(etiqueta, nominal, modo, aire, metal, ancho) {
	f = factorUm(); getPixelSize(u, pw, ph, pd);
	px = pw * f; py = ph * f;
	getLine(x1, y1, x2, y2, lw0);
	run("Line Width...", "line=" + ancho);
	makeLine(x1, y1, x2, y2);
	p = getProfile();
	run("Line Width...", "line=" + lw0);
	makeLine(x1, y1, x2, y2);
	L = sqrt(pow((x2 - x1) * px, 2) + pow((y2 - y1) * py, 2));
	paso = L / (p.length - 1);
	if (modo == "local") {
		s = Array.copy(p); Array.sort(s);
		aire = s[floor(0.05 * (s.length - 1))]; metal = s[floor(0.95 * (s.length - 1))];
	}
	nivel = (aire + metal) / 2;
	c = cruces(p, nivel);
	m0 = meta();
	nombre = "perfil_" + gMuestra + "_" + etiqueta + "_" + marcaTiempo() + ".csv";
	dir = gOut + "perfiles" + File.separator; File.makeDirectory(dir);
	txt = "pos_um,gris";
	for (i = 0; i < p.length; i++) txt = txt + "\n" + (i * paso) + "," + p[i];
	File.saveString(txt + "\n", dir + nombre);
	coords = "," + (x1 * px) + "," + (y1 * py) + "," + (x2 * px) + "," + (y2 * py) + "," + ancho + "," + nombre;
	comun = m0 + "," + etiqueta + "," + nominal + "," + c.length;
	if (c.length < 2) {
		mn = minArr(p);
		appendCSV("perfiles.csv", META_HDR + PERFIL_HDR, comun + ",0,sin_tramos,NaN,NaN,NaN," + nivel + "," + aire + "," + metal + "," +
			((metal - mn) / (metal - aire)) + coords);
		return c.length;
	}
	for (k = 0; k < c.length - 1; k++) {
		i0 = floor(c[k]) + 1; i1 = floor(c[k + 1]);
		mid = floor((c[k] + c[k + 1]) / 2);
		tipo = "aire"; if (p[mid] > nivel) tipo = "metal";
		ext = p[mid];
		for (i = i0; i <= i1; i++) { if (tipo == "aire" && p[i] < ext) ext = p[i]; if (tipo == "metal" && p[i] > ext) ext = p[i]; }
		contraste = (metal - ext) / (metal - aire);
		appendCSV("perfiles.csv", META_HDR + PERFIL_HDR, comun + "," + (k + 1) + "," + tipo + "," + (c[k] * paso) + "," +
			(c[k + 1] * paso) + "," + ((c[k + 1] - c[k]) * paso) + "," + nivel + "," + aire + "," + metal + "," + contraste + coords);
	}
	return c.length;
}

function medirCanal(rx, ry, rw, rh, nivel) {
	f = factorUm(); getPixelSize(u, pw, ph, pd);
	px = pw * f; py = ph * f; pz = pd * f;
	orig = getImageID(); m0 = meta();
	setBatchMode(true);
	makeRectangle(rx, ry, rw, rh);
	run("Duplicate...", "title=ebg_canal_gris");
	run("Properties...", "unit=um pixel_width=" + px + " pixel_height=" + py + " voxel_depth=" + pz);
	gris = getImageID();
	run("Duplicate...", "title=ebg_canal_mask");
	umbralizar("ISO50", nivel);
	run("Invert");                                   // el aire pasa a primer plano
	run("Set Measurements...", "area centroid bounding redirect=None decimal=6");
	run("Analyze Particles...", "size=0-Infinity display clear exclude show=Nothing");
	if (nResults == 0) { close(); selectImage(gris); close(); setBatchMode(false); selectImage(orig); return false; }
	imax = 0;
	for (i = 1; i < nResults; i++) if (getResult("Area", i) > getResult("Area", imax)) imax = i;
	A = getResult("Area", imax); xc = getResult("X", imax); yc = getResult("Y", imax);
	wb = getResult("Width", imax); hb = getResult("Height", imax);
	close();
	selectImage(gris);
	// anchura y altura sub-vóxel: perfiles por el centroide del hueco
	xcp = xc / px; ycp = yc / py;
	makeLine(0, ycp, rw - 1, ycp); ph_ = getProfile();
	makeLine(xcp, 0, xcp, rh - 1); pv_ = getProfile();
	kh = (rw - 1) / (ph_.length - 1); kv = (rh - 1) / (pv_.length - 1);     // píxeles por muestra del perfil
	wsub = tramoCentral(ph_, nivel, xcp / kh) * kh * px;
	hsub = tramoCentral(pv_, nivel, ycp / kv) * kv * py;
	close();
	setBatchMode(false);
	selectImage(orig);
	appendCSV("canal.csv", META_HDR + CANAL_HDR, m0 + "," + nivel + "," + wb + "," + hb + "," + A + "," + wsub + "," + hsub + "," +
		(xc + rx * px) + "," + (yc + ry * py));
	return true;
}

function medirRugosidad(semiancho, lambdac, nivel) {
	f = factorUm(); getPixelSize(u, pw, ph, pd);
	px = pw * f; py = ph * f;
	if (abs(px - py) > 1e-6 * px) exit("La rugosidad necesita píxeles cuadrados en la imagen (px = py).");
	getLine(x1, y1, x2, y2, lw0);
	L = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
	ux = (x2 - x1) / L; uy = (y2 - y1) / L; nx = -uy; ny = ux;
	hw = semiancho / px;
	N = floor(L) + 1;
	sPos = newArray(N); off = newArray(N); nval = 0;
	run("Line Width...", "line=1");
	for (s = 0; s < N; s++) {
		cx = x1 + ux * s; cy = y1 + uy * s;
		makeLine(cx - nx * hw, cy - ny * hw, cx + nx * hw, cy + ny * hw);
		p = getProfile();
		c = cruces(p, nivel);
		centro = (p.length - 1) / 2; best = NaN; dbest = 1e30;
		for (k = 0; k < c.length; k++) if (abs(c[k] - centro) < dbest) { dbest = abs(c[k] - centro); best = c[k]; }
		sPos[s] = s * px;
		if (isNaN(best)) off[s] = NaN; else { off[s] = (best - centro) * (2 * hw * px) / (p.length - 1); nval++; }
	}
	run("Line Width...", "line=" + lw0);
	makeLine(x1, y1, x2, y2);
	r = quitarTendencia(sPos, off);
	st = estadRug(r);
	if (lambdac > 0) { rf = filtroGauss(sPos, r, lambdac); stf = estadRug(rf); } else { rf = r; stf = newArray(NaN, NaN, NaN); }
	m0 = meta();
	nombre = "rugosidad_" + gMuestra + "_" + marcaTiempo() + ".csv";
	dir = gOut + "perfiles" + File.separator; File.makeDirectory(dir);
	txt = "s_um,borde_um,residuo_um,residuo_filtrado_um";
	for (i = 0; i < N; i++) txt = txt + "\n" + sPos[i] + "," + off[i] + "," + r[i] + "," + rf[i];
	File.saveString(txt + "\n", dir + nombre);
	appendCSV("rugosidad.csv", META_HDR + RUG_HDR, m0 + "," + nivel + "," + (L * px) + "," + N + "," + nval + "," + st[0] + "," + st[1] + "," +
		st[2] + "," + lambdac + "," + stf[0] + "," + stf[1] + "," + stf[2] + "," + (x1 * px) + "," + (y1 * py) + "," + (x2 * px) + "," +
		(y2 * py) + "," + nombre);
	return st[1];
}

function medirPoros(rx, ry, rw, rh, z1, z2, nivel, dmin) {
	f = factorUm(); getPixelSize(u, pw, ph, pd);
	px = pw * f; py = ph * f; pz = pd * f;
	orig = getImageID(); zOrig = getSliceNumber();
	amin = PI * pow(dmin / 2, 2);
	total = 0;
	setBatchMode(true);
	for (z = z1; z <= z2; z++) {
		selectImage(orig); setSlice(z);
		m0 = meta();
		makeRectangle(rx, ry, rw, rh);
		run("Duplicate...", "title=ebg_metal");
		run("Properties...", "unit=um pixel_width=" + px + " pixel_height=" + py + " voxel_depth=" + pz);
		umbralizar("ISO50", nivel);
		run("Duplicate...", "title=ebg_solido");
		run("Fill Holes");
		run("Set Measurements...", "area centroid redirect=None decimal=6");
		run("Analyze Particles...", "size=0-Infinity display clear show=Nothing");
		asol = 0; for (i = 0; i < nResults; i++) asol = asol + getResult("Area", i);
		imageCalculator("Subtract create", "ebg_solido", "ebg_metal");
		rename("ebg_poros");
		run("Analyze Particles...", "size=" + amin + "-Infinity display clear show=Nothing");
		np = nResults; apor = 0;
		for (i = 0; i < np; i++) {
			A = getResult("Area", i); apor = apor + A;
			appendCSV("poros_lista.csv", META_HDR + PORO_HDR, m0 + "," + (getResult("X", i) + rx * px) + "," + (getResult("Y", i) + ry * py) +
				"," + A + "," + (2 * sqrt(A / PI)));
		}
		pct = NaN; if (asol > 0) pct = 100 * apor / asol;
		appendCSV("poros.csv", META_HDR + POROS_HDR, m0 + "," + nivel + "," + dmin + "," + asol + "," + np + "," + apor + "," + pct);
		total = total + np;
		close("ebg_poros"); close("ebg_solido"); close("ebg_metal");
	}
	setBatchMode(false);
	selectImage(orig); setSlice(zOrig); makeRectangle(rx, ry, rw, rh);
	return total;
}

// ==== UTILIDADES ==============================================================

function umbralizar(metodo, nivel) {
	setOption("BlackBackground", true);
	if (metodo == "ISO50") {
		top = 1e30;
		if (bitDepth() == 8) top = 255;
		if (bitDepth() == 16) top = 65535;
		setThreshold(nivel, top);
	} else setAutoThreshold("Otsu dark");
	run("Convert to Mask");
}

function cruces(p, nivel) {
	// posiciones sub-píxel (en índices del perfil) donde el perfil cruza 'nivel'
	out = newArray(0);
	for (i = 0; i < p.length - 1; i++) {
		a = p[i] - nivel; b = p[i + 1] - nivel;
		if ((a < 0 && b >= 0) || (a >= 0 && b < 0)) out = Array.concat(out, i + a / (a - b));
	}
	return out;
}

function tramoCentral(p, nivel, centroPx) {
	// longitud (en índices) del tramo de aire que contiene la posición centroPx
	c = cruces(p, nivel);
	izq = NaN; der = NaN;
	for (k = 0; k < c.length; k++) {
		if (c[k] <= centroPx) izq = c[k];
		if (c[k] > centroPx && isNaN(der)) der = c[k];
	}
	return der - izq;
}

function quitarTendencia(x, y) {
	n = 0; sx = 0; sy = 0; sxx = 0; sxy = 0;
	for (i = 0; i < x.length; i++) if (!isNaN(y[i])) { n++; sx += x[i]; sy += y[i]; sxx += x[i] * x[i]; sxy += x[i] * y[i]; }
	b = (n * sxy - sx * sy) / (n * sxx - sx * sx); a = (sy - b * sx) / n;
	r = newArray(x.length);
	for (i = 0; i < x.length; i++) { if (isNaN(y[i])) r[i] = NaN; else r[i] = y[i] - (a + b * x[i]); }
	return r;
}

function filtroGauss(x, r, lambdac) {
	// filtro de perfil gaussiano (ISO 16610-21): quita la ondulación de longitud > λc
	alfa = 0.4697; out = newArray(r.length);
	for (i = 0; i < r.length; i++) {
		if (isNaN(r[i])) { out[i] = NaN; continue; }
		sw = 0; sv = 0;
		for (j = 0; j < r.length; j++) {
			if (isNaN(r[j])) continue;
			t = (x[j] - x[i]) / (alfa * lambdac);
			if (abs(t) > 3) continue;
			w = exp(-PI * t * t); sw += w; sv += w * r[j];
		}
		out[i] = r[i] - sv / sw;
	}
	return out;
}

function estadRug(r) {
	n = 0; sa = 0; sq = 0; mx = -1e30; mn = 1e30;
	for (i = 0; i < r.length; i++) if (!isNaN(r[i])) { n++; sa += abs(r[i]); sq += r[i] * r[i]; mx = maxOf(mx, r[i]); mn = minOf(mn, r[i]); }
	return newArray(sa / n, sqrt(sq / n), mx - mn);
}

function minArr(a) { m = a[0]; for (i = 1; i < a.length; i++) m = minOf(m, a[i]); return m; }

function factorUm() {
	getPixelSize(u, pw, ph, pd);
	if (u == "mm") return 1000;
	if (u == "um" || u == "micron" || u == "microns" || u == fromCharCode(181) + "m" || u == fromCharCode(956) + "m") return 1;
	exit("La imagen no está calibrada en µm o mm (unidad: '" + u + "').\nUsa F1 · Configurar sesión con «Aplicar este vóxel a la imagen activa».");
}

function meta() {
	f = factorUm(); getPixelSize(u, pw, ph, pd);
	z = getSliceNumber();
	return gMuestra + "," + gMaterial + "," + gGeom + "," + gEscaneo + "," + gVoxel + "," + replace(getTitle(), ",", "_") + "," + z + "," +
		((z - 1) * pd * f) + "," + fecha();
}

function appendCSV(nombre, cabecera, linea) {
	if (gOut == "") exit("Primero configura la sesión (F1) para elegir la carpeta de salida.");
	ruta = gOut + nombre;
	if (!File.exists(ruta)) File.append(cabecera, ruta);
	File.append(linea, ruta);
}

function fecha() {
	getDateAndTime(an, me, ds, di, ho, mi, se, ms);
	return "" + an + "-" + IJ.pad(me + 1, 2) + "-" + IJ.pad(di, 2) + " " + IJ.pad(ho, 2) + ":" + IJ.pad(mi, 2) + ":" + IJ.pad(se, 2);
}

function marcaTiempo() {
	getDateAndTime(an, me, ds, di, ho, mi, se, ms);
	return "" + an + IJ.pad(me + 1, 2) + IJ.pad(di, 2) + "_" + IJ.pad(ho, 2) + IJ.pad(mi, 2) + IJ.pad(se, 2) + "_" + IJ.pad(ms, 3);
}

function cargarSesion() {
	gOut = call("ij.Prefs.get", "ebg.out", "");
	gMuestra = call("ij.Prefs.get", "ebg.muestra", "");
	gMaterial = call("ij.Prefs.get", "ebg.material", "");
	gGeom = call("ij.Prefs.get", "ebg.geom", "");
	gEscaneo = call("ij.Prefs.get", "ebg.escaneo", "");
	gVoxel = parseFloat(call("ij.Prefs.get", "ebg.voxel", "NaN"));
	gAire = parseFloat(call("ij.Prefs.get", "ebg.aire", "NaN"));
	gMetal = parseFloat(call("ij.Prefs.get", "ebg.metal", "NaN"));
}

function guardarSesion() {
	call("ij.Prefs.set", "ebg.out", gOut);
	call("ij.Prefs.set", "ebg.muestra", gMuestra);
	call("ij.Prefs.set", "ebg.material", gMaterial);
	call("ij.Prefs.set", "ebg.geom", gGeom);
	call("ij.Prefs.set", "ebg.escaneo", gEscaneo);
	call("ij.Prefs.set", "ebg.voxel", "" + gVoxel);
	call("ij.Prefs.set", "ebg.aire", "" + gAire);
	call("ij.Prefs.set", "ebg.metal", "" + gMetal);
}

function requiereImagen() { if (nImages == 0) exit("Abre primero la pila .tiff."); }

function requiereNiveles() {
	if (isNaN(gAire) || isNaN(gMetal)) exit("Primero mide los niveles de aire y metal (F2).");
}

function def(v, d) { if (v == "") return d; return v; }
function defn(v, d) { if (isNaN(v) || v == 0) return d; return v; }
