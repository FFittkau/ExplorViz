package explorviz.visualization.renderer

import elemental.html.WebGLTexture
import explorviz.shared.model.Application
import explorviz.shared.model.Communication
import explorviz.shared.model.Landscape
import explorviz.shared.model.Node
import explorviz.shared.model.NodeGroup
import explorviz.shared.model.System
import explorviz.shared.model.helper.DrawNodeEntity
import explorviz.visualization.engine.math.Vector3f
import explorviz.visualization.engine.math.Vector4f
import explorviz.visualization.engine.primitives.BoxContainer
import explorviz.visualization.engine.primitives.LabelContainer
import explorviz.visualization.engine.primitives.LineContainer
import explorviz.visualization.engine.primitives.PipeContainer
import explorviz.visualization.engine.primitives.PrimitiveObject
import explorviz.visualization.engine.primitives.Quad
import explorviz.visualization.engine.primitives.QuadContainer
import explorviz.visualization.engine.textures.TextureManager
import explorviz.visualization.experiment.Experiment
import java.util.ArrayList
import java.util.List
import explorviz.shared.model.helper.ELanguage
import explorviz.shared.model.helper.CommunicationAccumulator
import explorviz.shared.model.helper.CommunicationTileAccumulator
import explorviz.shared.model.helper.Point
import explorviz.visualization.main.MathHelpers
import explorviz.visualization.main.ExplorViz
import explorviz.visualization.engine.main.SceneDrawer

class LandscapeRenderer {
	static var Vector3f viewCenterPoint = null
	static val DEFAULT_Z_LAYER_DRAWING = 0f

	public static val SYSTEM_LABEL_HEIGHT = 0.5f

	public static val NODE_LABEL_HEIGHT = 0.25f

	public static val APPLICATION_PIC_SIZE = 0.16f
	public static val APPLICATION_PIC_PADDING_SIZE = 0.15f
	public static val APPLICATION_LABEL_HEIGHT = 0.25f

	static val List<PrimitiveObject> arrows = new ArrayList<PrimitiveObject>(2)

	static var WebGLTexture javaPicture
	static var WebGLTexture cppPicture
	static var WebGLTexture perlPicture
	static var WebGLTexture javascriptPicture
	static var WebGLTexture unknownPicture
	static var WebGLTexture cPicture
	static var WebGLTexture csharpPicture
	static var WebGLTexture pythonPicture
	static var WebGLTexture rubyPicture
	static var WebGLTexture phpPicture

	static var WebGLTexture databasePicture
	static var WebGLTexture requestsPicture

	def static init() {
		TextureManager::deleteTextureIfExisting(javaPicture)
		TextureManager::deleteTextureIfExisting(cppPicture)
		TextureManager::deleteTextureIfExisting(perlPicture)
		TextureManager::deleteTextureIfExisting(javascriptPicture)
		TextureManager::deleteTextureIfExisting(unknownPicture)
		TextureManager::deleteTextureIfExisting(databasePicture)
		TextureManager::deleteTextureIfExisting(requestsPicture)

		TextureManager::deleteTextureIfExisting(cPicture)
		TextureManager::deleteTextureIfExisting(csharpPicture)
		TextureManager::deleteTextureIfExisting(pythonPicture)
		TextureManager::deleteTextureIfExisting(rubyPicture)
		TextureManager::deleteTextureIfExisting(phpPicture)

		javaPicture = TextureManager::createTextureFromImagePath("logos/java12.png")
		cPicture = TextureManager::createTextureFromImagePath("logos/c.png")
		cppPicture = TextureManager::createTextureFromImagePath("logos/cpp.png")
		csharpPicture = TextureManager::createTextureFromImagePath("logos/csharp.png")
		perlPicture = TextureManager::createTextureFromImagePath("logos/perl.png")
		javascriptPicture = TextureManager::createTextureFromImagePath("logos/javascript.png")
		pythonPicture = TextureManager::createTextureFromImagePath("logos/python.png")
		rubyPicture = TextureManager::createTextureFromImagePath("logos/ruby.png")
		phpPicture = TextureManager::createTextureFromImagePath("logos/php.png")
		unknownPicture = TextureManager::createTextureFromImagePath("logos/unknown.png")
		databasePicture = TextureManager::createTextureFromImagePath("logos/database2.png")
		requestsPicture = TextureManager::createTextureFromImagePath("logos/requests.png")
	}

