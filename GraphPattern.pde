/** Pattern Ideas.
 *
 * Tracers extend from a single node along all bars of dodecahedron.
 * Split and recombine at each node but keep tracing greater graph distance.
 * Color bars/points as a function of graph distance. Sparkle tetrahedra bars
 * whenever getting to a point connecting back to first node (i.e. at graph
 * distance 3). Color Tetrahedra by lerp from node colors.
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




/** *********************************************************** TETRA BAR TEST
 * Light each bar a different color, and blank the black pixel
 ****************************************************************************/

public class TetraBarTest extends GraphPattern {
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

  public TetraBarTest(LX lx) {
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



/** ********************************************************* TETRAHEDRON TEST
 * Light each tetrahedron a different color, and blank the black pixel
 ****************************************************************************/

public class TetrahedronTest extends GraphPattern {
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

  public TetrahedronTest(LX lx) {
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
      if (t>=2 && t<5) { continue; }
      if (t>=7 && t<10) { continue; }
      GraphModel tetra = tetrahedra.get(t);
      float db = dBrt / (float)tetra.bars.length ;
      float ds = dSat / (float)tetra.bars.length ;
      hue = (float)t * dHue + baseHue;
      sat = LXUtils.constrainf(bSat - (float)t * ds, 0., 100.);
      brt = LXUtils.constrainf(bBrt + (float)t * db, 0., 100.);
      for (int b = 0; b < tetra.bars.length; b++) {
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






/** ********************************************************* TETRAHEDRON TEST
 * Light each tetrahedron a different color, and blank the black pixel
 ****************************************************************************/

/*
public class TetrahedronTest extends LXPattern {
  private final BoundedParameter colorSpread
      = new BoundedParameter("CLR", 60.0, 0.0, 360.0);
  private final BoundedParameter cycleSpeed
      = new BoundedParameter("SPD",  1., 0., 20.);
  //private final ColorParameter clr
  //    = new ColorParameter("COLOR", LXColor.hsb(Math.random() * 360, 100, 100));
  //private final FunctionalParameter period = new FunctionalParameter() {
  //  @Override
  //  public double getValue() {
  //    return (1000 / speed.getValue()) * lx.total;
  //  }
  //};

  private float baseHue = 0.0;
  private int pixelsPerChannel = 123;
  private int channelCount = 5;

  public TetrahedronTest(LX lx) {
    super(lx);
    addParameter(colorSpread);
    addParameter(cycleSpeed);
    //addParameter(clr);
  }

  public void run(double deltaMs) {
    int pixel = 0;
    float hue = 0.0;
    baseHue += Math.log(cycleSpeed.getValuef());
    baseHue %= 360.;
    for (int channel = 0; channel < channelCount; channel++) {
      hue = (float)channel * (float)colorSpread.getValue() + baseHue;
      for (int p = 0; p < pixelsPerChannel; p++) {
        colors[pixel++] = lx.hsb(hue,100.,30.);
      }
    }
  }
}

*/



/** ********************************************************* TETRAHEDRON SPIN
 * Spin around showing a single tetrahedron at a time.
 ****************************************************************************/

public class TetraSpin extends GraphPattern {

  // rotations per second
  private final BoundedParameter rotateSpeed
      = new BoundedParameter("Spin", 4.0, 0.0, 10.0);
  /*
  private final BoundedParameter colorAttk
      = new BoundedParameter("Attk", 300.0, 1.0, 1000.0);
  private final BoundedParameter colorFade
      = new BoundedParameter("Fade", 300.0, 1.0, 1000.0);
  */
  // fraction of period in phase
  private final BoundedParameter colorAttk
      = new BoundedParameter("Attk", 1.0, 0.0, 2.0);
  private final BoundedParameter colorFade
      = new BoundedParameter("Fade", 1.0, 0.0, 10.0);

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







/** ****************************************************** TETRAHEDRON MAPPING
 * Show the mapping for a single channel of a tetrahedron.
 ****************************************************************************/

public class MappingTetrahedron extends GraphPattern {

  float hueRange = 270.f;
  //float dHue     =  30.f;
  float baseHue  =  0.f;
  float baseSat  = 80.f;
  float baseBrt  = 90.f;

  public MappingTetrahedron(LX lx) {
    super(lx);
    //for (GraphModel g: model.tetraL.subGraphs) { tetrahedra.add(g); }
    //for (GraphModel g: model.tetraR.subGraphs) { tetrahedra.add(g); }
  }

  public void run(double deltaMs) {

    for (LXPoint p: model.getLayer(DD).points) {
      colors[p.index] = LXColor.hsb(0.0,0.0,40.0);
    }
    for (LXPoint p: model.getLayer(TL).points) {
      colors[p.index] = LXColor.hsb(0.0,0.0,20.0);
    }
    for (LXPoint p: model.getLayer(TR).points) {
      colors[p.index] = LXColor.hsb(0.0,0.0,20.0);
    }


    for (int i = 0; i < 5; i++) { 
      GraphModel tetraL = model.getLayer(TL).getLayer(i);
      GraphModel tetraR = model.getLayer(TR).getLayer(i);
      Bar bar0 = tetraL.bars[0];
      float dHue = hueRange / ((float)tetraL.bars.length) / ((float)bar0.points.length);
      float hue = 0.0;
      for (int b = 0; b < tetraL.bars.length; b++) {
        Bar bar = tetraL.bars[b];
        for (LXPoint p: bar.points) {
          colors[p.index] = lx.hsb(hue,baseSat,baseBrt);
          hue += dHue;
        }
      }

      hue = 0.0;
      for (int b = 0; b < tetraR.bars.length; b++) {
        Bar bar = tetraR.bars[b];
        for (LXPoint p: bar.points) {
          colors[p.index] = lx.hsb(hue,baseSat,baseBrt);
          hue += dHue;
        }
      }
    }
  }
}




/** ****************************************************** Dodecahedron MAPPING
 * Show the mapping for a single channel of a tetrahedron.
 ****************************************************************************/

public class MappingDodecahedron extends GraphPattern {

  float hueRange = 270.f;
  //float dHue     =  30.f;
  float baseHue  =  0.f;
  float baseSat  = 80.f;
  float baseBrt  = 90.f;

  LXPoint point;

  public MappingDodecahedron(LX lx) {
    super(lx);
    //for (GraphModel g: model.tetraL.subGraphs) { tetrahedra.add(g); }
    //for (GraphModel g: model.tetraR.subGraphs) { tetrahedra.add(g); }
  }

  public void run(double deltaMs) {

    for (LXPoint p: model.getLayer(DD).points) {
      colors[p.index] = LXColor.hsb(0.0,0.0,40.0);
    }
    for (LXPoint p: model.getLayer(TL).points) {
      colors[p.index] = LXColor.hsb(0.0,0.0,20.0);
    }
    for (LXPoint p: model.getLayer(TR).points) {
      colors[p.index] = LXColor.hsb(0.0,0.0,20.0);
    }

    GraphModel dodeca = model.getLayer(DD);
    //GraphModel tetraL = model.getLayer(TL).getLayer(0);
    //GraphModel tetraR = model.getLayer(TR).getLayer(0);
    Bar bar0 = dodeca.bars[0];
    //float dHue = hueRange / ((float)dodeca.bars.length) / ((float)bar0.points.length);
    //float dHue = hueRange / ((float)dodeca.bars.length);
    float dHue = 1.0;
    float hue = 0.0;
    for (int b = 0; b < dodeca.bars.length; b++) {
      if (b >= 6) { continue; }
      Bar bar = dodeca.bars[b];
      for (LXPoint p: bar.points) {
        colors[p.index] = lx.hsb(hue,baseSat,baseBrt);
        hue += dHue;
      }
    }
  }
}


/** ********************************************************** TEST BAR MATRIX
 *
 ****************************************************************************/

public class TestBarMatrix extends GraphPattern {

  private final DiscreteParameter method = new DiscreteParameter("GEN", 1, 1, 5);
  private final BoundedParameter speed = new BoundedParameter("SPD",  5000, 0, 10000);
  private final BoundedParameter fadeRate =
    new BoundedParameter("FADE", 10.0, 0.0, 1000.0);

  //private final SinLFO xPeriod = new SinLFO(100, 1000, 10000);
  private final SinLFO position = new SinLFO(0.0, 1.0, speed);


  float thisPos = 0.0;
  float lastPos = 0.0;
  float hueRange = 270.f;
  //float dHue     =  30.f;
  float baseHue  =  0.f;
  float baseSat  = 80.f;
  float baseBrt  = 90.f;

  LXPoint point;

  public TestBarMatrix(LX lx) {
    super(lx);
    addParameter(method);
    addParameter(speed);
    addParameter(fadeRate);
    addModulator(position).start();
    //for (GraphModel g: model.tetraL.subGraphs) { tetrahedra.add(g); }
    //for (GraphModel g: model.tetraR.subGraphs) { tetrahedra.add(g); }
  }

  public void run(double deltaMs) {

    float hue = 0.0;
    float sat = 100.0;
    float brt = 100.0;

    thisPos = position.getValuef();
    boolean rev = thisPos >= lastPos;
    lastPos = thisPos;

    // Fade everything
    fade(model.points, fadeRate.getValuef() * (float)deltaMs / 1000.0);

    int M = method.getValuei();

    // Chase up one bar and back down its reverse
    if (M == 1) {
      int i, s;
      for (Bar _bar : model.bars) {
        Bar bar = _bar;
        s = bar.points.length;
        i = LXUtils.constrain((int)((float)s * thisPos), 0, s-1);
        if (rev) {
          bar = _bar.reversed();
          hue = 270.0;
          i = s-i-1;
        }
        //System.out.format("Bar[%2d][%2d] R: %s   P: %8.2f   S: %3d   I: %3d\n",
        //  bar.node1.index, bar.node2.index, rev, thisPos, s, i);
        colors[bar.points[i].index] = lx.hsb(hue,sat,brt);
      }

    // Chase up one bar and back down its reverse by looking it up in barMatrix
    } else if (M == 2) {
      int i, s;
      for (Bar _bar : model.bars) {
        Bar bar = _bar;
        s = bar.points.length;
        i = LXUtils.constrain((int)((float)s * thisPos), 0, s-1);
        if (rev) {
          bar = model.getBar(bar.node2, bar.node1);
          hue = 270.0;
          i = s-i-1;
        }
        //System.out.format("Bar[%2d][%2d] R: %s   P: %8.2f   S: %3d   I: %3d\n",
        //  bar.node1.index, bar.node2.index, rev, thisPos, s, i);
        colors[bar.points[i].index] = lx.hsb(hue,sat,brt);
      }

    // Color by bar direction
    } else if (M == 3) {
      for (Bar bar : model.bars) {
        if (bar.node1.index < bar.node2.index) {
          for (LXPoint p: bar.points) {
            colors[p.index]= lx.hsb(0.0, baseSat, baseBrt);
          }
        } else {
          for (LXPoint p: bar.points) {
            colors[p.index]= lx.hsb(180.0, baseSat, baseBrt);
          }
        }
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
 * @author Geoff Schmiddt
 *
 * @author Mike Pesavento, adding EEG mapping to parameters, heavy edits
 ************************************************************************* **/

public class PixiePattern extends GraphPattern {
  // How many pixies are zipping around.
  private final BoundedParameter numPixies =
      new BoundedParameter("NUM", 100, 0, 1000);
  // How fast each pixie moves, in pixels per second.
  private final BoundedParameter speed =
      new BoundedParameter("SPD", 50.0, 10.0, 150.0);
  // How long the trails persist. (Decay factor for the trails, each frame.)
  // XXX really should be scaled by frame time
  private final BoundedParameter fade =
      new BoundedParameter("FADE", 0.9, 0.8, .97);
  // Brightness adjustment factor.
  private final BoundedParameter brightness =
      new BoundedParameter("BRIGHT", 1.0, .25, 2.0);
  private final BoundedParameter colorHue = new BoundedParameter("HUE", 210, 0, 359.0);
  private final BoundedParameter colorSat = new BoundedParameter("SAT", 63.0, 0.0, 100.0);


  class Pixie {
    public Node fromNode, toNode;
    public double offset;
    public int kolor;

    public Pixie() {
      // Nothing to do in here, just a holder for attributes
    }
  }
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



