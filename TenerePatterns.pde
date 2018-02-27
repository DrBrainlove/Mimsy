//Borrowed from Tree of Tenere (https://github.com/treeoftenere/Tenere)
 
 
 public static class Wave extends LXPattern {
  // by Mark C. Slee
  
  public final CompoundParameter size =
    new CompoundParameter("Size", 4*FEET, 28*FEET)
    .setDescription("Width of the wave");
    
  public final CompoundParameter rate =
    new CompoundParameter("Rate", 6000, 18000)
    .setDescription("Rate of the of the wave motion");
  
  public final SawLFO phase = new SawLFO(0, TWO_PI, rate);
  
  public final double[] bins = new double[512];
  
  public Wave(LX lx) {
    super(lx);
    startModulator(phase);
    addParameter(size);
    addParameter(rate);
  }
    
  public void run(double deltaMs) {
    double phaseValue = phase.getValue();
    float falloff = 100 / size.getValuef();
    for (int i = 0; i < bins.length; ++i) {
      bins[i] = model.cy + model.yRange/2 * Math.sin(i * TWO_PI / bins.length + phaseValue);
    }
    for (LXPoint p : model.points) {
      int idx = Math.round((bins.length-1) * (p.x - model.xMin) / model.xRange);
      float y1 = (float) bins[idx];
      float y2 = (float) bins[(idx*4 / 3 + bins.length/2) % bins.length];
      float b1 = max(0, 100 - falloff * abs(p.y - y1));
      float b2 = max(0, 100 - falloff * abs(p.y - y2));
      float b = max(b1, b2);
      colors[p.index] = b > 0 ? palette.getColor(p, b) : #000000;
    }
  }
}

public static class Swirl extends LXPattern {
  // by Mark C. Slee
  
  public final SinLFO xPos = new SinLFO(model.xMin, model.xMax, startModulator(
    new SinLFO(19000, 39000, 51000).randomBasis()
  ));
    
  public final SinLFO yPos = new SinLFO(model.yMin, model.yMax, startModulator(
    new SinLFO(19000, 39000, 57000).randomBasis()
  ));
  
  public final CompoundParameter swarmBase = new CompoundParameter("Base",
    12*INCHES,
    1*INCHES,
    140*INCHES
  );
  
  public final CompoundParameter swarmMod = new CompoundParameter("Mod", 0, 120*INCHES);
  
  public final SinLFO swarmSize = new SinLFO(0, swarmMod, 19000);
  
  public final SawLFO pos = new SawLFO(0, 1, startModulator(
    new SinLFO(1000, 9000, 17000)
  ));
  
  public final SinLFO xSlope = new SinLFO(-1, 1, startModulator(
    new SinLFO(78000, 104000, 17000).randomBasis()
  ));
  
  public final SinLFO ySlope = new SinLFO(-1, 1, startModulator(
    new SinLFO(37000, 79000, 51000).randomBasis()
  ));
  
  public final SinLFO zSlope = new SinLFO(-.2, .2, startModulator(
    new SinLFO(47000, 91000, 53000).randomBasis()
  ));
  
  public Swirl(LX lx) {
    super(lx);
    addParameter(swarmBase);
    addParameter(swarmMod);
    startModulator(xPos.randomBasis());
    startModulator(yPos.randomBasis());
    startModulator(pos);
    startModulator(swarmSize);
    startModulator(xSlope);
    startModulator(ySlope);
    startModulator(zSlope);
  }
  
  public void run(double deltaMs) {
    final float xPos = this.xPos.getValuef();
    final float yPos = this.yPos.getValuef();
    final float pos = this.pos.getValuef();
    final float swarmSize = this.swarmBase.getValuef() + this.swarmSize.getValuef();
    final float xSlope = this.xSlope.getValuef();
    final float ySlope = this.ySlope.getValuef();
    final float zSlope = this.zSlope.getValuef();
    
    for (LXPoint p : model.points) {
      float radix = (xSlope*(p.x-model.cx) + ySlope*(p.y-model.cy) + zSlope*(p.z-model.cz)) % swarmSize; // (p.x - model.xMin + p.y - model.yMin) % swarmSize;
      float dist = dist(p.x, p.y, xPos, yPos); 
      float size = max(20*INCHES, 2*swarmSize - .5*dist);
      float b = 100 - (100 / size) * LXUtils.wrapdistf(radix, pos * swarmSize, swarmSize);
      colors[p.index] = (b > 0) ? palette.getColor(p, b) : #000000;
    }
  }
}