	def static void drawLandscape(Landscape landscape, List<PrimitiveObject> polygons, boolean firstViewAfterChange) {
		calcViewCenterPoint(landscape, firstViewAfterChange)

		arrows.clear()
		BoxContainer::clear()
		LabelContainer::clear()
		QuadContainer::clear()
		LineContainer::clear()
		PipeContainer::clear()

		for (system : landscape.systems) {
			clearDrawingEntities(system)
			createSystemDrawing(system, DEFAULT_Z_LAYER_DRAWING, polygons)
		}

		landscape.communicationsAccumulated.clear()

		for (commu : landscape.applicationCommunication)
			createCommunicationAccumlated(DEFAULT_Z_LAYER_DRAWING, commu, landscape.communicationsAccumulated)

		createCommunicationLineDrawing(landscape.communicationsAccumulated)

		QuadContainer::doQuadCreation()
		LabelContainer::doLabelCreation()
		LineContainer::doLineCreation()

		polygons.addAll(arrows)
	}

	public def static void calcViewCenterPoint(Landscape landscape, boolean firstViewAfterChange) {
		if (viewCenterPoint == null || firstViewAfterChange) {
			viewCenterPoint = ViewCenterPointerCalculator::calculateLandscapeCenterAndZZoom(landscape)
		}
	}
	
	public def static void reCalcViewCenterPoint(){
		calcViewCenterPoint(SceneDrawer::lastLandscape,true)
	}

	def private static void clearDrawingEntities(System system) {
		system.primitiveObjects.clear()

		for (nodeGroup : system.nodeGroups) {
			nodeGroup.primitiveObjects.clear()
			for (node : nodeGroup.nodes) {
				node.primitiveObjects.clear()
				for (application : node.applications)
					application.primitiveObjects.clear()
			}
		}
	}

	def private static createSystemDrawing(System system, float z, List<PrimitiveObject> polygons) {
		var specialRequestSymbol = false
		if (system.nodeGroups.size == 1 && system.nodeGroups.get(0).nodes.size == 1 &&
			system.nodeGroups.get(0).nodes.get(0).applications.size == 1 &&
			system.nodeGroups.get(0).nodes.get(0).applications.get(0).name == "Requests") {
			specialRequestSymbol = true
		}

		system.positionZ = z - 0.2f
		if (!ExplorViz::controlGroupActive && !specialRequestSymbol) {
			QuadContainer::createQuad(system, viewCenterPoint, null, System::backgroundColor, false)

			createOpenSymbol(system, System::plusColor, System::backgroundColor)
			createSystemLabel(system, system.name)
		}

		if (system.opened) {
			for (nodeGroup : system.nodeGroups)
				createNodeGroupDrawing(nodeGroup, z, polygons)
		}

		if (!ExplorViz::controlGroupActive && !specialRequestSymbol) {
			drawTutorialIfEnabled(system, new Vector3f(system.positionX, system.positionY, z))
		}
	}

	def private static void createOpenSymbol(DrawNodeEntity entity, Vector4f plusColor, Vector4f backgroundColor) {
		val extensionX = 0.2f
		val extensionY = 0.2f

		val TOP_RIGHT = new Vector3f(entity.positionX + entity.width, entity.positionY, entity.positionZ)

		var float centerX = TOP_RIGHT.x - extensionX
		var float centerY = TOP_RIGHT.y - extensionY

		var symbol = "-" // -
		if (entity instanceof System) {
			if (!entity.opened) symbol = "+"
		} else if (entity instanceof NodeGroup) {
			if (!entity.opened) symbol = "+"
		}

		val zValue = entity.positionZ + 0.01f
		LabelContainer::createLabel(symbol,
			new Vector3f(centerX - extensionX, centerY - extensionY, zValue).sub(viewCenterPoint),
			new Vector3f(centerX + extensionX, centerY - extensionY, zValue).sub(viewCenterPoint),
			new Vector3f(centerX + extensionX, centerY + extensionY, zValue).sub(viewCenterPoint),
			new Vector3f(centerX - extensionX, centerY + extensionY, zValue).sub(viewCenterPoint), false, false, false,
			false, false)
	}

