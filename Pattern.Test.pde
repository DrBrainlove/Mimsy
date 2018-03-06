

/*****************************************************************************
 *    PATTERNS PRIMARILY INTENDED TO DEMO CONCEPTS, BUT NOT BE DISPLAYED
 ****************************************************************************/
public class BlankPattern extends LXPattern {
  public BlankPattern(LX lx) {
    super(lx);
  }

  public void run(double deltaMs) {
    setColors(#000000);
  }
}





/** ***************************************************************** GRADIENT
 * Example public class making use of LXPalette's X/Y/Z interpolation to set
 * the color of each point in the model
 * @author Scouras
 ************************************************************************* **/

public class GradientPattern extends LXPattern {
  public GradientPattern(LX lx) {
    super(lx);
  }

  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      colors[p.index] = palette.getColor(p);
    }
  }
}





/** ********************************************************** TEST TETRA BARS
 * Light each bar a different color, and blank the black pixel
 ****************************************************************************/

public class TestTetraBars extends GraphPattern {
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

  public TestTetraBars(LX lx) {
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



/** ********************************************************** TEST TETRAHEDRA
 * Light each tetrahedron a different color, and blank the black pixel
 ****************************************************************************/

public class TestTetrahedra extends GraphPattern {
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

  public TestTetrahedra(LX lx) {
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



/** **************************************************** TEST BAR REGISTRATION
 * Show Pixels At the End of Each Bar
 ****************************************************************************/

public class TestBarRegistration extends GraphPattern {


  private final CompoundParameter brtMid
      = new CompoundParameter("brtMid", 10.0, 0.0, 100.0);
  private final CompoundParameter brtEnd
      = new CompoundParameter("brtEnd", 100.0, 0.0, 100.0);

  int buffer = 1;
  int length;
  float hue =   0.0;
  float sat = 100.0;
  float brt =  10.0;

  GraphModel gmDD = model.getLayer(DD);
  GraphModel gmTL = model.getLayer(TL);
  GraphModel gmTR = model.getLayer(TR);

  public TestBarRegistration(LX lx) {
    super(lx);
    addParameter(brtMid);
    addParameter(brtEnd);
  }

  public void run(double deltaMs) {


    hue = 0.0;
    brt = brtMid.getValuef();
    for (LXPoint p: gmDD.points) {
      colors[p.index] = LXColor.hsb(hue,sat,brt);
    }
    hue = 120.0;
    for (LXPoint p: gmTL.points) {
      colors[p.index] = LXColor.hsb(hue,sat,brt);
    }
    hue = 240.0;
    for (LXPoint p: gmTR.points) {
      colors[p.index] = LXColor.hsb(hue,sat,brt);
    }
    
    hue =   0.0;
    brt = brtEnd.getValuef();
    length = gmDD.bars[0].points.length;
    for (Bar bar: gmDD.bars) {
      for (int i = 0; i < buffer; i++) {
        colors[bar.points[i].index] = LXColor.hsb(hue,sat,brt);
        colors[bar.points[length-i-1].index] = LXColor.hsb(hue,sat,brt);
      }
    }


    hue = 120.0;
    length = gmTL.bars[0].points.length;
    for (Bar bar: gmTL.bars) {
      for (int i = 0; i < buffer; i++) {
        colors[bar.points[i].index] = LXColor.hsb(hue,sat,brt);
        colors[bar.points[length-i-1].index] = LXColor.hsb(hue,sat,brt);
      }
    }

    hue = 240.0;
    length = gmTR.bars[0].points.length;
    for (Bar bar: gmTR.bars) {
      for (int i = 0; i < buffer; i++) {
        colors[bar.points[i].index] = LXColor.hsb(hue,sat,brt);
        colors[bar.points[length-i-1].index] = LXColor.hsb(hue,sat,brt);
      }
    }


    colors[model.points[model.points.length-1].index] = LXColor.WHITE;

  }
}



/** ************************************************************** BUILD ORDER
 * Show Pixels At the End of Each Bar
 ****************************************************************************/



public class BuildOrder extends GraphPattern {


  private final int MAX_STEP = 18;
  private final DiscreteParameter buildStep
      = new DiscreteParameter("Step", 0, 0, 19);
  
  private final CompoundParameter dHue 
      = new CompoundParameter("dHue", 15.0, 0.0, 360.0);
  private final CompoundParameter brtPast
      = new CompoundParameter("BrtPast", 50.0, 0.0, 100.0);
  private final CompoundParameter brtFuture
      = new CompoundParameter("BrtFuture", 30.0, 0.0, 100.0);

  int buffer = 1;
  int length;
  float hue =   0.0;
  float sat = 100.0;
  float brt = 100.0;
  //float dHue = 15.0;

  GraphModel gmDD = model.getLayer(DD);
  GraphModel gmTL = model.getLayer(TL);
  GraphModel gmTR = model.getLayer(TR);

  List<Bar[]> barGroups = new ArrayList<Bar[]>();

  public BuildOrder(LX lx) {
    super(lx);
    addParameter(buildStep);
    addParameter(brtPast);
    addParameter(brtFuture);

    // Level A
    barGroups.add(getBarBatch(gmDD, 0)); // DD::A::A+1
    
    // Level B
    barGroups.add(getBarBatch(gmDD, 1)); // DD::A::B+0
    barGroups.add(getBarBatch(gmTL, 2)); // TL::A::B-2
    barGroups.add(getBarBatch(gmTR, 0)); // TR::A::B+2

    // Level C (Inner Tetrahedra)
    barGroups.add(getBarBatch(gmDD, 2)); // DD::B::C-1
    barGroups.add(getBarBatch(gmDD, 3)); // DD::B::C+0
    barGroups.add(getBarBatch(gmTL, 0)); // TL::A::C+1
    barGroups.add(getBarBatch(gmTL, 3)); // TL::B::C-2
    barGroups.add(getBarBatch(gmTR, 2)); // TR::A::C-2
    barGroups.add(getBarBatch(gmTR, 3)); // TR::C::B-1
    
    // Level D
    barGroups.add(getBarBatch(gmDD, 4)); // DD::C::D+0
    barGroups.add(getBarBatch(gmTL, 4)); // TL::A::D-1
    barGroups.add(getBarBatch(gmTR, 4)); // TR::A::D+0
    
    barGroups.add(getBarBatch(gmDD, 5)); // DD::D::D+1
    barGroups.add(getBarBatch(gmTL, 5)); // TL::D::B-1
    barGroups.add(getBarBatch(gmTL, 1)); // TL::C::D-2

    // Outer Tetrahedra
    barGroups.add(getBarBatch(gmTR, 1)); // TR::B::D-2
    barGroups.add(getBarBatch(gmTR, 5)); // TR::D::C-2
  }

  /**
   * Get the batch of 5 bars in a layer with given index
   */
  public Bar[] getBarBatch(GraphModel layer, int index) {
    Bar[] bars = new Bar[5];
    for (int i = 0; i < 5; i++) {
      bars[i] = layer.bars[i*6 + index];
    }
    return bars;
  }  

  public void run(double deltaMs) {

    int step = buildStep.getValuei();
    float h = hue;
        
    
    // Defaul to dim gray color
    for (LXPoint p: model.points) {
      colors[p.index] = LXColor.hsb(0.0, 0.0, brtFuture.getValuef());
    }

    // Previous steps colored in rainbow
    for (int s = 0; s < step; s++) {
      if (s >= MAX_STEP) { continue; }
      for (Bar bar : barGroups.get(s)) {
        for (LXPoint p: bar.points) {
          colors[p.index] = LXColor.hsb(h,sat,brtPast.getValuef());
        }
      }
      h += dHue.getValuef();
    }
  
    // Current step colored white
    if (step < MAX_STEP) {
      for (Bar bar : barGroups.get(step)) {
        for (LXPoint p: bar.points) {
          colors[p.index] = LXColor.hsb(h,0.0,brt);
        }
      }
    }


  }
}



/** ****************************************************** MAPPING TETRAHEDRON
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




/** ***************************************************** MAPPING DODECAHEDRON
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