public static class Rotors extends LXPattern {
  // by Mark C. Slee
  
  public final SawLFO aziumuth = new SawLFO(0, PI, startModulator(
    new SinLFO(11000, 29000, 33000)
  ));
  
  public final SawLFO aziumuth2 = new SawLFO(PI, 0, startModulator(
    new SinLFO(23000, 49000, 53000)
  ));
  
  public final SinLFO falloff = new SinLFO(200, 900, startModulator(
    new SinLFO(5000, 17000, 12398)
  ));
  
  public final SinLFO falloff2 = new SinLFO(250, 800, startModulator(
    new SinLFO(6000, 11000, 19880)
  ));
  
  public Rotors(LX lx) {
    super(lx);
    startModulator(aziumuth);
    startModulator(aziumuth2);
    startModulator(falloff);
    startModulator(falloff2);
  }
  
  public void run(double deltaMs) {
    float aziumuth = this.aziumuth.getValuef();
    float aziumuth2 = this.aziumuth2.getValuef();
    float falloff = this.falloff.getValuef();
    float falloff2 = this.falloff2.getValuef();
    for (LXPoint p : model.points) {
      float yn = (1 - .8 * (p.y - model.yMin) / model.yRange);
      float fv = .3 * falloff * yn;
      float fv2 = .3 * falloff2 * yn;
      float b = max(
        100 - fv * LXUtils.wrapdistf(p.azimuth, aziumuth, PI),
        100 - fv2 * LXUtils.wrapdistf(p.azimuth, aziumuth2, PI)
      );
      b = max(30, b);
      float s = constrain(50 + b/2, 0, 100);
      colors[p.index] = palette.getColor(p, s, b);
      
    }
  }
}

public static class DiamondRain extends LXPattern {
  // by Mark C. Slee
 
  public final static int NUM_DROPS = 24; 
  
  public DiamondRain(LX lx) {
    super(lx);
    for (int i = 0; i < NUM_DROPS; ++i) {
      addLayer(new Drop(lx));
    }
  }
  
