/*
Pattern ideas
*/




/** ********************************************************* AV BRAIN PATTERN
 * A rate model of the brain with semi-realistic connectivity and time delays
 * Responds to sound.
 * @author: rhancock@gmail.com.
 *
 * MJP notes: A rate model is a neuronal model that uses the average firing
 * rate of a neuron to create activity. One such model is the mean field model
 * (http://www.scholarpedia.org/article/Neural_fields).
 ************************************************************************* **/
/*** MJP: disabled until we update the node map
/*
import java.util.Random;
import ddf.minim.*;
import ddf.minim.ugens.*;
// the effects package is needed because the filters are there for now.
import ddf.minim.effects.*;

class AVBrainPattern extends LXPattern {

  //sound
  Minim minim;
  AudioInput audio_in;
  IIRFilter bpf;

  // (MJP):
  // maybe idx of the nodes creating the visual representation of audio source?
  int audio_source_left = 84;
  int audio_source_right = 85;

  float[][] C;
  int[][] D;
  float[][] gain;
  int max_delay = 0;
  String[] lf_nodes = loadStrings("avbrain_resources/nodelist.txt");

  int n_sources;
  int n_nodes;
  //params
  //float sigma = .25;
  private final BoundedParameter sigma = new BoundedParameter("S", 50, 10, 1000);
  private final BoundedParameter nsteps = new BoundedParameter("SPD", 200, 100, 1000);
  private final BoundedParameter audio_wt = new BoundedParameter("VOL", 0, 0, 500);
  private final BoundedParameter k = new BoundedParameter("K", 100, 0, 1000);
  private final BoundedParameter hueShiftSpeed = new BoundedParameter("HSS", 5000, 0, 10000);
  private final SinLFO whatHue = new SinLFO(0, 360, hueShiftSpeed);



  float tstep = .001; //changing this requires updating the delay matrix
  //float k;

  //working variables
  float[][] activity;
  float[] sensor_act;
  Random noise;
  List<Bar> barlist;
  public AVBrainPattern(LX lx) {
    super(lx);
    addParameter(sigma);
    addParameter(nsteps);
    addParameter(audio_wt);
    addParameter(k);
    addParameter(hueShiftSpeed);
    addModulator(whatHue).trigger();


    //audio
    minim = new Minim(this);
    //minim.debugOn();
    audio_in = minim.getLineIn(Minim.STEREO, 8192);
    bpf = new LowPassFS(400, audio_in.sampleRate());
    audio_in.addEffect(bpf);



    //load connectivity and delays
    String[] conn_rows = loadStrings("avbrain_resources/connectivity_norm.txt");
    String[] conn_cols;
    String[] delay_rows = loadStrings("avbrain_resources/T_discrete.txt");
    String[] delay_cols;
    C = new float[conn_rows.length][conn_rows.length];
    D = new int[delay_rows.length][delay_rows.length];
    for (int i=0; i < conn_rows.length; i++) {
      conn_cols = splitTokens(conn_rows[i]);
      delay_cols = splitTokens(delay_rows[i]);
      for (int j=0; j < conn_cols.length; j++) {
        C[i][j] = float(conn_cols[j]);
        D[i][j] = int(delay_cols[j]);
        max_delay=max(max(D[i]), max_delay);
      }
    }

    //load leadfield
    String[] gain_rows = loadStrings("avbrain_resources/leadfield1r.txt");
    //String[] gain_rows = loadStrings("avbrain_resources/leadfield1.txt");
    String[] gain_cols = splitTokens(gain_rows[0]);
    gain = new float[gain_rows.length][gain_cols.length];
    for (int i=0; i < gain_rows.length; i++) {
      gain_cols = splitTokens(gain_rows[i]);
      for (int j=0; j < gain_cols.length; j++) {
        gain[i][j] = float(gain_cols[j]);
      }
    }


    n_sources = gain_cols.length;
    n_nodes = lf_nodes.length;

    //initialize
    //k = 1/n_sources;
    activity = new float[n_sources][max_delay+2];
    sensor_act = new float[n_nodes];

    noise = new Random();
    for (int i=0; i < n_sources; i++) {
      for (int j=0; j < max_delay; j++) {
        activity[i][j]=(float)((noise.nextGaussian())*sigma.getValue()/100);
      }
    }

    //start the sim
    for (int t=0; t < max_delay; t++) {
      step_simulation();
    }
  }

  public void step_simulation() {

    int t=max_delay;
    for (int i=0; i<n_sources; i++) {
      float w=0;
      for (int j=0; j<n_sources; j++) {
        w = w+C[j][i]*activity[j][t-D[j][i]];
      }
      //floats can't possibly be helping at this point
      activity[i][t+1]=activity[i][t] + tstep/.2 * (-activity[i][t]+(k.getValuef()/100/n_nodes)*w+(sigma.getValuef()/100*(float)noise.nextGaussian()));
    }
    activity[audio_source_left][t+1]=activity[audio_source_left][t+1]+audio_in.left.get(0)*(audio_wt.getValuef()/1000);//*tstep;
    activity[audio_source_right][t+1]=activity[audio_source_right][t+1]+audio_in.right.get(0)*(audio_wt.getValuef()/1000);//*tstep;
    //System.out.println(activity[84][t+1]);

    //update node values
    for (int i=0; i<n_nodes; i++) {
      for (int j=0; j<n_sources; j++) {
        sensor_act[i]=sensor_act[i] + gain[i][j]*activity[j][t+1]*10;
      }
    }
    //ugh
    for (int j=1; j< max_delay+2; j++) {
      for (int i=0; i<n_sources; i++) {
        activity[i][j-1]=activity[i][j];
      }
    }
  }

  public void run(double deltaMs) {
    audio_source_right = noise.nextInt(n_sources);
    audio_source_left = noise.nextInt(n_sources);
    for (int s=0; s < nsteps.getValue(); s++) {
      step_simulation();
    }
    float dmin=min(sensor_act);
    float dmax=max(sensor_act);
    for (int i=0; i<n_nodes; i++) {
      float v = (sensor_act[i]-dmin)/(dmax-dmin);
      Node node = model.nodes.get(lf_nodes[i]);
      barlist = node.adjacent_bars();
      for (Bar b : barlist) {
        for (LXPoint p : b.points) {
          colors[p.index]=lx.hsb((v*200-160+whatHue.getValuef())%360, 80, 80);
          //colors[p.index]=palette.getColor(bv);
        }
      }
    }
  }
}
*/
