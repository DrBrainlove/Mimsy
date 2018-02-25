
static int PIXELS_PER_BAR = 100;

public static ArrayList<int[]> channelMap;


static String DD = "Dodecahedron";
static String TL = "TetraL";
static String TR = "TetraR";

public static final Dodecahedron dd = new Dodecahedron(RADIUS);









//***************************************************** MAPPING CONFIGURATIONS
/**
 * Generates the model from indiviual bars, and assigns them to channels.
 * Primary content includes the pixels per bar, the list of bars based on node
 * pairs, and the matrix of bars in each channel.
 **/

static class MimsyMap {

  String MimsyType = "MiniMim";

  int channelCount = 0;
  int pixelsDD;
  int pixelsTL;
  int pixelsTR;

  int barsTL[][] = new int[30][2];
  int barsTR[][] = new int[30][2];
  int barsDD[][] = new int[30][2];

  
  ArrayList<Bar[]> barMap = new ArrayList<Bar[]>();
  ArrayList<int[]> pixelMap = new ArrayList<int[]>();


  public MimsyMap(String type) {
    MimsyType = type;
    if (type == "MiniMim") {
      pixelsDD = 25;
      pixelsTL = 50;
      pixelsTR = 54;
    } else if (type == "ArtCar") {
      pixelsDD = 72;
      pixelsTL = 158;
      pixelsTR = 171;
    }
  }

  /**
   * Build the Mimsy Model
   **/
  public GraphModel buildModel() {
    
    return buildModelMiniMim();
  
    /*
    if (MimsyType == "MiniMim") {
    } else if (MimsyType == "ArtCar") {
      return buildModelArtCar();
    }
    */

  }

  /**
   * Build the Mimsy Channel Map
   **/
  public void buildChannelMap(GraphModel model) {
    if (MimsyType == "MiniMim") {
      buildMapMiniMim(model);
    }

    channelMap = pixelMap;
  }


  /**
   * Build graphs based on Dodecahedral subNet geometries
   **/

  public GraphModel buildCompound( Node[] nodes, 
                                  Dodecahedron.Net net, 
                                  int[][] ordering,
                                  String layer) {
    GraphModel[] compound = new GraphModel[net.subnets];
    for (int t = 0; t < net.subnets; t++) {
      //System.out.format(" !! Creating TetraR %d\n", t);  
      Node[] pg_nodes = new Node[net.nodes[t].length];
      for(int n = 0; n < net.nodes[t].length; n++) {
        pg_nodes[n] = nodes[net.nodes[t][n]];
      }
      compound[t] = GraphModel.fromNodes(pg_nodes, ordering)
                              .setLayer(layer + "_" + t);
    }
    return new GraphModel(nodes, compound).setLayer(layer).markAsCompound();
  }





  /**
   * Create a new channel from the list of bars
   **/
  public void addChannel(Bar[] bars) {
    int total = 0;
    for (Bar bar : bars) { total += bar.points.length; }
    int[] pixels = new int[total];
    int pixel = 0;
    for (Bar bar : bars) {
      for (LXPoint point : bar.points) {
        pixels[pixel++] = point.index;
      }
    }
    barMap.add(channelCount, bars);
    pixelMap.add(channelCount, pixels);
    channelCount++;
    /** channelMap.add(channelCount++, pixels); */
  }







  /** 
   * Build Mimsy Art Car
   **/