  public void run(double deltaMs) {
    setColors(#000000);
  }
  
  public class Drop extends LXLayer {
    
    public final float MAX_LENGTH = 14*FEET;
    
    public final SawLFO yPos = new SawLFO(model.yMax + MAX_LENGTH, model.yMin - MAX_LENGTH, 4000 + Math.random() * 3000);
    public float azimuth;
    public float azimuthFalloff;
    public float yFalloff;
    
    Drop(LX lx) {
      super(lx);
      startModulator(yPos.randomBasis());
      init();
    }
    
    private void init() {
      this.yPos.setPeriod(2500 + Math.random() * 11000);
      azimuth = (float) Math.random() * TWO_PI;
      azimuthFalloff = 140 + 340 * (float) Math.random();
      yFalloff = 100 / (2*FEET + 12*FEET * (float) Math.random());
    }
    
    public void run(double deltaMs) {
      float yPos = this.yPos.getValuef();
      if (this.yPos.loop()) {
        init();
      }
      for (LXPoint p : model.points) {
        float yDist = abs(p.y - yPos);
        float azimuthDist = abs(p.azimuth - azimuth); 
        float b = 100 - yFalloff*yDist - azimuthFalloff*azimuthDist;
        if (b > 0) {
          addColor(p.index, palette.getColor(p, b));
        }
      }
    }
  }  
}

//public class Azimuth extends LXPattern {
  
//  public final CompoundParameter azim = new CompoundParameter("Azimuth", 0, TWO_PI);  
  
//  public Azimuth(LX lx) {
//    super(lx);
//    addParameter("azim", this.azim);
//  }
  
//  public void run(double deltaMs) {
//    float azim = this.azim.getValuef();
//    for (Branch b : tree.branches) {
//      setColor(b, LX.hsb(0, 0, max(0, 100 - 400 * LXUtils.wrapdistf(b.azimuth, azim, TWO_PI))));
//    }
//  }
//}

//public class AxisTest extends LXPattern {
  
//  public final CompoundParameter xPos = new CompoundParameter("X", 0);
//  public final CompoundParameter yPos = new CompoundParameter("Y", 0);
//  public final CompoundParameter zPos = new CompoundParameter("Z", 0);
  
//  public AxisTest(LX lx) {
//    super(lx);
//    addParameter("xPos", xPos);
//    addParameter("yPos", yPos);
//    addParameter("zPos", zPos);
//  }
  
//  public void run(double deltaMs) {
//    float x = this.xPos.getValuef();
//    float y = this.yPos.getValuef();
//    float z = this.zPos.getValuef();
//    for (LXPoint p : model.points) {
//      float d = abs(p.xn - x);
//      d = min(d, abs(p.yn - y));
//      d = min(d, abs(p.zn - z));
//      colors[p.index] = palette.getColor(p, max(0, 100 - 1000*d));
//    }
//  }
//}

//public class Swarm extends LXPattern {
  
//  private static final int NUM_GROUPS = 5;
  
//  public final CompoundParameter speed = new CompoundParameter("Speed", 2000, 10000, 500);
//  public final CompoundParameter base = new CompoundParameter("Base", 10, 60, 1);
  
//  public final LXModulator[] pos = new LXModulator[NUM_GROUPS];
  
//  public final LXModulator swarmX = startModulator(new SinLFO(
//    startModulator(new SinLFO(0, .2, startModulator(new SinLFO(3000, 9000, 17000).randomBasis()))),
//    startModulator(new SinLFO(.8, 1, startModulator(new SinLFO(4000, 7000, 15000).randomBasis()))),
//    startModulator(new SinLFO(9000, 17000, 33000).randomBasis())
//  ).randomBasis());
  
//  public final LXModulator swarmY = startModulator(new SinLFO(
//    startModulator(new SinLFO(0, .2, startModulator(new SinLFO(3000, 9000, 19000).randomBasis()))),
//    startModulator(new SinLFO(.8, 1, startModulator(new SinLFO(4000, 7000, 13000).randomBasis()))),
//    startModulator(new SinLFO(9000, 17000, 33000).randomBasis())
//  ).randomBasis());
  
//  public Swarm(LX lx) {
//    super(lx);
//    addParameter("speed", speed);
//    addParameter("base", base);
//    for (int i = 0; i < pos.length; ++i) {
//      final int ii = i;
//      pos[i] = new SawLFO(0, LeafAssemblage.NUM_LEAVES, new FunctionalParameter() {
//        public double getValue() {
//          return speed.getValue() + ii*500; 
//      }}).randomBasis();
//      startModulator(pos[i]);
//    }
//  }
  
//  public void run(double deltaMs) {
//    int i = 0;
//    float base = this.base.getValuef();
//    float swarmX = this.swarmX.getValuef();
//    float swarmY = this.swarmY.getValuef();
//    for (LeafAssemblage assemblage : tree.assemblages) {
//      float pos = this.pos[i++ % NUM_GROUPS].getValuef();
//      for (Leaf leaf : assemblage.leaves) {
//        float falloff = min(100, base + 40 * dist(leaf.point.xn, leaf.point.yn, swarmX, swarmY));  
//        colors[leaf.point.index] = palette.getColor(leaf.point, max(20, 100 - falloff*LXUtils.wrapdistf(leaf.orientation.index, pos, LeafAssemblage.LEAVES.length)));
//      }
//    }
//  }
//}
 
 public class Turbulence extends LXPattern {
  // by Alexander Green 

  public class FluidData implements DwFluid2D.FluidData{
    