	private def static void createSystemLabel(System system, String name) {
		val Vector3f ORIG_TOP_LEFT = new Vector3f(system.positionX, system.positionY, 0f).sub(viewCenterPoint)
		val Vector3f ORIG_TOP_RIGHT = new Vector3f(system.positionX + system.width, system.positionY, 0f).sub(
			viewCenterPoint)

		val labelWidth = 2.5f

		val labelOffsetTop = 0.3f

		val absolutLabelLeftStart = ORIG_TOP_LEFT.x + ((ORIG_TOP_RIGHT.x - ORIG_TOP_LEFT.x) / 2f) - (labelWidth / 2f)

		val BOTTOM_LEFT = new Vector3f(absolutLabelLeftStart, ORIG_TOP_LEFT.y - labelOffsetTop - SYSTEM_LABEL_HEIGHT,
			0.05f)
		val BOTTOM_RIGHT = new Vector3f(absolutLabelLeftStart + labelWidth,
			ORIG_TOP_RIGHT.y - labelOffsetTop - SYSTEM_LABEL_HEIGHT, 0.05f)
		val TOP_RIGHT = new Vector3f(absolutLabelLeftStart + labelWidth, ORIG_TOP_RIGHT.y - labelOffsetTop, 0.05f)
		val TOP_LEFT = new Vector3f(absolutLabelLeftStart, ORIG_TOP_LEFT.y - labelOffsetTop, 0.05f)

		LabelContainer::createLabel(name, BOTTOM_LEFT, BOTTOM_RIGHT, TOP_RIGHT, TOP_LEFT, false, false, false, false,
			false)
	}

	private def static void drawTutorialIfEnabled(DrawNodeEntity nodeEntity, Vector3f pos) {
		arrows.addAll(
			Experiment::drawTutorial(nodeEntity.name, pos, nodeEntity.width, nodeEntity.height, viewCenterPoint))
	}

	def private static createNodeGroupDrawing(NodeGroup nodeGroup, float z, List<PrimitiveObject> polygons) {
		if (!ExplorViz::controlGroupActive) {
			nodeGroup.positionZ = z

			if (nodeGroup.nodes.size() > 1) {
				QuadContainer::createQuad(nodeGroup, viewCenterPoint, null, NodeGroup::backgroundColor, false)
				createOpenSymbol(nodeGroup, NodeGroup::plusColor, NodeGroup::backgroundColor)
			}
		}

		for (node : nodeGroup.nodes)
			createNodeDrawing(node, z, polygons)

		if (!ExplorViz::controlGroupActive) {
			drawTutorialIfEnabled(nodeGroup, new Vector3f(nodeGroup.positionX, nodeGroup.positionY + 0.05f, z))
		}
	}

	def private static createNodeDrawing(Node node, float z, List<PrimitiveObject> polygons) {
		if (node.visible) {
			var specialRequestSymbol = false
			if (node.applications.size == 1 && node.applications.get(0).name == "Requests") {
				specialRequestSymbol = true
			}

			node.positionZ = z + 0.01f
			if (!specialRequestSymbol) {
				QuadContainer::createQuad(node, viewCenterPoint, null, ColorDefinitions::nodeBackgroundColor, false)

				createNodeLabel(node, node.displayName)
			}

			for (app : node.applications)
				createApplicationDrawing(app, z, polygons)

			if (!specialRequestSymbol) {
				drawTutorialIfEnabled(node, new Vector3f(node.positionX, node.positionY, z))
			}
		}
	}

	def private static void createNodeLabel(Node node, String labelName) {
		val ORIG_BOTTOM_LEFT = new Vector3f(node.positionX, node.positionY - node.height, 0f).sub(viewCenterPoint)
		val ORIG_BOTTOM_RIGHT = new Vector3f(node.positionX + node.width, node.positionY - node.height, 0f).sub(
			viewCenterPoint)

		val labelWidth = 2.0f
		val labelHeight = NODE_LABEL_HEIGHT

		val labelOffsetBottom = 0.2f

		val absolutLabelLeftStart = ORIG_BOTTOM_LEFT.x + ((ORIG_BOTTOM_RIGHT.x - ORIG_BOTTOM_LEFT.x) / 2f) -
			(labelWidth / 2f)

		val BOTTOM_LEFT = new Vector3f(absolutLabelLeftStart, ORIG_BOTTOM_LEFT.y + labelOffsetBottom, 0.05f)
		val BOTTOM_RIGHT = new Vector3f(absolutLabelLeftStart + labelWidth, ORIG_BOTTOM_RIGHT.y + labelOffsetBottom,
			0.05f)
		val TOP_RIGHT = new Vector3f(absolutLabelLeftStart + labelWidth,
			ORIG_BOTTOM_RIGHT.y + labelOffsetBottom + labelHeight, 0.05f)
		val TOP_LEFT = new Vector3f(absolutLabelLeftStart, ORIG_BOTTOM_LEFT.y + labelOffsetBottom + labelHeight, 0.05f)

		LabelContainer::createLabel(labelName, BOTTOM_LEFT, BOTTOM_RIGHT, TOP_RIGHT, TOP_LEFT, false, true, false,
			false, false)
	}

