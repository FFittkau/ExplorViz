package explorviz.visualization.layout.graph;

public interface Graph<V> {
	/** Return the number of vertices in the graph */
	public int getSize();

	/** Return the vertices in the graph */
	public java.util.List<V> getVertices();

	/** Return the object for the specified vertex index */
	public V getVertex(int index);

	/** Return the index for the specified vertex object */
	public int getIndex(V v);

	/** Return the neighbors of vertex with the specified index */
	public java.util.List<Integer> getNeighbors(int index);

	/** Return the degree for a specified vertex */
	public int getDegree(int v);

	/** Print the edges */
	public void printEdges();

	/** Clear graph */
	public void clear();

	/** Add a vertex to the graph */
	public void addVertex(V vertex);

	/** Add an edge to the graph */
	public void addEdge(int u, int v);

	/** create an adjacency matrix from the graph */
	public int[][] getAdjacencyMatrix();

	/** print the adjacency matrix on the console */
	public void printAdjacencyMatrix();

	public void printWeights(final int[] field);

	public int[] calculateColSumm(int[][] adj);

	public int[] getRank(final int[][] adjMatrix);

	/** Obtain a depth-first search tree starting from v */
	public AbstractGraph<V>.Tree dfs(int v);

	/** Obtain a breadth-first search tree starting from v */
	public AbstractGraph<V>.Tree bfs(int v);
}