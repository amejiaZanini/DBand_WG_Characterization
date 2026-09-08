import pyvisa
import numpy as np
from time import sleep

class VNAMeasurement:
    def __init__(self, device='USB0::0x0AAD::0x0240::101285::0::INSTR'):
        self.rm = pyvisa.ResourceManager()
        self.pna = self.rm.open_resource(device)
        self.pna.timeout = 30000  # 30s — enough for large sweeps and data transfers
        print(self.pna.query('*IDN?'))
        self.Nfreqs = 10000

    def start_analyzer(self, start_f, stop_f, points_n, bw=5000):
        self.pna.write('SENS:SWE:TYPE LIN')  # Initialize type of data
        self.pna.write('SENS1:FREQ:STAR ' + str(start_f) + 'GHz')  # Initialize the initial frequency CH1
        self.pna.write('SENS1:FREQ:STOP ' + str(stop_f) + 'GHz')  # Initialize the final frequency CH1
        self.pna.write('SENS2:FREQ:STAR ' + str(start_f) + 'GHz')  # Initialize the initial frequency CH2
        self.pna.write('SENS2:FREQ:STOP ' + str(stop_f) + 'GHz')  # Initialize the final frequency CH2
        self.pna.write('SENS1:SWE:POIN ' + str(points_n))  # Initialize the number of frequency points CH1
        self.pna.write('SENS2:SWE:POIN ' + str(points_n))  # Initialize the number of frequency points CH2
        self.pna.write('SENS1:BWID ' + str(bw))  # Initialize the bandwidth
        self.pna.write('SENS2:BWID ' + str(bw))  # Initialize the bandwidth

    def start_analyzer_Sparameter(self, start_f, stop_f, points_n, bw=5000):
        self.pna.write('SENS:SWE:TYPE LIN')  # Initialize type of data
        self.pna.write('SENS1:FREQ:STAR ' + str(start_f) + 'GHz')  # Initialize the initial frequency CH1
        self.pna.write('SENS1:FREQ:STOP ' + str(stop_f) + 'GHz')  # Initialize the final frequency CH1
        self.pna.write('SENS2:FREQ:STAR ' + str(start_f) + 'GHz')  # Initialize the initial frequency CH2
        self.pna.write('SENS2:FREQ:STOP ' + str(stop_f) + 'GHz')  # Initialize the final frequency CH2
        self.pna.write('SENS3:FREQ:STAR ' + str(start_f) + 'GHz')  # Initialize the initial frequency CH2
        self.pna.write('SENS3:FREQ:STOP ' + str(stop_f) + 'GHz')  # Initialize the final frequency CH2
        self.pna.write('SENS4:FREQ:STAR ' + str(start_f) + 'GHz')  # Initialize the initial frequency CH2
        self.pna.write('SENS4:FREQ:STOP ' + str(stop_f) + 'GHz')  # Initialize the final frequency CH2
        self.pna.write('SENS1:SWE:POIN ' + str(points_n))  # Initialize the number of frequency points CH1
        self.pna.write('SENS2:SWE:POIN ' + str(points_n))  # Initialize the number of frequency points CH2
        self.pna.write('SENS3:SWE:POIN ' + str(points_n))  # Initialize the number of frequency points CH2
        self.pna.write('SENS4:SWE:POIN ' + str(points_n))  # Initialize the number of frequency points CH2
        self.pna.write('SENS1:BWID ' + str(bw))  # Initialize the bandwidth
        self.pna.write('SENS2:BWID ' + str(bw))  # Initialize the bandwidth
        self.pna.write('SENS3:BWID ' + str(bw))  # Initialize the bandwidth
        self.pna.write('SENS4:BWID ' + str(bw))  # Initialize the bandwidth

    def set_trigger_single(self):
        self.pna.write('INIT1:COUNT ALL OFF')
        sleep(1)
        self.pna.write('INIT2:COUNT ALL OFF')
    def auto_scale(self, traces=None, settle_s=0.25):
        """Autoscale trace windows on the VNA display.

        AUTO ONCE reads whatever is in the trace buffer *right now* — if the
        previous write hasn't been applied yet by the instrument's display
        engine, the next one can land on stale data. A short delay between
        commands lets each one settle before the next is sent (writes are
        async: pna.write() returns as soon as the bytes are on the bus, not
        when the VNA has finished acting on them).
        """
        if traces is None:
            traces = [
                (1, "S11_Real"), (1, "S11_Imag"),
                (2, "S31_Real"), (2, "S31_Imag"),
                (3, "S13_Real"), (3, "S13_Imag"),
                (4, "S33_Real"), (4, "S33_Imag"),
            ]
        for wind, trace in traces:
            self.pna.write(f'DISP:WIND{wind}:TRAC:Y:AUTO ONCE, "{trace}"')
            sleep(settle_s)
        self.pna.query('*OPC?')  # block until the VNA has processed all of the above

    def _wait_full_cycle(self, points_n, bw, n_channels):
        """Block until every channel has swept at least once since the
        last stimulus change. In continuous mode the VNA round-robins
        through SENS1..SENSn, so fresh data only lands in *all* trace
        buffers after n_channels * (points_n/bw) seconds, not after a
        single-channel sweep time."""
        sleep(n_channels * (points_n / bw) * 1.3)

    def set_trigger_continuous(self):
        self.pna.write('INIT1:COUNT ALL ON')
        sleep(1)
        self.pna.write('INIT2:COUNT ALL ON')

    def setup_traces(self, start_f, stop_f, points_n, bw=5000):
        self.pna.write('CALC:PAR:DEL:ALL')
        # self.start_analyzer(start_f, stop_f, points_n, bw=bw)
        sleep(0.5)

        # Ventana 1 S11
        self.pna.write('CALC1:PAR:DEF "S11_Real", S11')
        self.pna.write('DISP:WIND1:TRAC1:FEED "S11_Real"')
        self.pna.write('CALC1:FORM REAL')
        sleep(0.5)

        self.pna.write('CALC1:PAR:DEF "S11_Imag", S11')
        self.pna.write('DISP:WIND1:TRAC2:FEED "S11_Imag"')
        self.pna.write('CALC1:FORM IMAG')

        # Ventana 2 S31
        self.pna.write('DISP:WIND2:STAT ON')
        self.pna.write('CALC2:PAR:DEF "S31_Real", S31')
        self.pna.write('DISP:WIND2:TRAC3:FEED "S31_Real"')
        self.pna.write('CALC2:FORM REAL')
        sleep(0.5)

        self.pna.write('CALC2:PAR:DEF "S31_Imag", S31')
        self.pna.write('DISP:WIND2:TRAC4:FEED "S31_Imag"')
        self.pna.write('CALC2:FORM IMAG')
        sleep(0.5)

        self.start_analyzer(start_f, stop_f, points_n, bw=bw)

        # Continuous mode round-robins SENS1→SENS2, so a fresh post-reconfig
        # sweep on both channels takes ~2x a single-channel sweep time.
        self._wait_full_cycle(points_n, bw, n_channels=2)
        self.auto_scale(traces=[
            (1, "S11_Real"), (1, "S11_Imag"),
            (2, "S31_Real"), (2, "S31_Imag"),
        ])

    def setup_traces_S11_S13_S31_S33(self, start_f, stop_f, points_n, bw=5000):
        # Borra todas las trazas existentes
        self.pna.write('CALC:PAR:DEL:ALL')
        sleep(0.5)

        # ---------- Ventana 1: S11 ----------
        self.pna.write('CALC1:PAR:DEF "S11_Real", S11')
        self.pna.write('DISP:WIND1:TRAC1:FEED "S11_Real"')
        self.pna.write('CALC1:FORM REAL')
        sleep(0.5)

        self.pna.write('CALC1:PAR:DEF "S11_Imag", S11')
        self.pna.write('DISP:WIND1:TRAC2:FEED "S11_Imag"')
        self.pna.write('CALC1:FORM IMAG')
        sleep(0.5)

        # ---------- Ventana 2: S31 ----------
        self.pna.write('DISP:WIND2:STAT ON')
        self.pna.write('CALC2:PAR:DEF "S31_Real", S31')
        self.pna.write('DISP:WIND2:TRAC3:FEED "S31_Real"')
        self.pna.write('CALC2:FORM REAL')
        sleep(0.5)

        self.pna.write('CALC2:PAR:DEF "S31_Imag", S31')
        self.pna.write('DISP:WIND2:TRAC4:FEED "S31_Imag"')
        self.pna.write('CALC2:FORM IMAG')
        sleep(0.5)

        # ---------- Ventana 3: S13 ----------
        self.pna.write('DISP:WIND3:STAT ON')
        self.pna.write('CALC3:PAR:DEF "S13_Real", S13')
        self.pna.write('DISP:WIND3:TRAC5:FEED "S13_Real"')
        self.pna.write('CALC3:FORM REAL')
        sleep(0.5)

        self.pna.write('CALC3:PAR:DEF "S13_Imag", S13')
        self.pna.write('DISP:WIND3:TRAC6:FEED "S13_Imag"')
        self.pna.write('CALC3:FORM IMAG')
        sleep(0.5)

        # ---------- Ventana 4: S33 ----------
        self.pna.write('DISP:WIND4:STAT ON')
        self.pna.write('CALC4:PAR:DEF "S33_Real", S33')
        self.pna.write('DISP:WIND4:TRAC7:FEED "S33_Real"')
        self.pna.write('CALC4:FORM REAL')
        sleep(0.5)

        self.pna.write('CALC4:PAR:DEF "S33_Imag", S33')
        self.pna.write('DISP:WIND4:TRAC8:FEED "S33_Imag"')
        self.pna.write('CALC4:FORM IMAG')
        sleep(0.5)
        self.start_analyzer_Sparameter(start_f, stop_f, points_n, bw=bw)

        # Continuous mode round-robins SENS1→2→3→4, so a fresh post-reconfig
        # sweep on all 4 channels takes ~4x a single-channel sweep time.
        # A flat sleep(2) was too short here (4 * 2001/3000 * 1.3 ≈ 3.5s),
        # so autoscale could fire before S13/S33 (later in the cycle) had
        # fresh data — explaining why scaling looked fine one command at a
        # time (human delay covers the cycle) but not when run back-to-back.
        self._wait_full_cycle(points_n, bw, n_channels=4)
        self.auto_scale()


    def get_data(self, channel, trace_name):
        """Read current sweep data for one channel/trace. Call trigger_sweep() first."""
        self.pna.write(f'CALC{channel}:PAR:SEL "{trace_name}"')
        self.pna.write(f'CALC{channel}:FORM REAL')
        data_str = self.pna.query(f'CALC{channel}:DATA? SDAT')
        data_floats = np.array([float(val) for val in data_str.strip().split(',')])
        return data_floats[::2], data_floats[1::2]

    def measure_and_save(self, filename='vna_measurements.mat'):
        freq_points = np.linspace(0, 1, self.Nfreqs)  # Sustituye con tus frecuencias reales

        s11_r, s11_i = self.get_data(1, 'S11_Real')
        sleep(1)

        s31_r, s31_i = self.get_data(2, 'S31_Real')
        sleep(0.5)

        data = {
            'f': freq_points,
            'S11_r': s11_r,
            'S11_i': s11_i,
            'S31_r': s31_r,
            'S31_i': s31_i
        }
        return data

    def measure_and_save_Sall(self, filename='vna_measurements.mat'):
        freq_points = np.linspace(0, 1, self.Nfreqs)  # Sustituye con tus frecuencias reales

        s11_r, s11_i = self.get_data(1, 'S11_Real')
        sleep(1)

        s31_r, s31_i = self.get_data(2, 'S31_Real')
        sleep(0.5)
        s13_r, s13_i = self.get_data(3, 'S13_Real')
        sleep(1)
        s33_r, s33_i = self.get_data(4, 'S33_Real')
        sleep(1)

        data = {
            'f': freq_points,
            'S11_r': s11_r,
            'S11_i': s11_i,
            'S31_r': s31_r,
            'S31_i': s31_i,
            'S13_r': s13_r,
            'S13_i': s13_i,
            'S33_r': s33_r,
            'S33_i': s33_i,

        }
        return data
        # savemat(filename, data)
        # print(f'Datos guardados en {filename}')

if __name__ == "__main__":
    from time import sleep
    vna = VNAMeasurement()
    vna.setup_traces_S11_S13_S31_S33(110, 170, points_n=2001, bw=3000)
    sleep(2001 / 3000 * 1.3)  # wait one sweep: N/BW * 1.3x margin
    vna.measure_and_save('resultado_vna.mat')
