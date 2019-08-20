/** Pattern Ideas.
 *
 * - Tracers extend from a single node along all bars of dodecahedron.
 * - Split and recombine at each node but keep tracing greater graph distance.
 * - Color bars/points as a function of graph distance. Sparkle tetrahedra bars
 *   whenever getting to a point connecting back to first node (i.e. at graph
 *   distance 3). Color Tetrahedra by lerp from node colors.
 *
 */



public abstract class GraphPattern extends LXPattern {

  GraphModel model;

  public GraphPattern(LX lx) {
    super(lx);
    this.model = (GraphModel) lx.model;
  }

  public void fade(LXPoint[] points, float fade) {
    float MIN_BRIGHTNESS = 10.0;
    for (LXPoint p : points) {
      colors[p.index] =
        LXColor.scaleBrightness(colors[p.index], fade);
      float brightness = LXColor.b(colors[p.index]);
      if (brightness < MIN_BRIGHTNESS) {
        colors[p.index] = LXColor.BLACK;
      }
    }
  }

}



//*********************************************************** SYMMETRY PATTERN


public class SymmetryPattern extends GraphPattern {

  /*
  private final BoundedParameter barRate
    = new BoundedParameter("BAR",  5000, 0, 60000);
  private final BoundedParameter nodeRate
    = new BoundedParameter("NODE",  5000, 0, 60000);
  private final BoundedParameter faceRate
    = new BoundedParameter("FACE",  5000, 0, 60000);
  */


  private final BoundedParameter runRate
    = new BoundedParameter("RUN",  1.0, 0.0, 5.0);
  private final BoundedParameter spinRate
    = new BoundedParameter("SPIN",  100.0, 1.0, 10000.0);
  private final BoundedParameter fadeRate =
    new BoundedParameter("FADE", 0.5, 0.0, 1.0);
  //private final SinLFO barPos = new SinLFO(0.0, 1.0, runRate);

  private final BoundedParameter colorSpread
    = new BoundedParameter("dHUE", 30.0, 0.0, 360.0);
  private final BoundedParameter colorSaturation
    = new BoundedParameter("SAT",  70.0, 0.0, 100.0);
  private final BoundedParameter colorSaturationRange
    = new BoundedParameter("dSAT", 50.0, 0.0, 100.0);
  private final BoundedParameter colorBrightness
    = new BoundedParameter("BRT",  30.0, 0.0, 100.0);
  private final BoundedParameter colorBrightnessRange
    = new BoundedParameter("dBRT", 50.0, 0.0, 100.0);
  private float baseHue = 0.0;


  List<GraphModel> tetrahedra = new ArrayList<GraphModel>();
  List<GraphModel> TLModels = new ArrayList<GraphModel>();
  List<GraphModel> TRModels = new ArrayList<GraphModel>();
  // Want the first bar of each tetrahedra
  List<Bar> TLBars = new ArrayList<Bar>();
  List<Bar> TRBars = new ArrayList<Bar>();

  LXPoint point;
  double totalMs;
  double lastSpin;
  double lastSwitch;
  double lastReset;
  float barPos;
  int nodeI = 0;
  boolean toggle = false;
  float hue =   0.0;
  float sat = 100.0;
  float brt = 100.0;

  int barPosI;
  int lastBarPosI;
  Bar symBar;
  Element symBarE;



  Symmetry sym = new Symmetry(model);
  Element baseFace = sym.rotateFace(0, 1, 0);

  public SymmetryPattern(LX lx) {
    super(lx);
    //addParameter(barRate);
    //addParameter(nodeRate);
    //addParameter(faceRate);

    addParameter(runRate);
    addParameter(spinRate);
    addParameter(fadeRate);
    //addModulator(barPos).start();

    addParameter(colorSpread);
    addParameter(colorSaturation);
    addParameter(colorSaturationRange);
    addParameter(colorBrightness);
    addParameter(colorBrightnessRange);

    barPos = 0.0;

    for (GraphModel g: model.getLayer(TL).subGraphs) {
      tetrahedra.add(g);
      TLModels.add(g);
      TLBars.add(g.bars[0]);
    }
    for (GraphModel g: model.getLayer(TR).subGraphs) {
      tetrahedra.add(g);
      TRModels.add(g);
      TRBars.add(g.bars[0]);
    }

    //baseFace.bloom();

  }

  public void run(double deltaMs) {

    totalMs += deltaMs;
    fade(model.points, 1.0 - (fadeRate.getValuef() * (float)deltaMs / 1000.0));

    float dHue = colorSpread.getValuef();
    float bSat = colorSaturation.getValuef();
    float dSat = colorSaturationRange.getValuef();
    float bBrt = colorBrightness.getValuef();
    float dBrt = colorBrightnessRange.getValuef();

    hue = (hue + dHue * (float)deltaMs / 1000.0) % 360.0;


    float delayReset = 60000;
    // Reset symmetry
    if ((totalMs - lastReset) > delayReset) {
      sym.reset();
      lastReset = totalMs;
    }

    //if ((totalMs - lastSwitch) > delaySwitch) {
    //  switchBar();
    //}


    // Spin the point around
    float spinMs = 1.0 / (float)Math.log(spinRate.getValuef() / 1000.0);
    out("Spinning after %.2f Ms (%.2f)", spinMs, totalMs-lastSpin);
    if ((totalMs-lastSpin) > spinMs) {
      out("!! SPIN !!");
      baseFace.addStep();
      lastSpin = totalMs;
    }

    Bar bar = TLBars.get(0);
    barPos += (float) (runRate.getValuef() * deltaMs / 1000.0);
    barPosI = (int)Math.floor(barPos * (float)bar.points.length);
    barPosI = LXUtils.constrain(barPosI, 0, bar.points.length-1);
    out("Run rate %.4f   Pos: %.4f   I: %d", runRate.getValuef(), barPos, barPosI);
    for (int i = lastBarPosI; i <= barPosI; i++) {
      LXPoint point = bar.points[i];
      int c = lx.hsb(hue,sat,brt);
      sym.template[point.index] = c;
    }
    lastBarPosI = barPosI;
    if (barPos >= 1.0) {
      switchBar();
    }

    //for (LXPoint p: bar.points) {
      //colors[p.index] = lx.hsb(hue,sat,brt);
      //out("Coloring pixel %d #%h\n", p.index, c);
    //}
    sym.draw(colors);

  }