  public GraphModel buildModelMiniMim() {
  
    // create the dodecahedral bar mapping
    for (int c = 0; c < 5; c++) { 
      int[][] bars = new int[][] {
        {  0 + c,        0 + (c+1)%5 },
        {  0 + (c+1)%5,  5 + (c+1)%5 },
        {  5 + (c+1)%5, 10 + c       },
        { 10 + c,        5 + c       },
        { 10 + c,       15 + c       },
        { 15 + c,       15 + (c+1)%5 }
      };

      for (int b = 0; b < 6; b++) {
        barsDD[c*6 + b] = bars[b];
      }
    }


    int[][] TETRAHEDRON_BAR_ORDER = 
      new int[][] {{0,1},{1,2},{2,3},{3,1},{2,0},{0,3}};


    Node[] nodes = new Node[dd.NODES];

    GraphModel dodecahedron = new GraphModel().setLayer(DD);
    GraphModel tetraLCompound = new GraphModel().setLayer(TL);
    GraphModel tetraRCompound = new GraphModel().setLayer(TR);

    // Build Nodes
    for (int n = 0; n < dd.NODES; n++) {
      nodes[n] = new Node(dd.xyz[n]).setName(dd.nodeNames[n]);
      //System.out.format("+ Node %2d - %8.2f %8.2f %8.2f\n",
      //  nodes[n].index, nodes[n].x, nodes[n].y, nodes[n].z);
    }


    // Build Graphs
    if (DRAW_DODECAHEDRON) {
      out("BUILDING DODECAHEDRON (25 LEDs/Bar)\n");
      PIXELS_PER_BAR = pixelsDD;
      dodecahedron = GraphModel.fromNodes(nodes, barsDD)
                   . setLayer("Dodecahedron");
      //faces = buildCompound(nodes, dd.faceNet, DODECAHEDRON_BAR_ORDER);
    }

    if (DRAW_TETRA_LEFT) {
      out("BUILDING COMPOUND TETRAHEDRA LEFT (INNER 50 LEDs/Bar)\n");
      PIXELS_PER_BAR = pixelsTL;
      tetraLCompound = buildCompound(
          nodes, 
          dd.tetraLNet, 
          TETRAHEDRON_BAR_ORDER,
          TL);
    }

    if (DRAW_TETRA_RIGHT) {
      out("BUILDING COMPOUND TETRAHEDRA RIGHT (OUTER 54 LEDs/Bar)\n");
      PIXELS_PER_BAR = pixelsTR;
      tetraRCompound = buildCompound(
          nodes, 
          dd.tetraRNet, 
          TETRAHEDRON_BAR_ORDER,
          TR);
    }

    return new GraphModel(nodes, 
      new GraphModel[]{dodecahedron, tetraLCompound, tetraRCompound})
      .setLayer("Mimsy");
  }




  /**
   * MiniMim mapping is one channel from each layer for each A-level node
   **/
  public void buildMapMiniMim(GraphModel model) {
    GraphModel dodeca = model.getLayer(DD);
    GraphModel tetraL = model.getLayer(TL);
    GraphModel tetraR = model.getLayer(TR);

    //int channel = 0;
    //Bar[] fakeChannel = new Bar[]{dodeca.bars[0]};
    Bar[] bars = new Bar[6];
    for (int i = 0; i < 5; i++) {
      // dodecahedral bars
      for (int b = 0; b < 6; b++) {
        bars[b] = dodeca.bars[i*6+b];
      }
      addChannel(bars);
      // tetrahedral bars
      addChannel(tetraL.subGraphs.get(i).bars);
      addChannel(tetraR.subGraphs.get(i).bars);
    }
  }


  /**
   * Art Car mapping is one receiver for each layer for each A-level node
   **/
  Bar[] BLANK_CHANNEL = new Bar[0];

  public void buildMapArtCar() {
    GraphModel dodeca = model.getLayer(DD);
    GraphModel tetraL = model.getLayer(TL);
    GraphModel tetraR = model.getLayer(TR);

    Bar[] bars = new Bar[3];
    
    for (int i = 0; i < 5; i++) {
    
      //***** dodecahedral bars
      // bottom 3 bars
      for (int b = 0; b < 3; b++) {
        bars[b] = dodeca.bars[i*6+b];
      }
      addChannel(bars);

      // top 3 bars
      for (int b = 0; b < 3; b++) {
        bars[b] = dodeca.bars[i*6+b];
      }
      addChannel(bars);

      // third channel is skipped on each receiver
      addChannel(BLANK_CHANNEL);
  


     /* TODO: Add Tetrahedral Layers */ 
    }
  }




}







  /*
  Tetrahedral Edges (right)
  Object 0 -  0 15 13  7
  Object 1 -  1 16 14  8
  Object 2 -  2 17 10  9
  Object 3 -  3 18 11  5
  Object 4 -  4 19 12  6

  a-d 0-3 0-1
  d-c 3-2 1-2
  c-b 2-1 2-3
  b-d 1-3 3-1
  c-a 2-0 2-0
  a-b 0-1 0-3
  */


  /* There are several methods for navigating the connectiviety
   * 1) [OBJECT][NODE] - lists of nodes
   * 2) [OBJECT][EDGE] - lists of edges
   * 3) [VERTICES][VERTICES] - connectivity matrix
   * 4) [OBJECT][NODE1][NODE2] - neighbors
   */

  /*
  static int nodes_face[][] = {
    {0,1,2,3,4},
  
    {0,1,6,10,5},
    {1,2,7,11,6},
    {2,3,8,12,7},
    {3,4,9,13,8},
    {4,0,5,14,9},
  
    {15,16,11,6,10},
    {16,17,12,7,11},
    {17,18,13,8,12},
    {18,19,14,9,13},
    {19,15,10,5,14},
    
    {15,16,17,18,19},
  };

  */






