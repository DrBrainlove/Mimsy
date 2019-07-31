
/* SYMMETRY
 *
 * STATIC METHODS
 * --------------
 * Knows symmetry generators for dodecahedron and tetrahedra
 * ENUM of Face, Edge, Vertex Rotations and Inversion
 * Can parse a string into a series of operations
 * Factory creates a given symmetry, for repeated application
 * Generate a random symmetry
 *
 * NON-STATIC METHODS
 * ------------------
 * Apply the given color scheme / symmetry across a PolyGraph
 * TODO: How to apply inversion when inner tetrahedral compound has fewer points
 * Iterate the current symmetry by one+ operations
 *
 *
 * OPERATIONS
 * ----------
 * Rotate Bar  - 2
 * Rotate Node - 3
 * Rotate Face - 5
 * Invert - 2
 *
 * All operations are pre-computed and stored as the modulous of the operation.
 * Normally, symmetries are set as a given step of the operation. However, if
 * NULL is passed instead, the symmetry will be applied across ALL steps. This
 * is useful for painting the full pallate through various symmetry operations.
 *
 *
 *
 */

public enum Generator { BAR, NODE, FACE, INVERT };
public enum Kind { TETRAHEDRAL, ICOSAHEDRAL };



//********************************************************** SYMMETRY ELEMENTS

/**
 * Encapsulates and stores the base generators for later use
 */
public static class Element {
  // The type of symmetry operation: Node, Bar, etc.
  public Generator type;
  public GraphModel model;
  public Symmetry sym;
  // Reference to WHICH Node, Bar, etc it operates on.
  public int[] nodes;
  // How many operations before repeating
  public int modulus;
  // One (or more) steps of the operation to take
  public int[] steps = new int[0];
  // Translation maps
  public int[]   base_map; // single step
  public int[][] real_map; // base map applied to steps

  // Make sure all elements are ready before attempting computations
  private boolean initialized = false;


  /**
   * Construct an element which take all steps
   */
  public Element(Generator type, int[] nodes) {
    this(type, nodes, new int[0]);
  }

  /**
   * Construct an Element which takes a specific step
   */
  public Element(Generator type, int[] nodes, int step) {
    this(type, nodes, new int[]{step});
  }

  /**
   * Construct an Element which takes specific steps
   */
  public Element(Generator type, int[] nodes, int[] steps) {
    this.type = type;
    this.nodes = nodes;;
    this.modulus = this.getModulus(type);
    this.steps = steps;
  }

  private int getModulus(Generator type) {
    switch (type) {
      case BAR:     return 2;
      case NODE:    return 3;
      case FACE:    return 5;
      case INVERT:  return 2;
      default:      return 1;
    }
  }

  public boolean isInitialized() {
    if (initialized) { return true; }
    if (sym == null) { return false; }
    if (steps.length == 0 ) { return false; }
    if (base_map == null) { return false; }

    initialized = true;
    return true;
  }


  /**
   * Set the translation map to apply to nodes
   */
  private void applyMap() {
    if (! isInitialized()) { return; }

    // Now build the map
    real_map = new int[steps.length][nodes.length];
    for (int s = 0; s < steps.length; s++) {
      real_map[s] = sym.P(base_map, steps[s]);
    }
    sym.noteChange();
  }

  /**
   * Set the base map
   */
  public Element setMap(int[] map) {
    base_map = map;
    applyMap();
    return this;
  }

  /**
   * Set the model for context
   */
  public Element setModel(GraphModel model) {
    this.model = model;
    return this;
  }

  /**
   * Set the symmetry for context
   */
  public Element setSymmetry(Symmetry sym) {
    this.sym = sym;
    applyMap();
    return this;
  }

  /**
   * Step an element through its rotations
   */
  public Element addStep() { return this.addStep(1); }
  public Element addStep(int step) {
    int[] newSteps = new int[this.steps.length];
    for (int i = 0; i < this.steps.length; i++) {
      newSteps[i] = this.steps[i] + step;
    }
    return this.setStep(newSteps);
  }

  public Element setStep(int step) {
    return this.setStep(new int[]{step});
  }
  public Element setStep(int[] step) {
    this.steps = step;
    for (int i = 0; i < this.steps.length; i++) {
      this.steps[i] %= this.modulus;
    }
    applyMap();
    return this;
  }

  /**
   * Bloom the element, setting it to all step options.
   */
  public void bloom() {
    setStep(range(modulus));
  }


  /**
   * Combine steps from another compatible element.
   */
  public Element combine(Element elem) {
    for (int i = 0; i < elem.steps.length; i++) {
      this.addStep(elem.steps[i]);
    }
    return this;
  }