  void switchBar() {
    sym.pop();
    symBar = model.getRandomBar();
    symBarE = sym.rotateBar(symBar);
    lastSwitch = totalMs;
    sym.push(baseFace);
    barPos = 0.0;
  }

}

//****************************************************** SYMMETRY TEST PATTERN


public class SymmetryTestPattern extends GraphPattern {
  private final BoundedParameter cycleSpeed
      = new BoundedParameter("SPD",  5.0, 1.0, 100.0);
  private final BoundedParameter colorSpread
      = new BoundedParameter("dHUE", 30.0, 0.0, 360.0);
  private final BoundedParameter colorSaturation
      = new BoundedParameter("SAT",  70.0, 0.0, 100.0);
  private final BoundedParameter colorSaturationRange
      = new BoundedParameter("dSAT", 50.0, 0.0, 100.0);
  private final BoundedParameter colorBrightness
      = new BoundedParameter("BRT",  30.0, 0.0, 100.0);
  private final BoundedParameter colorBrightnessRange
      = new BoundedParameter("dBRT", 50.0, 0.0, 100.0);
  private float baseHue = 0.0;


  List<GraphModel> tetrahedra = new ArrayList<GraphModel>();
  LXPoint point;
  double diffMs;
  double totalMs;
  double lastSwitch;
  int nodeI = 0;
  boolean toggle = false;
  float hue =   0.0;
  float sat = 100.0;
  float brt = 100.0;


  Symmetry sym = new Symmetry(model);

  public SymmetryTestPattern(LX lx) {
    super(lx);
    addParameter(cycleSpeed);
    addParameter(colorSpread);
    addParameter(colorSaturation);
    addParameter(colorSaturationRange);
    addParameter(colorBrightness);
    addParameter(colorBrightnessRange);

    for (GraphModel g: model.getLayer(TR).subGraphs) { tetrahedra.add(g); }
    for (GraphModel g: model.getLayer(TL).subGraphs) { tetrahedra.add(g); }
  }

  public void run(double deltaMs) {

    float dHue = colorSpread.getValuef();
    float bSat = colorSaturation.getValuef();
    float dSat = colorSaturationRange.getValuef();
    float bBrt = colorBrightness.getValuef();
    float dBrt = colorBrightnessRange.getValuef();

    int symBarI = 0;
    Bar symBar;
    Node symNode;
    Element symBarE;
    Element symNodeE;
    diffMs += deltaMs;
    totalMs += deltaMs;


    // Switch nodes every 30 seconds
    if ((totalMs - lastSwitch) > 30000) {
      sym.reset();
      nodeI = (nodeI + 1) % model.nodes.length;
      lastSwitch = totalMs;
    }

    if (diffMs >= 1000) {
      hue = (hue + dHue) % 360.0;
      if (toggle) {
        symBar = model.getRandomBar();
        symBarE = sym.rotateBar(symBar);
        //symBarE.setStep(new int[]{0,1});
      } else if (deltaMs < 2000) {
        //symNode = model.getRandomNode();
        symNode = model.nodes[nodeI];
        symNodeE = sym.rotateNode(symNode);
        symNodeE.setStep(new int[]{0,1,2});
      }

      toggle = !toggle;
      diffMs = 0.0;
    }

    /*
    for (int i = 0; i < colors.length; i++) {
      colors[i] = lx.hsb(0.0, 0.0, 0.0);
    }
    */

    GraphModel tetra = tetrahedra.get(0);
    Bar bar = tetra.bars[0];
    for (LXPoint p: bar.points) {
      //colors[p.index] = lx.hsb(hue,sat,brt);
      int c = lx.hsb(hue,sat,brt);
      sym.template[p.index] = c;
      //out("Coloring pixel %d #%h\n", p.index, c);
    }
    sym.draw(colors);

    /*
    for (int t = 0; t<tetrahedra.size(); t++) {
      GraphModel tetra = tetrahedra.get(t);
      float db = dBrt / (float)tetra.bars.length ;
      float ds = dSat / (float)tetra.bars.length ;
      hue = (float)t * dHue + baseHue;
      for (int b = 0; b < tetra.bars.length; b++) {
        sat = LXUtils.constrainf(bSat - (float)b * ds, 0., 100.);
        brt = LXUtils.constrainf(bBrt + (float)b * db, 0., 100.);
        Bar bar = tetra.bars[b];
        //int last_point = 0;
        for (LXPoint p: bar.points) {
          colors[p.index] = lx.hsb(hue,sat,brt);
          //last_point = p.index;
        }
        //colors[last_point] = -1;
      }
    }
    */
  }
}





/** ********************************************************* TETRAHEDRON SPIN
 * Spin around showing a single tetrahedron at a time.
 ****************************************************************************/

public class TetraSpin extends GraphPattern {

  // rotations per second
  private final CompoundParameter rotateSpeed
      = new CompoundParameter("Spin", 4.0, 0.0, 10.0);
  /*
  private final BoundedParameter colorAttk
      = new BoundedParameter("Attk", 300.0, 1.0, 1000.0);
  private final BoundedParameter colorFade
      = new BoundedParameter("Fade", 300.0, 1.0, 1000.0);
  */
  // fraction of period in phase
  private final CompoundParameter colorAttk
      = new CompoundParameter("Attk", 1.0, 0.0, 2.0);
  private final CompoundParameter colorFade
      = new CompoundParameter("Fade", 1.0, 0.0, 10.0);

  Random r = new Random();

  boolean shell = false;
  int index = 0;
  float elapsed = 0;
  float period = 100;

