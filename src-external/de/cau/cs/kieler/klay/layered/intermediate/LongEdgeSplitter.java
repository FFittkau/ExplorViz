/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2010 by
 * + Christian-Albrechts-University of Kiel
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.klay.layered.intermediate;

import java.util.ListIterator;

import de.cau.cs.kieler.core.alg.IKielerProgressMonitor;
import de.cau.cs.kieler.kiml.options.LayoutOptions;
import de.cau.cs.kieler.kiml.options.PortConstraints;
import de.cau.cs.kieler.kiml.options.PortSide;
import de.cau.cs.kieler.klay.layered.ILayoutProcessor;
import de.cau.cs.kieler.klay.layered.graph.LEdge;
import de.cau.cs.kieler.klay.layered.graph.LNode;
import de.cau.cs.kieler.klay.layered.graph.LPort;
import de.cau.cs.kieler.klay.layered.graph.Layer;
import de.cau.cs.kieler.klay.layered.graph.LGraph;
import de.cau.cs.kieler.klay.layered.properties.InternalProperties;
import de.cau.cs.kieler.klay.layered.properties.NodeType;

/**
 * Splits the long edges of the layered graph to obtain a proper layering.
 * For each edge that connects two nodes that are more than one layer apart
 * from each other, create a dummy node to split the edge. The resulting layering
 * is <i>proper</i>, i.e. all edges connect only nodes from subsequent layers.
 * 
 * <p>The dummy nodes retain a reference to the ports the original long edge's
 * source and target ports.</p>
 * 
 * <dl>
 *   <dt>Precondition:</dt><dd>a layered graph.</dd>
 *   <dt>Postcondition:</dt><dd>the graph is properly layered.</dd>
 *   <dt>Slots:</dt><dd>Before phase 3.</dd>
 *   <dt>Same-slot dependencies:</dt><dd>{@link LayerConstraintProcessor}</dd>
 * </dl>
 *
 * @author msp
 * @kieler.design 2012-08-10 chsch grh
 * @kieler.rating proposed yellow by msp
 */
public final class LongEdgeSplitter implements ILayoutProcessor {

    /**
     * {@inheritDoc}
     */
    public void process(final LGraph layeredGraph, final IKielerProgressMonitor monitor) {
        monitor.begin("Edge splitting", 1);
        
        if (layeredGraph.getLayers().size() <= 2) {
            monitor.done();
            return;
        }
        
        // Iterate through the layers
        ListIterator<Layer> layerIter = layeredGraph.getLayers().listIterator();
        Layer nextLayer = layerIter.next();
        while (layerIter.hasNext()) {
            Layer layer = nextLayer;
            nextLayer = layerIter.next();
            
            // Iterate through the nodes
            for (LNode node : layer) {
                // Iterate through the outgoing edges
                for (LPort port : node.getPorts()) {
                    // Iterate through the edges
                    for (LEdge edge : port.getOutgoingEdges()) {
                        LPort targetPort = edge.getTarget();
                        Layer targetLayer = targetPort.getNode().getLayer();
                        
                        // If the edge doesn't go to the current or next layer, split it
                        if (targetLayer != layer && targetLayer != nextLayer) {
                            // If there is no next layer, something is wrong
                            assert layerIter.hasNext();
                            
                            // Create dummy node
                            LNode dummyNode = new LNode(layeredGraph);
                            dummyNode.setProperty(InternalProperties.ORIGIN, edge);
                            dummyNode.setProperty(InternalProperties.NODE_TYPE, NodeType.LONG_EDGE);
                            dummyNode.setProperty(LayoutOptions.PORT_CONSTRAINTS,
                                    PortConstraints.FIXED_POS);
                            dummyNode.setLayer(nextLayer);
                            
                            // Set thickness of the edge
                            float thickness = edge.getProperty(LayoutOptions.THICKNESS);
                            if (thickness < 0) {
                                thickness = 0;
                                edge.setProperty(LayoutOptions.THICKNESS, thickness);
                            }
                            dummyNode.getSize().y = thickness;
                            double portPos = Math.floor(thickness / 2);
                            
                            // Create dummy input and output ports
                            LPort dummyInput = new LPort(layeredGraph);
                            dummyInput.setSide(PortSide.WEST);
                            dummyInput.setNode(dummyNode);
                            dummyInput.getPosition().y = portPos;
                            
                            LPort dummyOutput = new LPort(layeredGraph);
                            dummyOutput.setSide(PortSide.EAST);
                            dummyOutput.setNode(dummyNode);
                            dummyOutput.getPosition().y = portPos;
                            
                            edge.setTarget(dummyInput);
                            
                            // Create a dummy edge
                            LEdge dummyEdge = new LEdge(layeredGraph);
                            dummyEdge.copyProperties(edge);
                            dummyEdge.setSource(dummyOutput);
                            dummyEdge.setTarget(targetPort);
                            
                            setDummyProperties(dummyNode, edge, dummyEdge);
                        }
                    }
                }
            }
        }
        
        monitor.done();
    }
    
    /**
     * Sets the source and target properties on the given dummy node.
     * 
     * @param dummy the dummy node.
     * @param inEdge the edge going into the dummy node.
     * @param outEdge the edge going out of the dummy node.
     */
    private void setDummyProperties(final LNode dummy, final LEdge inEdge, final LEdge outEdge) {
        LNode inEdgeSourceNode = inEdge.getSource().getNode();
        
        if (inEdgeSourceNode.getProperty(InternalProperties.NODE_TYPE) == NodeType.LONG_EDGE) {
            // The incoming edge originates from a long edge dummy node, so we can
            // just copy its properties
            dummy.setProperty(InternalProperties.LONG_EDGE_SOURCE,
                    inEdgeSourceNode.getProperty(InternalProperties.LONG_EDGE_SOURCE));
            dummy.setProperty(InternalProperties.LONG_EDGE_TARGET,
                    inEdgeSourceNode.getProperty(InternalProperties.LONG_EDGE_TARGET));
        } else {
            // The source is the input edge's source port, the target is the output
            // edge's target port
            dummy.setProperty(InternalProperties.LONG_EDGE_SOURCE, inEdge.getSource());
            dummy.setProperty(InternalProperties.LONG_EDGE_TARGET, outEdge.getTarget());
        }
    }

}