  /**
   * Test various types of element equality. Compatible elements map to the
   * same fundamental symmetry operation, i.e. rotation around a specific
   * face.
   */
  public boolean isCompatible(Element elem) {
    // Must be same Generator
    if (this.type != elem.type) { return false; }

    // Reference nodes must match
    // TODO: Ultimately they don't have to match order, but fixing that
    // requires some fancy comparison testing. Hopefully not too
    // inconvenient in practice.
    if (this.nodes.length != elem.nodes.length) { return false; }
    for (int i = 0; i < this.nodes.length; i++) {
      if (this.nodes[i] != elem.nodes[i]) {
        return false;
      }
    }
    return true;
  }
}



public static class Symmetry {

  /**
   *  Cached or derived data from the model
   */
  public final GraphModel model;
  public final Node[] nodes;
  public final LXPoint[] points;
  public final Kind kind;

  /**
   * Vector form of relevant symmetry operations on nodes
   */
  private final int[] ID; // Identity
  private final int[] xN; // Rotation 120 deg about Node
  private final int[] xB; // Rotation 180 deg about Bar
  private final int[] xF; // Rotation  72 deg about Face
  private final int[] xI; // Inversion

  private final int[][] xX; // Arbitrary, computed from above


  /**
   * Colors in the template are applied to the whole object by symmetry ops.
   */
  public int[] template;
  //public final List<Integer> template;

  /**
   * Current symmetry state. Updated as new symmetry elements are added.
   */

  // A history of applied symmetry elements
  public List<Element> elements;

  // How many symmetries are there currently?
  public int symmetries;
  public List<int[]> xNodes;

  public HashMap<Node,List<Node>> nodeMap;
  public HashMap<Bar,List<Bar>> barMap;
  public HashMap<GraphModel,List<GraphModel>> faceMap;

  // Record if any elements have changed, so can rebuild before drawing.
  private boolean changed = false;





  //************************************************************* CONSTRUCTORS


  public Symmetry() {
    this(new GraphModel());
  }

  public Symmetry(GraphModel model){
    this.model = model;
    this.nodes = model.nodes;
    this.points = model.points;
    this.template = new int[model.points.length];
    //this.template = new ArrayList<LXColor>(model.points.length);

    // Populate all the symmetry operations
    this.ID = new int[nodes.length];
    for (int i = 0; i<nodes.length; i++) { ID[i] = i; }
    //if (nodes.length == 20) {
      this.kind = Kind.ICOSAHEDRAL;


      // Inversion about the origin (anti-chiral)
      this.xI = new int[] { 17, 18, 19, 15, 16,
                            12, 13, 14, 10, 11,
                             8,  9,  5,  6,  7,
                             3,  4,  0,  1,  2};

      // Rotation 180 degrees about the bar/edge (0,1)
      this.xB = new int[] { 1,  0,  5, 10,  6,
                            2,  4, 14, 15, 11,
                            3,  9, 19, 16,  7,
                            8, 13, 18, 17, 12};


      // Rotation cc-wise of the face (0,1,2,3,4)
      this.xF = new int[] {  1,  2,  3,  4,  0,
                             6,  7,  8,  9,  5,
                            11, 12, 13, 14, 10,
                            16, 17, 18, 19, 15};

      // Rotation cc-wise around the node/vertex 0
      this.xN = I(M(xB,xF));
      out("*** xN ***\n%s\n", Arrays.toString(this.xN));

      // Canonical transformations for all nodes, when node 0 is moved to any
      // other node.  May subsequently need to be corrected for orientation.
      // These are computed as rotations around nodes and bars to get to the
      // right place.
      this.xX = new int[][] {
        this.ID,
        this.xF,
        P(xF, 2),
        P(xF, 3),
        P(xF, 4),

        M(P(xF,4), M(xB, P(xF, 4))),
        M(xB, P(xF, 4)),
        M(xF, M(xB, P(xF, 4))),
        M(P(xF,2), M(xB, P(xF, 4))),
        M(P(xF,3), M(xB, P(xF, 4))),

        M(xB, P(xF, 3)),
        M(xF, M(xB, P(xF, 3))),
        M(P(xF,2), M(xB, P(xF,3))),
        M(P(xF,3), M(xB, P(xF,3))),
        M(P(xF,4), M(xB, P(xF,3))),

        M(xB,M(P(xF,2), M(xB, P(xF,4)))),
        M(xF, M(xB, M(P(xF, 2), M(xB, P(xF, 4))))),
        M(P(xF, 2), M(xB, M(P(xF, 2), M(xB, P(xF, 4))))),
        M(P(xF, 3), M(xB, M(P(xF, 2), M(xB, P(xF, 4))))),
        M(P(xF, 4), M(xB, M(P(xF, 2), M(xB, P(xF, 4)))))
      };


    //} else {
    //  this.kind = Kind.TETRAHEDRAL;
    //}
    //

    initializeCache();

  }






