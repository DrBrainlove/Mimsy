/*****************************************************************************
 *     NEURAL ANATOMY AND PHYSIOLOGICAL SIMULATIONS OR INSPIRED PATTERNS
 ****************************************************************************/



/** ********************************************************************
 * Muse bandwidth energy pattern
 *
 * Does variation of Pixies pattern, with multiple layers.
 * Each Pixie layer represents a different EEG bandwidth energy,
 * eg alpha, beta, gamma, delta, theta.
 * The speed of the particle along a line varies with the amplitude
 * of the energy in the associated bandwidth. When there is high alpha,
 * the alpha particles (orange) will move faster.

 * @author Mike Pesavento
 * original by Geoff Schmiddt
 *
 * Requires use of the muse_connect.pde file, which gives access to the muse headset data
 * Also written by MJP.
 * Needs global object variable to be declared to access it in this pattern.
 * Run "muse-io' from command prompt, eg
 *    muse-io --preset 14 --osc osc.udp://localhost:5000
 *
 */
/*
class EEGBandwidthParticlesPattern extends LXPattern {
  // How many pixies are zipping around.
  private final BoundedParameter numPixies = new BoundedParameter("NUM", 50, 0, 400);

  // How fast each pixie moves, in pixels per second.
  private final BoundedParameter globalSpeed = new BoundedParameter("SPD", 0.5, 0.1, 2.0);
  // How long the trails persist. (Decay factor/percent for the trails, updated each frame.)
  private final BoundedParameter fade = new BoundedParameter("FADE", 0.97, 0.8, 0.99);
    // Brightness adjustment factor.
  private final BoundedParameter brightness = new BoundedParameter("BRITE", 1.5, .25, 2.0);

  // speed will be manually set, in pixels per second.
  // Typical range= 10-1000, good starting value might be 60 (about a bar a second)

  private final BoundedParameter gammaScale = new BoundedParameter("gamma", 0.27, 0, 1.0);
  private final BoundedParameter betaScale = new BoundedParameter("beta", 0.6, 0, 1.0);
  private final BoundedParameter alphaScale = new BoundedParameter("alpha", 0.3, 0, 1.0);
  private final BoundedParameter thetaScale = new BoundedParameter("theta", 0.25, 0, 1.0);
  private final BoundedParameter deltaScale = new BoundedParameter("delta", 0.25, 0, 1.0);


  public EEGBandwidthParticlesPattern(LX lx) {
    super(lx);
    addParameter(numPixies);
    addParameter(brightness);
    addParameter(fade);
    addParameter(globalSpeed);
    addParameter(gammaScale);
    addParameter(betaScale);
    addParameter(alphaScale);
    addParameter(thetaScale);
    addParameter(deltaScale);

    // a good colormap to use is from the ColorBrewer palette, 5-class "Spectral"
    // RGB values: red (215, 25, 28), orange (253, 174,97), yellow (255,255,191), green (135,206,125), blue (43,131,186)
    // HSV values:     (359, 88, 84),         (30, 62, 99),        (60, 25, 100),       (113, 45, 65),      (203, 77, 73)
    addLayer(new PixiePattern(lx, 4, gammaScale, lx.hsb(60, 25, 100), 20)); // yellow
    addLayer(new PixiePattern(lx, 3, betaScale, lx.hsb(359, 82, 84), 20)); //red
    addLayer(new PixiePattern(lx, 2, alphaScale, lx.hsb(30, 82, 99), 20)); //orange
    addLayer(new PixiePattern(lx, 1, thetaScale, lx.hsb(113, 45, 65), 20)); //green
    addLayer(new PixiePattern(lx, 0, deltaScale, lx.hsb(203, 82, 73), 20)); //blue
  }

  public float getMuseSessionScore(int bandID) {
    switch (bandID) {
    case 0: // delta (2-6 Hz)
      return muse.averageTemporal(muse.delta_session);
    case 1: // theta (4-8 Hz)
      return muse.averageTemporal(muse.theta_session);
    case 2: // alpha (8-12 Hz)
      return muse.averageTemporal(muse.alpha_session);
    case 3: // beta (14-26 Hz)
      return muse.averageTemporal(muse.beta_session);
    case 4: // gamma (26-40 Hz)
      //println(muse.averageTemporal(muse.gamma_session));
      return muse.averageTemporal(muse.gamma_session);
    }
    return -1; // somehow not getting where we need to be
  }

  public void run(double deltaMs) {
    // the layers run themselves
  }

  // pixie concept borrowed from Geoff Schmidt's Pixie Pattern
  class PixiePattern extends LXLayer {

    public int bandID;
    public BoundedParameter scale;
    public int pixieColor = lx.hsb(0, 0, 100); // basic color for this instance of the pattern, matches bandwidth energy
    public float speed; // controls speed of particles, roughly in pixels/sec

    private class Pixie {
      public Node fromNode, toNode;
      public double offset = 0;  // explicitly init to zero
      public int pixieColor;

      public Pixie() {
      }
    }

    // the list of active particles
    private ArrayList<Pixie> pixies = new ArrayList<Pixie>();

    public PixiePattern(LX lx, int bandID, BoundedParameter scale, int pixieColor, float speed) {
      super(lx);
      this.bandID = bandID;
      this.scale = scale;
      addParameter(scale);
      this.pixieColor = pixieColor;
      this.speed = speed;
    }

    public void setPixieCount(int count) {
      while ( this.pixies.size() < count) {
        Pixie p = new Pixie();
        p.fromNode = model.getRandomNode();
        p.toNode = model.getRandomNode(p.fromNode);
        p.pixieColor = this.pixieColor;
        // add a noisy base speed here?
        this.pixies.add(p);
      }
      // if we have too many pixies in the list, take them off of the end of the list, FILO
      if (this.pixies.size() > count) {
        this.pixies.subList(count, this.pixies.size()).clear();
      }
    }
    public float scalePixieSpeed(float scale) {
      // speeds go between 10 and 1000 px/sec
      // muse session values go between 0.0 - 1.0
      // so let's linearly scale between them
      float speed = map(scale, 0.0, 1.0, 10.0, 300.0);
      return speed * globalSpeed.getValuef();
    }

    public void run(double deltaMs) {
      this.setPixieCount(Math.round(numPixies.getValuef()));

      float speedRate = 0;
      // ***** HERE is the magical muse line
      // This boolean comes from a global variable, set in Internals.pde
      if (museEnabled) {
        //println("*** Muse Activated!!!");
        //pixieScale = scale.getValuef() * MAX_PIXIES;
        // pixieScale = getMuseSessionScore(this.bandID) * MAX_MUSE_PIXIES;
        speedRate = scalePixieSpeed(getMuseSessionScore(this.bandID));
      }
      else {
        // speedRate = scale.getValuef() * MAX_PIXIES;
        speedRate = scalePixieSpeed(scale.getValuef());
      }

      for (LXPoint p : model.points) {
        colors[p.index] = LXColor.scaleBrightness(colors[p.index], fade.getValuef());
      }

      for (Pixie p : this.pixies) {
        double drawOffset = p.offset;
        p.offset += (deltaMs / 1000.0) * speedRate;

        while (drawOffset < p.offset) {
          // List<LXPoint> points = nodeToNodePoints(p.fromNode, p.toNode);
          Bar bar = model.getBar(p.fromNode, p.toNode);
          LXPoint[] points = bar.points;

          int index = (int)Math.floor(drawOffset);
          if (index >= points.length) {
            //swap nodes to find new direction
            Node oldFromNode = p.fromNode;
            p.fromNode = p.toNode;
            do {
              p.toNode = model.getRandomNode(p.fromNode);
            }
            while (model.getNodeAngle(oldFromNode, p.fromNode, p.toNode)
              < 4*PI/360*3 ); // don't go back the way we came
            drawOffset -= points.length;
            p.offset -= points.length;
            continue;
          }
          // How long, notionally, was the pixie at this pixel during
          // this frame? If we are moving at 100 pixels per second, say,
          // then timeHereMs will add up to 1/100th of a second for each
          // pixel in the pixie's path, possibly accumulated over
          // multiple frames.
          double end = Math.min(p.offset, Math.ceil(drawOffset + .000000001));
          double timeHereMs = (end - drawOffset) / speedRate * 1000.0;

          LXPoint here = points[(int)Math.floor(drawOffset)];
          //        System.out.format("%.2fms at offset %d\n", timeHereMs, (int)Math.floor(drawOffset));

          addColor(here.index,
              LXColor.scaleBrightness(
                p.pixieColor,
                (float)timeHereMs / 1000.0
                  * speedRate
                  * brightness.getValuef()));
          drawOffset = end;
        }
      }
    } // end run
  } //end PixiePattern
} //end EEGBandwidthParticlesPattern

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

  // (MJP): channel locations of audio input?
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
    for (int s=0; s < nsteps.getValue (); s++) {
      step_simulation();
    }
    float dmin=min(sensor_act);
    float dmax=max(sensor_act);
    for (int i=0; i<n_nodes; i++) {
      float v = (sensor_act[i]-dmin)/(dmax-dmin);
      Node node = model.nodemap.get(lf_nodes[i]);
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