  public TetraSpin(LX lx) {
    super(lx);
    addParameter(rotateSpeed);
    addParameter(colorAttk);
    addParameter(colorFade);

    //for (GraphModel g: model.tetraL.subGraphs) { tetrahedra.add(g); }
    //for (GraphModel g: model.tetraR.subGraphs) { tetrahedra.add(g); }
  }

  public void run(double deltaMs) {

    // Track elapsed periods
    period = 1000.0 / rotateSpeed.getValuef();
    elapsed += (float)deltaMs;
    if (elapsed >= period) {
      elapsed = 0.0;
      if (r.nextFloat() < 0.33) {
        shell = !shell;
      } else {
        index = (index + (int)Math.floor(r.nextFloat() * 4.0)) % 5;
        //index = (index + 1) % 5;
      }
    }

    // Fade to Black
    float fadeVal = 1.0 - (((float)deltaMs/period) / colorFade.getValuef());
    float attkVal = elapsed/period / colorAttk.getValuef() * 100.0;
    fade(model.points, fadeVal);

    GraphModel tetra;
    if (shell) { tetra = model.getLayer(TL).getLayer(index); }
    else       { tetra = model.getLayer(TR).getLayer(index); }

    Bar bar0 = tetra.bars[0];
    float hue = 0.0;
    float sat = 100.0;
    float brt = min(100.0, attkVal);

    for (int b = 0; b < tetra.bars.length; b++) {
      Bar bar = tetra.bars[b];
      for (LXPoint p: bar.points) {
        hue = (float)palette.getHue(p);
        colors[p.index] = LXColor.lightest(colors[p.index], LXColor.hsb(hue, sat, brt));
      }
    }
  }
}











/** *********************************************** SYMMETRY TEST ROTATE FACES
 * Apply a test pattern to a tetrahedron, then iteratively rotate it around
 * faces.
 *
 * ---------------------------------------------------------------------------
 * - Instantiate a Symmetry object for Mimsy
 * -- By default, initial operation is to Rotate 0 times around Face 0
 * - Draw the test pattern into the Template
 * - Have Symmetry replicate it across Mimsy
 * - Every period, add a random rotation around a random Face
 *
 * **************************************************************************/



public class TetraSymmetryFace extends GraphPattern {

  private final BoundedParameter cycleSpeed
      = new BoundedParameter("SPD",  5.0, 1.0, 100.0);
  private final BoundedParameter colorSpread
      = new BoundedParameter("dHUE", 30.0, 0.0, 360.0);
  private final BoundedParameter colorSaturation
      = new BoundedParameter("SAT",  70.0, 0.0, 100.0);
  private final BoundedParameter colorSaturationRange
      = new BoundedParameter("dSAT", 50.0, 0.0, 100.0);
  private final BoundedParameter colorBrightness
      = new BoundedParameter("BRT",  30.0, 0.0, 100.0);
  private final BoundedParameter colorBrightnessRange
      = new BoundedParameter("dBRT", 50.0, 0.0, 100.0);
  private float baseHue = 0.0;

  List<GraphModel> tetrahedra = new ArrayList<GraphModel>();
  LXPoint point;

  public TetraSymmetryFace(LX lx) {
    super(lx);
    addParameter(cycleSpeed);
    addParameter(colorSpread);
    addParameter(colorSaturation);
    addParameter(colorSaturationRange);
    addParameter(colorBrightness);
    addParameter(colorBrightnessRange);

    for (GraphModel g: model.getLayer(TR).subGraphs) { tetrahedra.add(g); }
    for (GraphModel g: model.getLayer(TL).subGraphs) { tetrahedra.add(g); }
  }

  public void run(double deltaMs) {
    float hue = 0.;
    float sat = 0.;
    float brt = 0.;

    float dHue = colorSpread.getValuef();
    float bSat = colorSaturation.getValuef();
    float dSat = colorSaturationRange.getValuef();
    float bBrt = colorBrightness.getValuef();
    float dBrt = colorBrightnessRange.getValuef();

    baseHue += Math.log(cycleSpeed.getValuef());
    baseHue %= 360.;

    for (int t = 0; t<tetrahedra.size(); t++) {
      GraphModel tetra = tetrahedra.get(t);
      float db = dBrt / (float)tetra.bars.length ;
      float ds = dSat / (float)tetra.bars.length ;
      hue = (float)t * dHue + baseHue;
      for (int b = 0; b < tetra.bars.length; b++) {
        sat = LXUtils.constrainf(bSat - (float)b * ds, 0., 100.);
        brt = LXUtils.constrainf(bBrt + (float)b * db, 0., 100.);
        Bar bar = tetra.bars[b];
        //int last_point = 0;
        for (LXPoint p: bar.points) {
          colors[p.index] = lx.hsb(hue,sat,brt);
          //last_point = p.index;
        }
        //colors[last_point] = -1;
      }
    }
  }
}




/** ************************************************************ PIXIE PATTERN
 * Pixies: points of light that chase along the edges.
 *
 * More ideas for later:
 * - Scatter/gather (they swarm around one point, then fly by
 *   divergent paths to another point)
 * - Fireworks (explosion of them coming out of one point)
 * - Multiple colors (maybe just a few in a different color)
 *
 * @author Geoff Schmidt
 *
 * @author Mike Pesavento, adding EEG mapping to parameters, heavy edits
 ************************************************************************* **/

public class PixiePattern extends GraphPattern {
  // How many pixies are zipping around.
  protected final BoundedParameter numPixies =
      new BoundedParameter("NUM", 100, 0, 1000);
  // How fast each pixie moves, in pixels per second.
  protected final BoundedParameter speed =
      new BoundedParameter("SPD", 50.0, 10.0, 150.0);
  // How long the trails persist. (Decay factor for the trails, each frame.)
  // XXX really should be scaled by frame time
  protected final BoundedParameter fade =
      new BoundedParameter("FADE", 0.9, 0.8, .97);
  // Brightness adjustment factor.
  protected final BoundedParameter brightness =
      new BoundedParameter("BRIGHT", 1.0, .25, 2.0);
  protected final BoundedParameter colorHue = new BoundedParameter("HUE", 210, 0, 359.0);
  protected final BoundedParameter colorSat = new BoundedParameter("SAT", 63.0, 0.0, 100.0);