    // update() is called during the fluid-simulation update step.
    @Override
    public void update(DwFluid2D fluid) {
    
      float px, py, vx, vy, radius, vscale, r, g, b, intensityV, temperature;
      
      // add impulse: density + temperature
      intensityV = 0.2f*intensity.getValuef();
      px = 1*200/3;
      py = 0;
      radius = 30*size.getValuef();
      r = 0.0f;
      g = 0.3f;
      b = 1.0f;
      fluid.addDensity(px, py, radius, r, g, b, intensityV);

      if((fluid.simulation_step) % 200 == 0){
        temperature = 50f;
        fluid.addTemperature(px, py, radius, temperature);
      }
      
      // add impulse: density + temperature
      float animator = sin(fluid.simulation_step*0.01f);
 
      intensityV = 1.0f*intensity.getValuef();
      px = 2*200/3f;
      py = 150;
      radius = 25*size.getValuef();
      r = 0.3f;
      g = 0.2f;
      b = 0.8f;
      fluid.addDensity(px, py, radius, r, g, b, intensityV);
      
      temperature = animator * 20f;
      fluid.addTemperature(px, py, radius, temperature);
      
      
      // add impulse: density 
      px = 1*200/3f;
      py = 200-2*200/3f;
      radius = 20.0f*size.getValuef();
      r = g = 150/255f;
      b = 1f;
      intensityV = 1.0f*intensity.getValuef();
      fluid.addDensity(px, py, radius, r, g, b, intensityV, 3);

        
      // add impulse: density 
      px = 200f/1.5;
      py = 200-2*200/3f;
      radius = 20.0f*size.getValuef();
      r = b = 115/255f;
      g =0.0f;

      intensityV = 1.0f*intensity.getValuef();
      fluid.addDensity(px, py, radius, r, g, b, intensityV, 3);
    }
  }
  
 //fluid system
  int viewport_w = 200;
  int viewport_h = 200;
  final int SIZE_OF_FLUID = viewport_h*viewport_w;
  int fluidgrid_scale = 1;
  
  DwPixelFlow context; 
  DwFluid2D fluid;
  //ObstaclePainter obstacle_painter;
  PGraphics2D pg_fluid;   // render targets
  PGraphics2D pg_obstacles;   //texture-buffer, for adding obstacles
  PGraphics2D pg_fluid2; //extra buffer for debugging 
  PImage moss = loadImage("../data/MossyTrees.jpg");
  // some state variables for the GUI/display
  int     BACKGROUND_COLOR           = 0;
  boolean UPDATE_FLUID               = true;
  boolean DISPLAY_FLUID_TEXTURES     = true;
  boolean DISPLAY_FLUID_VECTORS      = false;
  // int     fluidDisplayMode = 2;
  int[] tempColors = new int[SIZE_OF_FLUID + 200]; //200 is to add extra pixels in

  public GraphicMeter eq = null;
  
  public final DiscreteParameter fluidDisplayMode =
    new DiscreteParameter("Mode", 0, 4 )
    .setDescription("Fluid Display Mode");

  public final DiscreteParameter colorMode =
    new DiscreteParameter("Colors", 0, 4)
    .setDescription("Switch Between Coloring Schemes");
  public final CompoundParameter speed =
    new CompoundParameter("Speed", 6000, 18000)
    .setDescription("Speed of fluid movement");
  public final CompoundParameter size =
    new CompoundParameter("size", 1, 0, 3)
    .setDescription("Size of fluid sources");
    public final CompoundParameter intensity =
    new CompoundParameter("intensity", 1, 0, 3)
    .setDescription("intensity");
  
  private final SawLFO phase = new SawLFO(0, TWO_PI, speed);
  
  private final double[] bins = new double[512];
  
  public Turbulence(LX lx) {
    super(lx);
    eq = new GraphicMeter(lx.engine.audio.input);
    startModulator(eq);
    startModulator(phase);
    addParameter(fluidDisplayMode);
    addParameter(colorMode);
    addParameter(speed);
    addParameter(size);
    addParameter(intensity);
    context = new DwPixelFlow(Mimsy.this);
    context.print();
    context.printGL();
    fluid = new DwFluid2D(context, 200, 200, 1);
    // set some simulation parameters
    fluid.param.dissipation_density     = 0.999f;
    fluid.param.dissipation_velocity    = 0.99f;
    fluid.param.dissipation_temperature = 0.80f;
    fluid.param.vorticity               = 0.10f;
    
    // interface for adding data to the fluid simulation
    FluidData fluidData = new FluidData();
    fluid.addCallback_FluiData(fluidData);
   
    //pgraphics for fluid
    pg_fluid = (PGraphics2D) createGraphics(200, 200, P2D);
    pg_fluid.smooth(4);
    pg_fluid.beginDraw();
    pg_fluid.background(BACKGROUND_COLOR);
    pg_fluid.endDraw();
    pg_fluid.loadPixels();
    // // pgraphics for obstacles
    // pg_obstacles = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
    // pg_obstacles.smooth(0);
    // pg_obstacles.beginDraw();
    // pg_obstacles.clear();
    // // circle-obstacles
    // pg_obstacles.strokeWeight(10);
    // pg_obstacles.noFill();
    // pg_obstacles.noStroke();
    // pg_obstacles.fill(64);
    // float radius;
    // radius = 100;
    // pg_obstacles.ellipse(1*width/3f,  2*_height/3f, radius, radius);
    // radius = 150;
    // pg_obstacles.ellipse(2*width/3f,  2*_height/4f, radius, radius);
    // radius = 200;
    // pg_obstacles.stroke(64);
    // pg_obstacles.strokeWeight(10);
    // pg_obstacles.noFill();
    // pg_obstacles.ellipse(1*width/2f,  1*_height/4f, radius, radius);
    // // border-obstacle
    // pg_obstacles.strokeWeight(20);
    // pg_obstacles.stroke(64);
    // pg_obstacles.noFill();
    // pg_obstacles.rect(0, 0, pg_obstacles.width, pg_obstacles._height);

    // pg_obstacles.endDraw();
    
    // public class, that manages interactive drawing (adding/removing) of obstacles
    //obstacle_painter = new ObstaclePainter(pg_obstacles);
  }