  //********************************************************  GROUP OPERATIONS
  // !!!! NOTE: THIS IS DEEP VOODOO. MAY BE INCOMPREHENSIBLE WITHOUT PHD. !!!!

  /**
   * Compose h with g.
   *
   * @param g Tranformation vector for a symmetry operation
   * @param h Nodes to be translated
   * @return Vector of translated nodes
   */

  private int[] M(int[] g, int[] h) {
    int[] r = new int[h.length];
    for (int i = 0; i < nodes.length; i++) {
      r[i] = g[h[i]];
    }
    return r;
  }

  /**
   * Compute the transofmration from composing by g, n times.
   *
   * @param g Tranformation vector for a symmetry operation
   * @param n Number of times to transform
   * @return The product of the repeated transformation
   */

  private int[] P(int[] g, int n) {
    if      (n > 0) { return M(g, P(g, n-1)); }
    else if (n < 0) { return I(P(g, -n)); }
    else            { return ID; }
  }

  /**
   * Invert g, that is, undo the transformation performed by g.
   *
   * @param g Tranformation vector for a symmetry operation
   * @return g-inverse
   */
  private int[] I(int[] g) {
    int[] r = new int[nodes.length];
    for (int i = 0; i < nodes.length; i++) {
      r[g[i]] = i;
    }
    return r;
  }

  /**
   * Conugate h with g.
   */

  private int[] conjugate(int[] g, int[] h) {
    return M(g,M(h,I(g)));
  }

  /**
   * Correct the orientation after applying a symmetry operation.
   */
  private int[] reorient(int[] g) {
    int n = I(xX[g[0]])[g[1]];
    int o = 0;
    if (n == 4) { o = 1; }
    if (n == 5) { o = 2; }
    return M(xX[g[0]], P(xB, o));
  }


  //************************************************ STATE & CACHE MAINTENANCE

  private void noteChange() {
    this.changed = true;
  }

  private void resetState() {
    elements = new ArrayList<Element>();
    xNodes = new ArrayList<int[]>();
    xNodes.add(ID);
    symmetries = 1;
    clear();
  }


  private void initializeCache() {
    resetState();
  }

  public void reset() {
    resetState();
  }

  /**
   * Remove the last symmetry element and rebuild.
   */
  public void pop() {
    if (elements.size() > 0) {
      elements.remove(elements.size()-1);
      rebuild();
    }
  }

  public void push(Element elem) {
    addElement(elem);
  }

  /**
   * Add a new element, possibly combining with the previous element.
   */
  private void addElement(Element elem) {

    // TODO: If elem == elements[-1], pop the last element and combine it
    // with the new one.

    boolean reduced = false;
    if (elements.size() > 0) {
      Element last = elements.get(elements.size()-1);
      if (last.isCompatible(elem)) {
        last.combine(elem);
        reduced = true;
      }
      out("Combined Symmetry Element #%d: %s/%d %s Step %s\n",
        elements.size(), last.type, last.modulus, Arrays.toString(last.nodes),
        Arrays.toString(last.steps));
    }

    if (!reduced) {
      out("Added Symmetry Element #%d: %s/%d %s Step %s\n",
        elements.size(), elem.type, elem.modulus, Arrays.toString(elem.nodes),
        Arrays.toString(elem.steps));
      elements.add(elem);
    }

    rebuild();
  }


  /**
   * Reduce redundant symmetries.
   */

  private void reduce() {
    boolean[][] seen = new boolean[nodes.length][nodes.length];
    int n1, n2;
    List<int[]> good = new ArrayList<int[]>();
    for (int[] map : xNodes) {
      n1 = map[0];
      n2 = map[1];
      if (seen[n1][n2]) {
        continue;
      } else {
        seen[n1][n2] = true;
        good.add(map);
      }
    }
    xNodes = good;
  }

  /**
   * Rebuild the symmetry map from scratch.
   */
  private void rebuild() {
    out("Rebuilding Symmetry\n");
    xNodes = new ArrayList<int[]>();
    xNodes.add(ID);

    for (Element elem : elements) {
      ArrayList<int[]> newMap = new ArrayList<int[]>();

      for (int[] cur : xNodes) {
        for (int[] map : elem.real_map) {
          newMap.add(M(map,cur));
        }
      }
      xNodes = newMap;
      reduce();
    }

    symmetries = xNodes.size();
    changed = false;
    out("--Rebuild Completed. %d elements. %d symmetries\n", elements.size(), symmetries);
  }



  //****************************************************** SYMMETRY OPERATIONS


  //---------------------------------------------------------------------- Bar

  /**
   * Get the node map resulting from rotateing around a bar.
   */
  public int[] getMapBar(int n1, int n2) {
    return getMapBar(n1, n2, 1);
  }
  public int[] getMapBar(int n1, int n2, int steps) {
    return P(conjugate(reorient(new int[]{n1, n2}), xB), steps);
  }