  class Pixie {
    public Node fromNode, toNode;
    public double offset;
    public int kolor;

    public Pixie() {
      // Nothing to do in here, just a holder for attributes
    }
  }

  // the list of active particles
  private ArrayList<Pixie> pixies = new ArrayList<Pixie>();

  public PixiePattern(LX lx) {
    super(lx);
    addParameter(numPixies);
    addParameter(fade);
    addParameter(speed);
    addParameter(brightness);
    addParameter(colorHue);
    addParameter(colorSat);

  }

  public void setPixieCount(int count) {
    //make sure all pixies are set to current color
    for (Pixie p : this.pixies) {
      p.kolor = lx.hsb(colorHue.getValuef(), colorSat.getValuef(), 100);
    }

    while (this.pixies.size() < count) {
      Pixie p = new Pixie();
      p.fromNode = model.getRandomNode();
      //p.toNode = p.fromNode.getRandomAdjacentNode();
      p.toNode = model.getRandomNode(p.fromNode);
      p.kolor = lx.hsb(colorHue.getValuef(), colorSat.getValuef(), 100);
      this.pixies.add(p);
    }
    if (this.pixies.size() > count) {
      this.pixies.subList(count, this.pixies.size()).clear();
    }
  }

  public void run(double deltaMs) {
    this.setPixieCount(Math.round(numPixies.getValuef()));
    //    System.out.format("FRAME %.2f\n", deltaMs);
    float fadeRate = 0;
    float speedRate = 0;
    float calm;
    float attention;

    if (museEnabled) {
      // NOTE: this usually uses getMellow() and getConcentration(), but
      // recent versions of muse-io look like they don't catch those values any longer :(
      // calm = muse.getTheta()/muse.getAlpha();
      // attention = muse.getBeta()/muse.getAlpha();
      //  // Placeholders, use these for now?
      calm = muse.getAlpha();
      attention = muse.getGamma();
      fadeRate = map(calm, 0.0, 1.0, (float)fade.range.min, (float)fade.range.max);
      speedRate = map(attention, 0.0, 1.0, (float)speed.range.min, (float)speed.range.max);
    }
    else {
      fadeRate = fade.getValuef();
      speedRate = speed.getValuef();
    }

    for (LXPoint p : model.points) {
     colors[p.index] =
         LXColor.scaleBrightness(colors[p.index], fadeRate);
    }

    for (Pixie p : this.pixies) {
      double drawOffset = p.offset;
      p.offset += (deltaMs / 1000.0) * speedRate;
      //      System.out.format("from %.2f to %.2f\n", drawOffset, p.offset);

      while (drawOffset < p.offset) {
          //        System.out.format("at %.2f, going to %.2f\n", drawOffset, p.offset);
        //List<LXPoint> points = nodeToNodePoints(p.fromNode, p.toNode);
        Bar bar = model.getBar(p.fromNode,p.toNode);
        LXPoint[] points = bar.points;

        int index = (int)Math.floor(drawOffset);
        if (index >= points.length) {
          Node oldFromNode = p.fromNode;
          p.fromNode = p.toNode;
          do {
            p.toNode = model.getRandomNode(p.fromNode);
          } while (model.getNodeAngle(oldFromNode, p.fromNode, p.toNode)
                   < 4*PI/360*3); // don't go back the way we came
          drawOffset -= points.length;
          p.offset -= points.length;
          //          System.out.format("next edge\n");
          continue;
        }

        // How long, notionally, was the pixie at this pixel during
        // this frame? If we are moving at 100 pixels per second, say,
        // then timeHereMs will add up to 1/100th of a second for each
        // pixel in the pixie's path, possibly accumulated over
        // multiple frames.
        double end = Math.min(p.offset, Math.ceil(drawOffset + .000000001));
        double timeHereMs = (end - drawOffset) /
            speedRate * 1000.0;

        LXPoint here = points[(int)Math.floor(drawOffset)];
        //        System.out.format("%.2fms at offset %d\n", timeHereMs, (int)Math.floor(drawOffset));

        addColor(here.index,
                 LXColor.scaleBrightness(p.kolor,
                                         (float)timeHereMs / 1000.0
                                         * speedRate
                                         * brightness.getValuef()));
        drawOffset = end;
      }
    }
  }
}


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
 *
 * Requires use of the muse_connect.pde file, which gives access to the muse headset data
 * Needs boolean museEnabled to be declared globall.
 * Needs global object variable `MuseConnect muse` to be declared to access it in this pattern.
 *
 * To connect Muse EEG headset via bluetooth, follow instructions in MuseConnect.pde
 * Run "muse-io' from command prompt, eg
 *    muse-io --preset 14 --osc osc.udp://localhost:5000
 *
 */

public class EEGBandwidthParticlesPattern extends GraphPattern {

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
  public class PixiePattern extends LXLayer {
    GraphModel model;

    public int bandID;
    public BoundedParameter bandEnergy;
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

    public PixiePattern(LX lx, int bandID, BoundedParameter bandEnergy, int pixieColor, float speed) {
      super(lx);
      this.model = (GraphModel) lx.model;

      this.bandID = bandID;
      this.bandEnergy = bandEnergy;
      // addParameter(bandEnergy);
      this.pixieColor = pixieColor;
      this.speed = speed;
    }