    public void fluid_reset(){
      fluid.reset();
    }
    public void fluid_togglePause(){
      UPDATE_FLUID = !UPDATE_FLUID;
    }
    public void fluid_displayMode(int val){
   //   fluidDisplayMode = val;
     // DISPLAY_FLUID_TEXTURES = fluidDisplayMode != -1;
    }
    public void fluid_displayVelocityVectors(int val){
      DISPLAY_FLUID_VECTORS = val != -1;
    }

  public void run(double deltaMs) {
    // update simulation
    if(UPDATE_FLUID){
   //   fluid.addObstacles(pg_obstacles)
      fluid.update();
    }
    // clear render target
    pg_fluid.beginDraw();
    pg_fluid.background(BACKGROUND_COLOR);
    pg_fluid.endDraw();
    // render fluid stuff
    //pg_fluid.loadPixels();
    //println("pg_fluid pixels loaded: " + pg_fluid.loaded);
    if(DISPLAY_FLUID_TEXTURES){
       //render: density (0), temperature (1), pressure (2), velocity (3)
      fluid.renderFluidTextures(pg_fluid, fluidDisplayMode.getValuei());

    }
    
      //println("fluid pixels loaded: " + fluid.loaded);
      // render: velocity vector field
    // fluid.renderFluidVectors(pg_fluid, 10);
    
    // display

    //  image(pg_fluid, 200, 0);
   // image(pg_obstacles, 0, 0);
   //   pg_fluid.loadPixels();

     pg_fluid.loadPixels();
     for (int x=0; x<pg_fluid.width; x++){
      for (int y=0; y<pg_fluid.height; y++){
        int location = x + y*pg_fluid.width; 
        tempColors[location]=pg_fluid.pixels[location];
       }
     }
     pg_fluid.updatePixels();


    for (LXPoint p : model.points) {
      float positionX = abs((p.x - model.xMin)/(model.xMax - model.xMin)); //to-do: make this faster by caching this 
      float positionY = abs((p.z - model.zMin)/(model.zMax - model.zMin));
      int fluidPixelX= floor(positionX*pg_fluid.width);  //gets the corresponding pixel in the fluid data array 
      int fluidPixelY= floor(positionY*pg_fluid.height);  
      int pixel = fluidPixelX + fluidPixelY*(pg_fluid.width);
      //println("fluidpixelX: "+fluidPixelX + "fluidpixelY: " + fluidPixelY);
      // int r = (tempColors[i] >> 16) & OxFF;
      // int g = (tempColors[i] >> 8) & OxFF;
      // int b = tempColors[i] & OxFF;
      switch(colorMode.getValuei()) {
        case 0: colors[p.index] = tempColors[pixel]; 
                break;
        case 1: float b = brightness(tempColors[pixel]);
                colors[p.index] = b > 0 ? palette.getColor(p, b) : #000000;
                break;
        case 2: float _b = brightness(tempColors[pixel]);
                colors[p.index] = _b > 0 ? moss.get(fluidPixelX,fluidPixelY) : #000000;
          

          }
      
      }
    
  }
}
 
 