  /**
   * Apply 180 degrees around a bar to this symmetry object.
   */


  public Element rotateBar(Bar bar) {
    return rotateBar(bar.node1.index, bar.node2.index, new int[]{1});
  }

  public Element rotateBar(int n1, int n2, int step) {
    return rotateBar(n1, n2, new int[]{step});
  }

  public Element rotateBar(int n1, int n2, int[] steps) {
    Element elem = new Element(Generator.BAR, new int[]{n1,n2}, steps)
                       .setModel(model)
                       .setMap(getMapBar(n1, n2))
                       .setSymmetry(this)
                       ;
    addElement(elem);
    return elem;
  }

  //--------------------------------------------------------------------- Face

  /**
   * Get the node map resulting from rotateing around a face.
   */
  public int[] getMapFace(int n1, int n2) {
    return getMapFace(n1, n2, 1);
  }
  public int[] getMapFace(int n1, int n2, int steps) {
    return P(conjugate(reorient(new int[]{n1, n2}), xF), steps);
  }

  /**
   * Apply 72 degree rotation around a face to this symmetry object.
   */

  public Element rotateFace(int n1, int n2, int step) {
    return rotateFace(n1, n2, new int[]{step});
  }

  public Element rotateFace(int n1, int n2, int[] steps) {
    Element elem = new Element(Generator.FACE, new int[]{n1,n2}, steps)
                       .setModel(model)
                       .setMap(getMapFace(n1, n2))
                       .setSymmetry(this)
                       ;
    addElement(elem);
    return elem;
  }




  //--------------------------------------------------------------------- Node

  /**
   * Get the node map resulting from rotating around a node.
   */
  public int[] getMapNode(int n) {
    return getMapNode(n, 1);
  }
  public int[] getMapNode(int n, int steps) {
    return P(conjugate(xX[n], xN), steps);
  }

  /**
   * Apply 120 degree rotation around a node to this symmetry object.
   */

  public Element rotateNode(Node node) {
    return rotateNode(node.index, new int[]{1});
  }

  public Element rotateNode(int n, int step) {
    return rotateNode(n, new int[]{step});
  }

  public Element rotateNode(int n, int[] steps) {
    Element elem = new Element(Generator.NODE, new int[]{n}, steps)
                       .setModel(model)
                       .setSymmetry(this)
                       .setMap(getMapNode(n))
                       ;
    addElement(elem);
    return elem;
  }


  //********************************************************* QUERY SYMMETRIES

  public Node[] getSymmetricNodes(Node refNode) {
    Node[] symNodes = new Node[symmetries];
    for (int i = 0; i < symmetries; i++) {
      symNodes[i] = nodes[xNodes.get(i)[refNode.index]];
    }
    return symNodes;
  }

  public Bar[] getSymmetricBars(Bar refBar) {
    //out("  Ref Bar    [%2d][%2d]\n", refBar.node1.index, refBar.node2.index);
    Node[] symNodes1 = getSymmetricNodes(refBar.node1);
    Node[] symNodes2 = getSymmetricNodes(refBar.node2);

    Bar[] symBars = new Bar[symmetries];
    Bar symBar;
    for (int i = 0; i < symmetries; i++) {
      symBar = model.getBar(symNodes1[i], symNodes2[i]);
      symBars[i] = symBar;
      //out("  Sym Bar %2d [%2d][%2d]\n", i, symBar.node1.index, symBar.node2.index);
    }
    return symBars;
  }

  //****************************************************************** DRAWING

  /**
   * Clear the symmetry color template for the next frame
   */
  public void clear() {
    template = new int[points.length];
    //template = new LinkedList<Integer>();
  }

  /**
   * Draw the template symmetrically into colors.
   */

  public void draw(int[] colors) {

    //out("Drawing Symmetry Pattern\n");

    if (changed) {
      rebuild();
    }

    //out("Loading %d Symmetric Bars\n", symmetries);
    int colored = 0;
    for (int i = 0; i < template.length; i++) {
      if (template[i] != 0) {
        colored++;
      }
    }
    //out("--Found %d colored template pixels\n", colored);

    colored = 0;
    for (Bar refBar : model.bars) {

      int[] indexes = refBar.getPointIndexes();
      Bar[] symBars = getSymmetricBars(refBar);
      int refPoint, symPoint;

      for (int i = 0; i < indexes.length; i++) {
        refPoint = indexes[i];
        if (template[indexes[i]] != 0) {
          colored++;
          for (Bar symBar : symBars) {
            symPoint = symBar.points[i].index;
            colors[symPoint] = template[refPoint];
          }
        }
      }
    }
    //out("--Found %d colored bar pixels\n", colored);
    clear();
  }

}