    public void setPixieCount(int count) {
      while (this.pixies.size() < count) {
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
    public float scalePixieSpeed(float bandEnergy) {
      // speeds go between 10 and 1000 px/sec
      // muse session values go between 0.0 - 1.0
      // so let's linearly bandEnergy between them
      float speed = map(bandEnergy, 0.0, 1.0, 10.0, 300.0);
      return speed * globalSpeed.getValuef();
    }

    public void run(double deltaMs) {
      this.setPixieCount(Math.round(numPixies.getValuef()));

      float speedRate = 0;
      // ***** HERE is the magical muse line
      // This boolean comes from a global variable, set in Internals.pde
      if (museEnabled) {
        //println("*** Muse Activated!!!");
        //pixieScale = bandEnergy.getValuef() * MAX_PIXIES;
        // pixieScale = getMuseSessionScore(this.bandID) * MAX_MUSE_PIXIES;
        speedRate = scalePixieSpeed(getMuseSessionScore(this.bandID));
      }
      else {
        // speedRate = bandEnergy.getValuef() * MAX_PIXIES;
        speedRate = scalePixieSpeed(bandEnergy.getValuef());
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


/** ************************************************************
 *  Make the dodecahedron twinkle and the L tetrahedra spin
 *
 * TODO:
 *   - better colors for the tetrahedra, NO MORE RAINBOWS
 *   - play with adding the R tetrahedra, in a complimentary color?
 *
 * @author Mike Pesavento
 *
 */
public class DDTwinkle extends GraphPattern {

  private final BoundedParameter rate =
      new BoundedParameter("RATE", 20.0, 1.0, 80.0);
  private final BoundedParameter hue =
    new BoundedParameter("HUE", 30, 0, 360);
  private final BoundedParameter hueWidth =
    new BoundedParameter("HUEW", 40, 0, 360);
  private final BoundedParameter fadeRate =
    new BoundedParameter("DDFADE", 1.75, 0.001, 5.0);


  private final CompoundParameter colorAttkTetra
      = new CompoundParameter("TAttk", 0.92, 0.0, 2.0);
  private final CompoundParameter colorFadeTetra
      = new CompoundParameter("TFade", 2.9, 0.0, 10.0);


  // rotations per second
  private final CompoundParameter rotateSpeed
      = new CompoundParameter("TSpin", 2.5, 0.0, 10.0);

  Random rand = new Random();

  int tetraIndex = 0;
  float tetraElapsed = 0;
  float tetraPeriod = 100.0;


  public DDTwinkle(LX lx) {
    super(lx);
    addParameter(rate);
    addParameter(hue);
    addParameter(hueWidth);
    addParameter(fadeRate);
    addParameter(colorAttkTetra);
    addParameter(colorFadeTetra);
    addParameter(rotateSpeed);
  }

  public void run(double deltaMs) {
    // ----
    // Dodecahedron
    updateDodecahedron(deltaMs);

    // tetrahedra
    // first, fade ALL tetrahedra, not just our current one
    float tetraFadeVal = 1.0 - (colorFadeTetra.getValuef() * (float)deltaMs / 1000.0);
    fade(model.getLayer(TL).points, tetraFadeVal);
    // add the L
    GraphModel tetra;
    tetra = model.getLayer(TL).getLayer(tetraIndex);
    updateTetrahedra(tetra, deltaMs);


  }

  private void colorTetraBars(GraphModel tetra, float attackVal) {
    // Given a tetrahedra, color all the bars in some clever way
    float hue = 0.0;
    float sat = 100.0;
    float brt = min(100.0, attackVal);

    for (int b=0; b < tetra.bars.length; b++) {
      Bar bar = tetra.bars[b];
      for (LXPoint p: bar.points) {
        hue = (float)palette.getHue(p);
        colors[p.index] = LXColor.lightest(colors[p.index], LXColor.hsb(hue, sat, brt));
      }
    }
  }

    private void updateTetrahedra(GraphModel tetra, double deltaMs) {
    // Tetrahedra, Left only
    // Track elapsed periods
    tetraPeriod = 1000.0 / rotateSpeed.getValuef();
    tetraElapsed += (float)deltaMs;
    // switch to a new tetrahedra if it's time
    if (tetraElapsed >= tetraPeriod) {
      tetraElapsed = 0.0;
      tetraIndex = (tetraIndex + (int)Math.floor(rand.nextFloat() * 4.0)) % 5;
      //tetraIndex = (tetraIndex + 1) % 5;

    }
    float attkVal = (tetraElapsed/tetraPeriod) / colorAttkTetra.getValuef() * 100.0;
    this.colorTetraBars(tetra, attkVal);
  }

  private void updateDodecahedron(double deltaMs){
    // make the dodecahedron twinkle
    GraphModel dodecahedron;
    dodecahedron = model.getLayer(DD);
    float ddFade = 1.0 - (fadeRate.getValuef() * (float)deltaMs / 1000.0);
    fade(dodecahedron.points, ddFade);

    ArrayList<LXPoint> twinklePoints = dodecahedron
        .getRandomPoints((int)rate.getValuef());
    for(LXPoint p: twinklePoints) {
      int hueShift = rand.nextInt((int)hueWidth.getValuef());
      float curHue = (hue.getValuef() + hueShift - hueShift / 2) % 360;
      colors[p.index] = lx.hsb(curHue, 100, 100);
    }
  }
}


/************************************************************** TTL PATTERN
 * Points of light colliding with each other within a finite TTL.
 * Upon collision, points change color and spawn a new point.
 * TTL is a registered parameter mutable in the UI.
 * Inspired by the pixie pattern.
 *
 * More ideas for later:
 * - Rather than becoming solid instantly, post-collision bars
 *   could have their coloring radiated from the point of collision.
 * - Collisions near/at the ends of a bar aren't that fun to watch;
 *   perhaps collisions at the ends of a bar should be ignored.
 * - Subsections of the bar could be rendered final when a collision
 *   occurs, rather than rendering the entire bar final.
 *
 * @author Matt Quinn
 ************************************************************************* **/

public class TimeToLivePattern extends PixiePattern {

  private final BoundedParameter ttlParam =
      new BoundedParameter("TTL", 8.0, 1.0, 20.0);

  // All living pixies. We want O(1) removal.
  private Set<TtlPixie> pixies = new HashSet<TtlPixie>();

  // Each *directed* bar mapped to the pixies that are currently on it.
  private final Map<Bar, Set> barPixies = new HashMap<Bar, Set>();

  // Each *directed* bar that has had a collision occur on it.
  // We want O(1) lookup to know whether or not a bar should be checked for collisions.
  private final Set<Bar> solidBars = new HashSet<Bar>();

  // Each *directed* bar that hasn't yet had a collision on it.
  // We sacrifice O(1) removal for O(1) random access
  private final List<Bar> blankBars = new ArrayList<Bar>();

  private final Random random = new Random();

  private float anglemod = 0;

  class TtlPixie extends PixiePattern.Pixie {
    public boolean isCollided;
    public int ttl;
    public TtlPixie(Node fromNode, Node toNode) {
      super();
      this.fromNode = fromNode;
      this.toNode = toNode;
      this.ttl = (int)ttlParam.getValuef();
      this.isCollided = false;
    }
    public void updateColor() {
      this.kolor = lx.hsb(colorHue.getValuef(), colorSat.getValuef(),
        (isCollided ? 255 : 100));
    }
  }

  public TimeToLivePattern(LX lx) {
    super(lx);
    addParameter(ttlParam);

    // All bars are initially blank and have zero pixies.
    // Iteration here is over bars directed in a single direction;
    // we call reversed() to also keep references to oppposing bars.
    for (int i = 0; i < model.bars.length; i++) {
      Bar bar = model.bars[i];
      this.blankBars.add(bar);
      this.blankBars.add(bar.reversed());
      this.barPixies.put(bar, new HashSet<TtlPixie>());
      this.barPixies.put(bar.reversed(), new HashSet<TtlPixie>());
    }

    // Let loose a single pixie.
    addNewPixieToSet(this.pixies);
  }

  /**
   * Accepts a set and potentially adds a new pixie to the collection.
   */
  protected void addNewPixieToSet(Collection<TtlPixie> set) {
    if (blankBars.size() == 0)
      return;

    // Get a random bar from the set of blank (non-collided) ones.
    Bar bar = blankBars.get(random.nextInt(blankBars.size()));
    TtlPixie newPixie = new TtlPixie(bar.node1, bar.node2);
    set.add(newPixie);
    this.barPixies.get(bar).add(newPixie);
  }

  public void run(double deltaMs) {

    float fadeRate = 0;
    float speedRate = 0;
    float calm;
    float attention;

    if (museEnabled) {
      // NOTE: this usually uses getMellow() and getConcentration(), but
      // recent versions of muse-io look like they don't catch those values any longer :(
      // calm = muse.getTheta()/muse.getAlpha();
      // attention = muse.getBeta()/muse.getAlpha();
      //  // Placeholders, use these for now?
      calm = muse.getAlpha();
      attention = muse.getGamma();
      fadeRate = map(calm, 0.0, 1.0, (float)fade.range.min, (float)fade.range.max);
      speedRate = map(attention, 0.0, 1.0, (float)speed.range.min, (float)speed.range.max);
    }
    else {
      fadeRate = fade.getValuef();
      speedRate = speed.getValuef();
    }

    // Scale brightness for all points
    for (LXPoint p : model.points) {
     colors[p.index] =
         LXColor.scaleBrightness(colors[p.index], fadeRate);
    }

    // Ensure all living pixies have the latest color
    for (TtlPixie p : this.pixies) {
      p.updateColor();
    }

    // Ensure all solid bars have the latest color.
    anglemod=anglemod+1;
    if (anglemod > 360)
      anglemod = anglemod % 360;
    for (Bar bar : this.solidBars) {
      for (LXPoint point: bar.points) {
        colors[point.index]=lx.hsb(((atan(point.x/point.z))*360/PI+anglemod),80,50);
      }
    }

    // To avoid concurrent modification exceptions while iterating
    // over living pixies, we accumulate pixies to add/remove in these lists.
    List<TtlPixie> newPixies = new ArrayList<TtlPixie>();
    List<TtlPixie> removePixies = new ArrayList<TtlPixie>();

    ALL_PIXIES_ITER:
    for (TtlPixie p : this.pixies) {

      Bar thisBar = model.getBar(p.fromNode, p.toNode);

      // If a pixie's TTL hits 0, remove it.
      if (p.ttl <= 0) {
        removePixies.add(p);
        barPixies.get(thisBar).remove(p);
        continue;
      }

      double drawOffset = p.offset;
      p.offset += (deltaMs / 1000.0) * speedRate;

      // Check the bar in the opposite direction for
      // pixies that are colliding with this pixie. Note that we
      // only check if for collisions if a collision *hasn't*
      // already occurred on this bar.
      Bar oppositeBar = model.getBar(p.toNode, p.fromNode);
      if (!solidBars.contains(thisBar)) {
        for (TtlPixie oncomingPixie : (Set<TtlPixie>)barPixies.get(oppositeBar)) {
          // Note the shenanery here: offset 0 in one direction is
          // opposite offset 0 in the other, so one of them needs to be flipped
          // before we can compare their "physical" locations.
          if (Math.abs((int)oncomingPixie.offset - (thisBar.points.length - (int)p.offset)) <= 2) {
            p.isCollided = true;
            oncomingPixie.isCollided = true;

            solidBars.add(thisBar);
            solidBars.add(oppositeBar);
            blankBars.remove(thisBar);
            blankBars.remove(oppositeBar);

            // When two pixies collide, spawn a new one.
            addNewPixieToSet(newPixies);

            continue ALL_PIXIES_ITER;
          }
        }
      }

      while (drawOffset < p.offset) {
        LXPoint[] points = thisBar.points;

        int index = (int)Math.floor(drawOffset);

        // If the pixie has reached the end of a bar,
        // send it down a connected bar (allowed to reverse).
        if (index >= points.length) {
          Node oldFromNode = p.fromNode;
          p.fromNode = p.toNode;
          p.toNode = model.getRandomNode(p.fromNode);
          drawOffset -= points.length;
          p.offset -= points.length;

          Bar newBar = model.getBar(p.fromNode, p.toNode);
          barPixies.get(thisBar).remove(p);
          barPixies.get(newBar).add(p);
          // Pixie's TTL is decremented once for each bar traversal.
          p.ttl -= 1;

          // When a pixie reaches the end of a bar,
          // potentially spawn a new pixie at a random node.
          int choice = random.nextInt(Math.max(2, pixies.size() / 2));
          if (choice == 0) {
             addNewPixieToSet(newPixies);
          }

          continue;
        }

        // How long, notionally, was the pixie at this pixel during
        // this frame? If we are moving at 100 pixels per second, say,
        // then timeHereMs will add up to 1/100th of a second for each
        // pixel in the pixie's path, possibly accumulated over
        // multiple frames.
        double end = Math.min(p.offset, Math.ceil(drawOffset + .000000001));
        double timeHereMs = (end - drawOffset) /
            speedRate * 1000.0;

        LXPoint here = points[(int)Math.floor(drawOffset)];
        addColor(here.index, LXColor.scaleBrightness(p.kolor,
                                         (float)timeHereMs / 1000.0
                                         * speedRate
                                         * brightness.getValuef()));
        drawOffset = end;
      }
    }

    // Process queued up additions/removals now that iteration is complete.
    this.pixies.addAll(newPixies);
    this.pixies.removeAll(removePixies);
  }
}


/* ************************************************************
 *  Fire on the bars, enclosed by the dodecahedron
 *
 * Fire stolen shamelessly from FastLED examples
 * https://github.com/FastLED/FastLED/blob/master/examples/Fire2012WithPalette/Fire2012WithPalette.ino
 *
 * Muse enabled!
 *  - calming the mind (high theta/alpha) increases the cooling parameter
 *  - increasing attention (high gamma/alpha) increases the sparking parameter
 *
 * TODO:
 *
 * @author Mike Pesavento
 *
 */
public class FireBars extends GraphPattern {

  // We need to create a map of int values for each pixel to
  // the associated color for that value.
  //
  // The easy option is to just create a full replica of the entire color array
  // using the "temperature" as the color value.
  // The indexes in this array map 1:1 with the pixel indexes in colors[]
  protected int heat_values[] = new int[colors.length];

  protected LutPalette heat_lut;

  //entropy
  Random rand = new Random();

  private final BoundedParameter rate =
      new BoundedParameter("RATE", 20.0, 1.0, 80.0);
  private final BoundedParameter hue =
    new BoundedParameter("HUE", 200, 0, 360);
  private final BoundedParameter hueWidth =
    new BoundedParameter("HUEW", 40, 0, 360);
  private final BoundedParameter fadeRate =
    new BoundedParameter("DDFADE", 1.75, 0.001, 5.0);

  // COOLING: How much does the air cool as it rises?
  // Less cooling = taller flames.  More cooling = shorter flames.
  // Default 55, suggested range 20-100
  private final BoundedParameter cooling_param =
      new BoundedParameter("COOL", 55, 20, 200);
  private int cooling = (int)cooling_param.getValue();

  // SPARKING: What chance (out of 255) is there that a new spark will be lit?
  // Higher chance = more roaring fire.  Lower chance = more flickery fire.
  // Default 120, suggested range 50-200.
  private final BoundedParameter sparking_param =
      new BoundedParameter("SPARK", 120, 50, 200);
  private int sparking = (int)sparking_param.getValue();

  // which colormap, heat or ice?
  private final CompoundParameter cmap_param = new CompoundParameter("CMAP", 0, 2);
  private int cmap_ix = 0;


  public FireBars(LX lx) {
    super(lx);
    heat_lut = new LutPalette("heat");
    addParameter(rate);
    addParameter(hue);
    addParameter(hueWidth);
    addParameter(fadeRate);

    addParameter(cooling_param);
    addParameter(sparking_param);
    addParameter(cmap_param);


    // set all heat values to something hot, and then it cools
    for(int i=0; i<heat_values.length; i++)
      heat_values[i] = 230;

  }


  public void run(double deltaMs) {
    // add muse interaction
    float calm;
    float attention;
    if (museEnabled) {
      // NOTE: this usually uses getMellow() and getConcentration(), but
      // recent versions of muse-io look like they don't catch those values any longer :(
      calm = muse.getTheta()/muse.getAlpha();
      attention = muse.getBeta()/muse.getAlpha();
      //  // Placeholders, use these for now?
      // calm = muse.getAlpha();
      // attention = muse.getGamma();
      cooling = (int)map(calm,
        0.0, 1.0,
        (float)cooling_param.range.min, (float)cooling_param.range.max);
      sparking = (int)map(attention,
        0.0, 1.0,
        (float)sparking_param.range.min, (float)sparking_param.range.max);
    }
    else {
      cooling = (int)cooling_param.getValue();
      sparking = (int)sparking_param.getValue();
    }

    // check which colormap
    int new_cmap_ix = (int)Math.floor(cmap_param.getValue());
    if ( new_cmap_ix != cmap_ix) {
      switch(new_cmap_ix) {
        case 0: heat_lut = new LutPalette("heat"); break;
        case 1: heat_lut = new LutPalette("ice"); break;
        }
      cmap_ix = new_cmap_ix;
    }


    // Dodecahedron
    updateDodecahedron(deltaMs);

    // fire on the tetras
    GraphModel tetraL = model.getLayer(TL);
    GraphModel tetraR = model.getLayer(TR);

    for (Bar bar : tetraL.bars) {
      // first, update the heat_values array based on old values
      fire(bar, heat_values);
      // then update the colors array for the given bar
      int bar_range[] = bar.getPointRange();
      for(int i=bar_range[0]; i<bar_range[1]; i++) {
        // System.out.format("[%d]=%3d,%3d\n", i, heat_values[i], scale8(heat_values[i], 240));
        int color_ix = scale8(heat_values[i], 240);
        int clr = heat_lut.get_color(color_ix);
        // System.out.format("[%d]=%d, clr=0x%08X\n", i, color_ix, clr);
        colors[i] = clr;
      }
    }
    // for (Bar bar : tetraR.bars) {
    //   fire(bar, heat_values);
    // }

  }

  // Fire2012 by Mark Kriegsman, July 2012
  // FastLED library
  // https://github.com/FastLED/FastLED/blob/master/examples/Fire2012WithPalette/Fire2012WithPalette.ino
  // as part of "Five Elements" shown here: http://youtu.be/knWiGsmgycY
  ////
  // This basic one-dimensional 'fire' simulation works roughly as follows:
  // There's a underlying array of 'heat' cells, that model the temperature
  // at each point along the line.  Every cycle through the simulation,
  // four steps are performed:
  //  1) All cells cool down a little bit, losing heat to the air
  //  2) The heat from each cell drifts 'up' and diffuses a little
  //  3) Sometimes randomly new 'sparks' of heat are added at the bottom
  //  4) The heat from each cell is rendered as a color into the leds array
  //     The heat-to-color mapping uses a black-body radiation approximation.
  //
  // Temperature is in arbitrary units from 0 (cold black) to 255 (white hot).
  //
  // This simulation scales it self a bit depending on NUM_LEDS; it should look
  // "OK" on anywhere from 20 to 100 LEDs without too much tweaking.

  void fire(Bar bar, int[] heat_values) {
    //MJP NOTES:
    // To get this to work without creating a second buffer of all colors,
    // i should create a reversible map for index to color int, and from colorint
    // to index. This would allow me to read the color from colors[bar.points.index]
    // and remember where we were for the next frame.
    // The colors[] array is ints, so should be able to map directly if we use a hash table

    int num_leds = bar.points.length;
    // Array of temperature readings at each simulation cell
    int heat[] = new int[num_leds];
    boolean reverse_direction = is_reversed(bar);

    // quick fills for testing
    //    for(LXPoint p : bar.points) {
    //       colors[p.index] = heat_lut.get_color(heat_values[p.index]);
    //       colors[p.index] = heat_lut.get_color((int)heat_value_knob.getValue());
    //       System.out.format("heat lut [%d] = 0x%08X = 0x%08X\n", p.index, heat_lut[160], colors[p.index]);
    //    }

    // load our local copy of the points to keep everything in line
    int ix = 0;  // index of the current pixel on our bar, local frame
    for(LXPoint p : bar.points) {
      // TODO: check which orientation of the bar is the bottom!
      if(reverse_direction) {
        heat[(num_leds-1) - ix++] = heat_values[p.index];
      }
      else {
        heat[ix++] = heat_values[p.index];
      }
    }

    // Step 1.  Cool down every cell a little
    for( int i = 0; i < num_leds; i++) {
      int cool = randInt(0, (int)((cooling * 10) / num_leds) + 2);
      heat[i] = subtract_floor(heat[i], cool);
    }

    // Step 2.  Heat from each cell drifts 'up' and diffuses a little
    for( int k= num_leds - 1; k >= 2; k--) {
      heat[k] = (heat[k - 1] + heat[k - 2] + heat[k - 2] ) / 3;
    }

    // Step 3.  Randomly ignite new 'sparks' of heat near the bottom
    if( rand.nextInt(255) < sparking ) {
      int y = randInt(0, 7);  // start spark this distance from bottom
      heat[y] = add_ceil(heat[y], randInt(160,255));
    }

    // update pattern values array
    ix = 0;  // index of the current pixel on our bar, local frame
    for(LXPoint p : bar.points) {
      if(reverse_direction) {
        heat_values[p.index] = heat[(num_leds-1) - ix++];
      }
      else {
        heat_values[p.index] = heat[ix++];
      }
      // heat_values[p.index] = heat[ix++];
      // System.out.format("[%d]=%d\n", p.index, heat_values[p.index]);
    }

  }

  // return true if highest point index is lowest z
  private boolean is_reversed(Bar bar) {
    boolean high_index_is_low_z = false;
    if (bar.points[0].z < bar.points[bar.points.length-1].z)
      high_index_is_low_z = true;
    return high_index_is_low_z;
  }

  private void updateDodecahedron(double deltaMs){
    // make the dodecahedron twinkle
    GraphModel dodecahedron;
    dodecahedron = model.getLayer(DD);
    float ddFade = 1.0 - (fadeRate.getValuef() * (float)deltaMs / 1000.0);
    fade(dodecahedron.points, ddFade);

    ArrayList<LXPoint> twinklePoints = dodecahedron
        .getRandomPoints((int)rate.getValuef());
    for(LXPoint p: twinklePoints) {
      int hueShift = rand.nextInt((int)hueWidth.getValuef());
      float curHue = (hue.getValuef() + hueShift - hueShift / 2) % 360;
      colors[p.index] = lx.hsb(curHue, 100, 100);
    }
  }


  /**
   * Scale the target value from [0, 255] to [0, target_max] range
   */
  private int scale8(int value, int target_max) {
    return (int)(target_max * value) / 255;
  }

  private int subtract_floor(int a, int b) {
    return Math.max(0, a - b);
  }

  private int add_ceil(int a, int b) {
    return Math.min(a+b, 255);
  }

  /**
   * Returns a pseudo-random number between min and max, inclusive.
   * The difference between min and max can be at most
   * <code>Integer.MAX_VALUE - 1</code>.
   *
   * @param min Minimum value
   * @param max Maximum value.  Must be greater than min.
   * @return Integer between min and max, inclusive.
   * @see java.util.Random#nextInt(int)
   */
  public int randInt(int min, int max) {
    // Better would be:
    // import java.util.concurrent.ThreadLocalRandom;
    // nextInt is normally exclusive of the top value,
    // so add 1 to make it inclusive
    //int randomNum = ThreadLocalRandom.current().nextInt(min, max + 1);


    // nextInt is normally exclusive of the top value,
    // so add 1 to make it inclusive
    int randomNum = rand.nextInt((max - min) + 1) + min;

    return randomNum;
  }

}