	def private static createApplicationDrawing(Application application, float z, List<PrimitiveObject> polygons) {
		var specialRequestSymbol = false
		if (application.name == "Requests") {
			specialRequestSymbol = true
		}

		if (!specialRequestSymbol) {
			application.positionZ = z + 0.1f
			QuadContainer::createQuad(application, viewCenterPoint, null, null, true)
			createApplicationLabel(application, application.name)

			val logoTexture = if (application.database)
					databasePicture
				else if (application.programmingLanguage == ELanguage::JAVA) {
					javaPicture
				} else if (application.programmingLanguage == ELanguage::C) {
					cPicture
				} else if (application.programmingLanguage == ELanguage::CPP) {
					cppPicture
				} else if (application.programmingLanguage == ELanguage::CSHARP) {
					csharpPicture
				} else if (application.programmingLanguage == ELanguage::PERL) {
					perlPicture
				} else if (application.programmingLanguage == ELanguage::JAVASCRIPT) {
					javascriptPicture
				} else if (application.programmingLanguage == ELanguage::PYTHON) {
					pythonPicture
				} else if (application.programmingLanguage == ELanguage::RUBY) {
					rubyPicture
				} else if (application.programmingLanguage == ELanguage::PHP) {
					phpPicture
				} else {
					unknownPicture
				}

			val logo = new Quad(
				new Vector3f(
					application.positionX + application.width - APPLICATION_PIC_SIZE / 2f -
						APPLICATION_PIC_PADDING_SIZE - viewCenterPoint.x,
					application.positionY - application.height / 2f - viewCenterPoint.y + APPLICATION_LABEL_HEIGHT / 8f,
					application.positionZ + 0.01f - viewCenterPoint.z),
				new Vector3f(APPLICATION_PIC_SIZE, APPLICATION_PIC_SIZE, 0f), logoTexture, null, true, true)

			polygons.add(logo)

		} else {
			val logo = new Quad(
				new Vector3f(application.positionX + application.width / 2f - viewCenterPoint.x,
					application.positionY - application.height / 2f - viewCenterPoint.y,
					application.positionZ + 0.01f - viewCenterPoint.z),
				new Vector3f(APPLICATION_PIC_SIZE * 6, APPLICATION_PIC_SIZE * 6, 0f), requestsPicture, null, true, true)

			polygons.add(logo)
		}

		drawTutorialIfEnabled(application, new Vector3f(application.positionX, application.positionY - 0.05f, z))
	}

	def private static void createApplicationLabel(Application app, String labelName) {
		val ORIG_BOTTOM_LEFT = new Vector3f(app.positionX, app.positionY - app.height, 0f).sub(viewCenterPoint)
		val ORIG_TOP_RIGHT = new Vector3f(app.positionX + app.width, app.positionY, 0f).sub(viewCenterPoint)

		val labelWidth = 2.0f

		val X_LEFT = ORIG_BOTTOM_LEFT.x +
			(((ORIG_TOP_RIGHT.x - ORIG_BOTTOM_LEFT.x) - APPLICATION_PIC_PADDING_SIZE - APPLICATION_PIC_SIZE) / 2f) -
			(labelWidth / 2f)
		val Y_BOTTOM = ORIG_BOTTOM_LEFT.y + ((ORIG_TOP_RIGHT.y - ORIG_BOTTOM_LEFT.y) / 2f) -
			(APPLICATION_LABEL_HEIGHT / 2f)

		val BOTTOM_LEFT = new Vector3f(X_LEFT, Y_BOTTOM, 0.05f)
		val BOTTOM_RIGHT = new Vector3f(X_LEFT + labelWidth, Y_BOTTOM, 0.05f)
		val TOP_RIGHT = new Vector3f(X_LEFT + labelWidth, Y_BOTTOM + APPLICATION_LABEL_HEIGHT, 0.05f)
		val TOP_LEFT = new Vector3f(X_LEFT, Y_BOTTOM + APPLICATION_LABEL_HEIGHT, 0.05f)

		LabelContainer::createLabel(labelName, BOTTOM_LEFT, BOTTOM_RIGHT, TOP_RIGHT, TOP_LEFT, false, true, false,
			false, false)
	}

