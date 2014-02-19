package explorviz.visualization.renderer

import explorviz.visualization.engine.math.Vector3f

import explorviz.visualization.engine.primitives.PrimitiveObject

import java.util.ArrayList
import java.util.List

import explorviz.visualization.model.CommunicationClientSide
import explorviz.visualization.model.NodeClientSide
import explorviz.visualization.model.ApplicationClientSide
import explorviz.visualization.model.NodeGroupClientSide
import explorviz.visualization.model.LandscapeClientSide

import explorviz.visualization.model.helper.DrawNodeEntity
import explorviz.visualization.engine.navigation.Camera
import explorviz.visualization.model.SystemClientSide

class LandscapeRenderer {
	static var Vector3f centerPoint = null

	def static drawLandscape(LandscapeClientSide landscape, List<PrimitiveObject> polygons) {
		if (centerPoint == null) {
			centerPoint = getCenterPoint(landscape)
			Camera::vector.z = -10f
		}

		val DEFAULT_Z = 0f

		landscape.systems.forEach [
			clearDrawingEntities(it)
			createSystemDrawing(it, DEFAULT_Z, polygons)
		]

		landscape.applicationCommunication.forEach [
			it.primitiveObjects.clear()
		]
		CommunicationClientSide::createCommunicationLines(0f, landscape, centerPoint, polygons)
	}

	//	def static moveVertices(DrawNodeEntity entity, Vector3f vector, List<PrimitiveObject> polygons) {
	//		for (primitiveObject : entity.primitiveObjects) {
	//			primitiveObject.reAddToBuffer()
	//			primitiveObject.moveByVector(vector)
	//			polygons.add(primitiveObject)
	//		}
	//	}
	def private static createSystemDrawing(SystemClientSide system, float z, List<PrimitiveObject> polygons) {
		if (system.nodeGroups.size() > 1) {
			val systemQuad = system.createSystemQuad(z - 0.2f, centerPoint)

			val systemQuadRectangle = system.createSystemQuadRectangle(z - 0.2f, centerPoint)
			val systemOpenSymbol = system.createSystemOpenSymbol()
			val systemLabel = system.createSystemLabel(systemQuad, system.name)

			system.primitiveObjects.add(systemQuad)
			system.primitiveObjects.add(systemQuadRectangle)
			system.primitiveObjects.add(systemOpenSymbol)
			system.primitiveObjects.add(systemLabel)

			polygons.add(systemQuad)
			polygons.add(systemQuadRectangle)
			polygons.add(systemOpenSymbol)
			polygons.add(systemLabel)
		}
		
		if (system.opened) {
			system.nodeGroups.forEach [
				createNodeGroupDrawing(it, z, polygons)
			]
		}
	}

	def private static createNodeGroupDrawing(NodeGroupClientSide nodeGroup, float z, List<PrimitiveObject> polygons) {
		if (nodeGroup.nodes.size() > 1) {
			val nodeGroupQuad = nodeGroup.createNodeGroupQuad(z, centerPoint)

			//				val nodeGroupQuadRectangle = nodeGroup.createNodeGroupQuadRectangle(z, centerPoint)
			val nodeGroupOpenSymbol = nodeGroup.createNodeGroupOpenSymbol()

			nodeGroup.primitiveObjects.add(nodeGroupQuad)
			nodeGroup.primitiveObjects.add(nodeGroupOpenSymbol)

			polygons.add(nodeGroupQuad)

			//				polygons.add(nodeGroupQuadRectangle)
			polygons.add(nodeGroupOpenSymbol)
		}

		nodeGroup.nodes.forEach [
			createNodeDrawing(it, z, polygons)
		]
	}

	def private static createNodeDrawing(NodeClientSide node, float z, List<PrimitiveObject> polygons) {
		if (node.visible) {
			val nodeQuad = node.createNodeQuad(z + 0.01f, centerPoint)

			//				val nodeLine = node.createLineAroundQuad(nodeQuad, z + 0.015f, true,
			//					new Vector4f(0.85f, 0.85f, 0.85f, 1f))
			val label = if (node.parent.opened) node.ipAddress else node.parent.name
			val nodeLabel = node.createNodeLabel(nodeQuad, label)
			node.primitiveObjects.add(nodeQuad)

			//				node.primitiveObjects.add(nodeLine)
			node.primitiveObjects.add(nodeLabel)

			polygons.add(nodeQuad)

			//				polygons.add(nodeLine)
			polygons.add(nodeLabel)

			node.applications.forEach [
				createApplicationDrawing(it, z, polygons)
			]
		}
	}

	def private static createApplicationDrawing(ApplicationClientSide application, float z,
		List<PrimitiveObject> polygons) {
		var PrimitiveObject oldQuad = null
		if (!application.primitiveObjects.empty) {
			oldQuad = application.primitiveObjects.get(0)
		}

		val applicationQuad = application.createApplicationQuad(application.name, z + 0.04f, centerPoint, oldQuad)
		val applicationLine = application.createApplicationShape(applicationQuad, z + 0.045f)
		application.primitiveObjects.add(applicationQuad)
		if (applicationLine != null)
			application.primitiveObjects.add(applicationLine)
		polygons.add(applicationQuad)
		if (applicationLine != null)
			polygons.add(applicationLine)
	}

	def private static getCenterPoint(LandscapeClientSide landscape) {
		val rect = new ArrayList<Float>
		rect.add(Float::MAX_VALUE)
		rect.add(-Float::MAX_VALUE)
		rect.add(Float::MAX_VALUE)
		rect.add(-Float::MAX_VALUE)

		val MIN_X = 0
		val MAX_X = 1
		val MIN_Y = 2
		val MAX_Y = 3

		landscape.systems.forEach [ system |
			system.nodeGroups.forEach [
				if (it.nodes.size() > 1) {
					getMinMaxFromQuad(it, rect, MIN_X, MAX_X, MAX_Y, MIN_Y)
				} else if (it.nodes.size() == 1) {
					getMinMaxFromQuad(it.nodes.get(0), rect, MIN_X, MAX_X, MAX_Y, MIN_Y)
				}
			]
		]

		new Vector3f(rect.get(MIN_X) + ((rect.get(MAX_X) - rect.get(MIN_X)) / 2f),
			rect.get(MIN_Y) + ((rect.get(MAX_Y) - rect.get(MIN_Y)) / 2f), 0)
	}

	def private static getMinMaxFromQuad(DrawNodeEntity it, ArrayList<Float> rect, int MIN_X, int MAX_X, int MAX_Y,
		int MIN_Y) {
		val curX = it.positionX
		val curY = it.positionY
		if (curX < rect.get(MIN_X)) {
			rect.set(MIN_X, curX)
		}
		if (rect.get(MAX_X) < curX + (it.width)) {
			rect.set(MAX_X, curX + (it.width))
		}
		if (curY > rect.get(MAX_Y)) {
			rect.set(MAX_Y, curY)
		}
		if (rect.get(MIN_Y) > curY - (it.height)) {
			rect.set(MIN_Y, curY - (it.height))
		}
	}

	def private static clearDrawingEntities(SystemClientSide system) {
		system.primitiveObjects.clear()

		system.nodeGroups.forEach [
			it.primitiveObjects.clear()
			it.nodes.forEach [
				it.primitiveObjects.clear()
				it.applications.forEach [
					it.primitiveObjects.clear()
				]
			]
		]
	}
}