	def static void createCommunicationAccumlated(float z, Communication commu,
		List<CommunicationAccumulator> communicationAccumulated) {
		val lineZvalue = z + 0.02f

		if (!commu.points.empty) {
			val accum = new CommunicationAccumulator()
			communicationAccumulated.add(accum)

			for (var i = 1; i < commu.points.size; i++) {
				val lastPoint = commu.points.get(i - 1)
				val thisPoint = commu.points.get(i)

				val tile = seekOrCreateTile(lastPoint, thisPoint, communicationAccumulated, lineZvalue)
				tile.communications.add(commu)
				tile.requestsCache = tile.requestsCache + commu.requests

				accum.tiles.add(tile)
			}
		}
	}

	def static private seekOrCreateTile(Point start, Point end, List<CommunicationAccumulator> communicationAccumulated,
		float z) {
		for (accum : communicationAccumulated) {
			for (tile : accum.tiles) {
				if (tile.startPoint.equals(start) && tile.endPoint.equals(end)) {
					return tile
				}
			}
		}

		val tile = new CommunicationTileAccumulator()
		tile.startPoint = start
		tile.endPoint = end
		tile.positionZ = z
		tile
	}

	def static private void createCommunicationLineDrawing(List<CommunicationAccumulator> communicationAccumulated) {
		val requestsList = new ArrayList<Integer>
		for (commu : communicationAccumulated)
			for (tile : commu.tiles)
				requestsList.add(tile.requestsCache)

		val categories = MathHelpers::getCategoriesForCommunication(requestsList)

		for (commu : communicationAccumulated) {
			commu.primitiveObjects.clear()
			for (var i = 0; i < commu.tiles.size; i++) {
				val tile = commu.tiles.get(i)
				
				if (!ExplorViz::controlGroupActive) {
					tile.lineThickness = 0.07f * categories.get(tile.requestsCache) + 0.01f
				} else {
					if (tile.communications.size == 1) {
						if (commu.tiles.size == 2) {
							if (i == commu.tiles.size - 1) {
								createCommunicationLabel(tile.requestsCache, tile)
							}
						} else if (commu.tiles.size >= 7) {
							if (i == commu.tiles.size - 3) {
								createCommunicationLabel(tile.requestsCache, tile)
							}
						} else if (commu.tiles.size >= 3) {
							if (i == commu.tiles.size - 2) {
								createCommunicationLabel(tile.requestsCache, tile)
							}
						} else {
							createCommunicationLabel(tile.requestsCache, tile)
						}
					}

					tile.lineThickness = 0.07f * 1.3f + 0.01f
				}
			}
			LineContainer::createLine(commu, viewCenterPoint)
		}
	}

	def static createCommunicationLabel(int requests, CommunicationTileAccumulator tileAccum) {
		var vectorX = (tileAccum.endPoint.x - tileAccum.startPoint.x) 
		var vectorY = (tileAccum.endPoint.y - tileAccum.startPoint.y)
		
		if (Math.abs(vectorX) >= 7f || Math.abs(vectorY) >= 7f) {
			vectorX = vectorX - 0.05f * vectorX
			vectorY = vectorY - 0.05f * vectorY
		} else {
			vectorX = vectorX - 0.5f * vectorX
			vectorY = vectorY - 0.5f * vectorY
		}

		val posX = tileAccum.startPoint.x + vectorX
		val posY = tileAccum.startPoint.y + vectorY

		val ORIG_BOTTOM_LEFT = new Vector3f(posX, posY, 0f).sub(viewCenterPoint)

		val labelWidth = 1.0f

		val X_LEFT = ORIG_BOTTOM_LEFT.x - (labelWidth / 2f)
		val Y_BOTTOM = ORIG_BOTTOM_LEFT.y - (APPLICATION_LABEL_HEIGHT / 2f)

		val BOTTOM_LEFT = new Vector3f(X_LEFT, Y_BOTTOM, 0.05f)
		val BOTTOM_RIGHT = new Vector3f(X_LEFT + labelWidth, Y_BOTTOM, 0.05f)
		val TOP_RIGHT = new Vector3f(X_LEFT + labelWidth, Y_BOTTOM + APPLICATION_LABEL_HEIGHT, 0.05f)
		val TOP_LEFT = new Vector3f(X_LEFT, Y_BOTTOM + APPLICATION_LABEL_HEIGHT, 0.05f)

		LabelContainer::createLabel(requests + " req", BOTTOM_LEFT, BOTTOM_RIGHT, TOP_RIGHT, TOP_LEFT, false, false,
			false, false, false)
	}

}
